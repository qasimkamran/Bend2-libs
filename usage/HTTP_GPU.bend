import Base
import ../libs/HTTPClient.bend as HttpClient

def result_text(result: Result<&2, &2, HttpClient.Error, List<&2, U32>>) -> String:
    match result:
        case Fail{_}: "encode-error"
        case Done{bytes}: "encoded:" ++ Nat.show(List.length(&2, U32, bytes))

def decode_text(result: HttpClient.Decode) -> String:
    match result:
        case HttpClient.NeedMore{}: "need-more"
        case HttpClient.Rejected{_}: "decode-error"
        case HttpClient.Parsed{response, rest}:
            HttpClient.Response{status, headers, body, trailers} = response
            "decoded:" ++ U32.show(status) ++ ":" ++ Nat.show(List.length(&2, U32, body))

def outcome_text(outcome: HttpClient.Outcome) -> String:
    match outcome:
        case HttpClient.Encoded{result}: result_text(result)
        case HttpClient.Decoded{result}: decode_text(result)

def results_text(results: HttpClient.BatchResult) -> String:
    match results:
        case HttpClient.LeafResult{outcome}: outcome_text(outcome)
        case HttpClient.ForkResult{left, right}: results_text(left) ++ "|" ++ results_text(right)

def optional_text(results: Maybe<&2, HttpClient.BatchResult>) -> String:
    match results:
        case None{}: "empty"
        case Some{tree}: results_text(tree)

def jobs() -> List<&2, HttpClient.Work>:
    +limits = {HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 2097152} : HttpClient.Limits}
    [HttpClient.EncodeWork{HttpClient.Request{"GET", "https://example.com/a", Nil{}, Nil{}}},
      HttpClient.DecodeWork{"GET", limits, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nabc"), False{}},
      HttpClient.DecodeWork{"GET", limits, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nab"), False{}},
      HttpClient.EncodeWork{HttpClient.Request{"GET", "ftp://example.com/", Nil{}, Nil{}}},
      HttpClient.DecodeWork{"GET", limits, HttpClient.utf8("HTTP/1.1 bad\r\n\r\n"), True{}}]

def check(equal: Bool) -> IO(Unit):
    match equal:
        case True{}: IO.print("HTTP GPU entry point: results agree")
        case False{}: IO.die(Unit, 1, "HTTP GPU dispatch mismatch")

# Run natively with --gpu off for the CPU path. A supported GPU is required
# to establish actual device execution with --gpu on.
def compared() -> Bool:
    +inputs = jobs()
    cpu = optional_text(HttpClient.run_many(inputs))
    gpu = optional_text(HttpClient.run_many_gpu(inputs))
    empty = optional_text(HttpClient.run_many_gpu(Nil{}))
    Bool.and(String.eq(cpu, gpu), String.eq(empty, "empty"))

def main() -> IO(Unit):
    check(compared())
