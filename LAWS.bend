# Library correctness laws and integration obligations.

import Base

# JSON contract: libs/JSON.bend.
#
# Expected API:
#   Json.parse(text: String) -> Result<&1, &1, Json.Error, Json.Value>
#   Json.stringify(value: Json.Value) -> String

import ./libs/JSON.bend as Json

# ============================================================
# JSON: Core correctness
# ============================================================

law stringify_parse_roundtrip:
    for value: Json.Value {
        Json.parse(Json.stringify(value))
        ==
        Done{value}
        :
        Result<&1, &1, Json.Error, Json.Value>
    }

# ============================================================
# JSON: Literals
# ============================================================

law parses_null:
    { Json.parse("null") == Done{Json.Null{}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_true:
    { Json.parse("true") == Done{Json.Bool{True{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_false:
    { Json.parse("false") == Done{Json.Bool{False{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

# ============================================================
# JSON: Whitespace
# ============================================================

law accepts_leading_space:
    for value: Json.Value {
        Json.parse(" " ++ Json.stringify(value)) == Done{value} :
        Result<&1, &1, Json.Error, Json.Value>
    }

law accepts_trailing_space:
    for value: Json.Value {
        Json.parse(Json.stringify(value) ++ " ") == Done{value} :
        Result<&1, &1, Json.Error, Json.Value>
    }

law accepts_surrounding_space:
    for value: Json.Value {
        Json.parse(" \n\t\r" ++ Json.stringify(value) ++ "\r\t\n ") == Done{value} :
        Result<&1, &1, Json.Error, Json.Value>
    }

# ============================================================
# JSON: Invalid and incomplete input
# ============================================================

law rejects_trailing_garbage:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("nullx"))
        == True{} : Bool }

law rejects_second_value:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("null true"))
        == True{} : Bool }

law rejects_invalid_null:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("nul"))
        == True{} : Bool }

law rejects_invalid_true:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("tru"))
        == True{} : Bool }

law rejects_invalid_false:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("fals"))
        == True{} : Bool }

law rejects_empty_input:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse(""))
        == True{} : Bool }

law rejects_whitespace_only:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse(" \t\r\n "))
        == True{} : Bool }

# ============================================================
# JSON: Strings
# ============================================================

law parses_empty_string:
    { Json.parse("\"\"") == Done{Json.Str{""}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_simple_string:
    { Json.parse("\"hello\"") == Done{Json.Str{"hello"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_newline_escape:
    { Json.parse("\"a\\nb\"") == Done{Json.Str{"a\nb"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_quote_escape:
    { Json.parse("\"a\\\"b\"") == Done{Json.Str{"a\"b"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_backslash_escape:
    { Json.parse("\"a\\\\b\"") == Done{Json.Str{"a\\b"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law rejects_unterminated_string:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("\"hello"))
        == True{} : Bool }

# ============================================================
# JSON: Arrays
# ============================================================

law parses_empty_array:
    { Json.parse("[]") == Done{Json.Arr{Nil{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_literal_array:
    {
        Json.parse("[null,true,false]")
        ==
        Done{Json.Arr{
            Json.Null{} <>
            Json.Bool{True{}} <>
            Json.Bool{False{}} <>
            Nil{}
        }}
        :
        Result<&1, &1, Json.Error, Json.Value>
    }

law rejects_array_trailing_comma:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("[null,]"))
        == True{} : Bool }

# ============================================================
# JSON: Objects
# ============================================================

law parses_empty_object:
    { Json.parse("{}") == Done{Json.Obj{Nil{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

law rejects_unquoted_object_key:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("{foo:null}"))
        == True{} : Bool }

law rejects_object_trailing_comma:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("{\"x\":null,}"))
        == True{} : Bool }

# ============================================================
# JSON: Nesting
# ============================================================

law parses_nested_containers:
    {
        Json.parse("[{\"x\":[true,null]}]")
        ==
        Done{Json.Arr{
            Json.Obj{
                ("x", Json.Arr{
                    Json.Bool{True{}} <>
                    Json.Null{} <>
                    Nil{}
                }) <>
                Nil{}
            } <>
            Nil{}
        }}
        :
        Result<&1, &1, Json.Error, Json.Value>
    }

# ============================================================
# JSON: Additional semantics
# ============================================================

# JSON permits only space, tab, carriage return and line feed as whitespace.
law rejects_non_json_whitespace:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("\u{000b}null"))
        == True{} : Bool }

# A raw control character is forbidden inside a JSON string.
law rejects_raw_string_control:
    { Result.is_fail(&1, &1, Json.Error, Json.Value,
            Json.parse("\"" ++ "\u{0001}" ++ "\""))
        == True{} : Bool }

# Unicode escapes decode to their scalar value, including a surrogate pair.
law parses_unicode_escape:
    { Json.parse("\"\\u263A\"") == Done{Json.Str{"\u{263a}"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_unicode_surrogate_pair:
    { Json.parse("\"\\uD83D\\uDE00\"") == Done{Json.Str{"\u{1f600}"}} :
        Result<&1, &1, Json.Error, Json.Value> }

# This representative decimal/exponent form is accepted. A separate law below
# checks that the smart number constructor preserves the original lexeme.
law parses_fraction_and_exponent:
    { Result.is_done(&1, &1, Json.Error, Json.Value, Json.parse("-12.50e+3"))
        == True{} : Bool }

law rejects_malformed_number_forms:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("01"))
        && Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("1."))
        && Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("1e+"))
        == True{} : Bool }

# Arrays retain source order. Objects retain source order and duplicate keys;
# consumers that need map semantics must choose their own duplicate-key policy.
law preserves_array_order:
    { Json.parse("[3,1,2]") == Done{Json.Arr{
            Json.Number{"3", Json.Certified{Json.number_proof("3", {==})}} <>
            Json.Number{"1", Json.Certified{Json.number_proof("1", {==})}} <>
            Json.Number{"2", Json.Certified{Json.number_proof("2", {==})}} <>
            Nil{}
        }} : Result<&1, &1, Json.Error, Json.Value> }

law preserves_object_order_and_duplicates:
    { Json.parse("{\"x\":1,\"x\":2}") == Done{Json.Obj{
            ("x", Json.Number{"1", Json.Certified{Json.number_proof("1", {==})}}) <>
            ("x", Json.Number{"2", Json.Certified{Json.number_proof("2", {==})}}) <>
            Nil{}
        }} : Result<&1, &1, Json.Error, Json.Value> }

# GPU entry points have the same specified results as their CPU counterparts.
law gpu_single_matches_cpu:
    for text: String {
        Json.parse_gpu(text) == Json.parse(text) :
        Result<&1, &1, Json.Error, Json.Value>
    }

law preserves_number_lexeme:
    { Json.number("-12.50e+3") == Done{Json.Number{
            "-12.50e+3",
            Json.Certified{Json.number_proof("-12.50e+3", {==})}
        }} : Result<&1, &1, Json.Error, Json.Value> }

law gpu_batch_matches_cpu:
    for batch: Json.Batch {
        Json.parse_batch_gpu(batch) == Json.parse_batch(batch) : Json.BatchResult
    }
