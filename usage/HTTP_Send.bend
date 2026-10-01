import Base
import ../libs/HTTPClient.bend as HttpClient

def local_request() -> HttpClient.Request:
    HttpClient.Request{"GET", "http://127.0.0.1:8765/", Nil{}, Nil{}}

def local_options() -> HttpClient.Options:
    HttpClient.Options{HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 2097152}, 2000, 2000, 2000, 7000, 64}

def show_error(error: HttpClient.Error) -> IO(Unit):
    match error:
        case HttpClient.Configuration{}: IO.die(Unit, 1, "configuration")
        case HttpClient.Connection{}: IO.die(Unit, 1, "connection")
        case HttpClient.Tls{}: IO.die(Unit, 1, "tls")
        case HttpClient.Io{}: IO.die(Unit, 1, "io")
        case HttpClient.Timeout{}: IO.die(Unit, 1, "timeout")
        case HttpClient.InvalidUrl{}: IO.die(Unit, 1, "invalid url")
        case HttpClient.UnsupportedScheme{}: IO.die(Unit, 1, "unsupported scheme")
        case HttpClient.UnsupportedHost{}: IO.die(Unit, 1, "unsupported host")
        case HttpClient.InvalidMethod{}: IO.die(Unit, 1, "invalid method")
        case HttpClient.InvalidHeader{}: IO.die(Unit, 1, "invalid header")
        case HttpClient.ReservedHeader{}: IO.die(Unit, 1, "reserved header")
        case HttpClient.InvalidByte{}: IO.die(Unit, 1, "invalid byte")
        case HttpClient.InvalidStatus{}: IO.die(Unit, 1, "invalid status")
        case HttpClient.InvalidVersion{}: IO.die(Unit, 1, "invalid version")
        case HttpClient.InvalidFraming{}: IO.die(Unit, 1, "invalid framing")
        case HttpClient.UnsupportedTransferEncoding{}: IO.die(Unit, 1, "unsupported transfer encoding")
        case HttpClient.UnexpectedEof{}: IO.die(Unit, 1, "unexpected eof")
        case HttpClient.LimitExceeded{}: IO.die(Unit, 1, "limit exceeded")
        case HttpClient.UnsupportedUpgrade{}: IO.die(Unit, 1, "unsupported upgrade")
        case HttpClient.NoProgress{}: IO.die(Unit, 1, "no progress")
        case HttpClient.InvalidJson{}: IO.die(Unit, 1, "invalid json")
        case HttpClient.UnsupportedContentEncoding{}: IO.die(Unit, 1, "unsupported content encoding")
        case HttpClient.InvalidUtf8{}: IO.die(Unit, 1, "invalid utf8")

def show_result(result: Result<&1, &1, HttpClient.Error, HttpClient.Response>) -> IO(Unit):
    match result:
        case Fail{error}: show_error(error)
        case Done{response}:
            HttpClient.Response{status, headers, body, trailers} = response
            IO.print("status=" ++ U32.show(status) ++ " bytes=" ++ U32.show(U32.from_nat(List.length(&2, U32, body))))

def main() -> IO(Unit):
    do IO<Unit>:
        result : Result<&1, &1, HttpClient.Error, HttpClient.Response>
            <- HttpClient.send(local_request(), local_options())
        show_result(result)
