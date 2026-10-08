import Base
import ../libs/DirectH1.bend as DirectH1
import 0x2ef00d214bb4173160420b61a1472572/http.bend as Http

def status(result: Result<&1, &1, Http.Err, Http.Res>) -> String:
    match result:
        case Fail{_}: "HTTP request failed"
        case Done{Http.Res{code, _, _}}: "HTTP status: " ++ U32.show(code)

def finish(pair: DirectH1.Pool & Result<&1, &1, Http.Err, Http.Res>) -> IO(Unit):
    (pool, result) = pair
    do IO<Unit>:
        IO.print(status(result))
        DirectH1.pool.close(pool)

def next(url: String, pair: DirectH1.Pool & Result<&1, &1, Http.Err, Http.Res>) -> IO(Unit):
    (pool, result) = pair
    do IO<Unit>:
        IO.print(status(result))
        second : DirectH1.Pool & Result<&1, &1, Http.Err, Http.Res> <- DirectH1.pool.get(pool, url)
        finish(second)

def request(+url: String) -> IO(Unit):
    do IO<Unit>:
        first : DirectH1.Pool & Result<&1, &1, Http.Err, Http.Res> <- DirectH1.pool.get(DirectH1.pool.new(), url)
        next(url, first)

# Running this example explicitly makes two GET requests to DIRECT_H1_URL.
# The second can reuse the first connection; no bodies/credentials are printed.
def configured(value: Result<&1, &1, U32 & String, String>) -> IO(Unit):
    match value:
        case Fail{_}: IO.print("Set DIRECT_H1_URL to the URL to request twice.")
        case Done{url}: request(url)

def main() -> IO(Unit):
    do IO<Unit>:
        url : Result<&1, &1, U32 & String, String> <- IO.get_env("DIRECT_H1_URL")
        configured(url)
