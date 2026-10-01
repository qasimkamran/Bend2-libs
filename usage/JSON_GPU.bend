import Base
import ../libs/JSON.bend as Json

def show_result(result: Result<&1, &1, Json.Error, Json.Value>) -> String:
    match result:
        case Fail{_}:
            "ERROR"
        case Done{value}:
            Json.stringify(value)

def show_batch(batch: Json.BatchResult) -> String:
    match batch:
        case Json.DocumentResult{result}:
            show_result(result)
        case Json.DocumentResults{left, right}:
            show_batch(left) ++ "|" ++ show_batch(right)

def show_optional(batch: Maybe<&1, Json.BatchResult>) -> String:
    match batch:
        case None{}:
            "EMPTY"
        case Some{results}:
            show_batch(results)

def check(ok: Bool) -> IO(Unit):
    match ok:
        case True{}:
            IO.print("GPU entry point: results and order match")
        case False{}:
            IO.die(Unit, 1, "GPU entry point returned unexpected results")

# A native executable uses the GPU when available. --gpu off exercises the
# CPU fallback. JavaScript executes this example sequentially.
def main() -> IO(Unit):
    do IO<Unit>:
        actual : String = show_optional(Json.parse_many_gpu(
            "null" <> "true" <> "[1,]" <> "-12.50e+3" <>
            "{\"x\":[false,\"ok\"]}" <> Nil{}))
        check(String.eq(actual, "null|true|ERROR|-12.50e+3 |{\"x\":[false,\"ok\"]}"))
