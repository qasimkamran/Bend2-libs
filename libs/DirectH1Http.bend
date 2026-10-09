# HTTP/1.1 subset of paymog/bend-kit HTTP, pinned source 0x2ef00d214bb4173160420b61a1472572.
# Extracted without changing retained definitions; shared by DirectH1 and its server.
import Base
import bend-kit-wire@0.4.2.0/wire.bend as Wire
import bend-kit-time@0.1.0.0/time.bend as Time
import 0x1f2d80f53f971b16c6de6a65cb1918ae/url.bend as Url
import 0x49814d83de8f70993a43e1002be29ecd/bytes.bend as Bytes

type Req is Type:
  Req{method: String, path: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes}


type Res is Type:
  Res{status: U32, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes}

# The body type and its conversions, so a caller needs no bytes import.

def from_string(+s: String) -> Bytes.Bytes:
  Bytes.from_string(s)


type Err is Data:
  ErrUrl{}
  ErrDns{}
  ErrConnect{code: U32, why: String}
  ErrTls{code: U32, why: String}
  ErrRead{code: U32, why: String}
  ErrWrite{code: U32, why: String}
  ErrTimeout{}
  ErrRedirect{}
  ErrBad{}


def err.late(+code: U32) -> Bool:
  Bool.or(U32.is_eq(code, 60), U32.is_eq(code, 110))


def err.pick(e: Err, late: Bool) -> Err:
  match late:
    case True{}:
      ErrTimeout{}
    case False{}:
      e


def err.or_late(code: U32, e: Err) -> Err:
  err.pick(e, err.late(code))


type Fields is Data:
  FieldsBad{}
  FieldsOk{m: Map<&2, List<&2, String>>}

# One list per field name, in arrival order. header() is the first value.
# Set-Cookie is never joined. Encode writes one line per value.

def empty() -> Map<&2, List<&2, String>>:
  Map.new(&2, List<&2, String>)


def fields.of(r: Map<&2, List<&2, String>> & List<&2, String>) -> List<&2, String>:
  (h, xs) = r
  xs


def fields(+h: Map<&2, List<&2, String>>, k: String) -> List<&2, String>:
  fields.of(Map.get(List<&2, String>, Nil{}, h, k))


def header.first(xs: List<&2, String>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{v, t}:
      v


def header(+h: Map<&2, List<&2, String>>, k: String) -> String:
  header.first(fields(h, k))


def field.last(xs: List<&2, String>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{v, Nil{}}:
      v
    case Con{v, t}:
      field.last(t)

# Transfer-Encoding is a list; chunked, when present, is the last coding.

def header.last(+h: Map<&2, List<&2, String>>, k: String) -> String:
  field.last(fields(h, k))


def snoc(xs: List<&2, String>, v: String) -> List<&2, String>:
  match xs:
    case Nil{}:
      [v]
    case Con{h, t}:
      Con{h, snoc(t, v)}


def set(m: Map<&2, List<&2, String>>, k: String, v: String) -> Map<&2, List<&2, String>>:
  Map.set(&2, List<&2, String>, m, k, [v])


def add(+m: Map<&2, List<&2, String>>, +k: String, v: String) -> Map<&2, List<&2, String>>:
  Map.set(&2, List<&2, String>, m, k, snoc(fields(m, k), v))


def sanitize.cons(ch: Char, rest: String, drop: Bool) -> String:
  match drop:
    case True{}:
      rest
    case False{}:
      SCon{ch, rest}


def sanitize(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{+c}, t}:
      sanitize.cons(Chr{c}, sanitize(t), Bool.or(U32.is_eq(c, 13), U32.is_eq(c, 10)))


def drop_cr.last.if(cr: Bool, c: U32) -> String:
  match cr:
    case True{}:
      SNil{}
    case False{}:
      SCon{Chr{c}, SNil{}}


def drop_cr.last(+c: U32) -> String:
  drop_cr.last.if(U32.is_eq(c, 13), c)

# prev is the char before s; it is kept unless it is a final CR.

def drop_cr.go(s: String, prev: U32) -> String:
  match s:
    case SNil{}:
      drop_cr.last(prev)
    case SCon{Chr{c}, t}:
      SCon{Chr{prev}, drop_cr.go(t, c)}


def drop_cr(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{c}, t}:
      drop_cr.go(t, c)

# w holds the last four octets; a char past 255 clears it.

def blank_end.go(s: String, w: U32) -> Bool:
  match s:
    case SNil{}:
      U32.is_eq(w, 218762506)
    case SCon{Chr{+c}, t}:
      blank_end.go(t, Bool.pick(U32, U32.is_lt(c, 256), (w * 256 + c : U32), 0))

# String.ends_with(s, "\r\n\r\n") in one pass, with no reversed copy.

def blank_end(s: String) -> Bool:
  blank_end.go(s, 0)


def trim_end.cons(h: Char, r: String, space: Bool) -> String:
  match r:
    case SNil{}:
      match space:
        case True{}:
          SNil{}
        case False{}:
          SCon{h, SNil{}}
    case SCon{a, t}:
      SCon{h, SCon{a, t}}

# String.trim_end without the two reversed copies.

def trim_end(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+h, t}:
      trim_end.cons(h, trim_end(t), Char.is_space(h))


def trim(s: String) -> String:
  trim_end(String.trim_start(s))

# Bool.pick evaluates both arms; a split that recursed inside it would reverse acc at every byte.

def take.cut(acc: String, rest: String) -> String & String:
  (String.reverse(String.drop(acc, 1n)), rest)

# hit: the last char pushed onto acc was the stop char.

def take_sp.go(s: String, acc: String, hit: Bool) -> String & String:
  match s:
    case SNil{}:
      match hit:
        case True{}:
          take.cut(acc, SNil{})
        case False{}:
          (String.reverse(acc), SNil{})
    case SCon{Chr{+c}, t}:
      match hit:
        case True{}:
          take.cut(acc, SCon{Chr{c}, t})
        case False{}:
          take_sp.go(t, SCon{Chr{c}, acc}, U32.is_eq(c, 32))


def take_sp(s: String) -> String & String:
  take_sp.go(s, SNil{}, False{})


def start_line.ver(m: String, pv: String & String) -> String & String & String:
  (p, v) = pv
  (m, p, drop_cr(v))


def start_line.rest(mr: String & String) -> String & String & String:
  (m, r) = mr
  start_line.ver(m, take_sp(r))


def start_line(s: String) -> String & String & String:
  start_line.rest(take_sp(s))


def split_at_blank.flag.go(+raw: String, s: String, off: Nat, w: U32, e: Bool) -> String & String & Bool:
  match s:
    case SNil{}:
      (String.take(raw, off), SNil{}, e)
    case SCon{Chr{+a}, t}:
      match e:
        case True{}:
          (String.take(raw, off), SCon{Chr{a}, t}, True{})
        case False{}:
          +w2 = (w * 256 + a : U32)
          +off1 = (1n + off : Nat)
          split_at_blank.flag.go(raw, t, off1, w2, U32.is_eq(w2, 218762506))


def split_at_blank.pair(r: String & String & Bool) -> String & String:
  (head, rest, whole) = r
  (head, rest)


def split_at_blank(+s: String) -> String & String:
  split_at_blank.pair(split_at_blank.flag.go(s, s, 0n, 0, False{}))


def split_colon.go(s: String, acc: String, hit: Bool) -> String & String:
  match s:
    case SNil{}:
      match hit:
        case True{}:
          take.cut(acc, SNil{})
        case False{}:
          (String.reverse(acc), SNil{})
    case SCon{Chr{+c}, t}:
      match hit:
        case True{}:
          take.cut(acc, SCon{Chr{c}, t})
        case False{}:
          split_colon.go(t, SCon{Char.to_lower(Chr{c}), acc}, U32.is_eq(c, 58))


def split_colon(+s: String) -> String & String:
  split_colon.go(s, SNil{}, False{})


def has_header.of(r: Map<&2, List<&2, String>> & Bool) -> Bool:
  (h, b) = r
  b


def has_header(+h: Map<&2, List<&2, String>>, k: String) -> Bool:
  has_header.of(Map.has(&2, List<&2, String>, h, k))


def folded(+line: String) -> Bool:
  Bool.or(String.starts_with(line, " "), String.starts_with(line, "\t"))


def tracked(+k: String) -> Bool:
  Bool.or(String.eq(k, "host"), String.eq(k, "content-length"))


def fields_put.dup(m: Map<&2, List<&2, String>>, k: String, v: String, bad: Bool) -> Fields:
  match bad:
    case True{}:
      FieldsBad{}
    case False{}:
      FieldsOk{add(m, k, v)}


def fields_put.tracked(+m: Map<&2, List<&2, String>>, +k: String, v: String, t: Bool) -> Fields:
  match t:
    case True{}:
      fields_put.dup(m, k, v, has_header(m, k))
    case False{}:
      FieldsOk{add(m, k, v)}


def fields_put.key(+m: Map<&2, List<&2, String>>, +k: String, v: String) -> Fields:
  fields_put.tracked(m, k, v, tracked(k))


def fields_put.kv(m: Map<&2, List<&2, String>>, kv: String & String) -> Fields:
  (k, v) = kv
  fields_put.key(m, k, trim(v))


def fields_put.fold(m: Map<&2, List<&2, String>>, line: String, fold: Bool) -> Fields:
  match fold:
    case True{}:
      FieldsBad{}
    case False{}:
      fields_put.kv(m, split_colon(line))


def fields_put.empty(m: Map<&2, List<&2, String>>, +line: String, e: Bool) -> Fields:
  match e:
    case True{}:
      FieldsOk{m}
    case False{}:
      fields_put.fold(m, line, folded(line))


def fields_put.ok(m: Map<&2, List<&2, String>>, +line: String) -> Fields:
  fields_put.empty(m, line, String.is_empty(line))


def fields_put(acc: Fields, line: String) -> Fields:
  match acc:
    case FieldsBad{}:
      FieldsBad{}
    case FieldsOk{m}:
      fields_put.ok(m, line)


def parse.headers.done(acc: Fields) -> Maybe<&2, Map<&2, List<&2, String>>>:
  match acc:
    case FieldsBad{}:
      None{}
    case FieldsOk{m}:
      Some{m}



def parse.headers.scan.line(acc: String, fields: Fields) -> Fields:
  match acc:
    case SCon{Chr{13}, t}:
      fields_put(fields, String.reverse(t))
    case other:
      fields_put(fields, String.reverse(other))


def parse.headers.scan(s: String, acc: String, fields: Fields) -> Fields:
  match s:
    case SNil{}:
      parse.headers.scan.line(acc, fields)
    case SCon{Chr{10}, t}:
      parse.headers.scan(t, SNil{}, parse.headers.scan.line(acc, fields))
    case SCon{c, t}:
      parse.headers.scan(t, SCon{c, acc}, fields)


def parse.headers.raw(s: String) -> Maybe<&2, Map<&2, List<&2, String>>>:
  parse.headers.done(parse.headers.scan(s, SNil{}, FieldsOk{empty()}))


def parse.first(s: String, acc: String) -> String & String:
  match s:
    case SNil{}:
      (String.reverse(acc), SNil{})
    case SCon{Chr{10}, t}:
      (String.reverse(acc), t)
    case SCon{c, t}:
      parse.first(t, SCon{c, acc})


def parse_u32.digit(+c: U32) -> Bool:
  Bool.and(U32.is_le(48, c), U32.is_le(c, 57))


def parse_u32.add(acc: U32, c: U32) -> U32:
  (acc * 10 + (c - 48 : U32) : U32)


def parse_u32.done(acc: U32, bad: Bool) -> Maybe<&2, U32>:
  match bad:
    case True{}:
      None{}
    case False{}:
      Some{acc}


def parse_u32.go(s: String, acc: U32, bad: Bool) -> Maybe<&2, U32>:
  match s:
    case SNil{}:
      parse_u32.done(acc, bad)
    case SCon{Chr{+c}, t}:
      parse_u32.go(t, parse_u32.add(acc, c), Bool.or(bad, Bool.not(parse_u32.digit(c))))


def parse_u32(s: String) -> Maybe<&2, U32>:
  match s:
    case SNil{}:
      None{}
    case SCon{Chr{+c}, t}:
      parse_u32.go(t, parse_u32.add(0, c), Bool.not(parse_u32.digit(c)))

# More: a valid prefix. Bad: cannot become a body. Body: a whole chunked body.

type Hold is Data:
  HoldMore{}
  HoldBad{}
  HoldBody{b: String}
  HoldUntil{b: String}


def is_hex(+c: U32) -> Bool:
  Bool.or(parse_u32.digit(c), Bool.or(Bool.and(U32.is_le(97, c), U32.is_le(c, 102)), Bool.and(U32.is_le(65, c), U32.is_le(c, 70))))


def hexv(+c: U32) -> U32:
  Bool.pick(U32, parse_u32.digit(c), (c - 48 : U32), Bool.pick(U32, U32.is_le(c, 70), (c - 55 : U32), (c - 87 : U32)))

# A chunked body decoder that reads each byte once, so a body fed in pieces
# costs O(bytes) in total. Tr{j}: j bytes of the closing CRLF CRLF matched.

type Dc is Data:
  DcSize{acc: U32, seen: Bool}
  DcExt{n: U32}
  DcSizeLf{n: U32}
  DcData{k: U32}
  DcDataCr{}
  DcDataLf{}
  DcTr{j: U32}
  DcDone{}
  DcBad{}

# st: where the decoder is. racc: the body so far, reversed. rest: bytes after a Done body.

type Dco is Data:
  Dco{st: Dc, racc: String, rest: String}


def dc.start() -> Dc:
  DcSize{0, False{}}


def dc.size.semi(+n: U32, semi: Bool) -> Dc:
  match semi:
    case True{}:
      DcExt{n}
    case False{}:
      DcBad{}


def dc.size.cr(+n: U32, +c: U32, cr: Bool) -> Dc:
  match cr:
    case True{}:
      DcSizeLf{n}
    case False{}:
      dc.size.semi(n, U32.is_eq(c, 59))


def dc.size.end(+n: U32, +c: U32, seen: Bool) -> Dc:
  match seen:
    case False{}:
      DcBad{}
    case True{}:
      dc.size.cr(n, c, U32.is_eq(c, 13))

# A size that would overflow 32 bits ends the digits, and size.end then refuses it.

def dc.size(+acc: U32, seen: Bool, +c: U32, digit: Bool) -> Dc:
  match digit:
    case True{}:
      DcSize{(acc * 16 + hexv(c) : U32), True{}}
    case False{}:
      dc.size.end(acc, c, seen)

# RFC 9112 §7.1.1: recipients ignore unknown chunk extensions; a bare LF is not CRLF.

def dc.ext.lf(+n: U32, lf: Bool) -> Dc:
  match lf:
    case True{}:
      DcBad{}
    case False{}:
      DcExt{n}


def dc.ext(+n: U32, +c: U32, cr: Bool) -> Dc:
  match cr:
    case True{}:
      DcSizeLf{n}
    case False{}:
      dc.ext.lf(n, U32.is_eq(c, 10))


def dc.sized(+n: U32, zero: Bool) -> Dc:
  match zero:
    case True{}:
      DcTr{2}
    case False{}:
      DcData{n}


def dc.size.lf(+n: U32, lf: Bool) -> Dc:
  match lf:
    case True{}:
      dc.sized(n, U32.is_eq(n, 0))
    case False{}:
      DcBad{}

# k data bytes are left and m of them were just read.

def dc.data(+k: U32, +m: U32) -> Dc:
  Bool.pick(Dc, U32.is_le(k, m), DcDataCr{}, DcData{(k - m : U32)})


def dc.pick(ok: Bool, next: Dc) -> Dc:
  match ok:
    case True{}:
      next
    case False{}:
      DcBad{}

# ponytail: trailer fields are dropped unparsed (§7.1.2 allows discarding)

def dc.tr.hit(+j: U32) -> Dc:
  Bool.pick(Dc, U32.is_eq(j, 3), DcDone{}, DcTr{(j + 1 : U32)})


def dc.tr(+j: U32, +c: U32, hit: Bool) -> Dc:
  match hit:
    case True{}:
      dc.tr.hit(j)
    case False{}:
      Bool.pick(Dc, U32.is_eq(c, 13), DcTr{1}, DcTr{0})


def dc.tr.want(+j: U32) -> U32:
  Bool.pick(U32, U32.is_eq(U32.mod(j, 2), 0), 13, 10)


def dc.byte(h: Char) -> U32:
  Chr{c} = h
  c

# One byte c. Done and Bad never look at it, and a data byte is not inspected.

def dc.step(st: Dc, +c: U32) -> Dc:
  match st:
    case DcBad{}:
      DcBad{}
    case DcSize{+acc, seen}:
      dc.size(acc, seen, c, Bool.and(is_hex(c), U32.is_le(acc, 268435455)))
    case DcExt{+n}:
      dc.ext(n, c, U32.is_eq(c, 13))
    case DcSizeLf{+n}:
      dc.size.lf(n, U32.is_eq(c, 10))
    case DcDataCr{}:
      dc.pick(U32.is_eq(c, 13), DcDataLf{})
    case DcDataLf{}:
      dc.pick(U32.is_eq(c, 10), dc.start())
    case DcTr{+j}:
      dc.tr(j, c, U32.is_eq(c, dc.tr.want(j)))
    case DcData{+k}:
      dc.data(k, 1)
    case DcDone{}:
      DcDone{}


def dc.live(st: Dc) -> Bool:
  match st:
    case DcDone{}:
      False{}
    case DcBad{}:
      False{}
    case DcSize{a, b}:
      True{}
    case DcExt{n}:
      True{}
    case DcSizeLf{n}:
      True{}
    case DcData{k}:
      True{}
    case DcDataCr{}:
      True{}
    case DcDataLf{}:
      True{}
    case DcTr{j}:
      True{}


def dc.feed(s: String, st: Dc, racc: String) -> Dco:
  match s:
    case SNil{}:
      Dco{st, racc, ""}
    case SCon{h, t}:
      match st:
        case DcBad{}:
          Dco{DcBad{}, racc, ""}
        case DcDone{}:
          Dco{DcDone{}, racc, SCon{h, t}}
        case DcData{+k}:
          dc.feed(t, dc.data(k, 1), SCon{h, racc})
        case DcSize{+acc, seen}:
          dc.feed(t, dc.step(DcSize{acc, seen}, dc.byte(h)), racc)
        case DcExt{+n}:
          dc.feed(t, dc.step(DcExt{n}, dc.byte(h)), racc)
        case DcSizeLf{+n}:
          dc.feed(t, dc.step(DcSizeLf{n}, dc.byte(h)), racc)
        case DcDataCr{}:
          dc.feed(t, dc.step(DcDataCr{}, dc.byte(h)), racc)
        case DcDataLf{}:
          dc.feed(t, dc.step(DcDataLf{}, dc.byte(h)), racc)
        case DcTr{+j}:
          dc.feed(t, dc.step(DcTr{j}, dc.byte(h)), racc)


def chunk.hold(o: Dco) -> Hold:
  Dco{st, racc, rest} = o
  match st:
    case DcDone{}:
      HoldBody{String.reverse(racc)}
    case DcBad{}:
      HoldBad{}
    case DcSize{a, b}:
      HoldMore{}
    case DcExt{n}:
      HoldMore{}
    case DcSizeLf{n}:
      HoldMore{}
    case DcData{k}:
      HoldMore{}
    case DcDataCr{}:
      HoldMore{}
    case DcDataLf{}:
      HoldMore{}
    case DcTr{j}:
      HoldMore{}


def chunk.live(s: String) -> Hold:
  chunk.hold(dc.feed(s, dc.start(), ""))


def bytes.snd(r: Bytes.Bytes & Bytes.Bytes) -> Bytes.Bytes:
  (a, b) = r
  b


def found.at(+from: U32, m: Maybe<&2, U32>) -> Maybe<&2, U32>:
  match m:
    case None{}:
      None{}
    case Some{+j}:
      Some{(from + j : U32)}

# A chunked body decoded from piece[i..]: a data run is sliced whole, and every other byte steps dc.

type Cs is Type:
  Cs{piece: Bytes.Bytes, i: U32, st: Dc, parts: List<&1, Bytes.Bytes>}

# st: where the decoder stopped. parts: the data so far, newest first. rest: the bytes after a Done body.

type Ck is Type:
  Ck{st: Dc, parts: List<&1, Bytes.Bytes>, rest: Bytes.Bytes}


def ck.next(+len: U32, +i: U32, +st: Dc, piece: Bytes.Bytes, parts: List<&1, Bytes.Bytes>) -> Bool & Cs:
  (Bool.and(U32.is_lt(i, len), dc.live(st)), Cs{piece, i, st, parts})


def ck.data(+len: U32, +i: U32, +k: U32, +m: U32, parts: List<&1, Bytes.Bytes>, r: Bytes.Bytes & Bytes.Bytes) -> Bool & Cs:
  (piece, run) = r
  ck.next(len, (i + m : U32), dc.data(k, m), piece, Con{run, parts})


def ck.byte(+len: U32, +i: U32, st: Dc, parts: List<&1, Bytes.Bytes>, r: Bytes.Bytes & Maybe<&2, U32>) -> Bool & Cs:
  (piece, m) = r
  match m:
    case None{}:
      ck.next(len, i, DcBad{}, piece, parts)
    case Some{+c}:
      ck.next(len, (i + 1 : U32), dc.step(st, c), piece, parts)


def ck.step(+len: U32, cs: Cs) -> Bool & Cs:
  Cs{piece, +i, st, parts} = cs
  match st:
    case DcData{+k}:
      +m = U32.min(k, (len - i : U32))
      ck.data(len, i, k, m, parts, Bytes.slice(piece, i, m))
    case DcDone{}:
      (False{}, Cs{piece, i, DcDone{}, parts})
    case DcBad{}:
      (False{}, Cs{piece, i, DcBad{}, parts})
    case DcSize{+acc, seen}:
      ck.byte(len, i, DcSize{acc, seen}, parts, Bytes.get(piece, i))
    case DcExt{+n}:
      ck.byte(len, i, DcExt{n}, parts, Bytes.get(piece, i))
    case DcSizeLf{+n}:
      ck.byte(len, i, DcSizeLf{n}, parts, Bytes.get(piece, i))
    case DcDataCr{}:
      ck.byte(len, i, DcDataCr{}, parts, Bytes.get(piece, i))
    case DcDataLf{}:
      ck.byte(len, i, DcDataLf{}, parts, Bytes.get(piece, i))
    case DcTr{+j}:
      ck.byte(len, i, DcTr{j}, parts, Bytes.get(piece, i))


def ck.rest(st: Dc, parts: List<&1, Bytes.Bytes>, r: Bytes.Bytes & Bytes.Bytes) -> Ck:
  (piece, rest) = r
  Ck{st, parts, rest}


def ck.end(+len: U32, cs: Cs) -> Ck:
  Cs{piece, +i, st, parts} = cs
  ck.rest(st, parts, Bytes.slice(piece, i, (len - i : U32)))

# Each step reads at least one byte, so len steps are enough.

def ck.feed(f: Nat, +len: U32, r: Bool & Cs) -> Ck:
  match f:
    case 0n:
      (go, cs) = r
      ck.end(len, cs)
    case 1n+p:
      (go, cs) = r
      match go:
        case False{}:
          ck.end(len, cs)
        case True{}:
          ck.feed(p, len, ck.step(len, cs))


def ck(piece: Bytes.Bytes, +st: Dc, parts: List<&1, Bytes.Bytes>) -> Ck:
  Bytes.Bytes{+len, buf} = piece
  ck.feed(U32.to_nat(len), len, ck.next(len, 0, st, Bytes.Bytes{len, buf}, parts))


def parse.res.cl.have(+rest: String, +k: Nat, short: Bool) -> Hold:
  match short:
    case True{}:
      HoldMore{}
    case False{}:
      HoldBody{String.take(rest, k)}


def parse.res.cl.k(+rest: String, +k: Nat) -> Hold:
  parse.res.cl.have(rest, k, Nat.is_lt(String.length(rest), k))


def parse.res.cl.n(rest: String, n: Maybe<&2, U32>) -> Hold:
  match n:
    case None{}:
      HoldBad{}
    case Some{k}:
      parse.res.cl.k(rest, U32.to_nat(k))


def parse.body.cl(+h: Map<&2, List<&2, String>>, rest: String, hascl: Bool) -> Hold:
  match hascl:
    case False{}:
      HoldBody{""}
    case True{}:
      parse.res.cl.n(rest, parse_u32(header(h, "content-length")))

# RFC 9112 §6.3 (4): a request coding other than chunked cannot be framed.

def parse.body.chunked.eq(rest: String, ok: Bool) -> Hold:
  match ok:
    case False{}:
      HoldBad{}
    case True{}:
      chunk.live(rest)


def parse.body.chunked.val(te: String, rest: String) -> Hold:
  parse.body.chunked.eq(rest, String.eq(String.to_lower(te), "chunked"))


def parse.body.chunked(+h: Map<&2, List<&2, String>>, rest: String, hascl: Bool) -> Hold:
  match hascl:
    case True{}:
      HoldBad{}
    case False{}:
      parse.body.chunked.val(header.last(h, "transfer-encoding"), rest)


def parse.body.te(+h: Map<&2, List<&2, String>>, rest: String, te: Bool) -> Hold:
  match te:
    case True{}:
      parse.body.chunked(h, rest, has_header(h, "content-length"))
    case False{}:
      parse.body.cl(h, rest, has_header(h, "content-length"))


def parse.body(+h: Map<&2, List<&2, String>>, rest: String) -> Hold:
  parse.body.te(h, rest, has_header(h, "transfer-encoding"))

# Bad: never a request. More: the head is not whole; read on. Head: the head is whole
# and valid, and the body is still coming (req.body is empty). Req: a whole request.

type Got is Type:
  GotBad{}
  GotMore{}
  GotHead{req: Req}
  GotReq{req: Req}


def parse.finish(method: String, path: String, h: Map<&2, List<&2, String>>, body: Hold) -> Got:
  match body:
    case HoldBad{}:
      GotBad{}
    case HoldMore{}:
      GotHead{Req{method, path, h, Bytes.new(0)}}
    case HoldUntil{b}:
      GotBad{}
    case HoldBody{b}:
      GotReq{Req{method, path, h, Bytes.from_string(b)}}


def parse.host(method: String, path: String, +h: Map<&2, List<&2, String>>, rest: String, has: Bool) -> Got:
  match has:
    case False{}:
      GotBad{}
    case True{}:
      parse.finish(method, path, h, parse.body(h, rest))

# RFC 9112 §3.2: only HTTP/1.1 requires Host.

def parse.fields(method: String, path: String, rest: String, v11: Bool, fs: Maybe<&2, Map<&2, List<&2, String>>>) -> Got:
  match fs:
    case None{}:
      GotBad{}
    case Some{+h}:
      parse.host(method, path, h, rest, Bool.or(Bool.not(v11), has_header(h, "host")))


def target_ok(+p: String) -> Bool:
  Bool.or(String.starts_with(p, "/"), Bool.or(String.eq(p, "*"), String.starts_with(p, "http://")))


def parse.target(method: String, +path: String, headers: String, rest: String, v11: Bool, ok: Bool) -> Got:
  match ok:
    case False{}:
      GotBad{}
    case True{}:
      parse.fields(method, path, rest, v11, parse.headers.raw(headers))


def parse.ver(method: String, +path: String, +v: String, headers: String, rest: String, ok: Bool) -> Got:
  match ok:
    case False{}:
      GotBad{}
    case True{}:
      parse.target(method, path, headers, rest, String.eq(v, "HTTP/1.1"), target_ok(path))


def parse.empty_method(method: String, path: String, +v: String, headers: String, rest: String, empty: Bool) -> Got:
  match empty:
    case True{}:
      GotBad{}
    case False{}:
      parse.ver(method, path, v, headers, rest, Bool.or(String.eq(v, "HTTP/1.1"), String.eq(v, "HTTP/1.0")))


def parse.start3(mpv: String & String & String, headers: String, rest: String) -> Got:
  (+method, path, v) = mpv
  parse.empty_method(method, path, v, headers, rest, String.is_empty(method))


def parse.lines(lr: String & String, rest: String) -> Got:
  (line, headers) = lr
  parse.start3(start_line(line), headers, rest)



def parse.head(+head: String, rest: String, whole: Bool) -> Got:
  match whole:
    case False{}:
      GotMore{}
    case True{}:
      parse.lines(parse.first(head, SNil{}), rest)


def parse.of(hb: String & String & Bool) -> Got:
  (head, rest, whole) = hb
  parse.head(head, rest, whole)

# serve reads until this is not GotMore.

def parse.got(+raw: String) -> Got:
  parse.of(split_at_blank.flag.go(raw, raw, 0n, 0, False{}))



def parse.res.cl(+h: Map<&2, List<&2, String>>, rest: String, hascl: Bool) -> Hold:
  match hascl:
    case False{}:
      HoldBody{rest}
    case True{}:
      parse.res.cl.n(rest, parse_u32(header(h, "content-length")))


def parse.res.chunked.eq(rest: String, ok: Bool) -> Hold:
  match ok:
    case False{}:
      HoldUntil{rest}
    case True{}:
      chunk.live(rest)


def parse.res.chunked.val(te: String, rest: String) -> Hold:
  parse.res.chunked.eq(rest, String.eq(String.to_lower(te), "chunked"))


def parse.res.chunked(+h: Map<&2, List<&2, String>>, rest: String, hascl: Bool) -> Hold:
  match hascl:
    case True{}:
      HoldBad{}
    case False{}:
      parse.res.chunked.val(header.last(h, "transfer-encoding"), rest)


def parse.res.te(+h: Map<&2, List<&2, String>>, rest: String, te: Bool) -> Hold:
  match te:
    case True{}:
      parse.res.chunked(h, rest, has_header(h, "content-length"))
    case False{}:
      parse.res.cl(h, rest, has_header(h, "content-length"))


def parse.res.body(+h: Map<&2, List<&2, String>>, rest: String) -> Hold:
  parse.res.te(h, rest, has_header(h, "transfer-encoding"))

# Bad: never a message. More: a valid prefix; read on. Done: a whole response.

type Frame is Type:
  FrameBad{}
  FrameMore{}
  FrameDone{res: Res}

# RFC 9112 §8: a message cut short by close is incomplete, not valid.

def frame.cut(closed: Bool) -> Frame:
  match closed:
    case True{}:
      FrameBad{}
    case False{}:
      FrameMore{}


def frame.wait(res: Res, wait: Bool) -> Frame:
  match wait:
    case True{}:
      FrameMore{}
    case False{}:
      FrameDone{res}


def frame.done(status: U32, h: Map<&2, List<&2, String>>, body: Hold, +closed: Bool, open: Bool) -> Frame:
  match body:
    case HoldBad{}:
      FrameBad{}
    case HoldMore{}:
      frame.cut(closed)
    case HoldUntil{b}:
      frame.wait(Res{status, h, Bytes.from_string(b)}, Bool.not(closed))
    case HoldBody{b}:
      frame.wait(Res{status, h, Bytes.from_string(b)}, Bool.and(open, Bool.not(closed)))

# RFC 9112 §6.3 (8): no TE and no CL ⇒ the body runs until the server closes.

def frame.open(+h: Map<&2, List<&2, String>>) -> Bool:
  Bool.not(Bool.or(has_header(h, "transfer-encoding"), has_header(h, "content-length")))

# RFC 9112 §6.3 (1): HEAD, 1xx, 204 and 304 responses end at the blank line.

def frame.nobody(+status: U32, head: Bool) -> Bool:
  Bool.or(head, Bool.or(U32.is_lt(status, 200), Bool.or(U32.is_eq(status, 204), U32.is_eq(status, 304))))

# 101 is the final response. Other 1xx are interim; a final response follows.

def frame.interim(+status: U32) -> Bool:
  Bool.and(U32.is_lt(status, 200), Bool.not(U32.is_eq(status, 101)))


def frame.status(status: U32, +h: Map<&2, List<&2, String>>, rest: String, closed: Bool, nobody: Bool) -> Frame:
  match nobody:
    case True{}:
      FrameDone{Res{status, h, Bytes.new(0)}}
    case False{}:
      frame.done(status, h, parse.res.body(h, rest), closed, frame.open(h))


def parse.res.fields(+status: U32, rest: String, fs: Maybe<&2, Map<&2, List<&2, String>>>, closed: Bool, head: Bool) -> Frame:
  match fs:
    case None{}:
      FrameBad{}
    case Some{h}:
      frame.status(status, h, rest, closed, frame.nobody(status, head))


def parse.res.num(code: Maybe<&2, U32>, headers: String, rest: String, closed: Bool, head: Bool) -> Frame:
  match code:
    case None{}:
      FrameBad{}
    case Some{n}:
      parse.res.fields(n, rest, parse.headers.raw(headers), closed, head)


def parse.res.ver(code: String, headers: String, rest: String, closed: Bool, head: Bool, ok: Bool) -> Frame:
  match ok:
    case False{}:
      FrameBad{}
    case True{}:
      parse.res.num(parse_u32(code), headers, rest, closed, head)


def parse.res.start3(mpv: String & String & String, headers: String, rest: String, closed: Bool, head: Bool) -> Frame:
  (+ver, code, reason) = mpv
  parse.res.ver(code, headers, rest, closed, head, Bool.or(String.eq(ver, "HTTP/1.1"), String.eq(ver, "HTTP/1.0")))


def parse.res.lines(lr: String & String, rest: String, closed: Bool, head: Bool) -> Frame:
  (line, headers) = lr
  parse.res.start3(start_line(line), headers, rest, closed, head)


def parse.res.blank(hd: String, rest: String, +closed: Bool, head: Bool, ok: Bool) -> Frame:
  match ok:
    case False{}:
      frame.cut(closed)
    case True{}:
      parse.res.lines(parse.first(hd, SNil{}), rest, closed, head)


def parse.res.of(hb: String & String, closed: Bool, head: Bool) -> Frame:
  (+hd, rest) = hb
  parse.res.blank(hd, rest, closed, head, blank_end(hd))


type Rb is Data:
  RbLen{left: U32}
  RbChunk{st: Dc}
  RbClose{}
  RbDone{}
  RbBad{}


def rb.cl(n: Maybe<&2, U32>) -> Maybe<&2, Rb>:
  match n:
    case None{}:
      None{}
    case Some{+k}:
      Some{Bool.pick(Rb, U32.is_zero(k), RbDone{}, RbLen{k})}


def rb.te(+h: Map<&2, List<&2, String>>, cl: Bool) -> Maybe<&2, Rb>:
  match cl:
    case True{}:
      None{}
    case False{}:
      Some{Bool.pick(Rb, String.eq(String.to_lower(header.last(h, "transfer-encoding")), "chunked"), RbChunk{dc.start()}, RbClose{})}


def rb.len(+h: Map<&2, List<&2, String>>, te: Bool) -> Maybe<&2, Rb>:
  match te:
    case True{}:
      rb.te(h, has_header(h, "content-length"))
    case False{}:
      Bool.pick(Maybe<&2, Rb>, has_header(h, "content-length"), rb.cl(parse_u32(header(h, "content-length"))), Some{RbClose{}})

# RFC 9112 §6.3: how the body of this response ends. None: it cannot be framed.

def rb.of(+h: Map<&2, List<&2, String>>, nobody: Bool) -> Maybe<&2, Rb>:
  match nobody:
    case True{}:
      Some{RbDone{}}
    case False{}:
      rb.len(h, has_header(h, "transfer-encoding"))

# rb: how the body goes on. parts: body bytes so far, newest first. rest: bytes past a Done body.

type Bf is Type:
  Bf{rb: Rb, parts: List<&1, Bytes.Bytes>, rest: Bytes.Bytes}


def rb.len.cut(parts: List<&1, Bytes.Bytes>, +len: U32, +left: U32, r: Bytes.Bytes & Bytes.Bytes) -> Bf:
  (piece, data) = r
  Bf{RbDone{}, Con{data, parts}, bytes.snd(Bytes.slice(piece, left, (len - left : U32)))}


def rb.len.have(short: Bool, +left: U32, parts: List<&1, Bytes.Bytes>, +len: U32, piece: Bytes.Bytes) -> Bf:
  match short:
    case True{}:
      Bf{RbLen{(left - len : U32)}, Con{piece, parts}, Bytes.new(0)}
    case False{}:
      rb.len.cut(parts, len, left, Bytes.slice(piece, 0, left))


def rb.chunk(c: Ck) -> Bf:
  Ck{st, parts, rest} = c
  match st:
    case DcDone{}:
      Bf{RbDone{}, parts, rest}
    case DcBad{}:
      Bf{RbBad{}, parts, rest}
    case DcSize{a, b}:
      Bf{RbChunk{DcSize{a, b}}, parts, rest}
    case DcExt{x}:
      Bf{RbChunk{DcExt{x}}, parts, rest}
    case DcSizeLf{x}:
      Bf{RbChunk{DcSizeLf{x}}, parts, rest}
    case DcData{k}:
      Bf{RbChunk{DcData{k}}, parts, rest}
    case DcDataCr{}:
      Bf{RbChunk{DcDataCr{}}, parts, rest}
    case DcDataLf{}:
      Bf{RbChunk{DcDataLf{}}, parts, rest}
    case DcTr{j}:
      Bf{RbChunk{DcTr{j}}, parts, rest}

# The body bytes in piece, added to parts.

def rb.feed(rb: Rb, parts: List<&1, Bytes.Bytes>, piece: Bytes.Bytes) -> Bf:
  match rb:
    case RbLen{+left}:
      Bytes.Bytes{+len, buf} = piece
      rb.len.have(U32.is_lt(len, left), left, parts, len, Bytes.Bytes{len, buf})
    case RbChunk{st}:
      rb.chunk(ck(piece, st, parts))
    case RbClose{}:
      Bf{RbClose{}, Con{piece, parts}, Bytes.new(0)}
    case RbDone{}:
      Bf{RbDone{}, parts, piece}
    case RbBad{}:
      Bf{RbBad{}, parts, piece}

# RFC 9112 §8: only a close-delimited body may end at close.

def rb.eof(rb: Rb) -> Bool:
  match rb:
    case RbClose{}:
      True{}
    case RbDone{}:
      True{}
    case RbLen{n}:
      False{}
    case RbChunk{st}:
      False{}
    case RbBad{}:
      False{}


def rb.body(parts: List<&1, Bytes.Bytes>) -> Bytes.Bytes:
  Bytes.concat(List.reverse(&1, Bytes.Bytes, parts))

# The head scan. Seek: look for the blank line from byte from; k interim heads are behind.
# Wait: no blank line yet. Res: the final head, how its body ends, and the bytes after it.

type Hs is Type:
  HsSeek{buf: Bytes.Bytes, from: U32, k: U32}
  HsWait{buf: Bytes.Bytes, k: U32}
  HsBad{}
  HsRes{res: Res, rb: Rb, rest: Bytes.Bytes}


def hs.final(+status: U32, +h: Map<&2, List<&2, String>>, rest: Bytes.Bytes, m: Maybe<&2, Rb>) -> Hs:
  match m:
    case None{}:
      HsBad{}
    case Some{rb}:
      HsRes{Res{status, h, Bytes.new(0)}, rb, rest}


def hs.skip(more: Bool, +k: U32, rest: Bytes.Bytes) -> Hs:
  match more:
    case True{}:
      HsSeek{rest, 0, (k + 1 : U32)}
    case False{}:
      HsBad{}


def hs.pick(interim: Bool, +head: Bool, +k: U32, +status: U32, +h: Map<&2, List<&2, String>>, rest: Bytes.Bytes) -> Hs:
  match interim:
    case True{}:
      hs.skip(U32.is_lt(k, 8), k, rest)
    case False{}:
      hs.final(status, h, rest, rb.of(h, frame.nobody(status, head)))


def hs.res(+head: Bool, +k: U32, rest: Bytes.Bytes, res: Res) -> Hs:
  Res{+status, +h, body} = res
  hs.pick(frame.interim(status), head, k, status, h, rest)

# The head alone, framed as a HEAD response so it stops at the blank line.

def hs.parsed(+head: Bool, +k: U32, rest: Bytes.Bytes, f: Frame) -> Hs:
  match f:
    case FrameDone{res}:
      hs.res(head, k, rest, res)
    case FrameBad{}:
      HsBad{}
    case FrameMore{}:
      HsBad{}


def hs.split(+head: Bool, +k: U32, +hlen: U32, +len: U32, r: Bytes.Bytes & Bytes.Bytes) -> Hs:
  (buf, hb) = r
  hs.parsed(head, k, bytes.snd(Bytes.slice(buf, hlen, (len - hlen : U32))), parse.res.of(split_at_blank(Bytes.to_string(hb)), False{}, True{}))


def hs.hit(+head: Bool, +k: U32, +len: U32, buf: Bytes.Bytes, at: Maybe<&2, U32>) -> Hs:
  match at:
    case None{}:
      HsWait{buf, k}
    case Some{+i}:
      +hlen = (i + 4 : U32)
      hs.split(head, k, hlen, len, Bytes.slice(buf, 0, hlen))


def hs.seek.of(+head: Bool, +k: U32, +len: U32, +from: U32, buf: Bytes.Bytes, r: Bytes.Bytes & Maybe<&2, U32>) -> Hs:
  (tail, m) = r
  hs.hit(head, k, len, buf, found.at(from, m))


def hs.seek(+head: Bool, +k: U32, +len: U32, +from: U32, r: Bytes.Bytes & Bytes.Bytes) -> Hs:
  (buf, tail) = r
  hs.seek.of(head, k, len, from, buf, Bytes.find(tail, "\r\n\r\n"))


def hs.step(+head: Bool, st: Hs) -> Hs:
  match st:
    case HsSeek{buf, +from, +k}:
      Bytes.Bytes{+len, b} = buf
      hs.seek(head, k, len, from, Bytes.slice(Bytes.Bytes{len, b}, from, (len - from : U32)))
    case HsWait{buf, k}:
      HsWait{buf, k}
    case HsBad{}:
      HsBad{}
    case HsRes{res, rb, rest}:
      HsRes{res, rb, rest}

# Each step ends the scan or passes one interim head, and at most 8 interim heads pass.

def fetch.max() -> Nat:
  U32.to_nat(16777216)

# A response read in pieces. Head: the head is not whole yet. Body: it is, and parts is the body so far.
# Len: a Content-Length body in one buffer of that size, with left bytes still to come.

def req.v11.ver(mpv: String & String & String) -> Bool:
  (+method, path, v) = mpv
  String.eq(v, "HTTP/1.1")


def req.v11.line(+line: String) -> Bool:
  req.v11.ver(start_line(line))


def req.v11.lines(xs: List<&2, String>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{line, headers}:
      req.v11.line(line)


def req.v11.pick(+head: String, ok: Bool) -> Bool:
  match ok:
    case False{}:
      False{}
    case True{}:
      req.v11.lines(String.lines(head))


def req.v11.of(hb: String & String) -> Bool:
  (+head, rest) = hb
  req.v11.pick(head, blank_end(head))


def req.v11(+raw: String) -> Bool:
  req.v11.of(split_at_blank(raw))


def req.conn_close(+headers: Map<&2, List<&2, String>>) -> Bool:
  String.eq(String.to_lower(header(headers, "connection")), "close")


def res.conn_close(+headers: Map<&2, List<&2, String>>) -> Bool:
  String.eq(String.to_lower(header(headers, "connection")), "close")


def serve.fail_close(+status: U32) -> Bool:
  Bool.or(U32.is_eq(status, 400), Bool.or(U32.is_eq(status, 413), U32.is_eq(status, 431)))


def serve.keep.ok(fail: Bool, res_close: Bool) -> Bool:
  match fail:
    case True{}:
      False{}
    case False{}:
      Bool.not(res_close)


def serve.keep.v11(v11: Bool, +req_close: Bool, +status: U32, res_close: Bool) -> Bool:
  match v11:
    case False{}:
      False{}
    case True{}:
      match req_close:
        case True{}:
          False{}
        case False{}:
          serve.keep.ok(serve.fail_close(status), res_close)


def serve.keep(+headers: Map<&2, List<&2, String>>, v11: Bool, +status: U32, +res: Map<&2, List<&2, String>>) -> Bool:
  serve.keep.v11(v11, req.conn_close(headers), status, res.conn_close(res))



def headers_lines(+k: String, vs: List<&2, String>, acc: String) -> String:
  match vs:
    case Nil{}:
      acc
    case Con{v, t}:
      headers_lines(k, t, acc ++ ("\r\n" ++ sanitize(k) ++ ": " ++ sanitize(v)))


def headers_block.go(xs: List<&2, Sigma<&2, &2, String, _ => List<&2, String>>>, acc: String) -> String:
  match xs:
    case Nil{}:
      acc
    case (k, vs) <> t:
      headers_block.go(t, headers_lines(k, vs, acc))


def headers_block(h: Map<&2, List<&2, String>>) -> String:
  headers_block.go(Map.to_list(&2, List<&2, String>, h), "")

# RFC 9110 §15. An unknown code gets an empty reason, which RFC 9112 §4 allows.

type Reason is Data:
  Reason{code: U32, text: String}


def reasons() -> List<&2, Reason>:
  [Reason{100, "Continue"}, Reason{101, "Switching Protocols"}, Reason{103, "Early Hints"},
   Reason{200, "OK"}, Reason{201, "Created"}, Reason{202, "Accepted"}, Reason{203, "Non-Authoritative Information"}, Reason{204, "No Content"}, Reason{205, "Reset Content"}, Reason{206, "Partial Content"},
   Reason{300, "Multiple Choices"}, Reason{301, "Moved Permanently"}, Reason{302, "Found"}, Reason{303, "See Other"}, Reason{304, "Not Modified"}, Reason{307, "Temporary Redirect"}, Reason{308, "Permanent Redirect"},
   Reason{400, "Bad Request"}, Reason{401, "Unauthorized"}, Reason{402, "Payment Required"}, Reason{403, "Forbidden"}, Reason{404, "Not Found"}, Reason{405, "Method Not Allowed"}, Reason{406, "Not Acceptable"}, Reason{407, "Proxy Authentication Required"}, Reason{408, "Request Timeout"}, Reason{409, "Conflict"}, Reason{410, "Gone"}, Reason{411, "Length Required"}, Reason{412, "Precondition Failed"}, Reason{413, "Content Too Large"}, Reason{414, "URI Too Long"}, Reason{415, "Unsupported Media Type"}, Reason{416, "Range Not Satisfiable"}, Reason{417, "Expectation Failed"}, Reason{421, "Misdirected Request"}, Reason{422, "Unprocessable Content"}, Reason{426, "Upgrade Required"}, Reason{428, "Precondition Required"}, Reason{429, "Too Many Requests"}, Reason{431, "Request Header Fields Too Large"},
   Reason{500, "Internal Server Error"}, Reason{501, "Not Implemented"}, Reason{502, "Bad Gateway"}, Reason{503, "Service Unavailable"}, Reason{504, "Gateway Timeout"}, Reason{505, "HTTP Version Not Supported"}]


def reason.go(xs: List<&2, Reason>, +status: U32) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{Reason{k, v}, t}:
      Bool.pick(String, U32.is_eq(k, status), v, reason.go(t, status))


def reason(+status: U32) -> String:
  reason.go(reasons(), status)


def response(+status: U32, headers: Map<&2, List<&2, String>>, body: String) -> String:
  ("HTTP/1.1 " ++ U32.show(status) ++ " " ++ reason(status) ++ headers_block(headers)) ++ ("\r\n\r\n" ++ body)


def encode.body(head: Bool, top: Bytes.Bytes, body: Bytes.Bytes) -> Bytes.Bytes:
  match head:
    case True{}:
      top
    case False{}:
      Bytes.append(top, body)


def encode.len(+status: U32, headers: Map<&2, List<&2, String>>, head: Bool, body: Bytes.Bytes) -> Bytes.Bytes:
  Bytes.Bytes{+len, buf} = body
  encode.body(head, Bytes.from_string(response(status, set(headers, "content-length", U32.show(len)), "")), Bytes.Bytes{len, buf})

# RFC 9110 §6.4.1, §8.6: 1xx, 204 and 304 have no body; HEAD gets the length but no body.

def encode.pick(+status: U32, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, head: Bool, nobody: Bool) -> Bytes.Bytes:
  match nobody:
    case True{}:
      Bytes.from_string(response(status, headers, ""))
    case False{}:
      encode.len(status, headers, head, body)


def encode.on(r: Res, head: Bool) -> Bytes.Bytes:
  Res{+status, headers, body} = r
  encode.pick(status, headers, body, head, frame.nobody(status, False{}))


def encode(r: Res) -> Bytes.Bytes:
  encode.on(r, False{})


def request(method: String, path: String, headers: Map<&2, List<&2, String>>, body: String) -> String:
  (method ++ " " ++ path ++ " HTTP/1.1" ++ headers_block(headers)) ++ ("\r\n\r\n" ++ body)


def req.reserved(+k: String) -> Bool:
  Bool.or(Bool.or(String.eq(k, "host"), String.eq(k, "connection")), Bool.or(String.eq(k, "content-length"), String.eq(k, "transfer-encoding")))


def req.put.one(m: Map<&2, List<&2, String>>, +k: String, vs: List<&2, String>, skip: Bool) -> Map<&2, List<&2, String>>:
  match skip:
    case True{}:
      m
    case False{}:
      Map.set(&2, List<&2, String>, m, k, vs)


def req.put(xs: List<&2, Sigma<&2, &2, String, _ => List<&2, String>>>, m: Map<&2, List<&2, String>>) -> Map<&2, List<&2, String>>:
  match xs:
    case Nil{}:
      m
    case (k, vs) <> t:
      +lk = String.to_lower(k)
      req.put(t, req.put.one(m, lk, vs, req.reserved(lk)))

# RFC 9110 §8.6: no Content-Length on a bodiless request whose method gives a body no meaning.

def req.cl(+m: Map<&2, List<&2, String>>, +method: String, +len: U32) -> Map<&2, List<&2, String>>:
  +bodied = Bool.or(Bool.not(U32.is_zero(len)), Bool.or(String.eq(method, "POST"), Bool.or(String.eq(method, "PUT"), String.eq(method, "PATCH"))))
  Bool.pick(Map<&2, List<&2, String>>, bodied, set(m, "content-length", U32.show(len)), m)

# Caller headers are lowercased so they cannot duplicate ours; host, connection,
# content-length and transfer-encoding are always ours (no smuggling through them).

def encode_req.word(close: Bool) -> String:
  match close:
    case True{}:
      "close"
    case False{}:
      "keep-alive"


def encode_req.on(+method: String, target: String, host: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, close: Bool) -> Bytes.Bytes:
  Bytes.Bytes{+len, buf} = body
  +h = set(set(req.put(Map.to_list(&2, List<&2, String>, headers), empty()), "host", host), "connection", encode_req.word(close))
  Bytes.append(Bytes.from_string(request(method, target, req.cl(h, method, len), "")), Bytes.Bytes{len, buf})


type Hop is Type:
  Hop{method: String, url: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes}


def redirect.code(+s: U32) -> Bool:
  Bool.or(Bool.or(U32.is_eq(s, 301), U32.is_eq(s, 302)), Bool.or(U32.is_eq(s, 303), Bool.or(U32.is_eq(s, 307), U32.is_eq(s, 308))))


def redirect.origin(a: Url.Abs) -> String:
  Url.Abs{scheme, host, port, target} = a
  scheme ++ "://" ++ host ++ ":" ++ U32.show(port)


def redirect.del(ks: List<&2, String>, m: Map<&2, List<&2, String>>) -> Map<&2, List<&2, String>>:
  match ks:
    case Nil{}:
      m
    case Con{k, t}:
      redirect.del(t, Map.del(&2, List<&2, String>, m, k))


def redirect.hdrs(+h: Map<&2, List<&2, String>>, drop: Bool, cross: Bool) -> Map<&2, List<&2, String>>:
  +h2 = Bool.pick(Map<&2, List<&2, String>>, drop, redirect.del(["content-type", "content-encoding", "content-language", "content-location"], h), h)
  Bool.pick(Map<&2, List<&2, String>>, cross, redirect.del(["authorization", "cookie", "proxy-authorization"], h2), h2)

# 303 turns any method but HEAD into GET; 301 and 302 turn POST into GET;
# 307 and 308 keep method and body. A GET carries no body or body headers.
# Credentials do not follow a hop to another origin.

def redirect.body(drop: Bool, body: Bytes.Bytes) -> Bytes.Bytes:
  match drop:
    case True{}:
      Bytes.new(0)
    case False{}:
      body


def redirect.to(+status: U32, +method: String, +from: Url.Abs, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, next: Maybe<&2, Url.Abs>) -> Maybe<&1, Hop>:
  match next:
    case None{}:
      None{}
    case Some{+to}:
      +drop = Bool.or(Bool.and(U32.is_eq(status, 303), Bool.not(String.eq(method, "HEAD"))), Bool.and(Bool.or(U32.is_eq(status, 301), U32.is_eq(status, 302)), String.eq(method, "POST")))
      Some{Hop{Bool.pick(String, drop, "GET", method), to, redirect.hdrs(headers, drop, Bool.not(String.eq(redirect.origin(from), redirect.origin(to)))), redirect.body(drop, body)}}


def redirect.hop(status: U32, h: Hop, loc: String) -> Maybe<&1, Hop>:
  Hop{method, +url, headers, body} = h
  redirect.to(status, method, url, headers, body, Url.resolve(url, loc))


def redirect.if(status: U32, h: Hop, loc: String, ok: Bool) -> Maybe<&1, Hop>:
  match ok:
    case False{}:
      None{}
    case True{}:
      redirect.hop(status, h, loc)

# The next request after a response, or None when it is not a redirect we follow.

def redirect(+status: U32, +headers: Map<&2, List<&2, String>>, h: Hop) -> Maybe<&1, Hop>:
  redirect.if(status, h, header(headers, "location"), Bool.and(redirect.code(status), has_header(headers, "location")))

# Cookies (RFC 6265bis §5)
# ------------------------

# A stored cookie. domain is lowercase, with no leading dot; host_only sends it to that host alone.
# expiry None is a session cookie. http_only and same_site ("strict", "lax", "none" or "default")
# are kept, not enforced: fetch has no browsing client, so its requests are same-site (§5.2).

def io.send.words(tls: Bool, s: Socket, +len: U32, buf: Array<U32>) -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
  match tls:
    case True{}:
      Wire.tls.send.words(s, len, buf)
    case False{}:
      Wire.send.words(s, len, buf)


def io.send.bytes(tls: Bool, s: Socket, b: Bytes.Bytes) -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
  Bytes.Bytes{+len, buf} = b
  io.send.words(tls, s, len, buf)


type Cert is Data:
  Cert{chain: String, key: String}


def pool.key(+scheme: String, +host: String, +port: U32) -> String:
  scheme ++ "://" ++ host ++ ":" ++ U32.show(port)


def pool.key.cert(+base: String, cert: Maybe<&2, Cert>) -> String:
  match cert:
    case None{}:
      base
    case Some{Cert{+chain, +key}}:
      base ++ "|cert:" ++ Nat.show(String.length(chain)) ++ ":" ++ chain
        ++ Nat.show(String.length(key)) ++ ":" ++ key


def pool.idempotent(+method: String) -> Bool:
  Bool.or(String.eq(method, "GET"), Bool.or(String.eq(method, "HEAD"), Bool.or(String.eq(method, "OPTIONS"), Bool.or(String.eq(method, "TRACE"), Bool.or(String.eq(method, "PUT"), String.eq(method, "DELETE"))))))


type Dial is Type:
  Dial{port: U32, ms: U32, deadline: Nat, action: IO(Result<&1, &1, U32 & String, Socket>)}


def conn.dial.time(+ip: String, +port: U32, +deadline: Nat, now: Nat, expired: Bool) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  match expired:
    case True{}:
      IO.pure(Result<&1, &1, U32 & String, Socket>, Fail{(60, "connect timeout")})
    case False{}:
      Wire.connect(ip, port, U32.from_nat(Nat.sub(deadline, now)))


def conn.dial.with(+ip: String, +port: U32, +ms: U32, +deadline: Nat, +now: Nat, unlimited: Bool) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  match unlimited:
    case True{}:
      Wire.connect(ip, port, 0)
    case False{}:
      conn.dial.time(ip, port, deadline, now, Nat.is_le(deadline, now))


def conn.dial.try(+ip: String, +port: U32, +ms: U32, +deadline: Nat) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  do IO<Result<&1, &1, U32 & String, Socket>>:
    now : Nat <- IO.now()
    conn.dial.with(ip, port, ms, deadline, now, U32.is_zero(ms))


def conn.dial.after(r: Result<&1, &1, U32 & String, Socket>, ip: String, +port: U32, +ms: U32, +deadline: Nat) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  match r:
    case Done{s}:
      IO.pure(Result<&1, &1, U32 & String, Socket>, Done{s})
    case Fail{e}:
      conn.dial.try(ip, port, ms, deadline)


def conn.dial.more(prev: IO(Result<&1, &1, U32 & String, Socket>), ip: String, +port: U32, +ms: U32, +deadline: Nat) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  do IO<Result<&1, &1, U32 & String, Socket>>:
    r : Result<&1, &1, U32 & String, Socket> <- prev
    conn.dial.after(r, ip, port, ms, deadline)


def conn.dial.fold(d: Dial, ip: String) -> Dial:
  Dial{+port, +ms, +deadline, action} = d
  Dial{port, ms, deadline, conn.dial.more(action, ip, port, ms, deadline)}


def conn.dial.run(d: Dial) -> IO(Result<&1, &1, U32 & String, Socket>):
  Dial{port, ms, deadline, action} = d
  action


def conn.dial.all(+port: U32, +ms: U32, +start: Nat, first: String, rest: List<&2, String>) ->
  IO(Result<&1, &1, U32 & String, Socket>):
  match rest:
    case Nil{}:
      Wire.connect(first, port, ms)
    case Con{ip, tail}:
      +deadline = Nat.add(start, U32.to_nat(ms))
      conn.dial.run(List.foldl(~&2, ~String, ~Dial, ~conn.dial.fold, Con{ip, tail},
        Dial{port, ms, deadline, Wire.connect(first, port, ms)}))


type Next is Type:
  NDone{res: Result<&1, &1, Err, Res>}
  NStop{}
  NGo{left: Nat, hop: Hop}


type Mode is Data:
  ModeFollow{}
  ModeManual{}
  ModeError{}

# left: redirects still allowed after the request we just finished.

def fetch.hop(left: Nat, h: Hop) -> Next:
  match left:
    case 0n:
      NStop{}
    case 1n+p:
      NGo{p, h}


def fetch.decide.r(left: Nat, r: Res, next: Maybe<&1, Hop>) -> Next:
  match next:
    case None{}:
      NDone{Done{r}}
    case Some{h}:
      fetch.hop(left, h)


def fetch.decide.res(left: Nat, h: Hop, r: Res) -> Next:
  Res{+status, +headers, body} = r
  fetch.decide.r(left, Res{status, headers, body}, redirect(status, headers, h))


def fetch.decide(left: Nat, h: Hop, m: Result<&1, &1, Err, Res>) -> Next:
  match m:
    case Fail{e}:
      NDone{Fail{e}}
    case Done{r}:
      fetch.decide.res(left, h, r)


def fetch.error.res(r: Res, bad: Bool) -> Next:
  match bad:
    case True{}:
      NDone{Fail{ErrRedirect{}}}
    case False{}:
      NDone{Done{r}}


def fetch.error(h: Hop, m: Result<&1, &1, Err, Res>) -> Next:
  match m:
    case Fail{e}:
      NDone{Fail{e}}
    case Done{r}:
      Res{+status, +headers, body} = r
      fetch.error.res(Res{status, headers, body}, Bool.and(redirect.code(status), has_header(headers, "location")))


def fetch.policy(mode: Mode, left: Nat, h: Hop, m: Result<&1, &1, Err, Res>) -> Next:
  match mode:
    case ModeFollow{}:
      fetch.decide(left, h, m)
    case ModeManual{}:
      NDone{m}
    case ModeError{}:
      fetch.error(h, m)

# A caller's own Accept-Encoding wins; enc is the codings fetch can undo.

def accept.enc(+h: Map<&2, List<&2, String>>, +enc: String) -> Map<&2, List<&2, String>>:
  Bool.pick(Map<&2, List<&2, String>>, has_header(h, "accept-encoding"), h, set(h, "accept-encoding", enc))


def ce.keep(+w: String, +rest: List<&2, String>) -> List<&2, String>:
  Bool.pick(List<&2, String>, String.is_empty(w), rest, Con{w, rest})


def ce.norm(xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{v, t}:
      ce.keep(String.to_lower(trim(v)), ce.norm(t))


def ce.split(xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{v, t}:
      List.append(&2, String, ce.norm(String.split(v, ',')), ce.split(t))

# Ok: decoded so far. Bad: a coding failed. Skip: a coding we cannot decode, so the body stays as sent.

def ce.has(xs: List<&2, String>, +c: String) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{x, t}:
      Bool.or(String.eq(c, x), ce.has(t, c))


type Fetch is Type:
  Fetch{method: String, url: String, headers: Map<&2, List<&2, String>>, body: Bytes.Bytes}


def reply.bytes(res: Res, head: Bool, close: Bool) -> Bytes.Bytes:
  Res{+status, +headers, body} = res
  encode.on(Res{status, Bool.pick(Map<&2, List<&2, String>>, close, set(headers, "connection", "close"), headers), body}, head)


def reply.fail.bytes(+status: U32) -> Res:
  Res{status, set(empty(), "connection", "close"), Bytes.from_string(reason(status))}


def reply.drain.of(m: Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>) -> Socket & Bool:
  (s, r) = m
  match r:
    case Fail{e}:
      (s, False{})
    case Done{data}:
      (len, words) = data
      (s, Bool.not(U32.is_zero(len)))

# ponytail: cap drain at 32 MiB and 2.55 s; use socket half-close if larger peers need guaranteed delivery.

def reply.drain(n: Nat, alive: Bool, +until: Time.Duration, st: Socket & Bool) -> IO(Unit):
  match n:
    case 0n:
      (s, more) = st
      Socket.close(s)
    case 1n+p:
      match alive:
        case False{}:
          (s, more) = st
          Socket.close(s)
        case True{}:
          (s, more) = st
          match more:
            case False{}:
              Socket.close(s)
            case True{}:
              do IO<Unit>:
                got : Socket & Result<&1, &1, U32 & String, U32 & Array<U32>> <- Wire.recv.words(s, 65536, 50)
                now : Time.Duration <- Time.mono()
                reply.drain(p, Cmp.is_lt(Time.Duration.cmp(now, until)), until, reply.drain.of(got))


def reply.sent.close(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (s, r) = m
  match r:
    case Fail{e}:
      Socket.close(s)
    case Done{u}:
      do IO<Unit>:
        now : Time.Duration <- Time.mono()
        reply.drain(U32.to_nat(512), True{}, Time.Duration.add(now, Time.Duration.of_ms(2500)), (s, True{}))


def reply_fail(s: Socket, +status: U32) -> IO(Unit):
  do IO<Unit>:
    sent : Socket & Result<&1, &1, U32 & String, Unit> <- io.send.bytes(False{}, s, encode(reply.fail.bytes(status)))
    reply.sent.close(sent)


# The head is parsed once, when it is whole. Body pieces are kept as they come and joined once.

type Sv is Type:
  SvHead{buf: Bytes.Bytes}
  SvLen{req: Req, v11: Bool, left: U32, parts: List<&1, Bytes.Bytes>}
  SvChunk{req: Req, v11: Bool, n: U32, st: Dc, parts: List<&1, Bytes.Bytes>}

# More: read on, first answering 100 Continue when cont is set.

type Turn is Type:
  TurnClose{}
  TurnFail{status: U32}
  TurnReq{req: Req, rest: Bytes.Bytes, v11: Bool}
  TurnMore{sv: Sv, cont: Bool}


def serve.max() -> Nat:
  fetch.max()


def sv.none() -> Sv:
  SvHead{Bytes.new(0)}


def sv.body(req: Req, +v11: Bool, parts: List<&1, Bytes.Bytes>, rest: Bytes.Bytes) -> Turn:
  Req{method, path, headers, body} = req
  TurnReq{Req{method, path, headers, rb.body(parts)}, rest, v11}


def sv.len.cut(req: Req, +v11: Bool, parts: List<&1, Bytes.Bytes>, +len: U32, +left: U32, r: Bytes.Bytes & Bytes.Bytes) -> Turn:
  (piece, last) = r
  sv.body(req, v11, Con{last, parts}, bytes.snd(Bytes.slice(piece, left, (len - left : U32))))


def sv.len.have(short: Bool, req: Req, +v11: Bool, +left: U32, parts: List<&1, Bytes.Bytes>, +len: U32, piece: Bytes.Bytes) -> Turn:
  match short:
    case True{}:
      TurnMore{SvLen{req, v11, (left - len : U32), Con{piece, parts}}, False{}}
    case False{}:
      sv.len.cut(req, v11, parts, len, left, Bytes.slice(piece, 0, left))


def sv.len(req: Req, +v11: Bool, +left: U32, parts: List<&1, Bytes.Bytes>, piece: Bytes.Bytes) -> Turn:
  Bytes.Bytes{+len, buf} = piece
  sv.len.have(U32.is_lt(len, left), req, v11, left, parts, len, Bytes.Bytes{len, buf})


def sv.chunk.of(req: Req, +v11: Bool, +n: U32, c: Ck) -> Turn:
  Ck{st, parts, rest} = c
  match st:
    case DcDone{}:
      sv.body(req, v11, parts, rest)
    case DcBad{}:
      TurnFail{400}
    case DcSize{a, b}:
      TurnMore{SvChunk{req, v11, n, DcSize{a, b}, parts}, False{}}
    case DcExt{x}:
      TurnMore{SvChunk{req, v11, n, DcExt{x}, parts}, False{}}
    case DcSizeLf{x}:
      TurnMore{SvChunk{req, v11, n, DcSizeLf{x}, parts}, False{}}
    case DcData{k}:
      TurnMore{SvChunk{req, v11, n, DcData{k}, parts}, False{}}
    case DcDataCr{}:
      TurnMore{SvChunk{req, v11, n, DcDataCr{}, parts}, False{}}
    case DcDataLf{}:
      TurnMore{SvChunk{req, v11, n, DcDataLf{}, parts}, False{}}
    case DcTr{j}:
      TurnMore{SvChunk{req, v11, n, DcTr{j}, parts}, False{}}


def sv.chunk.cap(big: Bool, req: Req, +v11: Bool, +n: U32, st: Dc, parts: List<&1, Bytes.Bytes>, piece: Bytes.Bytes) -> Turn:
  match big:
    case True{}:
      TurnFail{413}
    case False{}:
      sv.chunk.of(req, v11, n, ck(piece, st, parts))


def sv.chunk(+max: Nat, req: Req, +v11: Bool, +n: U32, st: Dc, parts: List<&1, Bytes.Bytes>, piece: Bytes.Bytes) -> Turn:
  Bytes.Bytes{+len, buf} = piece
  +n2 = (n + len : U32)
  sv.chunk.cap(Bool.or(U32.is_lt(n2, n), Nat.is_lt(max, U32.to_nat(n2))), req, v11, n2, st, parts, Bytes.Bytes{len, buf})

# RFC 9110 §10.1.1: answer 100 Continue only when the body is still to come.

def sv.cont(want: Bool, t: Turn) -> Turn:
  match t:
    case TurnMore{sv, c}:
      TurnMore{sv, want}
    case TurnClose{}:
      TurnClose{}
    case TurnFail{s}:
      TurnFail{s}
    case TurnReq{req, rest, v11}:
      TurnReq{req, rest, v11}


def sv.cl.k(big: Bool, req: Req, +v11: Bool, +k: U32, rest: Bytes.Bytes) -> Turn:
  match big:
    case True{}:
      TurnFail{413}
    case False{}:
      sv.len(req, v11, k, Nil{}, rest)


def sv.cl(+max: Nat, req: Req, +v11: Bool, rest: Bytes.Bytes, n: Maybe<&2, U32>) -> Turn:
  match n:
    case None{}:
      TurnFail{400}
    case Some{+k}:
      sv.cl.k(Nat.is_lt(max, U32.to_nat(k)), req, v11, k, rest)


def sv.frame(+max: Nat, req: Req, +v11: Bool, rest: Bytes.Bytes, te: Bool) -> Turn:
  Req{method, path, +headers, body} = req
  match te:
    case True{}:
      sv.chunk(max, Req{method, path, headers, body}, v11, 0, dc.start(), Nil{}, rest)
    case False{}:
      sv.cl(max, Req{method, path, headers, body}, v11, rest, parse_u32(header(headers, "content-length")))


def sv.expects(+v11: Bool, +headers: Map<&2, List<&2, String>>) -> Bool:
  Bool.and(v11, String.eq(String.to_lower(header(headers, "expect")), "100-continue"))


def sv.got.head(+max: Nat, +v11: Bool, rest: Bytes.Bytes, req: Req) -> Turn:
  Req{method, path, +headers, body} = req
  sv.cont(sv.expects(v11, headers), sv.frame(max, Req{method, path, headers, body}, v11, rest, has_header(headers, "transfer-encoding")))


def sv.parsed(+max: Nat, +v11: Bool, rest: Bytes.Bytes, g: Got) -> Turn:
  match g:
    case GotBad{}:
      TurnFail{400}
    case GotMore{}:
      TurnFail{400}
    case GotReq{req}:
      TurnReq{req, rest, v11}
    case GotHead{req}:
      sv.got.head(max, v11, rest, req)


def sv.split(+max: Nat, +hlen: U32, +len: U32, r: Bytes.Bytes & Bytes.Bytes) -> Turn:
  (buf, hb) = r
  +head = Bytes.to_string(hb)
  sv.parsed(max, req.v11(head), bytes.snd(Bytes.slice(buf, hlen, (len - hlen : U32))), parse.got(head))


def sv.hit.none(big: Bool, buf: Bytes.Bytes) -> Turn:
  match big:
    case True{}:
      TurnFail{431}
    case False{}:
      TurnMore{SvHead{buf}, False{}}


def sv.hit.some(big: Bool, +max: Nat, +hlen: U32, +len: U32, buf: Bytes.Bytes) -> Turn:
  match big:
    case True{}:
      TurnFail{431}
    case False{}:
      sv.split(max, hlen, len, Bytes.slice(buf, 0, hlen))

# RFC 6585 §5: a head over 64 KiB is refused.

def sv.hit(+max: Nat, +len: U32, buf: Bytes.Bytes, at: Maybe<&2, U32>) -> Turn:
  match at:
    case None{}:
      sv.hit.none(U32.is_lt(65536, len), buf)
    case Some{+i}:
      +hlen = (i + 4 : U32)
      sv.hit.some(U32.is_lt(65536, hlen), max, hlen, len, buf)


def sv.seek.of(+max: Nat, +len: U32, +from: U32, buf: Bytes.Bytes, r: Bytes.Bytes & Maybe<&2, U32>) -> Turn:
  (tail, m) = r
  sv.hit(max, len, buf, found.at(from, m))


def sv.seek(+max: Nat, +len: U32, +from: U32, r: Bytes.Bytes & Bytes.Bytes) -> Turn:
  (buf, tail) = r
  sv.seek.of(max, len, from, buf, Bytes.find(tail, "\r\n\r\n"))

# Only the new bytes, and the 3 before them, can finish the blank line.

def sv.head.at(+max: Nat, +from: U32, buf: Bytes.Bytes) -> Turn:
  Bytes.Bytes{+len, b} = buf
  sv.seek(max, len, from, Bytes.slice(Bytes.Bytes{len, b}, from, (len - from : U32)))


def sv.head(+max: Nat, buf: Bytes.Bytes, piece: Bytes.Bytes) -> Turn:
  Bytes.Bytes{+ol, ob} = buf
  sv.head.at(max, Bool.pick(U32, U32.is_lt(ol, 3), 0, (ol - 3 : U32)), Bytes.append(Bytes.Bytes{ol, ob}, piece))


def sv.closed.pick(empty: Bool) -> Turn:
  match empty:
    case True{}:
      TurnClose{}
    case False{}:
      TurnFail{400}


def sv.closed.head(buf: Bytes.Bytes) -> Turn:
  Bytes.Bytes{+len, b} = buf
  sv.closed.pick(U32.is_eq(len, 0))

# A close mid-request is a request cut short (RFC 9112 §8).

def sv.step(closed: Bool, +max: Nat, sv: Sv, piece: Bytes.Bytes) -> Turn:
  match closed:
    case True{}:
      match sv:
        case SvHead{buf}:
          sv.closed.head(buf)
        case SvLen{req, v11, left, parts}:
          TurnFail{400}
        case SvChunk{req, v11, n, st, parts}:
          TurnFail{400}
    case False{}:
      match sv:
        case SvHead{buf}:
          sv.head(max, buf, piece)
        case SvLen{req, +v11, +left, parts}:
          sv.len(req, v11, left, parts, piece)
        case SvChunk{req, +v11, +n, st, parts}:
          sv.chunk(max, req, v11, n, st, parts, piece)


def talk.piece(+max: Nat, sv: Sv, p: U32 & Array<U32>) -> Turn:
  (+len, buf) = p
  sv.step(U32.is_eq(len, 0), max, sv, Bytes.Bytes{len, buf})


def talk.next(+max: Nat, sv: Sv, m: Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>) -> Socket & Turn:
  (s, r) = m
  match r:
    case Fail{e}:
      (s, TurnClose{})
    case Done{p}:
      (s, talk.piece(max, sv, p))


def talk.after.pick(empty: Bool, +max: Nat, rest: Bytes.Bytes) -> Turn:
  match empty:
    case True{}:
      TurnMore{sv.none(), False{}}
    case False{}:
      sv.step(False{}, max, sv.none(), rest)


def talk.after.rest(+max: Nat, rest: Bytes.Bytes, s: Socket) -> Socket & Turn:
  Bytes.Bytes{+len, buf} = rest
  (s, talk.after.pick(U32.is_eq(len, 0), max, Bytes.Bytes{len, buf}))


def talk.after.keep(keep: Bool, +max: Nat, rest: Bytes.Bytes, s: Socket) -> Socket & Turn:
  match keep:
    case False{}:
      (s, TurnClose{})
    case True{}:
      talk.after.rest(max, rest, s)


def talk.after(+max: Nat, keep: Bool, rest: Bytes.Bytes, m: Socket & Result<&1, &1, U32 & String, Unit>) -> Socket & Turn:
  (s, r) = m
  match r:
    case Fail{e}:
      (s, TurnClose{})
    case Done{u}:
      talk.after.keep(keep, max, rest, s)


def talk.send(+max: Nat, s: Socket, rest: Bytes.Bytes, +headers: Map<&2, List<&2, String>>, v11: Bool, +head: Bool, res: Res) -> IO(Socket & Turn):
  Res{+status, +rh, body} = res
  +keep = serve.keep(headers, v11, status, rh)
  do IO<Socket & Turn>:
    sent : Socket & Result<&1, &1, U32 & String, Unit> <- io.send.bytes(False{}, s, reply.bytes(Res{status, rh, body}, head, Bool.not(keep)))
    return talk.after(max, keep, rest, sent)


def talk.cont.sent(m: Socket & Result<&1, &1, U32 & String, Unit>) -> Socket:
  (s, r) = m
  s


def talk.cont(cont: Bool, s: Socket) -> IO(Socket):
  match cont:
    case False{}:
      IO.pure(Socket, s)
    case True{}:
      do IO<Socket>:
        sent : Socket & Result<&1, &1, U32 & String, Unit> <-
          io.send.bytes(False{}, s, Bytes.from_string("HTTP/1.1 100 Continue\r\n\r\n"))
        return talk.cont.sent(sent)


@unsafe
def talk(~h: Req -> IO(Res), +max: Nat, st: Socket & Turn) -> IO(Unit):
  (s, t) = st
  match t:
    case TurnMore{sv, cont}:
      do IO<Unit>:
        s2 : Socket <- talk.cont(cont, s)
        m : Socket & Result<&1, &1, U32 & String, U32 & Array<U32>> <- Wire.recv.words(s2, 65536, 30000)
        talk(~h, max, talk.next(max, sv, m))
    case TurnReq{req, rest, v11}:
      Req{+method, path, +headers, body} = req
      do IO<Unit>:
        res : Res <- h(Req{method, path, headers, body})
        next : Socket & Turn <- talk.send(max, s, rest, headers, v11, String.eq(method, "HEAD"), res)
        talk(~h, max, next)
    case TurnFail{status}:
      reply_fail(s, status)
    case TurnClose{}:
      Socket.close(s)


def conn(~h: Req -> IO(Res), +max: Nat, m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Listener):
  (l, r) = m
  do IO<Listener>:
    s : Socket <- IO.pass(Socket, r)
    IO.spawn(Unit, talk(~h, max, (s, TurnMore{sv.none(), False{}})))
    return l


@unsafe
def loop(~h: Req -> IO(Res), +max: Nat, l: Listener) -> IO(Unit):
  do IO<Unit>:
    m  : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    l2 : Listener <- conn(~h, max, m)
    loop(~h, max, l2)


def serve.on.with(~h: Req -> IO(Res), host: String, +port: U32, +max: Nat) -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen(host, port))
    loop(~h, max, l)


def serve.on(~h: Req -> IO(Res), host: String, +port: U32) -> IO(Unit):
  serve.on.with(~h, host, port, serve.max())

