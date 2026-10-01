import Base
import ./JSON.bend as Json
import 0xcfc8be7b076f41f95c8e118383892d55/encoding.bend as Encoding
import 0x49814d83de8f70993a43e1002be29ecd/bytes.bend as Bytes
import 0x1f2d80f53f971b16c6de6a65cb1918ae/url.bend as Url
import ./wire/wire.bend as Wire
import ./wire/dns.bend as Dns

# HTTP/1.1 client and codec. Implements the supported RFC 9112 framing subset
# and RFC 9110 request/response semantics; see README.md for the scope.

type Header is Data:
    Header{name: String, value: List<&2, U32>}

type Target is Data:
    Target{tls: Bool, host: String, port: U32, authority: String, resource: String}

type Request is Data:
    Request{method: String, url: String, headers: List<&2, Header>, body: List<&2, U32>}

type Response is Data:
    Response{status: U32, headers: List<&2, Header>, body: List<&2, U32>, trailers: List<&2, Header>}

type Limits is Data:
    Limits{header_bytes: U32, header_count: U32, body_bytes: U32, trailer_bytes: U32, trailer_count: U32, interim_count: U32, chunk_line_bytes: U32, wire_bytes: U32}

type Error is Data:
    InvalidUrl{}
    UnsupportedScheme{}
    UnsupportedHost{}
    InvalidMethod{}
    InvalidHeader{}
    ReservedHeader{}
    InvalidByte{}
    InvalidStatus{}
    InvalidVersion{}
    InvalidFraming{}
    UnsupportedTransferEncoding{}
    UnexpectedEof{}
    LimitExceeded{}
    UnsupportedUpgrade{}
    NoProgress{}
    InvalidJson{}
    UnsupportedContentEncoding{}
    InvalidUtf8{}
    Configuration{}
    Connection{}
    Tls{}
    Io{}
    Timeout{}

type Decode is Data:
    NeedMore{}
    Parsed{response: Response, rest: List<&2, U32>}
    Rejected{error: Error}

type Cut is Data:
    CutFound{before: String, after: String}
    CutMore{}
    CutBad{}

type StatusLine is Data:
    StatusOk{status: U32}
    StatusBad{error: Error}

type HeadScan is Data:
    HeadMore{}
    HeadBad{error: Error}
    HeadDone{status: U32, headers: List<&2, Header>, rest: String, size: Nat}

type HeadStep is Data:
    HeadContinue{rest: String, status: StatusLine, headers: List<&2, Header>, size: Nat, count: Nat}
    HeadStepMore{}
    HeadStepBad{error: Error}
    HeadStepDone{status: U32, headers: List<&2, Header>, rest: String, size: Nat}

type Options is Data:
    Options{limits: Limits, connect_ms: U32, read_ms: U32, write_ms: U32, total_ms: U32, fuel: U32}

type Work is Data:
    EncodeWork{request: Request}
    DecodeWork{method: String, limits: Limits, bytes: List<&2, U32>, eof: Bool}

type Outcome is Data:
    Encoded{result: Result<&2, &2, Error, List<&2, U32>>}
    Decoded{result: Decode}

type Batch is Data:
    Leaf{work: Work}
    Fork{left: Batch, right: Batch}

type BatchResult is Data:
    LeafResult{outcome: Outcome}
    ForkResult{left: BatchResult, right: BatchResult}

def append_bytes(xs: List<&2, U32>, ys: List<&2, U32>) -> List<&2, U32>:
    match xs:
        case Nil{}: ys
        case h <> t: h <> append_bytes(t, ys)

def append_headers(xs: List<&2, Header>, ys: List<&2, Header>) -> List<&2, Header>:
    match xs:
        case Nil{}: ys
        case h <> t: h <> append_headers(t, ys)

def utf8_char_bmp(+c: U32, bmp: Bool) -> List<&2, U32>:
    match bmp:
        case True{}:
            ((224 + U32.shrn(c, 12n) : U32)) <>
            ((128 + U32.and(U32.shrn(c, 6n), 63) : U32)) <>
            ((128 + U32.and(c, 63) : U32)) <> Nil{}
        case False{}:
            ((240 + U32.shrn(c, 18n) : U32)) <>
            ((128 + U32.and(U32.shrn(c, 12n), 63) : U32)) <>
            ((128 + U32.and(U32.shrn(c, 6n), 63) : U32)) <>
            ((128 + U32.and(c, 63) : U32)) <> Nil{}

def utf8_char_short(+c: U32, short: Bool) -> List<&2, U32>:
    match short:
        case True{}:
            ((192 + U32.shrn(c, 6n) : U32)) <>
            ((128 + U32.and(c, 63) : U32)) <> Nil{}
        case False{}: utf8_char_bmp(c, U32.is_lt(c, 65536))

def utf8_char_ascii(+c: U32, ascii: Bool) -> List<&2, U32>:
    match ascii:
        case True{}: [c]
        case False{}: utf8_char_short(c, U32.is_lt(c, 2048))

def utf8_scalar(+c: U32, scalar: Bool) -> U32:
    match scalar:
        case True{}: c
        case False{}: 65533

def utf8_char(+c: U32) -> List<&2, U32>:
    +scalar = utf8_scalar(c, U32.is_le(c, 1114111))
    utf8_char_ascii(scalar, U32.is_lt(scalar, 128))

def utf8(+text: String) -> List<&2, U32>:
    match text:
        case SNil{}: Nil{}
        case SCon{Chr{+c}, rest}: append_bytes(utf8_char(c), utf8(rest))

def valid_byte(n: U32) -> Bool:
    U32.is_lt(n, 256)

def valid_byte_tail(valid: Bool, rest: Bool) -> Bool:
    match valid rest:
        case True{} True{}: True{}
        case _ _: False{}

def valid_bytes(bytes: List<&2, U32>) -> Bool:
    match bytes:
        case Nil{}: True{}
        case h <> t: valid_byte_tail(valid_byte(h), valid_bytes(t))

def byte_lists_equal(left: List<&2, U32>, right: List<&2, U32>) -> Bool:
    match left right:
        case Nil{} Nil{}: True{}
        case h <> lt k <> rt: Bool.and(U32.is_eq(h, k), byte_lists_equal(lt, rt))
        case _ _: False{}

def lower(s: String) -> String:
    String.to_lower(s)

def is_hex_digit(c: Char) -> Bool:
    match c:
        case '0': True{}
        case '1': True{}
        case '2': True{}
        case '3': True{}
        case '4': True{}
        case '5': True{}
        case '6': True{}
        case '7': True{}
        case '8': True{}
        case '9': True{}
        case 'a': True{}
        case 'b': True{}
        case 'c': True{}
        case 'd': True{}
        case 'e': True{}
        case 'f': True{}
        case 'A': True{}
        case 'B': True{}
        case 'C': True{}
        case 'D': True{}
        case 'E': True{}
        case 'F': True{}
        case _: False{}

def valid_escape_digits_checked(hi: Bool, lo: Bool, tail_valid: Bool) -> Bool:
    match hi lo tail_valid:
        case True{} True{} True{}: True{}
        case _ _ _: False{}

def valid_escape_digits(hi: Char, lo: Char, tail_valid: Bool) -> Bool:
    valid_escape_digits_checked(is_hex_digit(hi), is_hex_digit(lo), tail_valid)

def valid_percent_escapes(url: String) -> Bool:
    match url:
        case SNil{}: True{}
        case SCon{'%', rest}:
            match rest:
                case SCon{hi, SCon{lo, tail}}: valid_escape_digits(hi, lo, valid_percent_escapes(tail))
                case _: False{}
        case SCon{_, rest}: valid_percent_escapes(rest)

def valid_url_char_class(control_or_space: Bool, delete: Bool) -> Bool:
    match control_or_space delete:
        case True{} _: False{}
        case _ True{}: False{}
        case _ _: True{}

def valid_url_char(+n: U32) -> Bool:
    valid_url_char_class(U32.is_lt(n, 33), U32.is_eq(n, 127))

def valid_url_chars(url: String) -> Bool:
    match url:
        case SNil{}: True{}
        case SCon{h, t}: Bool.and(valid_url_char(Char.to_u32(h)), valid_url_chars(t))

def valid_host_char(+c: U32) -> Bool:
    Bool.or(Bool.and(U32.is_le(48, c), U32.is_le(c, 57)),
        Bool.or(Bool.and(U32.is_le(65, c), U32.is_le(c, 90)),
            Bool.or(Bool.and(U32.is_le(97, c), U32.is_le(c, 122)),
                Bool.or(U32.is_eq(c, 45), U32.is_eq(c, 46)))))

def valid_host_tail(host: String) -> Bool:
    match host:
        case SNil{}: True{}
        case SCon{h, t}: Bool.and(valid_host_char(Char.to_u32(h)), valid_host_tail(t))

def valid_host_name(host: String) -> Bool:
    match host:
        case SNil{}: False{}
        case SCon{h, t}: Bool.and(valid_host_char(Char.to_u32(h)), valid_host_tail(t))

def url_authority(+text: String) -> String:
    match text:
        case SNil{}: SNil{}
        case SCon{'/', _}: SNil{}
        case SCon{'?', _}: SNil{}
        case SCon{'#', _}: SNil{}
        case SCon{h, t}: SCon{h, url_authority(t)}

def url_empty_port_scheme(url: String, prefix_len: Nat, matches: Bool) -> Bool:
    match matches:
        case False{}: False{}
        case True{}: String.ends_with(url_authority(String.drop(url, prefix_len)), ":")

def url_has_empty_port(+url: String) -> Bool:
    Bool.or(url_empty_port_scheme(url, 7n, String.starts_with(url, "http://")),
        url_empty_port_scheme(url, 8n, String.starts_with(url, "https://")))

def valid_url_form(+url: String) -> Bool:
    Bool.and(valid_url_chars(url), valid_percent_escapes(url))

def parse_url_error(url: String,
                    has_scheme: Bool,
                    http: Bool,
                    https: Bool) -> Result<&2, &2, Error, Target>:
    match has_scheme http:
        case False{} _: Fail{InvalidUrl{}}
        case True{} True{}: Fail{InvalidUrl{}}
        case True{} False{}:
            match https:
                case True{}: Fail{InvalidUrl{}}
                case False{}: Fail{UnsupportedScheme{}}

def parse_url_target_error(is_ipv6: Bool) -> Result<&2, &2, Error, Target>:
    match is_ipv6:
        case True{}: Fail{UnsupportedHost{}}
        case False{}: Fail{InvalidUrl{}}

def parse_url_target(+absolute: Url.Abs,
                     scheme: String,
                     +host: String,
                     port: U32,
                     resource: String,
                     valid: Bool) -> Result<&2, &2, Error, Target>:
    match valid:
        case False{}:
            parse_url_target_error(String.contains(host, ":"))
        case True{}:
            Done{Target{String.eq(scheme, "https"), host, port, Url.host_field(absolute), resource}}

def parse_url_result(+url: String, parsed: Maybe<&2, Url.Abs>) -> Result<&2, &2, Error, Target>:
    match parsed:
        case None{}:
            parse_url_error(url, String.contains(url, "://"), String.starts_with(url, "http://"), String.starts_with(url, "https://"))
        case Some{+absolute}:
            Url.Abs{scheme, host, port, resource} = absolute
            parse_url_target(absolute, scheme, host, port, resource,
                Bool.and(Bool.not(String.contains(host, ":")),
                Bool.and(valid_host_name(host), Bool.and(U32.is_lt(0, port), Bool.and(valid_url_form(url), Bool.not(url_has_empty_port(url)))))))

def parse_url(+url: String) -> Result<&2, &2, Error, Target>:
    parse_url_result(url, Url.absolute(url))

def field_values(+name: String, headers: List<&2, Header>) -> List<&2, List<&2, U32>>:
    match headers:
        case Nil{}: Nil{}
        case Header{+field, value} <> rest:
            +tail = field_values(name, rest)
            Bool.pick(List<&2, List<&2, U32>>, String.eq(String.to_lower(field), String.to_lower(name)), value <> tail, tail)

def valid_method(method: String) -> Bool:
    match method:
        case "GET": True{}
        case "HEAD": True{}
        case "POST": True{}
        case "PUT": True{}
        case "PATCH": True{}
        case "DELETE": True{}
        case "OPTIONS": True{}
        case _: False{}

def method_has_length(method: String) -> Bool:
    match method:
        case "POST": True{}
        case "PUT": True{}
        case "PATCH": True{}
        case _: False{}

def token_char(+n: U32) -> Bool:
    Bool.or(Bool.and(U32.is_le(48, n), U32.is_le(n, 57)),
        Bool.or(Bool.and(U32.is_le(65, n), U32.is_le(n, 90)),
            Bool.or(Bool.and(U32.is_le(97, n), U32.is_le(n, 122)),
                Bool.or(U32.is_eq(n, 33), Bool.or(U32.is_eq(n, 35), Bool.or(U32.is_eq(n, 36),
                Bool.or(U32.is_eq(n, 37), Bool.or(U32.is_eq(n, 38), Bool.or(U32.is_eq(n, 39),
                Bool.or(U32.is_eq(n, 42), Bool.or(U32.is_eq(n, 43), Bool.or(U32.is_eq(n, 45),
                Bool.or(U32.is_eq(n, 46), Bool.or(U32.is_eq(n, 94), Bool.or(U32.is_eq(n, 95),
                Bool.or(U32.is_eq(n, 96), Bool.or(U32.is_eq(n, 124), U32.is_eq(n, 126))))))))))))))))))

def token_tail(chars: List<&2, Char>) -> Bool:
    match chars:
        case Nil{}: True{}
        case h <> t: Bool.and(token_char(Char.to_u32(h)), token_tail(t))

def valid_header_name_chars(chars: List<&2, Char>) -> Bool:
    match chars:
        case Nil{}: False{}
        case h <> t: Bool.and(token_char(Char.to_u32(h)), token_tail(t))

def valid_header_name(name: String) -> Bool:
    valid_header_name_chars(String.to_list(name))

def header_byte_allowed(n: U32, tab: Bool, control: Bool, delete: Bool, octet: Bool) -> Bool:
    match tab control delete octet:
        case _ _ True{} _: False{}
        case _ _ _ False{}: False{}
        case True{} _ _ True{}: True{}
        case False{} True{} False{} True{}: False{}
        case False{} False{} False{} True{}: True{}
        case _ _ _ _: False{}

def valid_header_value_byte(+n: U32) -> Bool:
    header_byte_allowed(n, U32.is_eq(n, 9), U32.is_lt(n, 32), U32.is_eq(n, 127), U32.is_lt(n, 256))

def valid_header_value_bytes(bytes: List<&2, U32>) -> Bool:
    match bytes:
        case Nil{}: True{}
        case h <> t: Bool.and(valid_header_value_byte(h), valid_header_value_bytes(t))

def reserved_header(+name: String) -> Bool:
    +lowered = String.to_lower(name)
    Bool.or(String.eq(lowered, "host"), Bool.or(String.eq(lowered, "content-length"),
        Bool.or(String.eq(lowered, "transfer-encoding"), Bool.or(String.eq(lowered, "connection"),
        Bool.or(String.eq(lowered, "accept-encoding"), Bool.or(String.eq(lowered, "expect"),
        Bool.or(String.eq(lowered, "upgrade"), String.eq(lowered, "trailer"))))))))

def validate_header_field_flags(name_ok: Bool,
                                reserved: Bool,
                                value_ok: Bool) -> Result<&1, &1, Error, Unit>:
    match name_ok reserved value_ok:
        case False{} _ _: Fail{InvalidHeader{}}
        case True{} True{} _: Fail{ReservedHeader{}}
        case True{} False{} False{}: Fail{InvalidHeader{}}
        case True{} False{} True{}: Done{Unit{}}

def validate_header_field(+name: String, value: List<&2, U32>) -> Result<&1, &1, Error, Unit>:
    validate_header_field_flags(valid_header_name(name), reserved_header(name), valid_header_value_bytes(value))

def validate_header_then(name: String,
                         value: List<&2, U32>,
                         result: Result<&1, &1, Error, Unit>) -> Result<&1, &1, Error, Unit>:
    match result:
        case Fail{error}: Fail{error}
        case Done{Unit{}}: validate_header_field(name, value)

def validate_headers(headers: List<&2, Header>) -> Result<&1, &1, Error, Unit>:
    match headers:
        case Nil{}: Done{Unit{}}
        case Header{name, value} <> rest:
            validate_header_then(name, value, validate_headers(rest))

def encode_headers(headers: List<&2, Header>) -> List<&2, U32>:
    match headers:
        case Nil{}: Nil{}
        case Header{name, value} <> rest:
            append_bytes(append_bytes(append_bytes(append_bytes(utf8(name), utf8(": ")), value), utf8("\r\n")), encode_headers(rest))

def encode_length_header_if(method: String, body: List<&2, U32>, include: Bool) -> List<&2, U32>:
    match include:
        case False{}: Nil{}
        case True{}: utf8("Content-Length: " ++ Nat.show(List.length(&2, U32, body)) ++ "\r\n")

def encode_length_header(+method: String, +body: List<&2, U32>) -> List<&2, U32>:
    encode_length_header_if(method, body, Bool.or(method_has_length(method), Bool.not(List.is_empty(&2, U32, body))))

def encode_request_target(+method: String,
                          target: Target,
                          headers: List<&2, Header>,
                          +body: List<&2, U32>) -> List<&2, U32>:
    Target{tls, host, port, authority, resource} = target
    append_bytes(utf8(method ++ " " ++ resource ++ " HTTP/1.1\r\nHost: " ++ authority ++ "\r\n"),
        append_bytes(encode_headers(headers), append_bytes(encode_length_header(method, body),
            append_bytes(utf8("Accept-Encoding: identity\r\nConnection: close\r\n\r\n"), body))))

def encode_after_headers(method: String,
                         target: Target,
                         headers: List<&2, Header>,
                         body: List<&2, U32>,
                         result: Result<&1, &1, Error, Unit>) -> Result<&2, &2, Error, List<&2, U32>>:
    match result:
        case Fail{error}: Fail{error}
        case Done{Unit{}}: Done{encode_request_target(method, target, headers, body)}

def encode_checked(method: String,
                   target: Target,
                   headers: List<&2, Header>,
                   body: List<&2, U32>,
                   method_ok: Bool,
                   bytes_ok: Bool,
                   header_result: Result<&1, &1, Error, Unit>) -> Result<&2, &2, Error, List<&2, U32>>:
    match method_ok bytes_ok:
        case False{} _: Fail{InvalidMethod{}}
        case True{} False{}: Fail{InvalidByte{}}
        case True{} True{}: encode_after_headers(method, target, headers, body, header_result)

def encode_validated(method: String,
                     target: Target,
                     +headers: List<&2, Header>,
                     body: List<&2, U32>,
                     method_ok: Bool,
                     bytes_ok: Bool) -> Result<&2, &2, Error, List<&2, U32>>:
    encode_checked(method, target, headers, body, method_ok, bytes_ok, validate_headers(headers))

def encode_url_result(method: String,
                      headers: List<&2, Header>,
                      body: List<&2, U32>,
                      parsed: Result<&2, &2, Error, Target>,
                      method_ok: Bool,
                      bytes_ok: Bool) -> Result<&2, &2, Error, List<&2, U32>>:
    match parsed:
        case Fail{error}: Fail{error}
        case Done{target}: encode_validated(method, target, headers, body, method_ok, bytes_ok)

def encode(request: Request) -> Result<&2, &2, Error, List<&2, U32>>:
    Request{+method, +url, +headers, +body} = request
    encode_url_result(method, headers, body, parse_url(url), valid_method(method), valid_bytes(body))

def octets_string(bytes: List<&2, U32>) -> String:
    match bytes:
        case Nil{}: SNil{}
        case h <> t: SCon{Chr{h}, octets_string(t)}

def string_octets(text: String) -> List<&2, U32>:
    match text:
        case SNil{}: Nil{}
        case SCon{Chr{h}, t}: h <> string_octets(t)

def dec_line(text: String, acc: String) -> Cut:
    match text:
        case SNil{}: CutMore{}
        case SCon{'\n', _}: CutBad{}
        case SCon{'\r', rest}:
            match rest:
                case SNil{}: CutMore{}
                case SCon{'\n', tail}: CutFound{acc, tail}
                case _: CutBad{}
        case SCon{h, t}: dec_line(t, acc ++ SCon{h, SNil{}})

def dec_colon(text: String, acc: String) -> Cut:
    match text:
        case SNil{}: CutBad{}
        case SCon{':', rest}: CutFound{acc, rest}
        case SCon{h, t}: dec_colon(t, acc ++ SCon{h, SNil{}})

def dec_trim_left(text: String) -> String:
    match text:
        case SCon{' ', t}: dec_trim_left(t)
        case SCon{'\t', t}: dec_trim_left(t)
        case _: text

def dec_trim_right(text: String) -> String:
    String.reverse(dec_trim_left(String.reverse(text)))

def dec_header_value_checked(name: String,
                             bytes: List<&2, U32>,
                             valid: Bool) -> Result<&2, &2, Error, Header>:
    match valid:
        case True{}: Done{Header{name, bytes}}
        case False{}: Fail{InvalidHeader{}}



def dec_header_name_checked(name: String,
                            value: String,
                            valid_name: Bool) -> Result<&2, &2, Error, Header>:
    match valid_name:
        case False{}: Fail{InvalidHeader{}}
        case True{}:
            +trimmed = dec_trim_right(dec_trim_left(value))
            dec_header_value_checked(name, string_octets(trimmed), valid_header_value_bytes(string_octets(trimmed)))

def dec_header_from_parts(+name: String,
                          value: String,
                          valid_name: Bool) -> Result<&2, &2, Error, Header>:
    dec_header_name_checked(name, value, valid_name)

def dec_header_colon(+text: String, colon: Cut) -> Result<&2, &2, Error, Header>:
    match colon:
        case CutBad{}: Fail{InvalidHeader{}}
        case CutFound{+name, value}: dec_header_from_parts(name, value, valid_header_name(name))
        case _: Fail{InvalidHeader{}}

def dec_header_leading(+original: String, text: String) -> Result<&2, &2, Error, Header>:
    match text:
        case SCon{' ', _}: Fail{InvalidHeader{}}
        case SCon{'\t', _}: Fail{InvalidHeader{}}
        case _: dec_header_colon(original, dec_colon(original, SNil{}))


def dec_header(+text: String) -> Result<&2, &2, Error, Header>:
    dec_header_leading(text, text)

def dec_status_valid(status: U32, in_range: Bool) -> StatusLine:
    match in_range:
        case True{}: StatusOk{status}
        case False{}: StatusBad{InvalidStatus{}}

def is_decimal_digit(c: Char) -> Bool:
    match c:
        case '0': True{}
        case '1': True{}
        case '2': True{}
        case '3': True{}
        case '4': True{}
        case '5': True{}
        case '6': True{}
        case '7': True{}
        case '8': True{}
        case '9': True{}
        case _: False{}

def digit_value(c: Char) -> U32:
    U32.sub(Char.to_u32(c), 48)

def dec_status_range(code: U32, valid: Bool) -> StatusLine:
    dec_status_valid(code, valid)



def dec_status_digit_checks(a: Char, b: Char, c: Char, digits: Bool) -> StatusLine:
    match digits:
        case False{}: StatusBad{InvalidStatus{}}
        case True{}:
            +code = (digit_value(a) * 100 + digit_value(b) * 10 + digit_value(c) : U32)
            dec_status_range(code, Bool.and(U32.is_le(100, code), U32.is_le(code, 599)))

def dec_status_digits(+a: Char, +b: Char, +c: Char) -> StatusLine:
    dec_status_digit_checks(a, b, c,
        Bool.and(is_decimal_digit(a), Bool.and(is_decimal_digit(b), is_decimal_digit(c))))

def dec_status_line_space_char(tail: String, a: Char, b: Char, c: Char) -> StatusLine:
    match tail:
        case SCon{' ', _}: dec_status_digits(a, b, c)
        case _: StatusBad{InvalidStatus{}}





def dec_status_line_space(tail: String, a: Char, b: Char, c: Char, empty: Bool) -> StatusLine:
    match empty:
        case True{}: dec_status_digits(a, b, c)
        case False{}: dec_status_line_space_char(tail, a, b, c)

def dec_status_line_code(rest: String) -> StatusLine:
    match rest:
        case SCon{a, SCon{b, SCon{c, +tail}}}:
            dec_status_line_space(tail, a, b, c, String.is_empty(tail))
        case _: StatusBad{InvalidStatus{}}

def dec_status_line_version(line: String, is_v11: Bool) -> StatusLine:
    match is_v11:
        case False{}: StatusBad{InvalidVersion{}}
        case True{}: dec_status_line_code(String.drop(line, 9n))

def dec_status_line(+line: String) -> StatusLine:
    dec_status_line_version(line, Bool.or(String.starts_with(line, "HTTP/1.1 "), String.starts_with(line, "HTTP/1.0 ")))









def dec_step_finish(status: StatusLine,
                    headers: List<&2, Header>,
                    rest: String,
                    size: Nat) -> HeadStep:
    match status:
        case StatusBad{error}: HeadStepBad{error}
        case StatusOk{code}: HeadStepDone{code, List.reverse(&2, Header, headers), rest, size}


def dec_step_status(rest: String,
                    headers: List<&2, Header>,
                    size: Nat,
                    count: Nat,
                    parsed: StatusLine) -> HeadStep:
    match parsed:
        case StatusBad{error}: HeadStepBad{error}
        case StatusOk{code}: HeadContinue{rest, StatusOk{code}, headers, size, count}


def dec_step_header(rest: String,
                    status: StatusLine,
                    headers: List<&2, Header>,
                    size: Nat,
                    count: Nat,
                    parsed: Result<&2, &2, Error, Header>) -> HeadStep:
    match parsed:
        case Fail{error}: HeadStepBad{error}
        case Done{header}: HeadContinue{rest, status, header <> headers, size, (count + 1n : Nat)}



def dec_step_count(line: String,
                   rest: String,
                   status: StatusLine,
                   headers: List<&2, Header>,
                   size: Nat,
                   count: Nat,
                   limits: Limits,
                   within: Bool) -> HeadStep:
    match within:
        case False{}: HeadStepBad{LimitExceeded{}}
        case True{}: dec_step_header(rest, status, headers, size, count, dec_header(line))


def dec_limits_header_count(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    header_count

def dec_limits_header_bytes(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    header_bytes

def dec_step_line_count(line: String,
                        rest: String,
                        status: StatusLine,
                        headers: List<&2, Header>,
                        size: Nat,
                        +count: Nat,
                        limits: Limits,
                        header_limit: U32) -> HeadStep:
    dec_step_count(line, rest, status, headers, size, count, limits,
        Nat.is_le((count + 1n : Nat), U32.to_nat(header_limit)))



def dec_step_line(line: String,
                  rest: String,
                  status: StatusLine,
                  headers: List<&2, Header>,
                  size: Nat,
                  count: Nat,
                  +limits: Limits) -> HeadStep:
    match status:
        case StatusBad{_}: dec_step_status(rest, headers, size, count, dec_status_line(line))
        case StatusOk{_}: dec_step_line_count(line, rest, status, headers, size, count, limits,
            dec_limits_header_count(limits))

def dec_step_blank(line: String,
                   rest: String,
                   status: StatusLine,
                   headers: List<&2, Header>,
                   size: Nat,
                   count: Nat,
                   limits: Limits,
                   blank: Bool) -> HeadStep:
    match blank:
        case True{}: dec_step_finish(status, headers, rest, size)
        case False{}: dec_step_line(line, rest, status, headers, size, count, limits)


def dec_step_size(+line: String,
                  rest: String,
                  status: StatusLine,
                  headers: List<&2, Header>,
                  size: Nat,
                  count: Nat,
                  limits: Limits,
                  within: Bool) -> HeadStep:
    match within:
        case False{}: HeadStepBad{LimitExceeded{}}
        case True{}: dec_step_blank(line, rest, status, headers, size, count, limits, String.is_empty(line))



def dec_step_cut(line_result: Cut,
                 status: StatusLine,
                 headers: List<&2, Header>,
                 size: Nat,
                 count: Nat,
                 +limits: Limits) -> HeadStep:
    match line_result:
        case CutMore{}: HeadStepMore{}
        case CutBad{}: HeadStepBad{InvalidFraming{}}
        case CutFound{+line, rest}:
            +new_size = (size + String.length(line) + 2n : Nat)
            dec_step_size(line, rest, status, headers, new_size, count, limits,
                Nat.is_le(new_size, U32.to_nat(dec_limits_header_bytes(limits))))



def dec_scan(fuel: Nat,
             text: String,
             status: StatusLine,
             headers: List<&2, Header>,
             size: Nat,
             count: Nat,
             +limits: Limits,
             step: HeadStep) -> HeadScan:
    match fuel:
        case 0n: HeadMore{}
        case 1n+p:
            match step:
                case HeadStepMore{}: HeadMore{}
                case HeadStepBad{error}: HeadBad{error}
                case HeadStepDone{code, parsed_headers, rest, head_size}: HeadDone{code, parsed_headers, rest, head_size}
                case HeadContinue{+rest, +next_status, +next_headers, +next_size, +next_count}:
                    dec_scan(p, rest, next_status, next_headers, next_size, next_count, limits,
                        dec_step_cut(dec_line(rest, SNil{}), next_status, next_headers, next_size, next_count, limits))

def dec_parse_head(+text: String, +limits: Limits) -> HeadScan:
    dec_scan(String.length(text), text, StatusBad{InvalidStatus{}}, Nil{}, 0n, 0n, limits,
        dec_step_cut(dec_line(text, SNil{}), StatusBad{InvalidStatus{}}, Nil{}, 0n, 0n, limits))

type DecLength is Data:
    DecNoLength{}
    DecHasLength{value: U32}
    DecLengthBad{error: Error}

type RxNumber is Data:
    RxNumberOk{value: U32}
    RxNumberBad{}
    RxNumberOverflow{}

def dec_decimal_overflow(okay: Bool, parsed: RxNumber) -> RxNumber:
    match okay:
        case False{}: RxNumberOverflow{}
        case True{}: parsed

def dec_decimal(text: String, +value: U32, seen: Bool) -> RxNumber:
    match text:
        case SNil{}:
            match seen:
                case True{}: RxNumberOk{value}
                case False{}: RxNumberBad{}
        case SCon{'0', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967295, 10)), dec_decimal(rest, U32.mul(value, 10), True{}))
        case SCon{'1', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967294, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 1), True{}))
        case SCon{'2', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967293, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 2), True{}))
        case SCon{'3', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967292, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 3), True{}))
        case SCon{'4', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967291, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 4), True{}))
        case SCon{'5', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967290, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 5), True{}))
        case SCon{'6', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967289, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 6), True{}))
        case SCon{'7', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967288, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 7), True{}))
        case SCon{'8', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967287, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 8), True{}))
        case SCon{'9', rest}: dec_decimal_overflow(U32.is_le(value, U32.div(4294967286, 10)), dec_decimal(rest, U32.add(U32.mul(value, 10), 9), True{}))
        case _: RxNumberBad{}

def dec_length_parsed(parsed: RxNumber) -> DecLength:
    match parsed:
        case RxNumberOk{value}: DecHasLength{value}
        case RxNumberBad{}: DecLengthBad{InvalidFraming{}}
        case RxNumberOverflow{}: DecLengthBad{LimitExceeded{}}



def dec_length_exact(rest: List<&2, List<&2, U32>>, value: List<&2, U32>) -> DecLength:
    match rest:
        case Nil{}: dec_length_parsed(dec_decimal(octets_string(value), 0, False{}))
        case _: DecLengthBad{InvalidFraming{}}


def dec_length_values(values: List<&2, List<&2, U32>>) -> DecLength:
    match values:
        case Nil{}: DecNoLength{}
        case value <> rest: dec_length_exact(rest, value)


def dec_length(headers: List<&2, Header>) -> DecLength:
    dec_length_values(field_values("content-length", headers))

def dec_no_body(+method: String, +status: U32) -> Bool:
    Bool.or(String.eq(method, "HEAD"), Bool.or(U32.is_eq(status, 204), U32.is_eq(status, 304)))

def dec_take_enough(status: U32,
                    headers: List<&2, Header>,
                    +bytes: List<&2, U32>,
                    +length: U32,
                    enough: Bool) -> Decode:
    match enough:
        case False{}: NeedMore{}
        case True{}:
            Parsed{Response{status, headers, List.take(&2, U32, bytes, U32.to_nat(length)), Nil{}},
                List.drop(&2, U32, bytes, U32.to_nat(length))}

def dec_take_body(status: U32,
                  headers: List<&2, Header>,
                  +bytes: List<&2, U32>,
                  +length: U32,
                  within: Bool) -> Decode:
    match within:
        case False{}: Rejected{LimitExceeded{}}
        case True{}: dec_take_enough(status, headers, bytes, length,
            Nat.is_le(U32.to_nat(length), List.length(&2, U32, bytes)))

type DecBodyState is Data:
    DecBodyComplete{}
    DecBodyTruncated{}
    DecBodyPartial{}

def dec_body_state(+enough: Bool, +closed: Bool) -> DecBodyState:
    Bool.pick(DecBodyState, enough, DecBodyComplete{}, Bool.pick(DecBodyState, closed, DecBodyTruncated{}, DecBodyPartial{}))

def dec_body_length_enough(status: U32,
                           headers: List<&2, Header>,
                           +bytes: List<&2, U32>,
                           +value: U32,
                           state: DecBodyState) -> Decode:
    match state:
        case DecBodyComplete{}: Parsed{Response{status, headers, List.take(&2, U32, bytes, U32.to_nat(value)), Nil{}}, List.drop(&2, U32, bytes, U32.to_nat(value))}
        case DecBodyTruncated{}: Rejected{UnexpectedEof{}}
        case DecBodyPartial{}: NeedMore{}

def dec_body_length_dispatch(status: U32,
                             headers: List<&2, Header>,
                             +bytes: List<&2, U32>,
                             +value: U32,
                             +eof: Bool,
                             limits: Limits,
                             within: Bool) -> Decode:
    match within:
        case False{}: Rejected{LimitExceeded{}}
        case True{}: dec_body_length_enough(status, headers, bytes, value, dec_body_state(
            Nat.is_le(U32.to_nat(value), List.length(&2, U32, bytes)), eof))

def dec_body_length_field(status: U32,
                          headers: List<&2, Header>,
                          +bytes: List<&2, U32>,
                          +value: U32,
                          +eof: Bool,
                          limits: Limits,
                          body_limit: U32) -> Decode:
    dec_body_length_dispatch(status, headers, bytes, value, eof, limits, U32.is_le(value, body_limit))


def dec_limits_body_bytes(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    body_bytes


def dec_body_length(status: U32,
                    headers: List<&2, Header>,
                    +bytes: List<&2, U32>,
                    +value: U32,
                    +eof: Bool,
                    +limits: Limits) -> Decode:
    dec_body_length_field(status, headers, bytes, value, eof, limits, dec_limits_body_bytes(limits))

def dec_body_close(status: U32,
                   headers: List<&2, Header>,
                   bytes: List<&2, U32>,
                   eof: Bool,
                   within: Bool) -> Decode:
    match eof within:
        case False{} _: NeedMore{}
        case True{} False{}: Rejected{LimitExceeded{}}
        case True{} True{}: Parsed{Response{status, headers, bytes, Nil{}}, Nil{}}

def dec_body_framing(method: String,
                     status: U32,
                     headers: List<&2, Header>,
                     +bytes: List<&2, U32>,
                     +eof: Bool,
                     +limits: Limits,
                     framing: DecLength) -> Decode:
    match framing:
        case DecLengthBad{error}: Rejected{error}
        case DecHasLength{value}: dec_body_length(status, headers, bytes, value, eof, limits)
        case DecNoLength{}:
            dec_body_close(status, headers, bytes, eof,
                Nat.is_le(List.length(&2, U32, bytes), U32.to_nat(dec_limits_body_bytes(limits))))



type ChunkSize is Data:
    ChunkSizeOk{value: U32}
    ChunkSizeBad{error: Error}

type ChunkResult is Data:
    ChunkNeedMore{}
    ChunkBad{error: Error}
    ChunkDone{body: List<&2, U32>, trailers: List<&2, Header>, rest: String}

def dec_hex_digit(c: Char) -> RxNumber:
    match c:
        case '0': RxNumberOk{0}
        case '1': RxNumberOk{1}
        case '2': RxNumberOk{2}
        case '3': RxNumberOk{3}
        case '4': RxNumberOk{4}
        case '5': RxNumberOk{5}
        case '6': RxNumberOk{6}
        case '7': RxNumberOk{7}
        case '8': RxNumberOk{8}
        case '9': RxNumberOk{9}
        case 'a': RxNumberOk{10}
        case 'b': RxNumberOk{11}
        case 'c': RxNumberOk{12}
        case 'd': RxNumberOk{13}
        case 'e': RxNumberOk{14}
        case 'f': RxNumberOk{15}
        case 'A': RxNumberOk{10}
        case 'B': RxNumberOk{11}
        case 'C': RxNumberOk{12}
        case 'D': RxNumberOk{13}
        case 'E': RxNumberOk{14}
        case 'F': RxNumberOk{15}
        case _: RxNumberBad{}

def dec_hex_accum_check(value: U32, n: U32, okay: Bool) -> RxNumber:
    match okay:
        case True{}: RxNumberOk{U32.add(U32.mul(value, 16), n)}
        case False{}: RxNumberOverflow{}

def dec_hex_accum(+value: U32, digit: RxNumber) -> RxNumber:
    match digit:
        case RxNumberOk{+n}: dec_hex_accum_check(value, n, U32.is_le(value, U32.div(U32.sub(4294967295, n), 16)))
        case _: digit

def dec_hex_number(+text: String, accumulator: RxNumber, seen: Bool) -> RxNumber:
    match text:
        case SNil{}:
            match accumulator:
                case RxNumberOk{value}:
                    match seen:
                        case True{}: RxNumberOk{value}
                        case False{}: RxNumberBad{}
                case _: accumulator
        case SCon{c, rest}:
            match accumulator:
                case RxNumberOk{+value}: dec_hex_number(rest, dec_hex_accum(value, dec_hex_digit(c)), True{})
                case _: accumulator

def dec_semicolon(text: String, acc: String) -> Cut:
    match text:
        case SNil{}: CutBad{}
        case SCon{';', rest}: CutFound{acc, rest}
        case SCon{h, t}: dec_semicolon(t, acc ++ SCon{h, SNil{}})

def dec_chunk_size_number(parsed: RxNumber) -> ChunkSize:
    match parsed:
        case RxNumberOk{value}: ChunkSizeOk{value}
        case RxNumberBad{}: ChunkSizeBad{InvalidFraming{}}
        case RxNumberOverflow{}: ChunkSizeBad{LimitExceeded{}}

def dec_chunk_size_split(line: String, split: Cut) -> ChunkSize:
    match split:
        case CutFound{size, _}: dec_chunk_size_number(dec_hex_number(size, RxNumberOk{0}, False{}))
        case _: dec_chunk_size_number(dec_hex_number(line, RxNumberOk{0}, False{}))

def dec_chunk_size_check(line: String, split: Cut, within: Bool) -> ChunkSize:
    match within:
        case False{}: ChunkSizeBad{LimitExceeded{}}
        case True{}: dec_chunk_size_split(line, split)

def dec_chunk_size(+line: String, line_limit: U32) -> ChunkSize:
    dec_chunk_size_check(line, dec_semicolon(line, SNil{}), Nat.is_le(String.length(line), U32.to_nat(line_limit)))

type ChunkStep is Data:
    ChunkContinue{rest: String, body: List<&2, U32>, trailers: List<&2, Header>, trailer_bytes: Nat, trailer_count: Nat}
    ChunkStepNeed{}
    ChunkStepBad{error: Error}
    ChunkStepDone{body: List<&2, U32>, trailers: List<&2, Header>, rest: String}

def dec_limits_chunk_line(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    chunk_line_bytes

def dec_limits_trailer_bytes(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    trailer_bytes

def dec_limits_trailer_count(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    trailer_count

def dec_trailer_forbidden_basic(+name: String) -> Bool:
    Bool.or(String.eq(String.to_lower(name), "content-length"),
        Bool.or(String.eq(String.to_lower(name), "transfer-encoding"),
            Bool.or(String.eq(String.to_lower(name), "host"), String.eq(String.to_lower(name), "trailer"))))

def dec_trailer_forbidden_connection(+name: String) -> Bool:
    Bool.or(String.eq(String.to_lower(name), "connection"),
        Bool.or(String.eq(String.to_lower(name), "keep-alive"), String.eq(String.to_lower(name), "upgrade")))

def dec_trailer_forbidden_proxy(+name: String) -> Bool:
    Bool.or(String.eq(String.to_lower(name), "te"),
        Bool.or(String.eq(String.to_lower(name), "proxy-authenticate"), String.eq(String.to_lower(name), "proxy-authorization")))

def dec_trailer_forbidden(+name: String) -> Bool:
    Bool.or(dec_trailer_forbidden_basic(name),
        Bool.or(dec_trailer_forbidden_connection(name), dec_trailer_forbidden_proxy(name)))

def dec_trailer_header_check(+header: Header,
                             name: String,
                             trailers: List<&2, Header>,
                             +rest: String,
                             trailer_bytes: Nat,
                             trailer_count: Nat,
                             forbidden: Bool) -> ChunkStep:
    match forbidden:
        case True{}: ChunkStepBad{InvalidFraming{}}
        case False{}: ChunkContinue{rest, Nil{}, append_headers(trailers, [header]), trailer_bytes, trailer_count}

def dec_trailer_header(+header: Header,
                       trailers: List<&2, Header>,
                       +rest: String,
                       trailer_bytes: Nat,
                       trailer_count: Nat) -> ChunkStep:
    match header:
        case Header{name, value}: dec_trailer_header_check(header, name, trailers, rest, trailer_bytes, trailer_count, dec_trailer_forbidden(name))

def dec_trailer_added_result(parsed: Result<&2, &2, Error, Header>,
                             trailers: List<&2, Header>,
                             +rest: String,
                             trailer_bytes: Nat,
                             trailer_count: Nat) -> ChunkStep:
    match parsed:
        case Fail{error}: ChunkStepBad{error}
        case Done{+header}: dec_trailer_header(header, trailers, rest, trailer_bytes, trailer_count)

def dec_trailer_added(parsed: Result<&2, &2, Error, Header>,
                      trailers: List<&2, Header>,
                      +rest: String,
                      trailer_bytes: Nat,
                      trailer_count: Nat,
                      limits: Limits,
                      within: Bool) -> ChunkStep:
    match within:
        case False{}: ChunkStepBad{LimitExceeded{}}
        case True{}: dec_trailer_added_result(parsed, trailers, rest, trailer_bytes, trailer_count)

def dec_trailer_blank(trailers: List<&2, Header>,
                      +rest: String,
                      trailer_bytes: Nat,
                      limits: Limits,
                      within: Bool) -> ChunkStep:
    match within:
        case True{}: ChunkStepDone{Nil{}, trailers, rest}
        case False{}: ChunkStepBad{LimitExceeded{}}

def dec_trailer_line_empty(+line: String,
                           +rest: String,
                           trailers: List<&2, Header>,
                           +trailer_bytes: Nat,
                           +trailer_count: Nat,
                           +limits: Limits,
                           empty: Bool) -> ChunkStep:
    match empty:
        case True{}: dec_trailer_blank(trailers, rest, trailer_bytes, limits,
            Nat.is_le((trailer_bytes + 2n : Nat), U32.to_nat(dec_limits_trailer_bytes(limits))))
        case False{}:
            dec_trailer_added(dec_header(line), trailers, rest,
                (trailer_bytes + String.length(line) + 2n : Nat), (trailer_count + 1n : Nat), limits,
                Bool.and(Nat.is_le((trailer_bytes + String.length(line) + 2n : Nat), U32.to_nat(dec_limits_trailer_bytes(limits))),
                    Nat.is_le((trailer_count + 1n : Nat), U32.to_nat(dec_limits_trailer_count(limits)))))

def dec_trailer_line(+line: String,
                     rest: String,
                     trailers: List<&2, Header>,
                     trailer_bytes: Nat,
                     trailer_count: Nat,
                     limits: Limits) -> ChunkStep:
    dec_trailer_line_empty(line, rest, trailers, trailer_bytes, trailer_count, limits, String.is_empty(line))

def dec_chunk_incomplete(eof: Bool) -> ChunkResult:
    match eof:
        case True{}: ChunkBad{UnexpectedEof{}}
        case False{}: ChunkNeedMore{}

def dec_trailer_line_scan_result(+text: String,
                                 trailers: List<&2, Header>,
                                 trailer_bytes: Nat,
                                 trailer_count: Nat,
                                 limits: Limits,
                                 eof: Bool,
                                 cut: Cut) -> ChunkStep:
    match cut:
        case CutMore{}: ChunkStepNeed{}
        case CutBad{}: ChunkStepBad{InvalidFraming{}}
        case CutFound{line, rest}: dec_trailer_line(line, rest, trailers, trailer_bytes, trailer_count, limits)

def dec_trailer_line_scan(+text: String,
                          trailers: List<&2, Header>,
                          +trailer_bytes: Nat,
                          +trailer_count: Nat,
                          +limits: Limits,
                          eof: Bool) -> ChunkStep:
    dec_trailer_line_scan_result(text, trailers, trailer_bytes, trailer_count, limits, eof, dec_line(text, SNil{}))

def dec_trailer_scan(fuel: Nat,
                     +text: String,
                     trailers: List<&2, Header>,
                     +trailer_bytes: Nat,
                     +trailer_count: Nat,
                     +limits: Limits,
                     +eof: Bool,
                     step: ChunkStep) -> ChunkResult:
    match fuel:
        case 0n: ChunkNeedMore{}
        case 1n+p:
            match step:
                case ChunkStepNeed{}: dec_chunk_incomplete(eof)
                case ChunkStepBad{error}: ChunkBad{error}
                case ChunkStepDone{+body, +trailers, +rest}: ChunkDone{body, trailers, rest}
                case ChunkContinue{+rest, +body, +trailers, +next_bytes, +next_count}:
                    dec_trailer_scan(p, rest, trailers, next_bytes, next_count, limits, eof,
                        dec_trailer_line_scan(rest, trailers, next_bytes, next_count, limits, eof))

def dec_trailer_step(body: List<&2, U32>, result: ChunkResult) -> ChunkStep:
    match result:
        case ChunkNeedMore{}: ChunkStepNeed{}
        case ChunkBad{error}: ChunkStepBad{error}
        case ChunkDone{_, trailers, rest}: ChunkStepDone{body, trailers, rest}

def dec_chunk_data_terminator(+size: U32,
                              body: List<&2, U32>,
                              trailers: List<&2, Header>,
                              +tail: String,
                              data: String,
                              valid: Bool) -> ChunkStep:
    match valid:
        case False{}: ChunkStepBad{InvalidFraming{}}
        case True{}: ChunkContinue{String.drop(tail, 2n), append_bytes(body, string_octets(data)), trailers, 0n, 0n}

def dec_chunk_data_enough(+size: U32,
                          body: List<&2, U32>,
                          trailers: List<&2, Header>,
                          +rest: String,
                          limits: Limits,
                          enough: Bool) -> ChunkStep:
    match enough:
        case False{}: ChunkStepNeed{}
        case True{}:
            data = String.take(rest, U32.to_nat(size))
            +tail = String.drop(rest, U32.to_nat(size))
            dec_chunk_data_terminator(size, body, trailers, tail, data, String.starts_with(tail, "\r\n"))

def dec_chunk_data(+size: U32,
                   body: List<&2, U32>,
                   trailers: List<&2, Header>,
                   +rest: String,
                   +limits: Limits,
                   within: Bool) -> ChunkStep:
    match within:
        case False{}: ChunkStepBad{LimitExceeded{}}
        case True{}: dec_chunk_data_enough(size, body, trailers, rest, limits, Nat.is_le((U32.to_nat(size) + 2n : Nat), String.length(rest)))

def dec_chunk_size_zero(+size: U32,
                        +body: List<&2, U32>,
                        +trailers: List<&2, Header>,
                        +rest: String,
                        +limits: Limits,
                        +eof: Bool,
                        zero: Bool) -> ChunkStep:
    match zero:
        case False{}: dec_chunk_data(size, body, trailers, rest, limits, True{})
        case True{}: dec_trailer_step(body, dec_trailer_scan((String.length(rest) + 1n : Nat), rest, trailers, 0n, 0n, limits, eof,
            dec_trailer_line_scan(rest, trailers, 0n, 0n, limits, eof)))

def dec_chunk_size_ready(+size: U32,
                         +body: List<&2, U32>,
                         +trailers: List<&2, Header>,
                         +rest: String,
                         +limits: Limits,
                         +eof: Bool,
                         body_within: Bool) -> ChunkStep:
    match body_within:
        case False{}: ChunkStepBad{LimitExceeded{}}
        case True{}: dec_chunk_size_zero(size, body, trailers, rest, limits, eof, U32.is_eq(size, 0))

def dec_chunk_size_limit(value: U32,
                         body: List<&2, U32>,
                         trailers: List<&2, Header>,
                         +tail: String,
                         +limits: Limits,
                         eof: Bool,
                         within: Bool) -> ChunkStep:
    dec_chunk_size_ready(value, body, trailers, tail, limits, eof, within)

def dec_chunk_line_size(size: ChunkSize,
                        +body: List<&2, U32>,
                        +trailers: List<&2, Header>,
                        +tail: String,
                        +limits: Limits,
                        +eof: Bool) -> ChunkStep:
    match size:
        case ChunkSizeBad{error}: ChunkStepBad{error}
        case ChunkSizeOk{+value}: dec_chunk_size_limit(value, body, trailers, tail, limits, eof,
            Nat.is_le((List.length(&2, U32, body) + U32.to_nat(value) : Nat), U32.to_nat(dec_limits_body_bytes(limits))))

def dec_chunk_line_cut(+line: String,
                       +tail: String,
                       body: List<&2, U32>,
                       trailers: List<&2, Header>,
                       +limits: Limits,
                       eof: Bool,
                       size: ChunkSize,
                       within: Bool) -> ChunkStep:
    match within:
        case False{}: ChunkStepBad{LimitExceeded{}}
        case True{}: dec_chunk_line_size(size, body, trailers, tail, limits, eof)

def dec_chunk_line_scan_result(+text: String,
                               +body: List<&2, U32>,
                               +trailers: List<&2, Header>,
                               +limits: Limits,
                               +eof: Bool,
                               cut: Cut) -> ChunkStep:
    match cut:
        case CutFound{+line, rest}: dec_chunk_line_cut(line, rest, body, trailers, limits, eof, dec_chunk_size(line, dec_limits_chunk_line(limits)),
            Nat.is_le((String.length(line) + 2n : Nat), U32.to_nat(dec_limits_chunk_line(limits))))
        case CutMore{}: ChunkStepNeed{}
        case CutBad{}: ChunkStepBad{InvalidFraming{}}

def dec_chunk_line_scan(+text: String,
                        body: List<&2, U32>,
                        trailers: List<&2, Header>,
                        +limits: Limits,
                        eof: Bool) -> ChunkStep:
    dec_chunk_line_scan_result(text, body, trailers, limits, eof, dec_line(text, SNil{}))

def dec_chunk_scan(fuel: Nat,
                   +text: String,
                   body: List<&2, U32>,
                   trailers: List<&2, Header>,
                   +limits: Limits,
                   +eof: Bool,
                   step: ChunkStep) -> ChunkResult:
    match fuel:
        case 0n: ChunkNeedMore{}
        case 1n+p:
            match step:
                case ChunkStepNeed{}: dec_chunk_incomplete(eof)
                case ChunkStepBad{error}: ChunkBad{error}
                case ChunkStepDone{+body, +trailers, +rest}: ChunkDone{body, trailers, rest}
                case ChunkContinue{+rest, +body, +trailers, trailer_bytes, trailer_count}:
                    dec_chunk_scan(p, rest, body, trailers, limits, eof, dec_chunk_line_scan(rest, body, trailers, limits, eof))

def dec_chunked_result(status: U32, headers: List<&2, Header>, result: ChunkResult) -> Decode:
    match result:
        case ChunkNeedMore{}: NeedMore{}
        case ChunkBad{error}: Rejected{error}
        case ChunkDone{body, trailers, rest}: Parsed{Response{status, headers, body, trailers}, string_octets(rest)}

def dec_chunked_decode(status: U32,
                       headers: List<&2, Header>,
                       +bytes: List<&2, U32>,
                       +eof: Bool,
                       +limits: Limits) -> Decode:
    +text = octets_string(bytes)
    dec_chunked_result(status, headers, dec_chunk_scan((String.length(text) + 1n : Nat), text, Nil{}, Nil{}, limits, eof,
        dec_chunk_line_scan(text, Nil{}, Nil{}, limits, eof)))

def dec_transfer_value_check(status: U32,
                             headers: List<&2, Header>,
                             bytes: List<&2, U32>,
                             eof: Bool,
                             limits: Limits,
                             is_chunked: Bool,
                             repeated: Bool) -> Decode:
    match is_chunked:
        case True{}: dec_chunked_decode(status, headers, bytes, eof, limits)
        case False{}:
            match repeated:
                case True{}: Rejected{InvalidFraming{}}
                case False{}: Rejected{UnsupportedTransferEncoding{}}

def dec_transfer_value_text(+status: U32,
                            +headers: List<&2, Header>,
                            +bytes: List<&2, U32>,
                            +eof: Bool,
                            +limits: Limits,
                            +value: String) -> Decode:
    dec_transfer_value_check(status, headers, bytes, eof, limits, String.eq(value, "chunked"), String.eq(value, "chunked, chunked"))

def dec_transfer_value(status: U32,
                       headers: List<&2, Header>,
                       bytes: List<&2, U32>,
                       eof: Bool,
                       limits: Limits,
                       value: List<&2, U32>,
                       framing: DecLength) -> Decode:
    match framing:
        case DecHasLength{_}: Rejected{InvalidFraming{}}
        case DecLengthBad{error}: Rejected{error}
        case DecNoLength{}: dec_transfer_value_text(status, headers, bytes, eof, limits, String.to_lower(octets_string(value)))

def dec_transfer_pick(status: U32,
                      headers: List<&2, Header>,
                      bytes: List<&2, U32>,
                      eof: Bool,
                      limits: Limits,
                      transfer: List<&2, List<&2, U32>>,
                      framing: DecLength) -> Decode:
    match transfer:
        case Nil{}: dec_body_framing("GET", status, headers, bytes, eof, limits, framing)
        case value <> Nil{}: dec_transfer_value(status, headers, bytes, eof, limits, value, framing)
        case _ <> _: Rejected{InvalidFraming{}}

def dec_transfer_for_method(method: String,
                            status: U32,
                            headers: List<&2, Header>,
                            bytes: List<&2, U32>,
                            eof: Bool,
                            limits: Limits,
                            transfer: List<&2, List<&2, U32>>,
                            framing: DecLength) -> Decode:
    match transfer:
        case Nil{}: dec_body_framing(method, status, headers, bytes, eof, limits, framing)
        case value <> Nil{}: dec_transfer_value(status, headers, bytes, eof, limits, value, framing)
        case _ <> _:
            match framing:
                case DecHasLength{_}: Rejected{InvalidFraming{}}
                case DecLengthBad{error}: Rejected{error}
                case DecNoLength{}: Rejected{InvalidFraming{}}

def dec_body_no_body(method: String,
                     status: U32,
                     +headers: List<&2, Header>,
                     +bytes: List<&2, U32>,
                     +eof: Bool,
                     +limits: Limits,
                     no_body: Bool) -> Decode:
    match no_body:
        case True{}: Parsed{Response{status, headers, Nil{}, Nil{}}, bytes}
        case False{}: dec_transfer_for_method(method, status, headers, bytes, eof, limits,
            field_values("transfer-encoding", headers), dec_length(headers))

def dec_body_dispatch(+method: String,
                      +status: U32,
                      +headers: List<&2, Header>,
                      +bytes: List<&2, U32>,
                      +eof: Bool,
                      +limits: Limits) -> Decode:
    dec_body_no_body(method, status, headers, bytes, eof, limits, dec_no_body(method, status))


type DecAfterHead is Data:
    DecAfterMore{}
    DecAfterBad{error: Error}
    DecAfterInterim{rest: String}
    DecAfterFinal{result: Decode}

def dec_status_is_interim(+status: U32) -> Bool:
    Bool.and(U32.is_le(100, status), Bool.and(U32.is_lt(status, 200), Bool.not(U32.is_eq(status, 101))))

def dec_after_head_code(method: String,
                        status: U32,
                        headers: List<&2, Header>,
                        rest: String,
                        eof: Bool,
                        limits: Limits,
                        interim: Bool,
                        upgrade: Bool) -> DecAfterHead:
    match interim upgrade:
        case True{} _: DecAfterInterim{rest}
        case False{} True{}: DecAfterBad{UnsupportedUpgrade{}}
        case False{} False{}: DecAfterFinal{dec_body_dispatch(method, status, headers, string_octets(rest), eof, limits)}

def dec_after_head_step(method: String, head: HeadScan, eof: Bool, limits: Limits) -> DecAfterHead:
    match head:
        case HeadMore{}:
            match eof:
                case True{}: DecAfterBad{UnexpectedEof{}}
                case False{}: DecAfterMore{}
        case HeadBad{error}: DecAfterBad{error}
        case HeadDone{+status, headers, rest, head_size}:
            dec_after_head_code(method, status, headers, rest, eof, limits, dec_status_is_interim(status), U32.is_eq(status, 101))

def dec_limits_interim_count(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    interim_count

def dec_after_head(fuel: Nat,
                   +method: String,
                   +limits: Limits,
                   +eof: Bool,
                   step: DecAfterHead) -> Decode:
    match fuel:
        case 0n: Rejected{LimitExceeded{}}
        case 1n+p:
            match step:
                case DecAfterMore{}: NeedMore{}
                case DecAfterBad{error}: Rejected{error}
                case DecAfterFinal{result}: result
                case DecAfterInterim{+rest}:
                    dec_after_head(p, method, limits, eof,
                        dec_after_head_step(method, dec_parse_head(rest, limits), eof, limits))

def dec_decode_wire(+method: String, +limits: Limits, bytes: List<&2, U32>, +eof: Bool) -> Decode:
    text = octets_string(bytes)
    dec_after_head((U32.to_nat(dec_limits_interim_count(limits)) + 1n : Nat), method, limits, eof, dec_after_head_step(method, dec_parse_head(text, limits), eof, limits))


def dec_limits_wire_bytes(limits: Limits) -> U32:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    wire_bytes

def dec_wire_parsed(response: Response, rest: List<&2, U32>, within: Bool) -> Decode:
    match within:
        case True{}: Parsed{response, rest}
        case False{}: Rejected{LimitExceeded{}}

def dec_wire_incomplete(within: Bool) -> Decode:
    match within:
        case True{}: NeedMore{}
        case False{}: Rejected{LimitExceeded{}}

def dec_decode_wire_result(result: Decode, +bytes: List<&2, U32>, limits: Limits) -> Decode:
    match result:
        case Parsed{response, +rest}:
            dec_wire_parsed(response, rest,
                Nat.is_le(Nat.sub(List.length(&2, U32, bytes), List.length(&2, U32, rest)), U32.to_nat(dec_limits_wire_bytes(limits))))
        case NeedMore{}:
            dec_wire_incomplete(Nat.is_le(List.length(&2, U32, bytes), U32.to_nat(dec_limits_wire_bytes(limits))))
        case Rejected{error}: Rejected{error}

def dec_decode_bytes(method: String,
                     +limits: Limits,
                     +bytes: List<&2, U32>,
                     eof: Bool,
                     bytes_ok: Bool) -> Decode:
    match bytes_ok:
        case False{}: Rejected{InvalidByte{}}
        case True{}:
            dec_decode_wire_result(dec_decode_wire(method, limits, bytes, eof), bytes, limits)


def decode(method: String, limits: Limits, +bytes: List<&2, U32>, eof: Bool) -> Decode:
    dec_decode_bytes(method, limits, bytes, eof, valid_bytes(bytes))




def nonempty_fragments(parts: List<&2, List<&2, U32>>) -> List<&2, List<&2, U32>>:
    match parts:
        case Nil{}: Nil{}
        case Nil{} <> t: nonempty_fragments(t)
        case h <> t: h <> nonempty_fragments(t)

def flatten_nonempty(parts: List<&2, List<&2, U32>>) -> List<&2, U32>:
    match parts:
        case Nil{}: Nil{}
        case h <> Nil{}: h
        case h <> t: append_bytes(h, flatten_nonempty(t))

def flatten_bytes(parts: List<&2, List<&2, U32>>) -> List<&2, U32>:
    flatten_nonempty(nonempty_fragments(parts))

def decode_parts(method: String,
                 limits: Limits,
                 fragments: List<&2, List<&2, U32>>,
                 eof: Bool) -> Decode:
    decode(method, limits, flatten_bytes(fragments), eof)

def drop_written_result(+bytes: List<&2, U32>,
                        +count: U32,
                        within: Bool,
                        zero: Bool,
                        empty: Bool) -> Result<&2, &2, Error, List<&2, U32>>:
    match within zero empty:
        case False{} _ _: Fail{InvalidFraming{}}
        case True{} True{} True{}: Done{Nil{}}
        case True{} True{} False{}: Fail{NoProgress{}}
        case True{} False{} _: Done{List.drop(&2, U32, bytes, U32.to_nat(count))}

def drop_written(+bytes: List<&2, U32>, +count: U32) -> Result<&2, &2, Error, List<&2, U32>>:
    drop_written_result(bytes, count,
        Nat.is_le(U32.to_nat(count), List.length(&2, U32, bytes)),
        U32.is_eq(count, 0), List.is_empty(&2, U32, bytes))

def read_json_parsed(parsed: Result<&1, &1, Json.Error, Json.Value>) -> Result<&1, &1, Error, Json.Value>:
    match parsed:
        case Done{value}: Done{value}
        case Fail{_}: Fail{InvalidJson{}}

def read_json_body(body: List<&2, U32>,
                   text: String,
                   is_utf8: Bool) -> Result<&1, &1, Error, Json.Value>:
    match is_utf8:
        case False{}: Fail{InvalidUtf8{}}
        case True{}: read_json_parsed(Json.parse(text))

def read_json_gpu_body(body: List<&2, U32>,
                       text: String,
                       is_utf8: Bool) -> Result<&1, &1, Error, Json.Value>:
    match is_utf8:
        case False{}: Fail{InvalidUtf8{}}
        case True{}: read_json_parsed(Json.parse_gpu(text))

def read_json_select(+text: String,
                     encoding_ok: Bool,
                     is_utf8: Bool,
                     gpu: Bool) -> Result<&1, &1, Error, Json.Value>:
    match encoding_ok is_utf8 gpu:
        case False{} _ _: Fail{UnsupportedContentEncoding{}}
        case True{} False{} _: Fail{InvalidUtf8{}}
        case True{} True{} False{}: read_json_parsed(Json.parse(text))
        case True{} True{} True{}: read_json_parsed(Json.parse_gpu(text))

def read_json_encoding(+body: List<&2, U32>,
                       +text: String,
                       encoding_ok: Bool) -> Result<&1, &1, Error, Json.Value>:
    read_json_select(text, encoding_ok, Bool.and(valid_bytes(body), byte_lists_equal(utf8(text), body)), False{})

def identity_encoding(values: List<&2, List<&2, U32>>) -> Bool:
    match values:
        case Nil{}: True{}
        case value <> Nil{}: String.eq(String.to_lower(octets_string(value)), "identity")
        case _: False{}

def read_json_encoding_gpu(+body: List<&2, U32>,
                           +text: String,
                           encoding_ok: Bool,
                           gpu: Bool) -> Result<&1, &1, Error, Json.Value>:
    read_json_select(text, encoding_ok, Bool.and(valid_bytes(body), byte_lists_equal(utf8(text), body)), gpu)

def read_json(response: Response) -> Result<&1, &1, Error, Json.Value>:
    Response{status, headers, +body, trailers} = response
    +values = field_values("content-encoding", headers)
    +text = Encoding.utf8.decode(Bytes.from_string(octets_string(body)))
    read_json_encoding(body, text, identity_encoding(values))

def encode_gpu(request: Request) -> Result<&2, &2, Error, List<&2, U32>>:
    encode!(request)

def decode_gpu(method: String, limits: Limits, bytes: List<&2, U32>, eof: Bool) -> Decode:
    decode!(method, limits, bytes, eof)

def read_json_gpu(response: Response) -> Result<&1, &1, Error, Json.Value>:
    Response{status, headers, +body, trailers} = response
    +values = field_values("content-encoding", headers)
    +text = Encoding.utf8.decode(Bytes.from_string(octets_string(body)))
    read_json_encoding_gpu(body, text, identity_encoding(values), True{})

def run_work(work: Work) -> Outcome:
    match work:
        case EncodeWork{request}: Encoded{encode(request)}
        case DecodeWork{method, limits, bytes, eof}: Decoded{decode(method, limits, bytes, eof)}

def run_batch(batch: Batch) -> BatchResult:
    match batch:
        case Leaf{work}: LeafResult{run_work(work)}
        case Fork{left, right}:
            l r = run_batch(left) run_batch(right)
            ForkResult{l, r}

def run_batch_gpu(batch: Batch) -> BatchResult:
    run_batch!(batch)

def append_outcomes(xs: List<&2, Outcome>, ys: List<&2, Outcome>) -> List<&2, Outcome>:
    match xs:
        case Nil{}: ys
        case h <> t: h <> append_outcomes(t, ys)

def batch_leaves(jobs: List<&2, Work>) -> List<&2, Batch>:
    match jobs:
        case Nil{}: Nil{}
        case job <> tail: Leaf{job} <> batch_leaves(tail)

def batch_pairs(trees: List<&2, Batch>) -> List<&2, Batch>:
    match trees:
        case Nil{}: Nil{}
        case tree <> Nil{}: tree <> Nil{}
        case left <> right <> tail: Fork{left, right} <> batch_pairs(tail)

def batch_fold_result(head: Batch, rest: Maybe<&2, Batch>) -> Maybe<&2, Batch>:
    match rest:
        case None{}: Some{head}
        case Some{tail}: Some{Fork{head, tail}}

def batch_fold(trees: List<&2, Batch>) -> Maybe<&2, Batch>:
    match trees:
        case Nil{}: None{}
        case head <> tail: batch_fold_result(head, batch_fold(tail))

def batch_build(fuel: Nat, trees: List<&2, Batch>) -> Maybe<&2, Batch>:
    match fuel:
        case 0n: batch_fold(trees)
        case 1n+p:
            match trees:
                case Nil{}: None{}
                case tree <> Nil{}: Some{tree}
                case left <> right <> tail: batch_build(p, batch_pairs(left <> right <> tail))

def batch_from_list(+jobs: List<&2, Work>) -> Maybe<&2, Batch>:
    batch_build(List.length(&2, Work, jobs), batch_leaves(jobs))

def run_many_tree(batch: Maybe<&2, Batch>) -> Maybe<&2, BatchResult>:
    match batch:
        case None{}: None{}
        case Some{tree}: Some{run_batch(tree)}

def run_many_gpu_tree(batch: Maybe<&2, Batch>) -> Maybe<&2, BatchResult>:
    match batch:
        case None{}: None{}
        case Some{tree}: Some{run_batch_gpu(tree)}

def run_many(jobs: List<&2, Work>) -> Maybe<&2, BatchResult>:
    run_many_tree(batch_from_list(jobs))

def run_many_gpu(jobs: List<&2, Work>) -> Maybe<&2, BatchResult>:
    run_many_gpu_tree(batch_from_list(jobs))

def flatten_results(results: BatchResult) -> List<&2, Outcome>:
    match results:
        case LeafResult{outcome}: [outcome]
        case ForkResult{left, right}: append_outcomes(flatten_results(left), flatten_results(right))

def valid_limits(limits: Limits) -> Bool:
    Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, wire_bytes} = limits
    Bool.and(U32.is_ne(header_bytes, 0), Bool.and(U32.is_ne(header_count, 0),
        Bool.and(U32.is_ne(body_bytes, 0), Bool.and(U32.is_ne(trailer_bytes, 0),
        Bool.and(U32.is_ne(trailer_count, 0), Bool.and(U32.is_ne(interim_count, 0),
        Bool.and(U32.is_ne(chunk_line_bytes, 0), U32.is_ne(wire_bytes, 0))))))))

def valid_options(options: Options) -> Bool:
    Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel} = options
    Bool.and(valid_limits(limits), Bool.and(U32.is_ne(connect_ms, 0),
        Bool.and(U32.is_ne(read_ms, 0), Bool.and(U32.is_ne(write_ms, 0),
        Bool.and(U32.is_ne(total_ms, 0), U32.is_ne(fuel, 0))))))

def send_preflight_size(bytes: List<&2, U32>, within: Bool) -> Result<&1, &1, Error, List<&2, U32>>:
    match within:
        case True{}: Done{bytes}
        case False{}: Fail{LimitExceeded{}}

def send_preflight_encoded(encoded: Result<&2, &2, Error, List<&2, U32>>,
                           maximum: U32) -> Result<&1, &1, Error, List<&2, U32>>:
    match encoded:
        case Fail{error}: Fail{error}
        case Done{+bytes}:
            send_preflight_size(bytes, Nat.is_le(List.length(&2, U32, bytes), U32.to_nat(maximum)))

# A character contributes at least one encoded byte. This rejects oversized
# caller input before encode allocates the request; the exact byte cap follows.
def send_header_input_size(headers: List<&2, Header>) -> Nat:
    match headers:
        case Nil{}: 0n
        case Header{name, value} <> rest:
            (String.length(name) + List.length(&2, U32, value) + send_header_input_size(rest) : Nat)

def send_request_input_size(request: Request) -> Nat:
    match request:
        case Request{method, url, headers, body}:
            (String.length(method) + String.length(url) + send_header_input_size(headers) + List.length(&2, U32, body) : Nat)

def send_request_header_count(request: Request) -> Nat:
    match request:
        case Request{method, url, headers, body}: List.length(&2, Header, headers)

def send_preflight_status(options_valid: Bool,
                          body_within: Bool,
                          request: Request,
                          maximum: U32) -> Result<&1, &1, Error, List<&2, U32>>:
    match options_valid:
        case False{}: Fail{Configuration{}}
        case True{}:
            match body_within:
                case False{}: Fail{LimitExceeded{}}
                case True{}: send_preflight_encoded(encode(request), maximum)

def send_preflight_request(+request: Request,
                           options_valid: Bool,
                           limits: Limits) -> Result<&1, &1, Error, List<&2, U32>>:
    match request:
        case Request{method, url, headers, +body}:
            Limits{header_bytes, +header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, +wire_bytes} = limits
            send_preflight_status(options_valid,
                Bool.and(Nat.is_le(List.length(&2, U32, body), U32.to_nat(body_bytes)),
                    Bool.and(Nat.is_le(send_request_input_size(request), U32.to_nat(wire_bytes)),
                        Nat.is_le(send_request_header_count(request), U32.to_nat(header_count)))),
                request, wire_bytes)

def send_preflight_options(+request: Request,
                           options_valid: Bool,
                           options: Options) -> Result<&1, &1, Error, List<&2, U32>>:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}:
            send_preflight_request(request, options_valid, limits)

def send_preflight(+request: Request, +options: Options) -> Result<&1, &1, Error, List<&2, U32>>:
    send_preflight_options(request, valid_options(options), options)

def send_option_connect_ms(options: Options) -> U32:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}: connect_ms

def send_option_limits(options: Options) -> Limits:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}: limits

def send_option_read_ms(options: Options) -> U32:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}: read_ms

def send_option_write_ms(options: Options) -> U32:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}: write_ms

def send_option_total_ms(options: Options) -> U32:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}: total_ms

def send_option_fuel(options: Options) -> U32:
    match options:
        case Options{limits, connect_ms, read_ms, write_ms, total_ms, fuel}: fuel

def send_error_timeout(is_timeout: Bool, fallback: Error) -> Error:
    match is_timeout:
        case True{}: Timeout{}
        case False{}: fallback

def send_error_code(+code: U32, fallback: Error) -> Error:
    send_error_timeout(Bool.or(U32.is_eq(code, 110), U32.is_eq(code, 60)), fallback)

def send_min_budget_choice(is_smaller: Bool, +remain: Nat, +maximum: U32) -> Maybe<&2, U32>:
    match is_smaller:
        case True{}: Some{maximum}
        case False{}: Some{U32.from_nat(remain)}

def send_min_budget_status(is_before: Bool,
                           +deadline: Nat,
                           +maximum: U32,
                           now: Nat) -> Maybe<&2, U32>:
    match is_before:
        case False{}: None{}
        case True{}:
            +remain = Nat.sub(deadline, now)
            send_min_budget_choice(Nat.is_lt(U32.to_nat(maximum), remain), remain, maximum)

def send_min_budget(+deadline: Nat, +maximum: U32, +now: Nat) -> Maybe<&2, U32>:
    send_min_budget_status(Nat.is_lt(now, deadline), deadline, maximum, now)

def send_budget(deadline: Nat, maximum: U32) -> IO(Maybe<&2, U32>):
    do IO<Maybe<&2, U32>>:
        now : Nat <- IO.now()
        return send_min_budget(deadline, maximum, now)

def send_dns_target_local(+host: String, is_local: Bool, budget: U32) -> IO(Maybe<&2, String>):
    match is_local:
        case True{}: IO.pure(Maybe<&2, String>, Some{"127.0.0.1"})
        case False{}: Dns.resolve.timeout(host, budget)

def send_dns_target_kind(+host: String, is_ipv4: Bool, budget: U32) -> IO(Maybe<&2, String>):
    match is_ipv4:
        case True{}: IO.pure(Maybe<&2, String>, Some{host})
        case False{}: send_dns_target_local(host, String.eq(host, "localhost"), budget)

def send_dns_target(+host: String, budget: U32) -> IO(Maybe<&2, String>):
    send_dns_target_kind(host, Dns.ipv4(host), budget)

def send_closed(tls: Bool, sock: Socket) -> IO(Unit):
    match tls:
        case True{}: Wire.tls.close(sock)
        case False{}: Socket.close(sock)

def send_fail_closed(tls: Bool, sock: Socket, error: Error) -> IO(Result<&1, &1, Error, Response>):
    do IO<Result<&1, &1, Error, Response>>:
        send_closed(tls, sock)
        return Fail{error}

def send_finish_closed(tls: Bool,
                       sock: Socket,
                       decoded: Decode) -> IO(Result<&1, &1, Error, Response>):
    match decoded:
        case Parsed{response, rest}:
            do IO<Result<&1, &1, Error, Response>>:
                send_closed(tls, sock)
                return Done{response}
        case Rejected{error}:
            send_fail_closed(tls, sock, error)
        case NeedMore{}:
            send_fail_closed(tls, sock, NoProgress{})

def send_recv(+tls: Bool,
              sock: Socket,
              max: U32,
              ms: U32) -> IO(Socket & Result<&1, &1, U32 & String, String>):
    match tls:
        case True{}: Wire.tls.recv(sock, max, ms)
        case False{}: Wire.recv(sock, max, ms)

def send_read_size_choice(small: Bool, limit: U32) -> U32:
    match small:
        case True{}: limit
        case False{}: 4096

def send_read_size(limits: Limits) -> U32:
    match limits:
        case Limits{header_bytes, header_count, body_bytes, trailer_bytes, trailer_count, interim_count, chunk_line_bytes, +wire_bytes}:
            send_read_size_choice(U32.is_lt(wire_bytes, 4096), wire_bytes)

def send_read_process_data(tls: Bool,
                           sock: Socket,
                           +method: String,
                           +limits: Limits,
                           +bytes: List<&2, U32>,
                           +data: String,
                           empty: Bool,
                           resume: Socket -> List<&2, U32> -> IO(Result<&1, &1, Error, Response>)) -> IO(Result<&1, &1, Error, Response>):
    match empty:
        case True{}: send_finish_closed(tls, sock, decode(method, limits, bytes, True{}))
        case False{}: resume(sock, append_bytes(bytes, string_octets(data)))

def send_read_process(tls: Bool,
                      +method: String,
                      +limits: Limits,
                      +bytes: List<&2, U32>,
                      resume: Socket -> List<&2, U32> -> IO(Result<&1, &1, Error, Response>),
                      result: Socket & Result<&1, &1, U32 & String, String>) -> IO(Result<&1, &1, Error, Response>):
    (sock, read_result) = result
    match read_result:
        case Fail{(+code, message)}: send_fail_closed(tls, sock, send_error_code(code, Io{}))
        case Done{+data}:
            send_read_process_data(tls, sock, method, limits, bytes, data, String.is_empty(data), resume)

def send_read_budget(+tls: Bool,
                     sock: Socket,
                     +method: String,
                     +limits: Limits,
                     +bytes: List<&2, U32>,
                     read_ms: U32,
                     budget: Maybe<&2, U32>,
                     resume: Socket -> List<&2, U32> -> IO(Result<&1, &1, Error, Response>)) -> IO(Result<&1, &1, Error, Response>):
    match budget:
        case None{}: send_fail_closed(tls, sock, Timeout{})
        case Some{ms}:
            do IO<Result<&1, &1, Error, Response>>:
                received : Socket & Result<&1, &1, U32 & String, String>
                    <- send_recv(tls, sock, send_read_size(limits), ms)
                send_read_process(tls, method, limits, bytes, resume, received)

def send_read_start(tls: Bool,
                    sock: Socket,
                    +method: String,
                    +limits: Limits,
                    +bytes: List<&2, U32>,
                    +deadline: Nat,
                    +read_ms: U32,
                    resume: Socket -> List<&2, U32> -> IO(Result<&1, &1, Error, Response>)) -> IO(Result<&1, &1, Error, Response>):
    do IO<Result<&1, &1, Error, Response>>:
        budget : Maybe<&2, U32> <- send_budget(deadline, read_ms)
        send_read_budget(tls, sock, method, limits, bytes, read_ms, budget, resume)

def send_read_decoded(tls: Bool,
                      sock: Socket,
                      +method: String,
                      +limits: Limits,
                      +bytes: List<&2, U32>,
                      resume: Socket -> List<&2, U32> -> IO(Result<&1, &1, Error, Response>),
                      decoded: Decode) -> IO(Result<&1, &1, Error, Response>):
    match decoded:
        case Parsed{response, rest}: send_finish_closed(tls, sock, Parsed{response, rest})
        case Rejected{error}: send_fail_closed(tls, sock, error)
        case NeedMore{}: resume(sock, bytes)

def send_read_step(fuel: Nat,
                   +tls: Bool,
                   sock: Socket,
                   +method: String,
                   +limits: Limits,
                   +bytes: List<&2, U32>,
                   +deadline: Nat,
                   +read_ms: U32) -> IO(Result<&1, &1, Error, Response>):
    match fuel:
        case 0n:
            send_read_decoded(tls, sock, method, limits, bytes,
                next_sock => next_bytes => send_fail_closed(tls, next_sock, LimitExceeded{}),
                decode(method, limits, bytes, False{}))
        case 1n+left:
            send_read_decoded(tls, sock, method, limits, bytes,
                next_sock => next_bytes => send_read_start(tls, next_sock, method, limits, next_bytes, deadline, read_ms,
                    after_sock => after_bytes => send_read_step(left, tls, after_sock, method, limits, after_bytes, deadline, read_ms)),
                decode(method, limits, bytes, False{}))

def send_written_success(tls: Bool,
                         sock: Socket,
                         request: Request,
                         +limits: Limits,
                         deadline: Nat,
                         read_ms: U32,
                         fuel: U32) -> IO(Result<&1, &1, Error, Response>):
    match request:
        case Request{method, url, headers, body}:
            send_read_step(U32.to_nat(fuel), tls, sock, method, limits, Nil{}, deadline, read_ms)

def send_written_result(tls: Bool,
                        +request: Request,
                        +limits: Limits,
                        deadline: Nat,
                        read_ms: U32,
                        fuel: U32,
                        result: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Result<&1, &1, Error, Response>):
    (sock, write_result) = result
    match write_result:
        case Fail{(+code, message)}:
            send_fail_closed(tls, sock, send_error_code(code, Io{}))
        case Done{Unit{}}:
            send_written_success(tls, sock, request, limits, deadline, read_ms, fuel)

def send_wire_method(tls: Bool) -> Socket -> String -> U32 -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
    match tls:
        case True{}: Wire.tls.send.timeout
        case False{}: Wire.send.timeout

def send_socket_action(+tls: Bool,
                       sock: Socket,
                       +request: Request,
                       +encoded: List<&2, U32>,
                       +limits: Limits,
                       deadline: Nat,
                       read_ms: U32,
                       fuel: U32,
                       ms: U32) -> IO(Result<&1, &1, Error, Response>):
    do IO<Result<&1, &1, Error, Response>>:
        written : Socket & Result<&1, &1, U32 & String, Unit>
            <- send_wire_method(tls)(sock, octets_string(encoded), ms)
        send_written_result(tls, request, limits, deadline, read_ms, fuel, written)

def send_socket_budget(tls: Bool,
                       sock: Socket,
                       +request: Request,
                       +encoded: List<&2, U32>,
                       +limits: Limits,
                       deadline: Nat,
                       write_ms: U32,
                       read_ms: U32,
                       fuel: U32,
                       budget: Maybe<&2, U32>) -> IO(Result<&1, &1, Error, Response>):
    match budget:
        case None{}: send_fail_closed(tls, sock, Timeout{})
        case Some{ms}: send_socket_action(tls, sock, request, encoded, limits, deadline, read_ms, fuel, ms)

def send_socket(tls: Bool,
                sock: Socket,
                +request: Request,
                +encoded: List<&2, U32>,
                +limits: Limits,
                +deadline: Nat,
                +write_ms: U32,
                read_ms: U32,
                fuel: U32) -> IO(Result<&1, &1, Error, Response>):
    do IO<Result<&1, &1, Error, Response>>:
        budget : Maybe<&2, U32> <- send_budget(deadline, write_ms)
        send_socket_budget(tls, sock, request, encoded, limits, deadline, write_ms, read_ms, fuel, budget)

def send_tls_result(+request: Request,
                    +encoded: List<&2, U32>,
                    +limits: Limits,
                    deadline: Nat,
                    write_ms: U32,
                    read_ms: U32,
                    fuel: U32,
                    result: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Result<&1, &1, Error, Response>):
    (sock, tls_result) = result
    match tls_result:
        case Fail{(+code, message)}:
            do IO<Result<&1, &1, Error, Response>>:
                Socket.close(sock)
                return Fail{send_error_code(code, Tls{})}
        case Done{Unit{}}:
            send_socket(True{}, sock, request, encoded, limits, deadline, write_ms, read_ms, fuel)

def send_tls_budget(sock: Socket,
                    +host: String,
                    +request: Request,
                    +encoded: List<&2, U32>,
                    +limits: Limits,
                    deadline: Nat,
                    write_ms: U32,
                    read_ms: U32,
                    fuel: U32,
                    budget: Maybe<&2, U32>) -> IO(Result<&1, &1, Error, Response>):
    match budget:
        case None{}:
            do IO<Result<&1, &1, Error, Response>>:
                Socket.close(sock)
                return Fail{Timeout{}}
        case Some{ms}:
            do IO<Result<&1, &1, Error, Response>>:
                connected : Socket & Result<&1, &1, U32 & String, Unit>
                    <- Wire.tls.connect(sock, host, ms)
                send_tls_result(request, encoded, limits, deadline, write_ms, read_ms, fuel, connected)

def send_connected_fields(tls: Bool,
                          +host: String,
                          +request: Request,
                          +encoded: List<&2, U32>,
                          +limits: Limits,
                          +deadline: Nat,
                          +options: Options,
                          sock: Socket) -> IO(Result<&1, &1, Error, Response>):
    match tls:
        case False{}: send_socket(False{}, sock, request, encoded, limits, deadline, send_option_write_ms(options), send_option_read_ms(options), send_option_fuel(options))
        case True{}:
            do IO<Result<&1, &1, Error, Response>>:
                budget : Maybe<&2, U32> <- send_budget(deadline, send_option_connect_ms(options))
                send_tls_budget(sock, host, request, encoded, limits, deadline, send_option_write_ms(options), send_option_read_ms(options), send_option_fuel(options), budget)

def send_connected(+target: Target,
                   +request: Request,
                   +encoded: List<&2, U32>,
                   +limits: Limits,
                   deadline: Nat,
                   options: Options,
                   sock: Socket) -> IO(Result<&1, &1, Error, Response>):
    match target:
        case Target{tls, host, port, authority, resource}:
            send_connected_fields(tls, host, request, encoded, limits, deadline, options, sock)

def send_connected_fields_result(tls: Bool,
                                 +host: String,
                                 +request: Request,
                                 +encoded: List<&2, U32>,
                                 +limits: Limits,
                                 deadline: Nat,
                                 options: Options,
                                 result: Result<&1, &1, U32 & String, Socket>) -> IO(Result<&1, &1, Error, Response>):
    match result:
        case Fail{(+code, message)}:
            IO.pure(Result<&1, &1, Error, Response>, Fail{send_error_code(code, Connection{})})
        case Done{sock}: send_connected_fields(tls, host, request, encoded, limits, deadline, options, sock)

def send_resolved_budget(tls: Bool,
                         +host: String,
                         port: U32,
                         +authority: String,
                         +resource: String,
                         +request: Request,
                         +encoded: List<&2, U32>,
                         +limits: Limits,
                         deadline: Nat,
                         options: Options,
                         +ip: String,
                         budget: Maybe<&2, U32>) -> IO(Result<&1, &1, Error, Response>):
    match budget:
        case None{}: IO.pure(Result<&1, &1, Error, Response>, Fail{Timeout{}})
        case Some{ms}:
            do IO<Result<&1, &1, Error, Response>>:
                result : Result<&1, &1, U32 & String, Socket> <- Wire.connect(ip, port, ms)
                send_connected_fields_result(tls, host, request, encoded, limits, deadline, options, result)

def send_resolved(+target: Target,
                  +request: Request,
                  +encoded: List<&2, U32>,
                  +limits: Limits,
                  +deadline: Nat,
                  +options: Options,
                  ip: String) -> IO(Result<&1, &1, Error, Response>):
    match target:
        case Target{tls, host, port, authority, resource}:
            do IO<Result<&1, &1, Error, Response>>:
                budget : Maybe<&2, U32> <- send_budget(deadline, send_option_connect_ms(options))
                send_resolved_budget(tls, host, port, authority, resource, request, encoded, limits, deadline, options, ip, budget)

def send_connected_result(+target: Target,
                          +request: Request,
                          +encoded: List<&2, U32>,
                          +limits: Limits,
                          deadline: Nat,
                          options: Options,
                          result: Result<&1, &1, U32 & String, Socket>) -> IO(Result<&1, &1, Error, Response>):
    match result:
        case Fail{(+code, message)}:
            IO.pure(Result<&1, &1, Error, Response>, Fail{send_error_code(code, Connection{})})
        case Done{sock}:
            send_connected(target, request, encoded, limits, deadline, options, sock)

def send_dns_missing(budget: Maybe<&2, U32>) -> IO(Result<&1, &1, Error, Response>):
    match budget:
        case None{}: IO.pure(Result<&1, &1, Error, Response>, Fail{Timeout{}})
        case Some{ms}: IO.pure(Result<&1, &1, Error, Response>, Fail{Connection{}})

def send_dns_result(+target: Target,
                    +request: Request,
                    +encoded: List<&2, U32>,
                    +limits: Limits,
                    deadline: Nat,
                    options: Options,
                    result: Maybe<&2, String>) -> IO(Result<&1, &1, Error, Response>):
    match result:
        case None{}:
            do IO<Result<&1, &1, Error, Response>>:
                budget : Maybe<&2, U32> <- send_budget(deadline, send_option_connect_ms(options))
                send_dns_missing(budget)
        case Some{ip}: send_resolved(target, request, encoded, limits, deadline, options, ip)

def send_target_budget(+target: Target,
                       +request: Request,
                       +encoded: List<&2, U32>,
                       +limits: Limits,
                       deadline: Nat,
                       options: Options,
                       +host: String,
                       budget: Maybe<&2, U32>) -> IO(Result<&1, &1, Error, Response>):
    match budget:
        case None{}: IO.pure(Result<&1, &1, Error, Response>, Fail{Timeout{}})
        case Some{ms}:
            do IO<Result<&1, &1, Error, Response>>:
                ip : Maybe<&2, String> <- send_dns_target(host, ms)
                send_dns_result(target, request, encoded, limits, deadline, options, ip)

def send_target(+target: Target,
                +request: Request,
                +encoded: List<&2, U32>,
                +limits: Limits,
                +deadline: Nat,
                +options: Options) -> IO(Result<&1, &1, Error, Response>):
    match target:
        case Target{tls, host, port, authority, resource}:
            do IO<Result<&1, &1, Error, Response>>:
                budget : Maybe<&2, U32> <- send_budget(deadline, send_option_connect_ms(options))
                send_target_budget(target, request, encoded, limits, deadline, options, host, budget)

def send_started_url(+request: Request,
                     +options: Options,
                     deadline: Nat,
                     +encoded: List<&2, U32>,
                     parsed: Result<&2, &2, Error, Target>) -> IO(Result<&1, &1, Error, Response>):
    match parsed:
        case Fail{error}: IO.pure(Result<&1, &1, Error, Response>, Fail{error})
        case Done{target}: send_target(target, request, encoded, send_option_limits(options), deadline, options)

def send_started_request(+request: Request,
                         +options: Options,
                         deadline: Nat,
                         +encoded: List<&2, U32>) -> IO(Result<&1, &1, Error, Response>):
    match request:
        case Request{method, url, headers, body}:
            send_started_url(request, options, deadline, encoded, parse_url(url))

def send_started(+request: Request,
                 +options: Options,
                 deadline: Nat,
                 preflight: Result<&1, &1, Error, List<&2, U32>>) -> IO(Result<&1, &1, Error, Response>):
    match preflight:
        case Fail{error}: IO.pure(Result<&1, &1, Error, Response>, Fail{error})
        case Done{encoded}:
            send_started_request(request, options, deadline, encoded)

def send_started_at(+request: Request,
                    +options: Options,
                    preflight: Result<&1, &1, Error, List<&2, U32>>,
                    now: Nat) -> IO(Result<&1, &1, Error, Response>):
    send_started(request, options, Nat.add(now, U32.to_nat(send_option_total_ms(options))), preflight)

def send_selected(+request: Request,
                  +options: Options,
                  options_ok: Bool) -> IO(Result<&1, &1, Error, Response>):
    match options_ok:
        case False{}: IO.pure(Result<&1, &1, Error, Response>, Fail{Configuration{}})
        case True{}:
            do IO<Result<&1, &1, Error, Response>>:
                now : Nat <- IO.now()
                send_started_at(request, options, send_preflight(request, options), now)

def send(+request: Request, +options: Options) -> IO(Result<&1, &1, Error, Response>):
    send_selected(request, options, valid_options(options))
