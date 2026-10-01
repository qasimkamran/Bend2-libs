# Library correctness laws and integration obligations.

import Base

# JSON contract: libs/JSON.bend.
#
# Expected API:
#   Json.parse(text: String) -> Result<&1, &1, Json.Error, Json.Value>
#   Json.stringify(value: Json.Value) -> String

import ./libs/JSON.bend as Json
import ./libs/HTTPClient.bend as HttpClient

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

# ============================================================
# HTTP: Client contract
# ============================================================

# These laws constrain the production libs/HTTPClient.bend implementation.
# Keep all JSON laws above. Implement these functions in production HTTP code;
# prove these laws in PROOF.bend without weakening or replacing the contract.
# Scope, type layouts, deterministic encoding policy and error meanings:
# Required interface is declared in libs/HTTPClient.bend.
# Standards: https://www.rfc-editor.org/rfc/rfc9112.html
#            https://www.rfc-editor.org/rfc/rfc9110.html
# Project choices include strict duplicate-length rejection, no redirects,
# no retries, bounded buffered bodies and one connection per request.

# Independent specification helpers; do not delegate these to HTTP helpers.
def http_append(xs: List<&2, U32>, ys: List<&2, U32>) -> List<&2, U32>:
    match xs:
        case Nil{}: ys
        case Con{h, t}: h <> http_append(t, ys)

def http_length(xs: List<&2, U32>) -> Nat:
    match xs:
        case Nil{}: 0n
        case Con{h, t}: 1n+http_length(t)

# Header cap includes the status line and terminating blank line, per head.
# Trailer cap includes its terminating blank line. Chunk-line cap includes CRLF.
# Body cap counts decoded payload; wire cap counts consumed framing and payload.
def http_limits() -> HttpClient.Limits:
    HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 2097152}

def http_header(name: String, value: String) -> HttpClient.Header:
    HttpClient.Header{name, HttpClient.utf8(value)}

def http_decode(method: String, text: String, eof: Bool) -> HttpClient.Decode:
    HttpClient.decode(method, http_limits(), HttpClient.utf8(text), eof)

# JSON wire roundtrips are defined for Unicode scalar strings. Bend's String
# type permits arbitrary U32 characters, while HTTP JSON crosses strict UTF-8.
def http_unicode_scalar(+c: U32) -> Bool:
    Bool.and(U32.is_le(c, 1114111), Bool.not(Bool.and(U32.is_le(55296, c), U32.is_le(c, 57343))))

def http_unicode_string(text: String) -> Bool:
    match text:
        case SNil{}: True{}
        case SCon{Chr{c}, rest}: Bool.and(http_unicode_scalar(c), http_unicode_string(rest))

# ============================================================
# HTTP: UTF-8 and binary correctness
# ============================================================

law http_utf8_octets:
    { HttpClient.utf8("é") == [195, 169] : List<&2, U32> }

# Deferred universal law; see libs/HTTPClient.bend's UTF-8 implementation.
# law http_utf8_produces_bytes:
#   for text: String {
#     HttpClient.valid_bytes(HttpClient.utf8(text)) == True{} : Bool
#   }

law http_binary_boundaries:
    { HttpClient.valid_bytes([0, 127, 128, 255]) == True{} : Bool }

law http_reject_non_octet:
    { HttpClient.valid_bytes([256]) == False{} : Bool }

# ============================================================
# HTTP: URL validation and request targets
# ============================================================

# URL validation and exact request-target preservation.

law http_https_target:
    { HttpClient.parse_url("https://Example.com/v1/responses?x=%2F&x=2#local")
        == Done{HttpClient.Target{True{}, "example.com", 443, "example.com", "/v1/responses?x=%2F&x=2"}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_http_default_path:
    { HttpClient.parse_url("http://example.com")
        == Done{HttpClient.Target{False{}, "example.com", 80, "example.com", "/"}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_query_without_path:
    { HttpClient.parse_url("https://example.com?q=1")
        == Done{HttpClient.Target{True{}, "example.com", 443, "example.com", "/?q=1"}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_nondefault_port:
    { HttpClient.parse_url("https://example.com:8443/a")
        == Done{HttpClient.Target{True{}, "example.com", 8443, "example.com:8443", "/a"}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_explicit_default_port:
    { HttpClient.parse_url("https://example.com:443/")
        == Done{HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_signed_path_unchanged:
    { HttpClient.parse_url("https://example.com/a/../b%2fc?z=2&a=1&a=0")
        == Done{HttpClient.Target{True{}, "example.com", 443, "example.com", "/a/../b%2fc?z=2&a=1&a=0"}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_unsupported_scheme:
    { HttpClient.parse_url("ftp://example.com/")
        == Fail{HttpClient.UnsupportedScheme{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_userinfo:
    { HttpClient.parse_url("https://user:secret@example.com/")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_empty_host:
    { HttpClient.parse_url("https:///a")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_port_overflow:
    { HttpClient.parse_url("https://example.com:65536/")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_port_zero:
    { HttpClient.parse_url("https://example.com:0/")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_empty_port:
    { HttpClient.parse_url("https://example.com:/")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_relative_url:
    { HttpClient.parse_url("/a")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_url_injection:
    { HttpClient.parse_url("https://example.com/a\r\nX: y")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_url_space:
    { HttpClient.parse_url("https://example.com/a b")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_invalid_escape:
    { HttpClient.parse_url("https://example.com/%Q0")
        == Fail{HttpClient.InvalidUrl{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

law http_reject_unsupported_ipv6:
    { HttpClient.parse_url("https://[::1]/")
        == Fail{HttpClient.UnsupportedHost{}} : Result<&2, &2, HttpClient.Error, HttpClient.Target> }

# ============================================================
# HTTP: Header lookup
# ============================================================

# Header lookup never joins duplicates or changes field values.

law http_header_lookup_case_insensitive:
    { HttpClient.field_values("set-cookie", [http_header("Set-Cookie", "a=1"), http_header("X-Other", "skip"), http_header("sEt-CoOkIe", "b=2")])
        == [HttpClient.utf8("a=1"), HttpClient.utf8("b=2")] : List<&2, List<&2, U32>> }

law http_header_lookup_missing:
    { HttpClient.field_values("missing", Nil{})
        == Nil{} : List<&2, List<&2, U32>> }

# ============================================================
# HTTP: Request encoding
# ============================================================

# Request encoder output is byte-exact and owns framing headers.

law http_encode_get:
    { HttpClient.encode(HttpClient.Request{"GET", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("GET / HTTP/1.1\r\nHost: example.com\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_encode_head:
    { HttpClient.encode(HttpClient.Request{"HEAD", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("HEAD / HTTP/1.1\r\nHost: example.com\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_encode_post:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: 0\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_encode_put:
    { HttpClient.encode(HttpClient.Request{"PUT", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("PUT / HTTP/1.1\r\nHost: example.com\r\nContent-Length: 0\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_encode_patch:
    { HttpClient.encode(HttpClient.Request{"PATCH", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("PATCH / HTTP/1.1\r\nHost: example.com\r\nContent-Length: 0\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_encode_delete:
    { HttpClient.encode(HttpClient.Request{"DELETE", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("DELETE / HTTP/1.1\r\nHost: example.com\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_encode_options:
    { HttpClient.encode(HttpClient.Request{"OPTIONS", "https://example.com", Nil{}, Nil{}})
        == Done{HttpClient.utf8("OPTIONS / HTTP/1.1\r\nHost: example.com\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_utf8_content_length:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com:8443/a?x=1&x=2", [http_header("Authorization", "Bearer sample"), http_header("Content-Type", "application/json")], HttpClient.utf8("é")})
        == Done{HttpClient.utf8("POST /a?x=1&x=2 HTTP/1.1\r\nHost: example.com:8443\r\nAuthorization: Bearer sample\r\nContent-Type: application/json\r\nContent-Length: 2\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\né")} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_host:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("host", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_content_length:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("content-length", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_transfer_encoding:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("transfer-encoding", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_connection:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("connection", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_accept_encoding:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("accept-encoding", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_expect:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("expect", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_upgrade:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("upgrade", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_reserved_trailer:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", [http_header("trailer", "x")], Nil{}})
        == Fail{HttpClient.ReservedHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_bad_header_name:
    { HttpClient.encode(HttpClient.Request{"GET", "https://example.com/", [http_header("Bad Name", "x")], Nil{}})
        == Fail{HttpClient.InvalidHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_header_name_injection:
    { HttpClient.encode(HttpClient.Request{"GET", "https://example.com/", [http_header("X\r\nInjected", "x")], Nil{}})
        == Fail{HttpClient.InvalidHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_header_value_injection:
    { HttpClient.encode(HttpClient.Request{"GET", "https://example.com/", [http_header("X", "ok\r\nInjected: bad")], Nil{}})
        == Fail{HttpClient.InvalidHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_header_nul:
    { HttpClient.encode(HttpClient.Request{"GET", "https://example.com/", [http_header("X", "a\u{0000}b")], Nil{}})
        == Fail{HttpClient.InvalidHeader{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_unsupported_method:
    { HttpClient.encode(HttpClient.Request{"CONNECT", "https://example.com/", Nil{}, Nil{}})
        == Fail{HttpClient.InvalidMethod{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_body_non_octet:
    { HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", Nil{}, [256]})
        == Fail{HttpClient.InvalidByte{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

# Universal body conservation: independent list length fixes Content-Length.
law http_encode_arbitrary_body:
    for +body: List<&2, U32>
    for valid: {HttpClient.valid_bytes(body) == True{} : Bool} {
        HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", Nil{}, body})
        == Done{http_append(HttpClient.utf8(
            "POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: "
            ++ Nat.show(http_length(body))
            ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)}
        : Result<&2, &2, HttpClient.Error, List<&2, U32>>
    }

# Fragmentation invariance includes splits within CRLF, UTF-8, chunk lengths,
# chunk data and trailers. Includes malformed inputs, EOF and leftover bytes.
law http_decode_partition_invariant:
    for +method: String
    for +limits: HttpClient.Limits
    for +left: List<&2, U32>
    for +right: List<&2, U32>
    for +eof: Bool {
        HttpClient.decode_parts(method, limits, [left, right], eof)
        == HttpClient.decode(method, limits, http_append(left, right), eof) : HttpClient.Decode
    }

law http_decode_empty_fragments:
    for +method: String
    for +limits: HttpClient.Limits
    for +bytes: List<&2, U32>
    for +eof: Bool {
        HttpClient.decode_parts(method, limits, [Nil{}, bytes, Nil{}], eof)
        == HttpClient.decode(method, limits, bytes, eof) : HttpClient.Decode
    }

# A broad binary response law (up to 100 bytes) guards against treating HTTP
# bodies as text, truncating at NUL, or losing bytes in length-delimited bodies.
# Deferred universal law; keep this contract when adding the general body proof.
# law http_decode_arbitrary_binary_body:
#   for +body: List<&2, U32>
#   for valid: {HttpClient.valid_bytes(body) == True{} : Bool}
#   for within: {Nat.is_le(http_length(body), 100n) == True{} : Bool} {
#     HttpClient.decode("GET", http_limits(), http_append(HttpClient.utf8(
#       "HTTP/1.1 200 OK\r\nContent-Length: " ++ Nat.show(http_length(body))
#       ++ "\r\n\r\n"), body), False{})
#     == HttpClient.Parsed{HttpClient.Response{200,
#       [http_header("Content-Length", Nat.show(http_length(body)))], body, Nil{}}, Nil{}}
#     : HttpClient.Decode
#   }

# ============================================================
# HTTP: Response framing and metadata
# ============================================================

law http_content_length:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nabc", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "3")], HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_preserve_remainder:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nabcNEXT", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "3")], HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_partial_body:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nab", False{})
        == HttpClient.NeedMore{} : HttpClient.Decode }

law http_truncated_body:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nab", True{})
        == HttpClient.Rejected{HttpClient.UnexpectedEof{}} : HttpClient.Decode }

law http_incomplete_headers:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 0\r", False{})
        == HttpClient.NeedMore{} : HttpClient.Decode }

law http_empty_eof:
    { http_decode("GET", "", True{})
        == HttpClient.Rejected{HttpClient.UnexpectedEof{}} : HttpClient.Decode }

law http_close_delimited_waits:
    { http_decode("GET", "HTTP/1.1 200 OK\r\n\r\nabc", False{})
        == HttpClient.NeedMore{} : HttpClient.Decode }

law http_close_delimited_eof:
    { http_decode("GET", "HTTP/1.1 200 OK\r\n\r\nabc", True{})
        == HttpClient.Parsed{HttpClient.Response{200, Nil{}, HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_head_ignores_length:
    { http_decode("HEAD", "HTTP/1.1 200 OK\r\nContent-Length: 9999999\r\n\r\nNEXT", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "9999999")], HttpClient.utf8(""), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_no_content:
    { http_decode("GET", "HTTP/1.1 204 No Content\r\n\r\nNEXT", False{})
        == HttpClient.Parsed{HttpClient.Response{204, Nil{}, HttpClient.utf8(""), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_not_modified:
    { http_decode("GET", "HTTP/1.1 304 Not Modified\r\nContent-Length: 100\r\n\r\nNEXT", False{})
        == HttpClient.Parsed{HttpClient.Response{304, [http_header("Content-Length", "100")], HttpClient.utf8(""), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_reset_content_still_framed:
    { http_decode("GET", "HTTP/1.1 205 Reset Content\r\nContent-Length: 0\r\n\r\nNEXT", False{})
        == HttpClient.Parsed{HttpClient.Response{205, [http_header("Content-Length", "0")], HttpClient.utf8(""), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_skip_interim:
    { http_decode("GET", "HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 103 Early Hints\r\n\r\nHTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nabc", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "3")], HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_interim_without_final:
    { http_decode("GET", "HTTP/1.1 100 Continue\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.UnexpectedEof{}} : HttpClient.Decode }

law http_status_301_is_response:
    { http_decode("GET", "HTTP/1.1 301 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{301, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_400_is_response:
    { http_decode("GET", "HTTP/1.1 400 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{400, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_401_is_response:
    { http_decode("GET", "HTTP/1.1 401 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{401, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_403_is_response:
    { http_decode("GET", "HTTP/1.1 403 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{403, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_404_is_response:
    { http_decode("GET", "HTTP/1.1 404 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{404, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_429_is_response:
    { http_decode("GET", "HTTP/1.1 429 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{429, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_500_is_response:
    { http_decode("GET", "HTTP/1.1 500 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{500, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_status_503_is_response:
    { http_decode("GET", "HTTP/1.1 503 Status\r\nContent-Length: 3\r\n\r\nerr", False{})
        == HttpClient.Parsed{HttpClient.Response{503, [http_header("Content-Length", "3")], HttpClient.utf8("err"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_header_value_trimming:
    { http_decode("GET", "HTTP/1.1 200 OK\r\ncOnTeNt-LeNgTh:\t3 \t\r\nSet-Cookie: a=1\r\nSet-Cookie: b=2\r\n\r\nabc", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("cOnTeNt-LeNgTh", "3"), http_header("Set-Cookie", "a=1"), http_header("Set-Cookie", "b=2")], HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

# ============================================================
# HTTP: Chunked coding
# ============================================================

# Chunked coding: payload only, extensions ignored, trailers kept separate.

law http_chunked:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\nab\r\n1\r\nc\r\n0\r\n\r\nNEXT", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Transfer-Encoding", "chunked")], HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_chunk_extensions_trailers:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3;foo=\"bar\"\r\nabc\r\n0\r\nX-End: yes\r\nX-End: again\r\n\r\n", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Transfer-Encoding", "chunked")], HttpClient.utf8("abc"), [http_header("X-End", "yes"), http_header("X-End", "again")]}, HttpClient.utf8("")} : HttpClient.Decode }

law http_uppercase_hex_chunk:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nA\r\n0123456789\r\n0\r\n\r\n", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Transfer-Encoding", "chunked")], HttpClient.utf8("0123456789"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_chunk_truncation:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nab", True{})
        == HttpClient.Rejected{HttpClient.UnexpectedEof{}} : HttpClient.Decode }

law http_chunk_incomplete:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nab", False{})
        == HttpClient.NeedMore{} : HttpClient.Decode }

law http_missing_final_chunk:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nabc\r\n", True{})
        == HttpClient.Rejected{HttpClient.UnexpectedEof{}} : HttpClient.Decode }

law http_unfinished_trailers:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\nX-End: yes\r\n", True{})
        == HttpClient.Rejected{HttpClient.UnexpectedEof{}} : HttpClient.Decode }

# ============================================================
# HTTP: Invalid and unsupported responses
# ============================================================

# Reject ambiguity, invalid syntax, unsupported features and length overflow.

law http_reject_duplicate_equal_length:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3\r\nContent-Length: 3\r\n\r\nabc", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_conflicting_length:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3\r\nContent-Length: 4\r\n\r\nabc", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_length_list:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 3, 3\r\n\r\nabc", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_te_and_cl:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nContent-Length: 3\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_negative_length:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: -1\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_huge_length:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nContent-Length: 18446744073709551616\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_reject_huge_chunk:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n10000000000000000\r\n", True{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_reject_bad_transfer_coding:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: gzip, chunked\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.UnsupportedTransferEncoding{}} : HttpClient.Decode }

law http_reject_repeated_chunked:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked, chunked\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_bad_chunk_size:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nZ\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_bad_chunk_terminator:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n1\r\naXX", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_forbidden_trailer:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\nContent-Length: 0\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_bare_lf:
    { http_decode("GET", "HTTP/1.1 200 OK\nContent-Length: 0\n\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidFraming{}} : HttpClient.Decode }

law http_reject_obsolete_fold:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nX: a\r\n b\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidHeader{}} : HttpClient.Decode }

law http_reject_space_before_colon:
    { http_decode("GET", "HTTP/1.1 200 OK\r\nX : a\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidHeader{}} : HttpClient.Decode }

law http_reject_invalid_status:
    { http_decode("GET", "HTTP/1.1 20 OK\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidStatus{}} : HttpClient.Decode }

law http_reject_invalid_version:
    { http_decode("GET", "HTTP/2.0 200 OK\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.InvalidVersion{}} : HttpClient.Decode }

law http_accept_http_10_response:
    { http_decode("GET", "HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nok", False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "2")], HttpClient.utf8("ok"), Nil{}}, Nil{}} : HttpClient.Decode }

law http_reject_upgrade:
    { http_decode("GET", "HTTP/1.1 101 Switching Protocols\r\n\r\n", True{})
        == HttpClient.Rejected{HttpClient.UnsupportedUpgrade{}} : HttpClient.Decode }

# ============================================================
# HTTP: Resource limit boundaries
# ============================================================

# Exact limit boundaries. All counts use bytes, never character counts.

law http_body_limit_exact:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 3, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nabc"), False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "3")], HttpClient.utf8("abc"), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_body_limit_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 3, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\nabcd"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_chunk_body_limit_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 3, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\nab\r\n2\r\ncd\r\n0\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_close_body_limit_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 3, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\n\r\nabcd"), True{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_header_bytes_exact:
    { HttpClient.decode("GET", HttpClient.Limits{38, 100, 1048576, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"), False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "0")], HttpClient.utf8(""), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_header_bytes_over:
    { HttpClient.decode("GET", HttpClient.Limits{37, 100, 1048576, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_wire_bytes_exact:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 38}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"), False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "0")], HttpClient.utf8(""), Nil{}}, HttpClient.utf8("")} : HttpClient.Decode }

law http_wire_bytes_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 37}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

# Bytes after the first complete response are returned untouched and do not
# consume that response's wire budget.
law http_wire_bytes_excludes_remainder:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 38}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\nNEXT"), False{})
        == HttpClient.Parsed{HttpClient.Response{200, [http_header("Content-Length", "0")], HttpClient.utf8(""), Nil{}}, HttpClient.utf8("NEXT")} : HttpClient.Decode }

law http_header_count_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 0, 1048576, 8192, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_interim_count_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 8192, 50, 0, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_trailer_count_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 8192, 0, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\nX: y\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_trailer_bytes_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 7, 50, 8, 1024, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\nX: y\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

law http_chunk_line_bytes_over:
    { HttpClient.decode("GET", HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 3, 2097152}, HttpClient.utf8("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0;foo=bar\r\n\r\n"), False{})
        == HttpClient.Rejected{HttpClient.LimitExceeded{}} : HttpClient.Decode }

# ============================================================
# HTTP: Short writes
# ============================================================

# Short writes consume exactly the acknowledged prefix.

law http_partial_write:
    { HttpClient.drop_written([0, 255, 1, 2], 2)
        == Done{[1, 2]} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_full_write:
    { HttpClient.drop_written([0, 255], 2)
        == Done{Nil{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_empty_write:
    { HttpClient.drop_written(Nil{}, 0)
        == Done{Nil{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_zero_write_progress:
    { HttpClient.drop_written([1], 0)
        == Fail{HttpClient.NoProgress{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

law http_write_overreport:
    { HttpClient.drop_written([1], 2)
        == Fail{HttpClient.InvalidFraming{}} : Result<&2, &2, HttpClient.Error, List<&2, U32>> }

# ============================================================
# HTTP: JSON integration
# ============================================================

# JSON integration uses the real local parser, keeps number lexemes and handles
# non-ASCII text. Read_json is explicit and need not require a Content-Type.
# Deferred universal law; requires a UTF-8 encode/decode inverse proof.
# law http_json_roundtrip:
#   for +value: Json.Value
#   for valid: {http_unicode_string(Json.stringify(value)) == True{} : Bool} {
#     HttpClient.read_json(HttpClient.Response{200, Nil{}, HttpClient.utf8(Json.stringify(value)), Nil{}})
#     == Done{value} : Result<&1, &1, HttpClient.Error, Json.Value>
#   }

law http_json_error_response:
    { HttpClient.read_json(HttpClient.Response{400, Nil{}, HttpClient.utf8("null"), Nil{}})
        == Done{Json.Null{}} : Result<&1, &1, HttpClient.Error, Json.Value> }

law http_json_empty:
    { HttpClient.read_json(HttpClient.Response{204, Nil{}, HttpClient.utf8(""), Nil{}})
        == Fail{HttpClient.InvalidJson{}} : Result<&1, &1, HttpClient.Error, Json.Value> }

law http_json_trailing:
    { HttpClient.read_json(HttpClient.Response{200, Nil{}, HttpClient.utf8("{}oops"), Nil{}})
        == Fail{HttpClient.InvalidJson{}} : Result<&1, &1, HttpClient.Error, Json.Value> }

law http_json_compressed:
    { HttpClient.read_json(HttpClient.Response{200, [http_header("Content-Encoding", "gzip")], HttpClient.utf8("{}"), Nil{}})
        == Fail{HttpClient.UnsupportedContentEncoding{}} : Result<&1, &1, HttpClient.Error, Json.Value> }

law http_json_invalid_utf8:
    { HttpClient.read_json(HttpClient.Response{200, Nil{}, [255], Nil{}})
        == Fail{HttpClient.InvalidUtf8{}} : Result<&1, &1, HttpClient.Error, Json.Value> }

# ============================================================
# HTTP: GPU codec parity and batch semantics
# ============================================================

# Required implementation and exact Work/Outcome/Batch types: libs/HTTPClient.bend.
# These equalities establish behavior, not GPU execution or speed. The native
# dispatch and hardware checks in HTTP-T14 below are also required.

law http_gpu_encode_matches_cpu:
    for +request: HttpClient.Request {
        HttpClient.encode_gpu(request) == HttpClient.encode(request)
        : Result<&2, &2, HttpClient.Error, List<&2, U32>>
    }

law http_gpu_decode_matches_cpu:
    for +method: String
    for +limits: HttpClient.Limits
    for +bytes: List<&2, U32>
    for +eof: Bool {
        HttpClient.decode_gpu(method, limits, bytes, eof)
        == HttpClient.decode(method, limits, bytes, eof) : HttpClient.Decode
    }

law http_gpu_json_matches_cpu:
    for +response: HttpClient.Response {
        HttpClient.read_json_gpu(response) == HttpClient.read_json(response)
        : Result<&1, &1, HttpClient.Error, Json.Value>
    }

law http_work_encode_uses_codec:
    for +request: HttpClient.Request {
        HttpClient.run_work(HttpClient.EncodeWork{request})
        == HttpClient.Encoded{HttpClient.encode(request)} : HttpClient.Outcome
    }

law http_work_decode_uses_codec:
    for +method: String
    for +limits: HttpClient.Limits
    for +bytes: List<&2, U32>
    for +eof: Bool {
        HttpClient.run_work(HttpClient.DecodeWork{method, limits, bytes, eof})
        == HttpClient.Decoded{HttpClient.decode(method, limits, bytes, eof)} : HttpClient.Outcome
    }

law http_batch_leaf:
    for +work: HttpClient.Work {
        HttpClient.run_batch(HttpClient.Leaf{work})
        == HttpClient.LeafResult{HttpClient.run_work(work)} : HttpClient.BatchResult
    }

law http_batch_fork:
    for +left: HttpClient.Batch
    for +right: HttpClient.Batch {
        HttpClient.run_batch(HttpClient.Fork{left, right})
        == HttpClient.ForkResult{HttpClient.run_batch(left), HttpClient.run_batch(right)}
        : HttpClient.BatchResult
    }

law http_gpu_batch_matches_cpu:
    for +batch: HttpClient.Batch {
        HttpClient.run_batch_gpu(batch) == HttpClient.run_batch(batch) : HttpClient.BatchResult
    }

law http_gpu_many_matches_cpu:
    for +jobs: List<&2, HttpClient.Work> {
        HttpClient.run_many_gpu(jobs) == HttpClient.run_many(jobs)
        : Maybe<&2, HttpClient.BatchResult>
    }

law http_empty_batch_builder:
    { HttpClient.batch_from_list(Nil{}) == None{} : Maybe<&2, HttpClient.Batch> }

law http_singleton_batch_builder:
    for +work: HttpClient.Work {
        HttpClient.batch_from_list([work]) == Some{HttpClient.Leaf{work}}
        : Maybe<&2, HttpClient.Batch>
    }

law http_empty_gpu_many:
    { HttpClient.run_many_gpu(Nil{}) == None{} : Maybe<&2, HttpClient.BatchResult> }

law http_singleton_gpu_many:
    for +work: HttpClient.Work {
        HttpClient.run_many_gpu([work]) == Some{HttpClient.LeafResult{HttpClient.run_work(work)}}
        : Maybe<&2, HttpClient.BatchResult>
    }

# The sequential oracle calls the codec directly, not run_work/run_many.
# This prevents two identically wrong batch implementations satisfying parity.
def http_expected_outcome(work: HttpClient.Work) -> HttpClient.Outcome:
    match work:
        case HttpClient.EncodeWork{request}: HttpClient.Encoded{HttpClient.encode(request)}
        case HttpClient.DecodeWork{method, limits, bytes, eof}:
            HttpClient.Decoded{HttpClient.decode(method, limits, bytes, eof)}

def http_expected_outcomes(jobs: List<&2, HttpClient.Work>) -> List<&2, HttpClient.Outcome>:
    match jobs:
        case Nil{}: Nil{}
        case Con{work, rest}:
            http_expected_outcome(work) <> http_expected_outcomes(rest)

def http_optional_outcomes(result: Maybe<&2, HttpClient.BatchResult>) -> List<&2, HttpClient.Outcome>:
    match result:
        case None{}: Nil{}
        case Some{tree}: HttpClient.flatten_results(tree)

law http_gpu_batch_preserves_order_and_errors:
    for +jobs: List<&2, HttpClient.Work> {
        http_optional_outcomes(HttpClient.run_many_gpu(jobs))
        == http_expected_outcomes(jobs) : List<&2, HttpClient.Outcome>
    }

law http_flatten_leaf:
    for +outcome: HttpClient.Outcome {
        HttpClient.flatten_results(HttpClient.LeafResult{outcome}) == [outcome]
        : List<&2, HttpClient.Outcome>
    }

def http_append_outcomes(xs: List<&2, HttpClient.Outcome>,
                         ys: List<&2, HttpClient.Outcome>) -> List<&2, HttpClient.Outcome>:
    match xs:
        case Nil{}: ys
        case Con{outcome, rest}: outcome <> http_append_outcomes(rest, ys)

law http_flatten_fork:
    for +left: HttpClient.BatchResult
    for +right: HttpClient.BatchResult {
        HttpClient.flatten_results(HttpClient.ForkResult{left, right})
        == http_append_outcomes(HttpClient.flatten_results(left), HttpClient.flatten_results(right))
        : List<&2, HttpClient.Outcome>
    }

# ============================================================
# HTTP: Transport and resource obligations
# ============================================================

# These are mandatory acceptance conditions, not claims proved by the pure
# equalities above. Implement a scripted transport harness and local TLS server.
# Keep the production IO loop tied to the same codec and short-write helpers.
#
# HTTP-T01 Verified HTTPS
#
# Select TLS for https, send SNI for the requested DNS host, check the chain
# and hostname, reject expired/untrusted/wrong-host certs. TLS failure emits
# no HTTP request bytes and never reconnects over plaintext. A trusted local
# certificate succeeds; plain http selects TCP explicitly.
#
# HTTP-T02 Wire fidelity
#
# Capture exact POST/PUT/PATCH/GET/HEAD/DELETE/OPTIONS request bytes at a
# loopback server. Match encode output, including Unicode Content-Length,
# binary NUL/255, authorization value, query order and path. No built-in
# credentials, provider defaults, hidden body edits or secret logs.
#
# HTTP-T03 Short writes
#
# Script acknowledgments 1,2,remaining and verify every byte appears exactly
# once and in order. Zero progress/overreport terminates with the specified
# error; never spin or replay an already written prefix.
#
# HTTP-T04 Read fragmentation
#
# Split each representative response at every byte boundary, including chunk
# CRLF and UTF-8 sequences; compare decode outcomes. Exercise multiple
# responses in one read and prove no leftover is body data. Production stops
# at the first final response and closes this one-shot socket.
#
# HTTP-T05 Cleanup
#
# Count acquired/released handles. Exactly one close for each acquired handle
# on success, malformed HTTP, limits, failed writes/reads, TLS errors and
# timeouts; no use after close or leak after partial initialization. If TLS
# upgrade transfers ownership, make that transfer explicit in the trace.
#
# HTTP-T06 Timeouts
#
# Stalled DNS/connect/TLS/write/read and a slow trickle of single bytes must
# respect the total deadline as well as stage deadlines. Monotonic time is
# required; counters alone do not bound a blocking syscall. Zero/invalid
# budgets fail before socket acquisition. Fuel exhaustion is typed.
#
# HTTP-T07 EOF integrity
#
# Reset, timeout and unclean TLS shutdown are errors. Never turn them into
# clean EOF to accept a close-delimited partial response. Length-
# delimited/chunked completion needs no additional EOF read; truncation before
# those boundaries is an error. Preserve provider error bodies intact.
#
# HTTP-T08 Resource bounds
#
# Bound request bytes before write and response allocation before buffering.
# Include interim heads, chunk extensions, trailers and decoded payload in the
# applicable counters; checked arithmetic cannot wrap. Excessive small chunks
# hit wire/step/deadline limits even if payload is small.
#
# HTTP-T09 Redirect/retry policy
#
# 301/302/303/307/308, 429/500/503 and connection loss after partial POST are
# returned without additional requests. Never send credentials to a Location
# target automatically, downgrade TLS, or replay POST.
#
# HTTP-T10 JSON
#
# Send the local serializer's UTF-8 bytes, preserve Content-Type, and parse
# only a completed decoded body with validated UTF-8. Keep the raw
# response/status/headers available alongside an optional JSON parse result.
# No empty-body-to-null conversion; no attempt to parse undecoded gzip/chunks.
#
# HTTP-T11 Protocol subset
#
# Support HTTP/1.1; if ALPN is used, offer only http/1.1. Reject
# h2/upgrade/tunnel results rather than misparse them as HTTP/1.1. Reject
# unsupported transfer-coding stacks; keep supported trailers separate.
#
# HTTP-T12 Concurrency
#
# Run independent loopback requests via IO.fork/IO.join. Responses remain
# associated with their requests; no shared headers, buffers, socket handles
# or credentials. Cancellation/failure closes only owned handles.
#
# HTTP-T13 Proof linkage
#
# All universal laws and fixtures must use exported production functions. The
# IO adapter uses that same codec. No mock-only implementation, laws bypass,
# unsafe proof, constant result or weakened limit. Document which behavior
# belongs to trusted wire/system effects and which properties have actual Bend
# proofs. Live credentials are not required.
#
# HTTP-T14 GPU execution
#
# Inspect real ! dispatch in the native codec, exercise GPU-off, GPU-on when
# hardware exists, and CPU fallback. Compare exact outputs and errors for
# mixed/odd/empty batches, large bodies, invalid messages and partial inputs.
# Keep one socket/parser state per request outside the device. Record
# hardware/runtime, memory bounds and throughput; CPU/GPU equality alone
# neither proves GPU execution nor guarantees a speedup for small workloads.
