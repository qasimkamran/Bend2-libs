# Direct HTTP/1.1 client. Reuses the pinned bend-kit HTTP codecs and policies.
import Base
import 0x2ef00d214bb4173160420b61a1472572/http.bend as Http
import 0x49814d83de8f70993a43e1002be29ecd/bytes.bend as Bytes
import 0x1f2d80f53f971b16c6de6a65cb1918ae/url.bend as Url
import ./wire/wire.bend as Wire
import ./direct_h1/Blocking.bend as Blocking
import ./direct_h1/Pool.bend as Idle
import bend-kit-concurrency@0.1.0.0/concurrency.bend as Conc

# Milliseconds; total_ms=0 disables the shared elapsed-time budget.
# Other timeouts and limits must be nonzero. Caps apply independently per hop.
# Decoded output also has the upstream decoder's fixed 16 MiB allocation cap.
type Options is Data:
    Options{connect_ms: U32, read_ms: U32, write_ms: U32, total_ms: U32,
        header_bytes: U32, body_bytes: U32, wire_bytes: U32,
        redirects: Nat, mode: Http.Mode, encoding: String,
        cert: Maybe<&2, Http.Cert>}

def defaults() -> Options:
    Options{5000, 10000, 5000, 30000, 65536, 16777216, 16842752,
        20n, Http.ModeFollow{}, "identity", None{}}

def valid(o: Options) -> Bool:
    Options{c, r, w, _, h, b, wire, _, _, _, _} = o
    Bool.and(Bool.and(U32.is_ne(c, 0), U32.is_ne(r, 0)),
        Bool.and(U32.is_ne(w, 0), Bool.and(U32.is_ne(h, 0),
            Bool.and(U32.is_ne(b, 0), U32.is_ne(wire, 0)))))

# Return zero only when the total budget is exhausted, never to mean an
# unlimited socket operation. IO.now is monotonic milliseconds.
def remaining(total: U32, start: Nat, now: Nat, phase: U32) -> U32:
    Blocking.remaining(total, start, now, phase)

type Reader is Type:
    Head{buf: Bytes.Bytes, interim: U32, received: U32}
    Body{res: Http.Res, framing: Http.Rb, parts: List<&1, Bytes.Bytes>, size: Nat, persistent: Bool}
    Complete{res: Http.Res, reusable: Bool}
    Broken{}

# Count only this read's newly decoded fragments; do not rescan old fragments.
def fragments.cons(+len: U32, buf: Array<U32>, counted: List<&1, Bytes.Bytes> & Nat) -> List<&1, Bytes.Bytes> & Nat:
    (parts, n) = counted
    (Bytes.Bytes{len, buf} <> parts, Nat.add(U32.to_nat(len), n))

def fragments(xs: List<&1, Bytes.Bytes>) -> List<&1, Bytes.Bytes> & Nat:
    match xs:
        case Nil{}: (Nil{}, 0n)
        case x <> tail:
            Bytes.Bytes{+len, buf} = x
            fragments.cons(len, buf, fragments(tail))

def reusable(+status: U32, +headers: Map<&2, List<&2, String>>, rest: Bytes.Bytes) -> Bool:
    Bytes.Bytes{len, _} = rest
    Bool.and(U32.is_zero(len), Bool.and(U32.is_ne(status, 101),
        Bool.not(Http.ce.has(Http.ce.split(Http.fields(headers, "connection")), "close"))))

def fed.kind(rb: Http.Rb, res: Http.Res, parts: List<&1, Bytes.Bytes>, rest: Bytes.Bytes, size: Nat, persistent: Bool) -> Reader:
    match rb:
        case Http.RbDone{}:
            Http.Res{+status, +headers, _} = res
            Complete{Http.Res{status, headers, Http.rb.body(parts)}, Bool.and(persistent, reusable(status, headers, rest))}
        case Http.RbBad{}: Broken{}
        case other: Body{res, other, parts, size, persistent}

def fed.cap(ok: Bool, rb: Http.Rb, res: Http.Res, parts: List<&1, Bytes.Bytes>, rest: Bytes.Bytes, size: Nat, persistent: Bool) -> Reader:
    match ok:
        case False{}: Broken{}
        case True{}: fed.kind(rb, res, parts, rest, size, persistent)

def fed.parts(limit: U32, res: Http.Res, old: List<&1, Bytes.Bytes>, size: Nat, rb: Http.Rb, rest: Bytes.Bytes, counted: List<&1, Bytes.Bytes> & Nat, persistent: Bool) -> Reader:
    (fresh, n) = counted
    +total = Nat.add(size, n)
    fed.cap(Nat.is_le(total, U32.to_nat(limit)), rb, res,
        List.append(&1, Bytes.Bytes, fresh, old), rest, total, persistent)

def fed(limit: U32, res: Http.Res, parts: List<&1, Bytes.Bytes>, size: Nat, bf: Http.Bf, persistent: Bool) -> Reader:
    Http.Bf{rb, fresh, rest} = bf
    fed.parts(limit, res, parts, size, rb, rest, fragments(fresh), persistent)

def body.start.ok(ok: Bool, limit: U32, res: Http.Res, rb: Http.Rb, rest: Bytes.Bytes, persistent: Bool) -> Reader:
    match ok:
        case False{}: Broken{}
        case True{}: fed(limit, res, Nil{}, 0n, Http.rb.feed(rb, Nil{}, rest), persistent)

# Check Content-Length before allocating/accumulating its body. Unknown-length
# bodies are checked after each bounded read, before retention/concatenation.
def body.start(+limit: U32, res: Http.Res, rb: Http.Rb, rest: Bytes.Bytes, persistent: Bool) -> Reader:
    match rb:
        case Http.RbLen{+n}: body.start.ok(U32.is_le(n, limit), limit, res, Http.RbLen{n}, rest, persistent)
        case other: body.start.ok(True{}, limit, res, other, rest, persistent)

def scanned.hs(limit: U32, received: U32, persistent: Bool, hs: Http.Hs) -> Reader:
    match hs:
        case Http.HsWait{buf, k}: Head{buf, k, received}
        case Http.HsRes{res, rb, rest}: body.start(limit, res, rb, rest, persistent)
        case Http.HsSeek{_, _, _}: Broken{}
        case Http.HsBad{}: Broken{}

type Scanned is Type:
    Scanned{state: Http.Hs, persistent: Bool}

# Retain the final response's HTTP version, which the upstream Res omits.
# Inspect a tiny slice, and reuse the original header scanner for every step.
@unsafe
def scan.step(fuel: Nat, head: Bool, persistent: Bool, hs: Http.Hs) -> Scanned:
    match hs:
        case Http.HsSeek{buf, from, k}: scan(fuel, head, Http.HsSeek{buf, from, k})
        case Http.HsRes{res, rb, rest}: Scanned{Http.HsRes{res, rb, rest}, persistent}
        case other: Scanned{other, False{}}

@unsafe
def scan.seek(fuel: Nat, +head: Bool, from: U32, k: U32, pair: Bytes.Bytes & Bytes.Bytes) -> Scanned:
    (buf, prefix) = pair
    scan.step(fuel, head, String.starts_with(Bytes.to_string(prefix), "HTTP/1.1 "),
        Http.hs.step(head, Http.HsSeek{buf, from, k}))

@unsafe
def scan(fuel: Nat, head: Bool, hs: Http.Hs) -> Scanned:
    match fuel:
        case 0n: Scanned{hs, False{}}
        case 1n+n:
            match hs:
                case Http.HsSeek{buf, from, k}: scan.seek(n, head, from, k, Bytes.slice(buf, 0, 12))
                case other: Scanned{other, False{}}

def scan.more(+head: Bool, +k: U32, buf: Bytes.Bytes, piece: Bytes.Bytes) -> Scanned:
    Bytes.Bytes{+len, words} = buf
    scan(10n, head, Http.HsSeek{Bytes.append(Bytes.Bytes{len, words}, piece),
        Bool.pick(U32, U32.is_lt(len, 3), 0, (len - 3 : U32)), k})

def scanned(limit: U32, received: U32, out: Scanned) -> Reader:
    Scanned{hs, persistent} = out
    scanned.hs(limit, received, persistent, hs)

def eof.ok(ok: Bool, res: Http.Res, parts: List<&1, Bytes.Bytes>) -> Reader:
    match ok:
        case False{}: Broken{}
        case True{}:
            Http.Res{status, headers, _} = res
            Complete{Http.Res{status, headers, Http.rb.body(parts)}, False{}}

def eof(st: Reader) -> Reader:
    match st:
        case Body{res, rb, parts, _, _}: eof.ok(Http.rb.eof(rb), res, parts)
        case Complete{res, keep}: Complete{res, keep}
        case Head{_, _, _}: Broken{}
        case Broken{}: Broken{}

def piece.open(limit: U32, head: Bool, st: Reader, +len: U32, buf: Array<U32>) -> Reader:
    match st:
        case Head{old, k, received}:
            scanned(limit, (received + len : U32), scan.more(head, k, old, Bytes.Bytes{len, buf}))
        case Body{res, rb, parts, size, persistent}:
            fed(limit, res, parts, size, Http.rb.feed(rb, Nil{}, Bytes.Bytes{len, buf}), persistent)
        case Complete{res, keep}: Complete{res, keep}
        case Broken{}: Broken{}

def piece(closed: Bool, limit: U32, head: Bool, st: Reader, len: U32, buf: Array<U32>) -> Reader:
    match closed:
        case True{}: eof(st)
        case False{}: piece.open(limit, head, st, len, buf)

def read.cap(header_limit: U32, wire_left: U32, st: Reader) -> Reader & U32:
    match st:
        case Head{buf, k, +received}:
            (Head{buf, k, received}, U32.min(65536, U32.min(wire_left,
                U32.from_nat(Nat.sub(U32.to_nat(header_limit), U32.to_nat(received))))))
        case other: (other, U32.min(65536, wire_left))

def receive(tls: Bool, s: Socket, cap: U32, ms: U32) -> IO(Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>):
    match tls:
        case True{}: Wire.tls.recv.words(s, cap, ms)
        case False{}: Wire.recv.words(s, cap, ms)

def close(tls: Bool, s: Socket) -> IO(Unit):
    match tls:
        case True{}: Wire.tls.close(s)
        case False{}: Socket.close(s)

type Exchange is Type:
    Exchange{result: Result<&1, &1, Http.Err, Http.Res>, connection: Maybe<&1, Idle.Connection>, empty: Bool}

def failed(error: Http.Err) -> IO(Exchange):
    IO.pure(Exchange, Exchange{Fail{error}, None{}, True{}})

def finish(tls: Bool, s: Socket, result: Result<&1, &1, Http.Err, Http.Res>) -> IO(Exchange):
    do IO<Exchange>:
        close(tls, s)
        return Exchange{result, None{}, False{}}

def finish.empty(tls: Bool, s: Socket, error: Http.Err, empty: Bool) -> IO(Exchange):
    do IO<Exchange>:
        close(tls, s)
        return Exchange{Fail{error}, None{}, empty}

def complete(keep: Bool, tls: Bool, s: Socket, res: Http.Res) -> IO(Exchange):
    match keep:
        case False{}: finish(tls, s, Done{res})
        case True{}: IO.pure(Exchange, Exchange{Done{res}, Some{Idle.Connection{tls, s}}, False{}})

type Reading is Type:
    Reading{socket: Socket, reader: Reader, wire: U32}
    ReadError{socket: Socket, error: Http.Err, empty: Bool}

def received.piece(empty: Bool, limit: U32, head: Bool, st: Reader, wire: U32, s: Socket, +len: U32, buf: Array<U32>) -> Reading:
    match empty:
        case True{}: ReadError{s, Http.ErrRead{0, "peer closed before response"}, True{}}
        case False{}: Reading{s, piece(U32.is_zero(len), limit, head, st, len, buf), (wire + len : U32)}

def received(limit: U32, head: Bool, st: Reader, +wire: U32, pair: Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>) -> Reading:
    (s, result) = pair
    match result:
        case Fail{(+code, why)}: ReadError{s, Http.err.or_late(code, Http.ErrRead{code, why}), U32.is_zero(wire)}
        case Done{(+len, buf)}:
            received.piece(Bool.and(U32.is_zero(wire), U32.is_zero(len)), limit, head, st, wire, s, len, buf)

# IO state machines mirror the upstream receiver's unsafe loop. Every socket
# operation has a finite timeout; each response has a finite wire-byte budget.
@unsafe
def read.loop(+o: Options, +start: Nat, +tls: Bool, +head: Bool, state: Reading) -> IO(Exchange):
    Options{_, r, _, +total, h, b, w, _, _, _, _} = o
    match state:
        case ReadError{s, error, empty}: finish.empty(tls, s, error, empty)
        case Reading{s, st, +wire}:
            match st:
                case Complete{res, keep}: complete(keep, tls, s, res)
                case Broken{}: finish(tls, s, Fail{Http.ErrBad{}})
                case other:
                    read.prepare(o, start, tls, head, s, wire, b, r, total,
                        read.cap(h, (w - wire : U32), other))

@unsafe
def read.timed(o: Options, start: Nat, tls: Bool, head: Bool, s: Socket, st: Reader, wire: U32, limit: U32, +cap: U32, +ms: U32) -> IO(Exchange):
    read.ready(Bool.and(U32.is_ne(cap, 0), U32.is_ne(ms, 0)), o, start, tls, head, s, st, wire, limit, cap, ms)

@unsafe
def read.prepare(o: Options, +start: Nat, tls: Bool, head: Bool, s: Socket, wire: U32, limit: U32, phase: U32, total: U32, pair: Reader & U32) -> IO(Exchange):
    (next, +cap) = pair
    do IO<Exchange>:
        now : Nat <- IO.now()
        read.timed(o, start, tls, head, s, next, wire, limit, cap, remaining(total, start, now, phase))

@unsafe
def read.ready(ok: Bool, o: Options, start: Nat, +tls: Bool, +head: Bool, s: Socket, st: Reader, wire: U32, limit: U32, cap: U32, ms: U32) -> IO(Exchange):
    match ok:
        case False{}: finish(tls, s, Fail{Bool.pick(Http.Err, U32.is_zero(ms), Http.ErrTimeout{}, Http.ErrBad{})})
        case True{}:
            do IO<Exchange>:
                pair : Socket & Result<&1, &1, U32 & String, U32 & Array<U32>> <- receive(tls, s, cap, ms)
                read.loop(o, start, tls, head, received(limit, head, st, wire, pair))

# Serialize before sampling the write budget, so encoding time is charged.
def send(tls: Bool, s: Socket, wire: String, ms: U32) -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
    match tls:
        case True{}: Wire.tls.send.timeout(s, wire, ms)
        case False{}: Wire.send.timeout(s, wire, ms)

def sent(o: Options, start: Nat, +tls: Bool, head: Bool, pair: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Exchange):
    (s, result) = pair
    match result:
        case Fail{(+code, why)}: finish.empty(tls, s, Http.err.or_late(code, Http.ErrWrite{code, why}), True{})
        case Done{_}: read.loop(o, start, tls, head, Reading{s, Head{Bytes.new(0), 0, 0}, 0})

def write.ready(ok: Bool, o: Options, start: Nat, +tls: Bool, s: Socket, head: Bool, wire: String, ms: U32) -> IO(Exchange):
    match ok:
        case False{}: finish(tls, s, Fail{Http.ErrTimeout{}})
        case True{}:
            do IO<Exchange>:
                pair : Socket & Result<&1, &1, U32 & String, Unit> <- send(tls, s, wire, ms)
                sent(o, start, tls, head, pair)

def write.timed(o: Options, start: Nat, tls: Bool, s: Socket, head: Bool, wire: String, +ms: U32) -> IO(Exchange):
    write.ready(U32.is_ne(ms, 0), o, start, tls, s, head, wire, ms)

def write.prepared(+o: Options, +start: Nat, tls: Bool, s: Socket, head: Bool, wire: String) -> IO(Exchange):
    Options{_, _, w, total, _, _, _, _, _, _, _} = o
    do IO<Exchange>:
        now : Nat <- IO.now()
        write.timed(o, start, tls, s, head, wire, remaining(total, start, now, w))

def write.encoded(o: Options, start: Nat, tls: Bool, s: Socket, head: Bool, wire: Bytes.Bytes) -> IO(Exchange):
    write.prepared(o, start, tls, s, head, Bytes.to_string(wire))

def write(o: Options, start: Nat, tls: Bool, s: Socket, +method: String, +url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Exchange):
    Url.Abs{_, _, _, target} = url
    write.encoded(o, start, tls, s, String.eq(method, "HEAD"),
        Http.encode_req.on(method, target, Url.host_field(url), headers, body, False{}))

def handshake.done(o: Options, start: Nat, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, pair: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Exchange):
    (s, result) = pair
    match result:
        case Fail{(+code, why)}: finish(True{}, s, Fail{Http.err.or_late(code, Http.ErrTls{code, why})})
        case Done{_}: write(o, start, True{}, s, method, url, headers, body)

def handshake.cert(cert: Maybe<&2, Http.Cert>, s: Socket, host: String, ms: U32) -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
    match cert:
        case None{}: Wire.tls.connect(s, host, ms)
        case Some{Http.Cert{chain, key}}: Wire.tls.connect.cert(s, host, ms, chain, key)

def handshake.ready(ok: Bool, o: Options, start: Nat, s: Socket, method: String, +url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, cert: Maybe<&2, Http.Cert>, ms: U32) -> IO(Exchange):
    match ok:
        case False{}: finish(False{}, s, Fail{Http.ErrTimeout{}})
        case True{}:
            Url.Abs{_, host, _, _} = url
            do IO<Exchange>:
                pair : Socket & Result<&1, &1, U32 & String, Unit> <- handshake.cert(cert, s, host, ms)
                handshake.done(o, start, method, url, headers, body, pair)

def handshake.timed(o: Options, start: Nat, s: Socket, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, cert: Maybe<&2, Http.Cert>, +ms: U32) -> IO(Exchange):
    handshake.ready(U32.is_ne(ms, 0), o, start, s, method, url, headers, body, cert, ms)

def connected.socket(+o: Options, +start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, s: Socket) -> IO(Exchange):
    Options{c, _, _, total, _, _, _, _, _, _, cert} = o
    match tls:
        case False{}: write(o, start, False{}, s, method, url, headers, body)
        case True{}:
            do IO<Exchange>:
                now : Nat <- IO.now()
                handshake.timed(o, start, s, method, url, headers, body, cert, remaining(total, start, now, c))

def connected(o: Options, start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, result: Result<&1, &1, U32 & String, Socket>) -> IO(Exchange):
    match result:
        case Fail{(+code, why)}: failed(Http.err.or_late(code, Http.ErrConnect{code, why}))
        case Done{s}: connected.socket(o, start, tls, method, url, headers, body, s)

def dial.ready(ok: Bool, o: Options, start: Nat, tls: Bool, method: String, +url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, first: String, rest: List<&2, String>, now: Nat, ms: U32) -> IO(Exchange):
    match ok:
        case False{}: failed(Http.ErrTimeout{})
        case True{}:
            Url.Abs{_, _, port, _} = url
            do IO<Exchange>:
                result : Result<&1, &1, U32 & String, Socket> <- Http.conn.dial.all(port, ms, now, first, rest)
                connected(o, start, tls, method, url, headers, body, result)

def dial.timed(o: Options, start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, first: String, rest: List<&2, String>, now: Nat, +ms: U32) -> IO(Exchange):
    dial.ready(U32.is_ne(ms, 0), o, start, tls, method, url, headers, body, first, rest, now, ms)

def resolved.time(o: Options, +start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, first: String, rest: List<&2, String>, +now: Nat, total: U32, phase: U32) -> IO(Exchange):
    dial.timed(o, start, tls, method, url, headers, body, first, rest, now, remaining(total, start, now, phase))

def resolved(+o: Options, +start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, addresses: List<&2, String>) -> IO(Exchange):
    Options{c, _, _, total, _, _, _, _, _, _, _} = o
    match addresses:
        case Nil{}: failed(Http.ErrDns{})
        case first <> rest:
            do IO<Exchange>:
                now : Nat <- IO.now()
                resolved.time(o, start, tls, method, url, headers, body, first, rest, now, total, c)

def resolved.result(o: Options, start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, result: Result<&1, &1, Http.Err, List<&2, String>>) -> IO(Exchange):
    match result:
        case Fail{e}: failed(e)
        case Done{addresses}: resolved(o, start, tls, method, url, headers, body, addresses)


def one.ready(ok: Bool, o: Options, start: Nat, tls: Bool, method: String, +url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, ms: U32) -> IO(Exchange):
    match ok:
        case False{}: failed(Http.ErrTimeout{})
        case True{}:
            Url.Abs{_, host, _, _} = url
            do IO<Exchange>:
                addresses : Result<&1, &1, Http.Err, List<&2, String>> <- Blocking.dns(host, ms)
                resolved.result(o, start, tls, method, url, headers, body, addresses)

def one.timed(o: Options, start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, +ms: U32) -> IO(Exchange):
    one.ready(U32.is_ne(ms, 0), o, start, tls, method, url, headers, body, ms)

def one.budget(+o: Options, +start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Exchange):
    Options{c, _, _, total, _, _, _, _, _, _, _} = o
    do IO<Exchange>:
        now : Nat <- IO.now()
        one.timed(o, start, tls, method, url, headers, body, remaining(total, start, now, c))

def one.valid(ok: Bool, o: Options, start: Nat, tls: Bool, method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Exchange):
    match ok:
        case False{}: failed(Http.ErrUrl{})
        case True{}: one.budget(o, start, tls, method, url, headers, body)

def one(o: Options, start: Nat, hop: Http.Hop) -> IO(Exchange):
    Http.Hop{method, +url, headers, body} = hop
    Url.Abs{+scheme, _, _, _} = url
    +tls = String.eq(scheme, "https")
    one.valid(Bool.or(tls, String.eq(scheme, "http")), o, start, tls, method, url, headers, body)

# Pool keys reuse the original origin/client-certificate identity scheme.
def Pool() -> Type:
    Idle.Pool

def pool.new() -> Idle.Pool:
    Idle.new()

def pool.new.with(capacity: U32, idle_ms: U32) -> Idle.Pool:
    Idle.new.with(capacity, idle_ms)

def pool.close(pool: Idle.Pool) -> IO(Unit):
    Idle.close(pool)

def exchange.store(pool: Idle.Pool, key: String, exchange: Exchange) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    Exchange{result, connection, _} = exchange
    match connection:
        case None{}: IO.pure(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>, (pool, result))
        case Some{c}:
            do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
                updated : Idle.Pool <- Idle.put(pool, key, c)
                return (updated, result)

def fresh(pool: Idle.Pool, key: String, o: Options, start: Nat, hop: Http.Hop) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
        exchange : Exchange <- one(o, start, hop)
        exchange.store(pool, key, exchange)

def reused.split(o: Options, start: Nat, +method: String, +url: Url.Abs, +headers: Map<&2, List<&2, String>>, connection: Idle.Connection, bodies: Bytes.Bytes & Bytes.Bytes) -> IO(Http.Hop & Exchange):
    Idle.Connection{tls, socket} = connection
    (original, body) = bodies
    do IO<Http.Hop & Exchange>:
        exchange : Exchange <- write(o, start, tls, socket, method, url, headers, body)
        return (Http.Hop{method, url, headers, original}, exchange)

def reused(o: Options, start: Nat, hop: Http.Hop, c: Idle.Connection) -> IO(Http.Hop & Exchange):
    Http.Hop{method, url, headers, body} = hop
    reused.split(o, start, method, url, headers, c, Bytes.slice(body, 0, 4294967295))

def retry.decide(retry: Bool, pool: Idle.Pool, key: String, o: Options, start: Nat, hop: Http.Hop, error: Http.Err) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    match retry:
        case True{}: fresh(pool, key, o, start, hop)
        case False{}: IO.pure(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>, (pool, Fail{error}))

# Only stale pooled connections can retry, once, and only for idempotent
# methods when no response bytes arrived. POST/PATCH are never replayed.
def reused.result(pool: Idle.Pool, +key: String, o: Options, start: Nat, pair: Http.Hop & Exchange) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    (hop, exchange) = pair
    Http.Hop{+method, url, headers, body} = hop
    Exchange{result, connection, empty} = exchange
    match result:
        case Done{res}:
            exchange.store(pool, key, Exchange{Done{res}, connection, empty})
        case Fail{e}:
            retry.decide(Bool.and(empty, Http.pool.idempotent(method)), pool, key, o, start,
                Http.Hop{method, url, headers, body}, e)

def taken(+o: Options, +start: Nat, +key: String, hop: Http.Hop, pair: Idle.Pool & Maybe<&1, Idle.Connection>) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    (pool, got) = pair
    match got:
        case None{}: fresh(pool, key, o, start, hop)
        case Some{c}:
            do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
                result : Http.Hop & Exchange <- reused(o, start, hop, c)
                reused.result(pool, key, o, start, result)

def pooled.take(o: Options, start: Nat, pool: Idle.Pool, +key: String, hop: Http.Hop) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
        pair : Idle.Pool & Maybe<&1, Idle.Connection> <- Idle.take(pool, key)
        taken(o, start, key, hop, pair)


def pooled.key(+o: Options, start: Nat, pool: Idle.Pool, hop: Http.Hop) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    Options{_, _, _, _, _, _, _, _, _, _, cert} = o
    Http.Hop{method, +url, headers, body} = hop
    Url.Abs{scheme, host, port, _} = url
    pooled.take(o, start, pool, Http.pool.key.cert(Http.pool.key(scheme, host, port), cert),
        Http.Hop{method, url, headers, body})

# Retain request bytes explicitly for redirects (Bytes and Hop are affine).
def one.back(hop: Http.Hop, pair: Idle.Pool & Result<&1, &1, Http.Err, Http.Res>) -> Idle.Pool & Http.Hop & Result<&1, &1, Http.Err, Http.Res>:
    (pool, result) = pair
    (pool, hop, result)


def one.split(o: Options, start: Nat, pool: Idle.Pool, +method: String, +url: Url.Abs, +headers: Map<&2, List<&2, String>>, pair: Bytes.Bytes & Bytes.Bytes) -> IO(Idle.Pool & Http.Hop & Result<&1, &1, Http.Err, Http.Res>):
    (original, body) = pair
    do IO<Idle.Pool & Http.Hop & Result<&1, &1, Http.Err, Http.Res>>:
        result : Idle.Pool & Result<&1, &1, Http.Err, Http.Res> <-
            pooled.key(o, start, pool, Http.Hop{method, url, headers, body})
        return one.back(Http.Hop{method, url, headers, original}, result)

def one.replay(o: Options, start: Nat, pool: Idle.Pool, hop: Http.Hop) -> IO(Idle.Pool & Http.Hop & Result<&1, &1, Http.Err, Http.Res>):
    Http.Hop{method, url, headers, body} = hop
    one.split(o, start, pool, method, url, headers, Bytes.slice(body, 0, 4294967295))

def policy(mode: Http.Mode, left: Nat, pair: Idle.Pool & Http.Hop & Result<&1, &1, Http.Err, Http.Res>) -> Idle.Pool & Http.Next:
    (pool, hop, result) = pair
    (pool, Http.fetch.policy(mode, left, hop, result))

def bounded(ok: Bool, res: Http.Res) -> Result<&1, &1, Http.Err, Http.Res>:
    match ok:
        case True{}: Done{res}
        case False{}: Fail{Http.ErrBad{}}

def final.size(limit: U32, result: Result<&1, &1, Http.Err, Http.Res>) -> Result<&1, &1, Http.Err, Http.Res>:
    match result:
        case Fail{e}: Fail{e}
        case Done{Http.Res{status, headers, Bytes.Bytes{+len, buf}}}:
            bounded(U32.is_le(len, limit), Http.Res{status, headers, Bytes.Bytes{len, buf}})

def final.time(ok: Bool, result: Result<&1, &1, Http.Err, Http.Res>) -> Result<&1, &1, Http.Err, Http.Res>:
    match ok:
        case True{}: result
        case False{}: Fail{Http.ErrTimeout{}}

# Discard idle connections after a terminal decode/total-budget failure.
def final.pool(pool: Idle.Pool, result: Result<&1, &1, Http.Err, Http.Res>) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    match result:
        case Done{res}: IO.pure(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>, (pool, Done{res}))
        case Fail{e}:
            do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
                cleared : Idle.Pool <- Idle.clear(pool)
                return (cleared, Fail{e})

def final.decoded(o: Options, +start: Nat, pool: Idle.Pool, result: Result<&1, &1, Http.Err, Http.Res>) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    Options{_, _, _, total, _, limit, _, _, _, _, _} = o
    do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
        now : Nat <- IO.now()
        final.pool(pool, final.time(U32.is_ne(remaining(total, start, now, 1), 0), final.size(limit, result)))

def final(+o: Options, +start: Nat, pool: Idle.Pool, result: Result<&1, &1, Http.Err, Http.Res>) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    Options{_, r, _, total, _, _, _, _, _, enc, _} = o
    do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
        decoded : Result<&1, &1, Http.Err, Http.Res> <- Blocking.final(enc, result, total, start, r)
        final.decoded(o, start, pool, decoded)

@unsafe
def hops(+o: Options, +start: Nat, pair: Idle.Pool & Http.Next) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    Options{_, _, _, _, _, _, _, _, mode, _, _} = o
    (pool, state) = pair
    match state:
        case Http.NDone{result}: final(o, start, pool, result)
        case Http.NStop{}: final(o, start, pool, Fail{Http.ErrRedirect{}})
        case Http.NGo{left, hop}:
            do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
                result : Idle.Pool & Http.Hop & Result<&1, &1, Http.Err, Http.Res> <- one.replay(o, start, pool, hop)
                hops(o, start, policy(mode, left, result))

def fetch.start(+o: Options, start: Nat, pool: Idle.Pool, method: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, url: Maybe<&2, Url.Abs>) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    Options{_, _, _, _, _, _, _, left, _, enc, _} = o
    match url:
        case None{}: final(o, start, pool, Fail{Http.ErrUrl{}})
        case Some{a}:
            hops(o, start, (pool, Http.NGo{left, Http.Hop{method, a,
                Http.accept.enc(Http.req.put(Map.to_list(&2, List<&2, String>, headers), Http.empty()), enc), body}}))

def fetch.valid(ok: Bool, o: Options, start: Nat, pool: Idle.Pool, method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    match ok:
        case False{}: final(o, start, pool, Fail{Http.ErrBad{}})
        case True{}: fetch.start(o, start, pool, method, headers, body, Url.absolute(url))

def pool.fetch.with(pool: Idle.Pool, method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, +options: Options) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    do IO<Idle.Pool & Result<&1, &1, Http.Err, Http.Res>>:
        now : Nat <- IO.now()
        fetch.valid(valid(options), options, now, pool, method, url, headers, body)

def pool.fetch(pool: Idle.Pool, method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    pool.fetch.with(pool, method, url, headers, body, defaults())

def pool.get(pool: Idle.Pool, url: String) -> IO(Idle.Pool & Result<&1, &1, Http.Err, Http.Res>):
    pool.fetch(pool, "GET", url, Http.empty(), Bytes.new(0))

def fetch.end(pair: Idle.Pool & Result<&1, &1, Http.Err, Http.Res>) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    (pool, result) = pair
    do IO<Result<&1, &1, Http.Err, Http.Res>>:
        pool.close(pool)
        return result

def fetch.with(method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, options: Options) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    do IO<Result<&1, &1, Http.Err, Http.Res>>:
        pair : Idle.Pool & Result<&1, &1, Http.Err, Http.Res> <- pool.fetch.with(pool.new(), method, url, headers, body, options)
        fetch.end(pair)

def fetch(method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    fetch.with(method, url, headers, body, defaults())

def get(url: String) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    fetch("GET", url, Http.empty(), Bytes.new(0))

def head(url: String) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    fetch("HEAD", url, Http.empty(), Bytes.new(0))

type Worker is Type:
    Worker{options: Options, pool: Idle.Pool}

def fetch.all.back(options: Options, pair: Idle.Pool & Result<&1, &1, Http.Err, Http.Res>) -> Worker & Result<&1, &1, Http.Err, Http.Res>:
    (pool, result) = pair
    (Worker{options, pool}, result)

def fetch.all.run(+o: Options, pool: Idle.Pool, method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes) -> IO(Worker & Result<&1, &1, Http.Err, Http.Res>):
    do IO<Worker & Result<&1, &1, Http.Err, Http.Res>>:
        pair : Idle.Pool & Result<&1, &1, Http.Err, Http.Res> <- pool.fetch.with(pool, method, url, headers, body, o)
        return fetch.all.back(o, pair)

def fetch.all.job(worker: Worker, request: Http.Fetch) -> IO(Worker & Result<&1, &1, Http.Err, Http.Res>):
    Worker{o, pool} = worker
    Http.Fetch{method, url, headers, body} = request
    fetch.all.run(o, pool, method, url, headers, body)

def fetch.all.close(workers: List<Worker>) -> IO(Unit):
    match workers:
        case Nil{}: IO.pure(Unit, Unit{})
        case Worker{_, pool} <> tail:
            do IO<Unit>:
                pool.close(pool)
                fetch.all.close(tail)

def fetch.all.results(pair: List<Worker> & List<Result<&1, &1, Http.Err, Http.Res>>) -> IO(List<Result<&1, &1, Http.Err, Http.Res>>):
    (workers, results) = pair
    do IO<List<Result<&1, &1, Http.Err, Http.Res>>>:
        fetch.all.close(workers)
        return results

def fetch.all.workers(n: Nat, +o: Options) -> List<Worker>:
    match n:
        case 0n: Nil{}
        case 1n+p: Worker{o, pool.new()} <> fetch.all.workers(p, o)

def fetch.all.counted(o: Options, workers: U32, counted: Nat & List<Http.Fetch>) -> IO(List<Result<&1, &1, Http.Err, Http.Res>>):
    (+n, requests) = counted
    match requests:
        case Nil{}: IO.pure(List<Result<&1, &1, Http.Err, Http.Res>>, Nil{})
        case first <> rest:
            do IO<List<Result<&1, &1, Http.Err, Http.Res>>>:
                pair : List<Worker> & List<Result<&1, &1, Http.Err, Http.Res>> <-
                    Conc.pool(~Worker, ~Http.Fetch, ~Result<&1, &1, Http.Err, Http.Res>,
                        ~fetch.all.job, fetch.all.workers(Nat.min(n, Nat.max(1n, U32.to_nat(workers))), o), first <> rest)
                fetch.all.results(pair)

def fetch.all.with(requests: List<Http.Fetch>, workers: U32, options: Options) -> IO(List<Result<&1, &1, Http.Err, Http.Res>>):
    fetch.all.counted(options, workers, Conc.count(Http.Fetch, requests))

def fetch.all(requests: List<Http.Fetch>, workers: U32) -> IO(List<Result<&1, &1, Http.Err, Http.Res>>):
    fetch.all.with(requests, workers, defaults())
