# HTTP/1.1 idle sockets only. No HTTP/2 connection or dispatch types.
import Base
import ../wire/wire.bend as Wire

type Connection is Type:
    Connection{tls: Bool, socket: Socket}

type Idle is Type:
    Idle{key: String, connection: Connection, since: Nat}

# Global capacity bounds the number of idle sockets across all origins.
# Affine ownership serializes access; concurrent workers each own a pool.
type Pool is Type:
    Pool{capacity: U32, idle_ms: U32, idle: List<Idle>}

def new.with(capacity: U32, idle_ms: U32) -> Pool:
    Pool{capacity, idle_ms, Nil{}}

def new() -> Pool:
    new.with(8, 30000)

def connection.close(c: Connection) -> IO(Unit):
    match c:
        case Connection{tls, socket}:
            match tls:
                case True{}: Wire.tls.close(socket)
                case False{}: Socket.close(socket)

def idle.close(xs: List<Idle>) -> IO(Unit):
    match xs:
        case Nil{}: IO.pure(Unit, Unit{})
        case Idle{_, c, _} <> tail:
            do IO<Unit>:
                connection.close(c)
                idle.close(tail)

def close(pool: Pool) -> IO(Unit):
    Pool{_, _, xs} = pool
    idle.close(xs)

def clear(pool: Pool) -> IO(Pool):
    Pool{capacity, ttl, xs} = pool
    do IO<Pool>:
        idle.close(xs)
        return Pool{capacity, ttl, Nil{}}

def trim(xs: List<Idle>, keep: Nat) -> IO(List<Idle>):
    match xs:
        case Nil{}: IO.pure(List<Idle>, Nil{})
        case item <> tail:
            match keep:
                case 0n:
                    do IO<List<Idle>>:
                        idle.close(item <> tail)
                        return Nil{}
                case 1n+n:
                    do IO<List<Idle>>:
                        rest : List<Idle> <- trim(tail, n)
                        return item <> rest

def put.with(pool: Pool, item: Idle) -> IO(Pool):
    Pool{+capacity, idle_ms, idle} = pool
    do IO<Pool>:
        retained : List<Idle> <- trim(item <> idle, U32.to_nat(capacity))
        return Pool{capacity, idle_ms, retained}

def put(pool: Pool, key: String, c: Connection) -> IO(Pool):
    do IO<Pool>:
        now : Nat <- IO.now()
        put.with(pool, Idle{key, c, now})

def taken.cons(item: Idle, pair: List<Idle> & Maybe<&1, Connection>) -> List<Idle> & Maybe<&1, Connection>:
    (rest, got) = pair
    (item <> rest, got)

@unsafe
def take.match(equal: Bool, +key: String, +ttl: U32, +now: Nat, item: Idle, tail: List<Idle>) -> IO(List<Idle> & Maybe<&1, Connection>):
    match equal:
        case True{}:
            Idle{_, c, _} = item
            IO.pure(List<Idle> & Maybe<&1, Connection>, (tail, Some{c}))
        case False{}:
            do IO<List<Idle> & Maybe<&1, Connection>>:
                pair : List<Idle> & Maybe<&1, Connection> <- take.list(key, ttl, now, tail)
                return taken.cons(item, pair)

@unsafe
def take.live(live: Bool, +key: String, +ttl: U32, +now: Nat, +name: String, c: Connection, since: Nat, tail: List<Idle>) -> IO(List<Idle> & Maybe<&1, Connection>):
    match live:
        case False{}:
            do IO<List<Idle> & Maybe<&1, Connection>>:
                connection.close(c)
                take.list(key, ttl, now, tail)
        case True{}:
            take.match(String.eq(key, name), key, ttl, now, Idle{name, c, since}, tail)

@unsafe
def take.list(+key: String, +ttl: U32, +now: Nat, xs: List<Idle>) -> IO(List<Idle> & Maybe<&1, Connection>):
    match xs:
        case Nil{}: IO.pure(List<Idle> & Maybe<&1, Connection>, (Nil{}, None{}))
        case Idle{name, c, +since} <> tail:
            take.live(Nat.is_lt(Nat.sub(now, since), U32.to_nat(ttl)),
                key, ttl, now, name, c, since, tail)

def take.done(capacity: U32, ttl: U32, pair: List<Idle> & Maybe<&1, Connection>) -> Pool & Maybe<&1, Connection>:
    (idle, got) = pair
    (Pool{capacity, ttl, idle}, got)

def take(pool: Pool, key: String) -> IO(Pool & Maybe<&1, Connection>):
    Pool{capacity, +ttl, idle} = pool
    do IO<Pool & Maybe<&1, Connection>>:
        now : Nat <- IO.now()
        pair : List<Idle> & Maybe<&1, Connection> <- take.list(key, ttl, now, idle)
        return take.done(capacity, ttl, pair)
