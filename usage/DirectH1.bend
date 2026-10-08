import Base
import ../libs/DirectH1.bend as DirectH1
import 0x2ef00d214bb4173160420b61a1472572/http.bend as Http

def show(result: Result<&1, &1, Http.Err, Http.Res>) -> String:
    match result:
        case Fail{_}: "HTTP request failed"
        case Done{Http.Res{status, _, _}}: "HTTP status: " ++ U32.show(status)

# Explicit opt-in: running the binary makes a request to DIRECT_H1_URL.
# No request is made while compiling it. Response bodies and credentials
# are never printed by this example.
def configured(value: Result<&1, &1, U32 & String, String>) -> IO(Unit):
    match value:
        case Fail{_}: IO.print("Set DIRECT_H1_URL to the URL to request.")
        case Done{url}:
            do IO<Unit>:
                result : Result<&1, &1, Http.Err, Http.Res> <- DirectH1.get(url)
                IO.print(show(result))

def main() -> IO(Unit):
    do IO<Unit>:
        url : Result<&1, &1, U32 & String, String> <- IO.get_env("DIRECT_H1_URL")
        configured(url)
