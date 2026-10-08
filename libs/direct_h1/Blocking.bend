# Cancellable blocking stages using Base.Process.run, never a shell.
import Base
import 0x2ef00d214bb4173160420b61a1472572/http.bend as Http
import 0x49814d83de8f70993a43e1002be29ecd/bytes.bend as Bytes

def remaining(+total: U32, start: Nat, now: Nat, phase: U32) -> U32:
    match total:
        case 0: phase
        case other: U32.from_nat(Nat.min(U32.to_nat(phase),
            Nat.sub(U32.to_nat(total), Nat.sub(now, start))))

# This is a build artifact, not a service. Override its trusted executable path
# with DIRECT_H1_WORKER. Request data goes through private stdin/stdout pipes.
def executable(value: Result<&1, &1, U32 & String, String>) -> String:
    match value:
        case Fail{_}: "direct-h1-worker"
        case Done{path}: path

def output.code(code: U32, out: String) -> Result<&1, &1, Http.Err, String>:
    match code:
        case 0: Done{out}
        case other: Fail{Http.ErrBad{}}

def output(result: Result<&1, &1, U32 & String, U32 & (String & String)>) -> Result<&1, &1, Http.Err, String>:
    match result:
        case Fail{(+code, why)}: Fail{Http.err.or_late(code, Http.ErrRead{code, why})}
        case Done{(code, (out, _))}: output.code(code, out)

def run.path(path: String, job: String, input: String, ms: U32, max: U32) -> IO(Result<&1, &1, Http.Err, String>):
    do IO<Result<&1, &1, Http.Err, String>>:
        result : Result<&1, &1, U32 & String, U32 & (String & String)> <-
            Process.run(path, [job, "--threads", "2"], input, max, ms)
        return output(result)

def run(job: String, input: String, ms: U32, max: U32) -> IO(Result<&1, &1, Http.Err, String>):
    do IO<Result<&1, &1, Http.Err, String>>:
        path : Result<&1, &1, U32 & String, String> <- IO.get_env("DIRECT_H1_WORKER")
        run.path(executable(path), job, input, ms, max)

def dns.nonempty(s: String) -> Bool:
    Bool.not(String.is_empty(s))

def dns.result(result: Result<&1, &1, Http.Err, String>) -> Result<&1, &1, Http.Err, List<&2, String>>:
    match result:
        case Fail{error}: Fail{error}
        case Done{out}: Done{List.filter(~String, ~dns.nonempty, String.split(out, '\n'))}

def dns(host: String, ms: U32) -> IO(Result<&1, &1, Http.Err, List<&2, String>>):
    do IO<Result<&1, &1, Http.Err, List<&2, String>>>:
        result : Result<&1, &1, Http.Err, String> <- run("dns", host, ms, 65536)
        return dns.result(result)

def decoded.body(status: U32, headers: Map<&2, List<&2, String>>, body: Maybe<&1, Bytes.Bytes>) -> Result<&1, &1, Http.Err, Http.Res>:
    match body:
        case None{}: Fail{Http.ErrBad{}}
        case Some{bytes}: Done{Http.Res{status, headers, bytes}}

def decoded.result(status: U32, headers: Map<&2, List<&2, String>>, result: Result<&1, &1, Http.Err, String>) -> Result<&1, &1, Http.Err, Http.Res>:
    match result:
        case Fail{error}: Fail{error}
        case Done{out}: decoded.body(status, headers, Bytes.from_base64(Http.trim(out)))

def decode.ready(ok: Bool, status: U32, headers: Map<&2, List<&2, String>>, input: String, ms: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    match ok:
        case False{}: IO.pure(Result<&1, &1, Http.Err, Http.Res>, Fail{Http.ErrTimeout{}})
        case True{}:
            do IO<Result<&1, &1, Http.Err, Http.Res>>:
                result : Result<&1, &1, Http.Err, String> <- run("decode", input, ms, 22370624)
                return decoded.result(status, headers, result)

def decode.timed(status: U32, headers: Map<&2, List<&2, String>>, input: String, +ms: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    decode.ready(U32.is_ne(ms, 0), status, headers, input, ms)

def decode.prepared(status: U32, headers: Map<&2, List<&2, String>>, input: String, total: U32, start: Nat, phase: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    do IO<Result<&1, &1, Http.Err, Http.Res>>:
        now : Nat <- IO.now()
        decode.timed(status, headers, input, remaining(total, start, now, phase))

def decode.run(enc: String, status: U32, +headers: Map<&2, List<&2, String>>, body: Bytes.Bytes, total: U32, start: Nat, phase: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    decode.prepared(status, headers,
        enc ++ "\n" ++ String.join(Http.fields(headers, "content-encoding"), ", ") ++ "\n" ++ Bytes.to_base64(body),
        total, start, phase)

def decode.needed(needed: Bool, enc: String, res: Http.Res, total: U32, start: Nat, phase: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    match needed:
        case False{}: IO.pure(Result<&1, &1, Http.Err, Http.Res>, Done{res})
        case True{}:
            Http.Res{status, headers, body} = res
            decode.run(enc, status, headers, body, total, start, phase)

def decode(enc: String, res: Http.Res, total: U32, start: Nat, phase: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    Http.Res{status, +headers, body} = res
    Bytes.Bytes{+len, words} = body
    decode.needed(Bool.and(U32.is_ne(len, 0), Bool.not(Bool.or(
        String.is_empty(Http.header(headers, "content-encoding")),
        String.eq(String.to_lower(Http.header(headers, "content-encoding")), "identity")))),
        enc, Http.Res{status, headers, Bytes.Bytes{len, words}}, total, start, phase)

def final(enc: String, result: Result<&1, &1, Http.Err, Http.Res>, total: U32, start: Nat, phase: U32) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    match result:
        case Fail{e}: IO.pure(Result<&1, &1, Http.Err, Http.Res>, Fail{e})
        case Done{res}: decode(enc, res, total, start, phase)
