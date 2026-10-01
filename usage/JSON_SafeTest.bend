import Base
import ../libs/JSON.bend as Json

def check(ok: Bool, label: String) -> IO(Unit):
    match ok:
        case True{}:
            IO.pure(Unit, Unit{})
        case False{}:
            IO.die(Unit, 1, "JSON test failed: " ++ label)

def valid_reparse(result: Result<&1, &1, Json.Error, Json.Value>, value: Json.Value) -> Bool:
    match result:
        case Fail{_}:
            False{}
        case Done{again}:
            String.eq(Json.stringify(again), Json.stringify(value))


def valid_parse(result: Result<&1, &1, Json.Error, Json.Value>) -> Bool:
    match result:
        case Fail{_}:
            False{}
        case Done{+value}:
            valid_reparse(Json.parse(Json.stringify(value)), value)

def valid_roundtrip(text: String) -> Bool:
    valid_parse(Json.parse(text))

def rejects_parse(result: Result<&1, &1, Json.Error, Json.Value>) -> Bool:
    match result:
        case Fail{_}: True{}
        case Done{_}: False{}

def rejects(text: String) -> Bool:
    rejects_parse(Json.parse(text))

def main() -> IO(Unit):
    do IO<Unit>:
        sample_ok : Bool = valid_roundtrip("{\"shop\":\"Bend & Thread\",\"active\":true,\"currency\":\"USD\",\"items\":[{\"listing_id\":84512037,\"title\":\"Handwoven linen table runner\",\"price\":42.5,\"tags\":[\"linen\",\"table decor\",\"handmade\"],\"personalization_enabled\":false},{\"listing_id\":84512038,\"title\":\"Indigo napkins\",\"price\":18.0,\"tags\":[],\"personalization_enabled\":true}],\"notes\":null}")
        check(sample_ok, "assets/sample.json round trip")
        check(valid_roundtrip("[null,true,false,0,-3,1.2e+4,\"ok\"]"), "nested values and numbers")
        check(rejects("01") && rejects("1.") && rejects("[1,]") && rejects("{\"x\":}"), "malformed JSON")
        IO.print("JSON parser tests passed")
