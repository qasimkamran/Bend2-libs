import Base
import ./LAWS.bend as L
import ./libs/JSON.bend as Json
import ./libs/HTTPClient.bend as HttpClient
import 0xcfc8be7b076f41f95c8e118383892d55/encoding.bend as Encoding
import 0x49814d83de8f70993a43e1002be29ecd/bytes.bend as Bytes
import ./proof/JSON_StringProof.bend as StringProof
import ./proof/JSON_PrimitiveProof.bend as PrimitiveProof
import ./proof/JSON_NumberLexProof.bend as NumberLexProof
import ./proof/JSON_ParallelProof.bend as ParallelProof
import ./proof/JSON_LexWhitespaceProof.bend as LexWhitespaceProof
import ./proof/JSON_AssemblyProof.bend as AssemblyProof
import ./proof/JSON_SourceProof.bend as SourceProof
import ./proof/JSON_RenderLexProof.bend as RenderLexProof

def ResultValue() -> Type:
    Result<&1, &1, Json.Error, Json.Value>

def parse_for_equality(text: String) -> ResultValue():
    Json.parse(text)

def assemble_atom(result: ResultValue()) -> {Json.assemble(Json.Atom{result} <> Nil{}, Json.NeedValue{Json.Top{}}) == result : ResultValue()}:
    match result:
        case Done{value}: {==}
        case Fail{Json.Error{}}: {==}

def parallel_single(+text: String) -> {Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{text} <> Nil{})), Nil{}) == Json.decode_lexeme(Json.Payload{text}) <> Nil{} : List<Json.Token>}:
    Equal.trans(List<Json.Token>, Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{text} <> Nil{})), Nil{}),
        ParallelProof.flat(Json.Payload{text} <> Nil{}, Nil{}), Json.decode_lexeme(Json.Payload{text}) <> Nil{},
        ParallelProof.decode(Json.Payload{text} <> Nil{}, Nil{}), {==})

def assemble_source(+value: Json.Value) -> {Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.source(value, False{}, Nil{}))), Nil{}), Json.NeedValue{Json.Top{}}) == Done{value} : ResultValue()}:
    Equal.trans(ResultValue(),
        Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.source(value, False{}, Nil{}))), Nil{}), Json.NeedValue{Json.Top{}}),
        Json.assemble(AssemblyProof.tokens(value, AssemblyProof.Whole{}, Nil{}), AssemblyProof.start(value, AssemblyProof.Whole{}, Nil{}, Nil{}, Json.Top{})),
        Done{value},
        Equal.cong(List<Json.Token>, ResultValue(), tokens => Json.assemble(tokens, Json.NeedValue{Json.Top{}}),
            Json.token_list(Json.decode_tree(Json.lex_tree(Json.source(value, False{}, Nil{}))), Nil{}),
            AssemblyProof.tokens(value, AssemblyProof.Whole{}, Nil{}),
            Equal.trans(List<Json.Token>,
                Json.token_list(Json.decode_tree(Json.lex_tree(Json.source(value, False{}, Nil{}))), Nil{}),
                SourceProof.token_source(Json.source(value, False{}, Nil{}), Nil{}),
                AssemblyProof.tokens(value, AssemblyProof.Whole{}, Nil{}),
                Equal.trans(List<Json.Token>,
                    Json.token_list(Json.decode_tree(Json.lex_tree(Json.source(value, False{}, Nil{}))), Nil{}),
                    ParallelProof.flat(Json.source(value, False{}, Nil{}), Nil{}),
                    SourceProof.token_source(Json.source(value, False{}, Nil{}), Nil{}),
                    ParallelProof.decode(Json.source(value, False{}, Nil{}), Nil{}),
                    Equal.sym(List<Json.Token>, SourceProof.token_source(Json.source(value, False{}, Nil{}), Nil{}),
                        ParallelProof.flat(Json.source(value, False{}, Nil{}), Nil{}),
                        SourceProof.token_source_flat(Json.source(value, False{}, Nil{}), Nil{}))),
                SourceProof.source_tokens(value, AssemblyProof.Whole{}, Nil{}, Nil{}))),
        Equal.trans(ResultValue(),
            Json.assemble(AssemblyProof.tokens(value, AssemblyProof.Whole{}, Nil{}), AssemblyProof.start(value, AssemblyProof.Whole{}, Nil{}, Nil{}, Json.Top{})),
            Json.assemble(Nil{}, Json.assembly_resume(Json.Top{}, value)),
            Done{value},
            AssemblyProof.roundtrip(value, AssemblyProof.Whole{}, Nil{}, Nil{}, Nil{}, Json.Top{}), {==}))

def parse_number_payload(+text: String,
                         +certificate: Json.NumberCert<text>) -> {Json.parse_normalized(text) == Done{Json.Number{text, certificate}} : ResultValue()}:
    Equal.trans(ResultValue(), Json.parse_normalized(text),
        Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{text} <> Nil{})), Nil{}), Json.NeedValue{Json.Top{}}),
        Done{Json.Number{text, certificate}},
        Equal.cong(List<&2, Json.Lexeme>, ResultValue(), items => Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
            Json.lex_scan(text, Json.Outside{}, SNil{}, Nil{}), Json.Payload{text} <> Nil{},
            NumberLexProof.lex_number_payload(text, PrimitiveProof.cert_valid(text, certificate))),
        Equal.trans(ResultValue(),
            Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{text} <> Nil{})), Nil{}), Json.NeedValue{Json.Top{}}),
            Json.decode_payload(text), Done{Json.Number{text, certificate}},
            Equal.trans(ResultValue(),
                Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{text} <> Nil{})), Nil{}), Json.NeedValue{Json.Top{}}),
                Json.assemble(Json.decode_lexeme(Json.Payload{text}) <> Nil{}, Json.NeedValue{Json.Top{}}),
                Json.decode_payload(text),
                Equal.cong(List<Json.Token>, ResultValue(), tokens => Json.assemble(tokens, Json.NeedValue{Json.Top{}}),
                    Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{text} <> Nil{})), Nil{}),
                    Json.decode_lexeme(Json.Payload{text}) <> Nil{},
                    parallel_single(text)),
                Equal.trans(ResultValue(),
                    Json.assemble(Json.decode_lexeme(Json.Payload{text}) <> Nil{}, Json.NeedValue{Json.Top{}}),
                    Json.decode_payload(text), Json.decode_payload(text),
                    assemble_atom(Json.decode_payload(text)), {==})),
            PrimitiveProof.number_roundtrip(text, certificate)))

def assembled_string_payload(+text: String) -> {Json.assemble(Json.Atom{Json.decode_payload("\"" ++ Json.escape_string(text) ++ "\"")} <> Nil{}, Json.NeedValue{Json.Top{}}) == Done{Json.Str{text}} : ResultValue()}:
    Equal.cong(ResultValue(), ResultValue(), result => Json.assemble(Json.Atom{result} <> Nil{}, Json.NeedValue{Json.Top{}}),
        Json.decode_payload("\"" ++ Json.escape_string(text) ++ "\""), Done{Json.Str{text}}, StringProof.string_payload(text))

def parse_string_payload(+text: String) -> {Json.parse_normalized("\"" ++ Json.escape_string(text) ++ "\"") == Done{Json.Str{text}} : ResultValue()}:
    Equal.trans(ResultValue(), Json.parse_normalized("\"" ++ Json.escape_string(text) ++ "\""),
        Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{"\"" ++ Json.escape_string(text) ++ "\""} <> Nil{})), Nil{}), Json.NeedValue{Json.Top{}}),
        Done{Json.Str{text}},
        Equal.cong(List<&2, Json.Lexeme>, ResultValue(), items => Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
            Json.lex_scan("\"" ++ Json.escape_string(text) ++ "\"", Json.Outside{}, SNil{}, Nil{}),
            Json.Payload{"\"" ++ Json.escape_string(text) ++ "\""} <> Nil{},
            LexWhitespaceProof.lex_rendered_string(text)),
        Equal.trans(ResultValue(),
            Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{"\"" ++ Json.escape_string(text) ++ "\""} <> Nil{})), Nil{}), Json.NeedValue{Json.Top{}}),
            Json.assemble(Json.decode_lexeme(Json.Payload{"\"" ++ Json.escape_string(text) ++ "\""}) <> Nil{}, Json.NeedValue{Json.Top{}}),
            Done{Json.Str{text}},
            Equal.cong(List<Json.Token>, ResultValue(), tokens => Json.assemble(tokens, Json.NeedValue{Json.Top{}}),
                Json.token_list(Json.decode_tree(Json.lex_tree(Json.Payload{"\"" ++ Json.escape_string(text) ++ "\""} <> Nil{})), Nil{}),
                Json.decode_lexeme(Json.Payload{"\"" ++ Json.escape_string(text) ++ "\""}) <> Nil{},
                parallel_single("\"" ++ Json.escape_string(text) ++ "\"")),
            assembled_string_payload(text)))

def parse_leading_space(+text: String) -> {Json.parse(" " ++ text) == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    {==}

def parse_trailing_space(+text: String) -> {Json.parse(text ++ " ") == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.cong(List<&2, Json.Lexeme>, ResultValue(),
        items => Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
        Json.lex_scan(text ++ " ", Json.Outside{}, SNil{}, Nil{}),
        Json.lex_scan(text, Json.Outside{}, SNil{}, Nil{}),
        LexWhitespaceProof.trailing_space(text, Json.Outside{}, SNil{}, Nil{}))

def parse_trailing_tab(+text: String) -> {Json.parse(text ++ "\t") == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.cong(List<&2, Json.Lexeme>, ResultValue(),
        items => Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
        Json.lex_scan(text ++ "\t", Json.Outside{}, SNil{}, Nil{}),
        Json.lex_scan(text, Json.Outside{}, SNil{}, Nil{}),
        LexWhitespaceProof.trailing_tab(text, Json.Outside{}, SNil{}, Nil{}))

def parse_trailing_return(+text: String) -> {Json.parse(text ++ "\r") == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.cong(List<&2, Json.Lexeme>, ResultValue(),
        items => Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
        Json.lex_scan(text ++ "\r", Json.Outside{}, SNil{}, Nil{}),
        Json.lex_scan(text, Json.Outside{}, SNil{}, Nil{}),
        LexWhitespaceProof.trailing_return(text, Json.Outside{}, SNil{}, Nil{}))

def parse_trailing_newline(+text: String) -> {Json.parse(text ++ "\n") == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.cong(List<&2, Json.Lexeme>, ResultValue(),
        items => Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
        Json.lex_scan(text ++ "\n", Json.Outside{}, SNil{}, Nil{}),
        Json.lex_scan(text, Json.Outside{}, SNil{}, Nil{}),
        LexWhitespaceProof.trailing_newline(text, Json.Outside{}, SNil{}, Nil{}))

def parse_suffix_space(+text: String,
                       +suffix: String) -> {Json.parse(text ++ (suffix ++ " ")) == Json.parse(text ++ suffix) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.trans(ResultValue(), Json.parse(text ++ (suffix ++ " ")), Json.parse((text ++ suffix) ++ " "), Json.parse(text ++ suffix),
        Equal.sym(ResultValue(), Json.parse((text ++ suffix) ++ " "), Json.parse(text ++ (suffix ++ " ")),
            Equal.cong(String, ResultValue(), parse_for_equality, (text ++ suffix) ++ " ", text ++ (suffix ++ " "), StringProof.append_assoc(text, suffix, " "))),
        parse_trailing_space(text ++ suffix))

def parse_suffix_tab(+text: String,
                     +suffix: String) -> {Json.parse(text ++ (suffix ++ "\t")) == Json.parse(text ++ suffix) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.trans(ResultValue(), Json.parse(text ++ (suffix ++ "\t")), Json.parse((text ++ suffix) ++ "\t"), Json.parse(text ++ suffix),
        Equal.sym(ResultValue(), Json.parse((text ++ suffix) ++ "\t"), Json.parse(text ++ (suffix ++ "\t")),
            Equal.cong(String, ResultValue(), parse_for_equality, (text ++ suffix) ++ "\t", text ++ (suffix ++ "\t"), StringProof.append_assoc(text, suffix, "\t"))),
        parse_trailing_tab(text ++ suffix))

def parse_suffix_return(+text: String,
                        +suffix: String) -> {Json.parse(text ++ (suffix ++ "\r")) == Json.parse(text ++ suffix) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.trans(ResultValue(), Json.parse(text ++ (suffix ++ "\r")), Json.parse((text ++ suffix) ++ "\r"), Json.parse(text ++ suffix),
        Equal.sym(ResultValue(), Json.parse((text ++ suffix) ++ "\r"), Json.parse(text ++ (suffix ++ "\r")),
            Equal.cong(String, ResultValue(), parse_for_equality, (text ++ suffix) ++ "\r", text ++ (suffix ++ "\r"), StringProof.append_assoc(text, suffix, "\r"))),
        parse_trailing_return(text ++ suffix))

def parse_suffix_newline(+text: String,
                         +suffix: String) -> {Json.parse(text ++ (suffix ++ "\n")) == Json.parse(text ++ suffix) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.trans(ResultValue(), Json.parse(text ++ (suffix ++ "\n")), Json.parse((text ++ suffix) ++ "\n"), Json.parse(text ++ suffix),
        Equal.sym(ResultValue(), Json.parse((text ++ suffix) ++ "\n"), Json.parse(text ++ (suffix ++ "\n")),
            Equal.cong(String, ResultValue(), parse_for_equality, (text ++ suffix) ++ "\n", text ++ (suffix ++ "\n"), StringProof.append_assoc(text, suffix, "\n"))),
        parse_trailing_newline(text ++ suffix))

def parse_leading_surround(+text: String) -> {Json.parse(" \n\t\r" ++ text) == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    {==}

def parse_surrounding_space(+text: String) -> {Json.parse(" \n\t\r" ++ text ++ "\r\t\n ") == Json.parse(text) : Result<&1, &1, Json.Error, Json.Value>}:
    Equal.trans(ResultValue(), Json.parse(" \n\t\r" ++ text ++ "\r\t\n "), Json.parse(text ++ "\r\t\n "), Json.parse(text),
        parse_leading_surround(text ++ "\r\t\n "),
        Equal.trans(ResultValue(), Json.parse(text ++ "\r\t\n "), Json.parse(text ++ "\r\t\n"), Json.parse(text),
            parse_suffix_space(text, "\r\t\n"),
            Equal.trans(ResultValue(), Json.parse(text ++ "\r\t\n"), Json.parse(text ++ "\r\t"), Json.parse(text),
                parse_suffix_newline(text, "\r\t"),
                Equal.trans(ResultValue(), Json.parse(text ++ "\r\t"), Json.parse(text ++ "\r"), Json.parse(text),
                    parse_suffix_tab(text, "\r"), parse_trailing_return(text)))))

def L.parses_null():
    {==}

def L.parses_true():
    {==}

def L.parses_false():
    {==}

def L.rejects_trailing_garbage():
    {==}

def L.rejects_second_value():
    {==}

def L.rejects_invalid_null():
    {==}

def L.rejects_invalid_true():
    {==}

def L.rejects_invalid_false():
    {==}

def L.rejects_empty_input():
    {==}

def L.rejects_whitespace_only():
    {==}

def L.parses_empty_string():
    {==}

def L.parses_simple_string():
    {==}

def L.parses_newline_escape():
    {==}

def L.parses_quote_escape():
    {==}

def L.parses_backslash_escape():
    {==}

def L.rejects_unterminated_string():
    {==}

def L.parses_empty_array():
    {==}

def L.parses_literal_array():
    {==}

def L.rejects_array_trailing_comma():
    {==}

def L.parses_empty_object():
    {==}

def L.rejects_unquoted_object_key():
    {==}

def L.rejects_object_trailing_comma():
    {==}

def L.parses_nested_containers():
    {==}

def L.rejects_non_json_whitespace():
    {==}

def L.rejects_raw_string_control():
    {==}

def L.parses_unicode_escape():
    {==}

def L.parses_unicode_surrogate_pair():
    {==}

def L.parses_fraction_and_exponent():
    {==}

def L.rejects_malformed_number_forms():
    {==}

def L.preserves_array_order():
    {==}

def L.preserves_object_order_and_duplicates():
    {==}

def L.gpu_single_matches_cpu(text):
    {==}

def L.preserves_number_lexeme():
    {==}

def L.gpu_batch_matches_cpu(batch):
    {==}


def L.stringify_parse_roundtrip(value):
    +v = value
    Equal.trans(ResultValue(), Json.parse(Json.stringify(v)),
        Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(Json.source(v, False{}, Nil{}))), Nil{}), Json.NeedValue{Json.Top{}}),
        Done{v},
        Equal.cong(List<&2, Json.Lexeme>, ResultValue(), items =>
            Json.assemble(Json.token_list(Json.decode_tree(Json.lex_tree(items)), Nil{}), Json.NeedValue{Json.Top{}}),
            Json.lex_scan(Json.stringify(v), Json.Outside{}, SNil{}, Nil{}),
            Json.source(v, False{}, Nil{}), RenderLexProof.lex_source(v)),
        assemble_source(v))

def L.accepts_leading_space(value):
    +v = value
    Equal.trans(Result<&1, &1, Json.Error, Json.Value>, Json.parse(" " ++ Json.stringify(v)), Json.parse(Json.stringify(v)), Done{v}, parse_leading_space(Json.stringify(v)), L.stringify_parse_roundtrip(v))

def L.accepts_trailing_space(value):
    +v = value
    Equal.trans(Result<&1, &1, Json.Error, Json.Value>, Json.parse(Json.stringify(v) ++ " "), Json.parse(Json.stringify(v)), Done{v}, parse_trailing_space(Json.stringify(v)), L.stringify_parse_roundtrip(v))

def L.accepts_surrounding_space(value):
    +v = value
    Equal.trans(Result<&1, &1, Json.Error, Json.Value>, Json.parse(" \n\t\r" ++ Json.stringify(v) ++ "\r\t\n "), Json.parse(Json.stringify(v)), Done{v}, parse_surrounding_space(Json.stringify(v)), L.stringify_parse_roundtrip(v))

def L.http_utf8_octets():
    {==}



def L.http_binary_boundaries():
    {==}

def L.http_reject_non_octet():
    {==}

def L.http_https_target():
    {==}

def L.http_http_default_path():
    {==}

def L.http_query_without_path():
    {==}

def L.http_nondefault_port():
    {==}

def L.http_explicit_default_port():
    {==}

def L.http_signed_path_unchanged():
    {==}

def L.http_reject_unsupported_scheme():
    {==}

def L.http_reject_userinfo():
    {==}

def L.http_reject_empty_host():
    {==}

def L.http_reject_port_overflow():
    {==}

def L.http_reject_port_zero():
    {==}

def L.http_reject_relative_url():
    {==}

def L.http_reject_url_injection():
    {==}

def L.http_reject_url_space():
    {==}

def L.http_header_lookup_case_insensitive():
    {==}

def L.http_header_lookup_missing():
    {==}

def L.http_encode_get():
    {==}

def L.http_encode_head():
    {==}

def L.http_encode_post():
    {==}

def L.http_encode_put():
    {==}

def L.http_encode_patch():
    {==}

def L.http_encode_delete():
    {==}

def L.http_encode_options():
    {==}

def L.http_utf8_content_length():
    {==}

def L.http_reserved_host():
    {==}

def L.http_reserved_content_length():
    {==}

def L.http_reserved_transfer_encoding():
    {==}

def L.http_reserved_connection():
    {==}

def L.http_reserved_accept_encoding():
    {==}

def L.http_reserved_expect():
    {==}

def L.http_reserved_upgrade():
    {==}

def L.http_reserved_trailer():
    {==}

def L.http_bad_header_name():
    {==}

def L.http_header_name_injection():
    {==}

def L.http_header_value_injection():
    {==}

def L.http_header_nul():
    {==}

def L.http_unsupported_method():
    {==}

def L.http_body_non_octet():
    {==}

def http_encode_accepts_valid_body(+body: List<&2, U32>,
                                   valid: {HttpClient.valid_bytes(body) == True{} : Bool}) -> {HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, HttpClient.valid_bytes(body), Done{Unit{}}) == HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, True{}, Done{Unit{}}) : Result<&2, &2, HttpClient.Error, List<&2, U32>>}:
    Equal.cong(Bool, Result<&2, &2, HttpClient.Error, List<&2, U32>>,
        ok => HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, ok, Done{Unit{}}),
        HttpClient.valid_bytes(body), True{}, valid)

def http_length_same(+body: List<&2, U32>) -> {List.length(&2, U32, body) == L.http_length(body) : Nat}:
    match body:
        case Nil{}: {==}
        case _ <> tail:
            Equal.cong(Nat, Nat, length => (1n + length : Nat),
                List.length(&2, U32, tail), L.http_length(tail), http_length_same(tail))

def append_bytes_assoc(+x: List<&2, U32>,
                       +y: List<&2, U32>,
                       +z: List<&2, U32>) -> {HttpClient.append_bytes(HttpClient.append_bytes(x, y), z) == HttpClient.append_bytes(x, HttpClient.append_bytes(y, z)) : List<&2, U32>}:
    match x:
        case Nil{}: {==}
        case h <> t:
            Equal.cong(List<&2, U32>, List<&2, U32>, rest => h <> rest,
                HttpClient.append_bytes(HttpClient.append_bytes(t, y), z), HttpClient.append_bytes(t, HttpClient.append_bytes(y, z)),
                append_bytes_assoc(t, y, z))

def utf8_append_same(+x: String,
                     +y: String) -> {HttpClient.utf8(x ++ y) == HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.utf8(y)) : List<&2, U32>}:
    match x:
        case SNil{}: {==}
        case SCon{Chr{+c}, rest}:
            Equal.trans(List<&2, U32>, HttpClient.utf8(x ++ y),
                HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.utf8(rest ++ y)),
                HttpClient.append_bytes(HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.utf8(rest)), HttpClient.utf8(y)),
                {==},
                Equal.trans(List<&2, U32>,
                    HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.utf8(rest ++ y)),
                    HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.append_bytes(HttpClient.utf8(rest), HttpClient.utf8(y))),
                    HttpClient.append_bytes(HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.utf8(rest)), HttpClient.utf8(y)),
                    Equal.cong(List<&2, U32>, List<&2, U32>, tail => HttpClient.append_bytes(HttpClient.utf8_char(c), tail),
                        HttpClient.utf8(rest ++ y), HttpClient.append_bytes(HttpClient.utf8(rest), HttpClient.utf8(y)), utf8_append_same(rest, y)),
                    Equal.sym(List<&2, U32>,
                        HttpClient.append_bytes(HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.utf8(rest)), HttpClient.utf8(y)),
                        HttpClient.append_bytes(HttpClient.utf8_char(c), HttpClient.append_bytes(HttpClient.utf8(rest), HttpClient.utf8(y))),
                    append_bytes_assoc(HttpClient.utf8_char(c), HttpClient.utf8(rest), HttpClient.utf8(y)))))



def L.http_json_error_response():
    {==}

def L.http_json_empty():
    {==}

def L.http_json_trailing():
    {==}

def L.http_json_compressed():
    {==}

def L.http_json_invalid_utf8():
    {==}

def L.http_partial_write():
    {==}

def L.http_full_write():
    {==}

def L.http_empty_write():
    {==}

def L.http_zero_write_progress():
    {==}

def L.http_write_overreport():
    {==}

def L.http_empty_batch_builder():
    {==}

def L.http_empty_gpu_many():
    {==}

def L.http_singleton_batch_builder(work):
    +item = work
    {==}

def L.http_singleton_gpu_many(work):
    +item = work
    {==}

def L.http_gpu_decode_matches_cpu(method, limits, bytes, eof):
    {==}


def L.http_work_encode_uses_codec(request):
    +req = request
    {==}

def L.http_work_decode_uses_codec(method, limits, bytes, eof):
    {==}

def L.http_batch_leaf(work):
    +job = work
    {==}

def L.http_batch_fork(left, right):
    +l = left
    +r = right
    {==}

def L.http_flatten_leaf(outcome):
    +result = outcome
    {==}


def L.http_content_length():
    {==}

def L.http_preserve_remainder():
    {==}

def L.http_partial_body():
    {==}

def L.http_truncated_body():
    {==}

def L.http_incomplete_headers():
    {==}

def L.http_empty_eof():
    {==}

def L.http_close_delimited_waits():
    {==}

def L.http_close_delimited_eof():
    {==}

def L.http_head_ignores_length():
    {==}

def L.http_no_content():
    {==}

def L.http_not_modified():
    {==}

def L.http_reset_content_still_framed():
    {==}

def L.http_reject_duplicate_equal_length():
    {==}

def L.http_reject_conflicting_length():
    {==}

def L.http_reject_length_list():
    {==}

def L.http_reject_te_and_cl():
    {==}

def L.http_reject_negative_length():
    {==}

def L.http_reject_huge_length():
    {==}

def L.http_reject_bad_transfer_coding():
    {==}


def L.http_reject_bare_lf():
    {==}

def L.http_reject_obsolete_fold():
    {==}

def L.http_reject_space_before_colon():
    {==}

def L.http_reject_invalid_status():
    {==}

def L.http_reject_invalid_version():
    {==}

def L.http_accept_http_10_response():
    {==}

def L.http_reject_upgrade():
    {==}

def L.http_body_limit_exact():
    {==}

def L.http_body_limit_over():
    {==}

def L.http_header_bytes_exact():
    {==}

def L.http_header_bytes_over():
    {==}

def L.http_wire_bytes_exact():
    {==}

def L.http_wire_bytes_over():
    {==}

def L.http_wire_bytes_excludes_remainder():
    {==}

def L.http_header_count_over():
    {==}

def L.http_reject_empty_port():
    {==}

def L.http_reject_invalid_escape():
    {==}

def L.http_reject_unsupported_ipv6():
    {==}

def L.http_header_value_trimming():
    {==}

def L.http_close_body_limit_over():
    {==}

def L.http_status_301_is_response():
    {==}

def L.http_status_400_is_response():
    {==}

def L.http_status_401_is_response():
    {==}

def L.http_status_403_is_response():
    {==}

def L.http_status_404_is_response():
    {==}

def L.http_status_429_is_response():
    {==}

def L.http_status_500_is_response():
    {==}

def L.http_status_503_is_response():
    {==}

def L.http_skip_interim():
    {==}

def L.http_interim_without_final():
    {==}

def L.http_interim_count_over():
    {==}

def L.http_chunked():
    {==}

def L.http_chunk_extensions_trailers():
    {==}

def L.http_uppercase_hex_chunk():
    {==}

def L.http_chunk_truncation():
    {==}

def L.http_chunk_incomplete():
    {==}

def L.http_missing_final_chunk():
    {==}

def L.http_unfinished_trailers():
    {==}

def L.http_reject_huge_chunk():
    {==}

def L.http_reject_repeated_chunked():
    {==}

def L.http_reject_bad_chunk_size():
    {==}

def L.http_reject_bad_chunk_terminator():
    {==}

def L.http_reject_forbidden_trailer():
    {==}

def L.http_chunk_body_limit_over():
    {==}

def L.http_trailer_count_over():
    {==}

def L.http_trailer_bytes_over():
    {==}

def L.http_chunk_line_bytes_over():
    {==}

def L.http_gpu_encode_matches_cpu(request):
    {==}

def http_append_outcomes_same(+xs: List<&2, HttpClient.Outcome>,
                              +ys: List<&2, HttpClient.Outcome>) -> {HttpClient.append_outcomes(xs, ys) == L.http_append_outcomes(xs, ys) : List<&2, HttpClient.Outcome>}:
    match xs:
        case Nil{}: {==}
        case Con{outcome, rest}:
            Equal.cong(List<&2, HttpClient.Outcome>, List<&2, HttpClient.Outcome>, tail => outcome <> tail,
                HttpClient.append_outcomes(rest, ys), L.http_append_outcomes(rest, ys), http_append_outcomes_same(rest, ys))

def L.http_flatten_fork(left, right):
    match left:
        case HttpClient.LeafResult{outcome}: {==}
        case HttpClient.ForkResult{inner_left, inner_right}:
            http_append_outcomes_same(HttpClient.append_outcomes(HttpClient.flatten_results(inner_left), HttpClient.flatten_results(inner_right)),
                HttpClient.flatten_results(right))

def flatten_empty_edges(+bytes: List<&2, U32>) -> {HttpClient.flatten_bytes([Nil{}, bytes, Nil{}]) == bytes : List<&2, U32>}:
    match bytes:
        case Nil{}: {==}
        case _ <> _: {==}

def append_bytes_nil(+bytes: List<&2, U32>) -> {HttpClient.append_bytes(bytes, Nil{}) == bytes : List<&2, U32>}:
    match bytes:
        case Nil{}: {==}
        case head <> tail:
            Equal.cong(List<&2, U32>, List<&2, U32>, rest => head <> rest,
                HttpClient.append_bytes(tail, Nil{}), tail, append_bytes_nil(tail))

def flatten_bytes_pair(+left: List<&2, U32>,
                       +right: List<&2, U32>) -> {HttpClient.flatten_bytes([left, right]) == HttpClient.append_bytes(left, right) : List<&2, U32>}:
    match left right:
        case Nil{} Nil{}: {==}
        case Nil{} head <> tail: {==}
        case head <> tail Nil{}:
            Equal.sym(List<&2, U32>, HttpClient.append_bytes(left, Nil{}), left, append_bytes_nil(left))
        case _ <> _ _ <> _: {==}

def append_bytes_same(+left: List<&2, U32>,
                      +right: List<&2, U32>) -> {HttpClient.append_bytes(left, right) == L.http_append(left, right) : List<&2, U32>}:
    match left:
        case Nil{}: {==}
        case head <> tail:
            Equal.cong(List<&2, U32>, List<&2, U32>, rest => head <> rest,
                HttpClient.append_bytes(tail, right), L.http_append(tail, right), append_bytes_same(tail, right))

def string_append_assoc(+x: String,
                        +y: String,
                        +z: String) -> {(x ++ y) ++ z == x ++ (y ++ z) : String}:
    match x:
        case SNil{}: {==}
        case SCon{head, tail}:
            Equal.cong(String, String, rest => SCon{head, rest},
                (tail ++ y) ++ z, tail ++ (y ++ z), string_append_assoc(tail, y, z))

def http_concat_tail(+x: String,
                     +y: String,
                     +body: List<&2, U32>) -> {HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.append_bytes(HttpClient.utf8(y), body)) == L.http_append(HttpClient.utf8(x ++ y), body) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.append_bytes(HttpClient.utf8(y), body)),
        HttpClient.append_bytes(HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.utf8(y)), body),
        L.http_append(HttpClient.utf8(x ++ y), body),
        Equal.sym(List<&2, U32>,
            HttpClient.append_bytes(HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.utf8(y)), body),
            HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.append_bytes(HttpClient.utf8(y), body)),
            append_bytes_assoc(HttpClient.utf8(x), HttpClient.utf8(y), body)),
        Equal.trans(List<&2, U32>,
            HttpClient.append_bytes(HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.utf8(y)), body),
            HttpClient.append_bytes(HttpClient.utf8(x ++ y), body),
            L.http_append(HttpClient.utf8(x ++ y), body),
            Equal.cong(List<&2, U32>, List<&2, U32>, head => HttpClient.append_bytes(head, body),
                HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.utf8(y)), HttpClient.utf8(x ++ y),
                Equal.sym(List<&2, U32>, HttpClient.utf8(x ++ y),
                    HttpClient.append_bytes(HttpClient.utf8(x), HttpClient.utf8(y)), utf8_append_same(x, y))),
            append_bytes_same(HttpClient.utf8(x ++ y), body)))

def http_encode_body_core(+body: List<&2, U32>) -> {HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, True{}, Done{Unit{}}) == Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ Nat.show(List.length(&2, U32, body)) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)} : Result<&2, &2, HttpClient.Error, List<&2, U32>>}:
    Equal.trans(Result<&2, &2, HttpClient.Error, List<&2, U32>>,
        HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, True{}, Done{Unit{}}),
        Done{HttpClient.append_bytes(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: "),
            L.http_append(HttpClient.utf8((Nat.show(List.length(&2, U32, body)) ++ "\r\n") ++
                "Accept-Encoding: identity\r\nConnection: close\r\n\r\n"), body))},
        Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ Nat.show(List.length(&2, U32, body)) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)},
    Equal.cong(List<&2, U32>, Result<&2, &2, HttpClient.Error, List<&2, U32>>,
        tail => Done{HttpClient.append_bytes(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: "), tail)},
        HttpClient.append_bytes(HttpClient.utf8(Nat.show(List.length(&2, U32, body)) ++ "\r\n"),
            HttpClient.append_bytes(HttpClient.utf8("Accept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)),
        L.http_append(HttpClient.utf8((Nat.show(List.length(&2, U32, body)) ++ "\r\n") ++ "Accept-Encoding: identity\r\nConnection: close\r\n\r\n"), body),
        http_concat_tail(Nat.show(List.length(&2, U32, body)) ++ "\r\n",
            "Accept-Encoding: identity\r\nConnection: close\r\n\r\n", body)),
    Equal.cong(String, Result<&2, &2, HttpClient.Error, List<&2, U32>>,
        text => Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ text), body)},
        (Nat.show(List.length(&2, U32, body)) ++ "\r\n") ++ "Accept-Encoding: identity\r\nConnection: close\r\n\r\n",
        Nat.show(List.length(&2, U32, body)) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n",
        string_append_assoc(Nat.show(List.length(&2, U32, body)), "\r\n",
            "Accept-Encoding: identity\r\nConnection: close\r\n\r\n")))

def L.http_encode_arbitrary_body(body, valid):
    Equal.trans(Result<&2, &2, HttpClient.Error, List<&2, U32>>,
        HttpClient.encode(HttpClient.Request{"POST", "https://example.com/", Nil{}, body}),
        HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, True{}, Done{Unit{}}),
        Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ Nat.show(L.http_length(body)) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)},
        http_encode_accepts_valid_body(body, valid),
        Equal.trans(Result<&2, &2, HttpClient.Error, List<&2, U32>>,
            HttpClient.encode_checked("POST", HttpClient.Target{True{}, "example.com", 443, "example.com", "/"}, Nil{}, body, True{}, True{}, Done{Unit{}}),
            Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ Nat.show(List.length(&2, U32, body)) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)},
            Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ Nat.show(L.http_length(body)) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)},
            http_encode_body_core(body),
            Equal.cong(Nat, Result<&2, &2, HttpClient.Error, List<&2, U32>>,
                length => Done{L.http_append(HttpClient.utf8("POST / HTTP/1.1\r\nHost: example.com\r\nContent-Length: " ++ Nat.show(length) ++ "\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n"), body)},
                List.length(&2, U32, body), L.http_length(body), http_length_same(body))))

def L.http_decode_partition_invariant(method, limits, left, right, eof):
    +m = method
    +l = limits
    +e = eof
    Equal.trans(HttpClient.Decode, HttpClient.decode_parts(m, l, [left, right], e),
        HttpClient.decode(m, l, HttpClient.append_bytes(left, right), e),
        HttpClient.decode(m, l, L.http_append(left, right), e),
        Equal.cong(List<&2, U32>, HttpClient.Decode, raw => HttpClient.decode(m, l, raw, e),
            HttpClient.flatten_bytes([left, right]), HttpClient.append_bytes(left, right), flatten_bytes_pair(left, right)),
        Equal.cong(List<&2, U32>, HttpClient.Decode, raw => HttpClient.decode(m, l, raw, e),
            HttpClient.append_bytes(left, right), L.http_append(left, right), append_bytes_same(left, right)))

def L.http_decode_empty_fragments(method, limits, bytes, eof):
    +m = method
    +l = limits
    +e = eof
    Equal.cong(List<&2, U32>, HttpClient.Decode, raw => HttpClient.decode(m, l, raw, e),
        HttpClient.flatten_bytes([Nil{}, bytes, Nil{}]), bytes, flatten_empty_edges(bytes))

def http_read_json_select_parity(+text: String,
                                 encoding_ok: Bool,
                                 is_utf8: Bool) -> {HttpClient.read_json_select(text, encoding_ok, is_utf8, True{}) == HttpClient.read_json_select(text, encoding_ok, is_utf8, False{}) : Result<&1, &1, HttpClient.Error, Json.Value>}:
    match encoding_ok is_utf8:
        case False{} _: {==}
        case True{} False{}: {==}
        case True{} True{}:
            Equal.cong(Result<&1, &1, Json.Error, Json.Value>, Result<&1, &1, HttpClient.Error, Json.Value>, parsed => HttpClient.read_json_parsed(parsed),
                Json.parse_gpu(text), Json.parse(text), L.gpu_single_matches_cpu(text))

def L.http_gpu_json_matches_cpu(response):
    match response:
        case HttpClient.Response{status, headers, +body, trailers}:
            +values = HttpClient.field_values("content-encoding", headers)
            +text = Encoding.utf8.decode(Bytes.from_string(HttpClient.octets_string(body)))
            http_read_json_select_parity(text, HttpClient.identity_encoding(values),
                Bool.and(HttpClient.valid_bytes(body), HttpClient.byte_lists_equal(HttpClient.utf8(text), body)))

def L.http_gpu_batch_matches_cpu(batch):
    {==}

def http_expected_batch(batch: HttpClient.Batch) -> List<&2, HttpClient.Outcome>:
    match batch:
        case HttpClient.Leaf{work}: [L.http_expected_outcome(work)]
        case HttpClient.Fork{+left, +right}:
            L.http_append_outcomes(http_expected_batch(left), http_expected_batch(right))

def http_run_work_expected(work: HttpClient.Work) -> {HttpClient.run_work(work) == L.http_expected_outcome(work) : HttpClient.Outcome}:
    match work:
        case HttpClient.EncodeWork{request}: {==}
        case HttpClient.DecodeWork{method, limits, bytes, eof}: {==}

def http_batch_cpu_expected(+batch: HttpClient.Batch) -> {HttpClient.flatten_results(HttpClient.run_batch(batch)) == http_expected_batch(batch) : List<&2, HttpClient.Outcome>}:
    match batch:
        case HttpClient.Leaf{work}:
            Equal.cong(HttpClient.Outcome, List<&2, HttpClient.Outcome>, outcome => [outcome],
                HttpClient.run_work(work), L.http_expected_outcome(work), http_run_work_expected(work))
        case HttpClient.Fork{+left, +right}:
            Equal.trans(List<&2, HttpClient.Outcome>,
                HttpClient.flatten_results(HttpClient.run_batch(batch)),
                L.http_append_outcomes(HttpClient.flatten_results(HttpClient.run_batch(left)), HttpClient.flatten_results(HttpClient.run_batch(right))),
                http_expected_batch(batch),
                L.http_flatten_fork(HttpClient.run_batch(left), HttpClient.run_batch(right)),
                Equal.trans(List<&2, HttpClient.Outcome>,
                    L.http_append_outcomes(HttpClient.flatten_results(HttpClient.run_batch(left)), HttpClient.flatten_results(HttpClient.run_batch(right))),
                    L.http_append_outcomes(http_expected_batch(left), HttpClient.flatten_results(HttpClient.run_batch(right))),
                    http_expected_batch(batch),
                    Equal.cong(List<&2, HttpClient.Outcome>, List<&2, HttpClient.Outcome>, xs => L.http_append_outcomes(xs, HttpClient.flatten_results(HttpClient.run_batch(right))),
                        HttpClient.flatten_results(HttpClient.run_batch(left)), http_expected_batch(left), http_batch_cpu_expected(left)),
                    Equal.cong(List<&2, HttpClient.Outcome>, List<&2, HttpClient.Outcome>, ys => L.http_append_outcomes(http_expected_batch(left), ys),
                        HttpClient.flatten_results(HttpClient.run_batch(right)), http_expected_batch(right), http_batch_cpu_expected(right))))

def http_batch_gpu_expected(+batch: HttpClient.Batch) -> {HttpClient.flatten_results(HttpClient.run_batch_gpu(batch)) == http_expected_batch(batch) : List<&2, HttpClient.Outcome>}:
    Equal.trans(List<&2, HttpClient.Outcome>, HttpClient.flatten_results(HttpClient.run_batch_gpu(batch)),
        HttpClient.flatten_results(HttpClient.run_batch(batch)), http_expected_batch(batch),
        Equal.cong(HttpClient.BatchResult, List<&2, HttpClient.Outcome>, HttpClient.flatten_results,
            HttpClient.run_batch_gpu(batch), HttpClient.run_batch(batch), L.http_gpu_batch_matches_cpu(batch)),
        http_batch_cpu_expected(batch))

def http_append_work(+xs: List<&2, HttpClient.Work>,
                     +ys: List<&2, HttpClient.Work>) -> List<&2, HttpClient.Work>:
    match xs:
        case Nil{}: ys
        case work <> tail: work <> http_append_work(tail, ys)

def http_append_work_assoc(+xs: List<&2, HttpClient.Work>,
                           +ys: List<&2, HttpClient.Work>,
                           +zs: List<&2, HttpClient.Work>) -> {http_append_work(xs, http_append_work(ys, zs)) == http_append_work(http_append_work(xs, ys), zs) : List<&2, HttpClient.Work>}:
    match xs:
        case Nil{}: {==}
        case work <> tail:
            Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Work>, rest => work <> rest,
                http_append_work(tail, http_append_work(ys, zs)), http_append_work(http_append_work(tail, ys), zs),
                http_append_work_assoc(tail, ys, zs))

def http_append_work_nil(+xs: List<&2, HttpClient.Work>) -> {http_append_work(xs, Nil{}) == xs : List<&2, HttpClient.Work>}:
    match xs:
        case Nil{}: {==}
        case work <> tail:
            Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Work>, rest => work <> rest,
                http_append_work(tail, Nil{}), tail, http_append_work_nil(tail))

def http_batch_work_order(+batch: HttpClient.Batch) -> List<&2, HttpClient.Work>:
    match batch:
        case HttpClient.Leaf{work}: [work]
        case HttpClient.Fork{+left, +right}:
            http_append_work(http_batch_work_order(left), http_batch_work_order(right))

def http_batches_work_order(+batches: List<&2, HttpClient.Batch>) -> List<&2, HttpClient.Work>:
    match batches:
        case Nil{}: Nil{}
        case batch <> tail:
            http_append_work(http_batch_work_order(batch), http_batches_work_order(tail))

def http_batch_pairs_work_order(+batches: List<&2, HttpClient.Batch>) -> {http_batches_work_order(HttpClient.batch_pairs(batches)) == http_batches_work_order(batches) : List<&2, HttpClient.Work>}:
    match batches:
        case Nil{}: {==}
        case batch <> Nil{}: {==}
        case +left <> +right <> +tail:
            Equal.trans(List<&2, HttpClient.Work>,
                http_batches_work_order(HttpClient.batch_pairs(batches)),
                http_append_work(http_batch_work_order(left),
                    http_append_work(http_batch_work_order(right), http_batches_work_order(HttpClient.batch_pairs(tail)))),
                http_batches_work_order(batches),
                Equal.sym(List<&2, HttpClient.Work>,
                    http_append_work(http_batch_work_order(left),
                        http_append_work(http_batch_work_order(right), http_batches_work_order(HttpClient.batch_pairs(tail)))),
                    http_append_work(http_append_work(http_batch_work_order(left), http_batch_work_order(right)),
                        http_batches_work_order(HttpClient.batch_pairs(tail))),
                    http_append_work_assoc(http_batch_work_order(left), http_batch_work_order(right), http_batches_work_order(HttpClient.batch_pairs(tail)))),
                Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Work>, rest =>
                        http_append_work(http_batch_work_order(left), http_append_work(http_batch_work_order(right), rest)),
                    http_batches_work_order(HttpClient.batch_pairs(tail)), http_batches_work_order(tail),
                    http_batch_pairs_work_order(tail)))

def http_optional_batch_work_order(batch: Maybe<&2, HttpClient.Batch>) -> List<&2, HttpClient.Work>:
    match batch:
        case None{}: Nil{}
        case Some{tree}: http_batch_work_order(tree)

def http_batch_fold_result_order(head: HttpClient.Batch,
                                 rest: Maybe<&2, HttpClient.Batch>,
                                 +tail: List<&2, HttpClient.Batch>,
                                 rest_order: {http_optional_batch_work_order(rest) == http_batches_work_order(tail) : List<&2, HttpClient.Work>}) -> {http_optional_batch_work_order(HttpClient.batch_fold_result(head, rest)) == http_append_work(http_batch_work_order(head), http_batches_work_order(tail)) : List<&2, HttpClient.Work>}:
    match rest:
        case None{}:
            Equal.trans(List<&2, HttpClient.Work>, http_batch_work_order(head),
                http_append_work(http_batch_work_order(head), Nil{}),
                http_append_work(http_batch_work_order(head), http_batches_work_order(tail)),
                Equal.sym(List<&2, HttpClient.Work>, http_append_work(http_batch_work_order(head), Nil{}), http_batch_work_order(head),
                    http_append_work_nil(http_batch_work_order(head))),
                Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Work>, jobs => http_append_work(http_batch_work_order(head), jobs),
                    Nil{}, http_batches_work_order(tail), rest_order))
        case Some{+tree}:
            Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Work>, jobs => http_append_work(http_batch_work_order(head), jobs),
                http_batch_work_order(tree), http_batches_work_order(tail), rest_order)

def http_batch_fold_work_order(+batches: List<&2, HttpClient.Batch>) -> {http_optional_batch_work_order(HttpClient.batch_fold(batches)) == http_batches_work_order(batches) : List<&2, HttpClient.Work>}:
    match batches:
        case Nil{}: {==}
        case head <> tail:
            http_batch_fold_result_order(head, HttpClient.batch_fold(tail), tail, http_batch_fold_work_order(tail))

def http_batch_build_work_order(fuel: Nat,
                                +batches: List<&2, HttpClient.Batch>) -> {http_optional_batch_work_order(HttpClient.batch_build(fuel, batches)) == http_batches_work_order(batches) : List<&2, HttpClient.Work>}:
    match fuel:
        case 0n: http_batch_fold_work_order(batches)
        case 1n+p:
            match batches:
                case Nil{}: {==}
                case head <> Nil{}:
                    Equal.sym(List<&2, HttpClient.Work>, http_append_work(http_batch_work_order(head), Nil{}),
                        http_batch_work_order(head), http_append_work_nil(http_batch_work_order(head)))
                case +left <> +right <> +tail:
                    Equal.trans(List<&2, HttpClient.Work>,
                        http_optional_batch_work_order(HttpClient.batch_build(p, HttpClient.batch_pairs(batches))),
                        http_batches_work_order(HttpClient.batch_pairs(batches)),
                        http_batches_work_order(batches),
                        http_batch_build_work_order(p, HttpClient.batch_pairs(batches)),
                        http_batch_pairs_work_order(batches))

def http_batch_leaves_work_order(+jobs: List<&2, HttpClient.Work>) -> {http_batches_work_order(HttpClient.batch_leaves(jobs)) == jobs : List<&2, HttpClient.Work>}:
    match jobs:
        case Nil{}: {==}
        case work <> tail:
            Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Work>, rest => work <> rest,
                http_batches_work_order(HttpClient.batch_leaves(tail)), tail, http_batch_leaves_work_order(tail))

def http_batch_from_list_work_order(+jobs: List<&2, HttpClient.Work>) -> {http_optional_batch_work_order(HttpClient.batch_from_list(jobs)) == jobs : List<&2, HttpClient.Work>}:
    Equal.trans(List<&2, HttpClient.Work>,
        http_optional_batch_work_order(HttpClient.batch_from_list(jobs)),
        http_batches_work_order(HttpClient.batch_leaves(jobs)), jobs,
        http_batch_build_work_order(List.length(&2, HttpClient.Work, jobs), HttpClient.batch_leaves(jobs)),
        http_batch_leaves_work_order(jobs))

def http_expected_outcomes_append(+xs: List<&2, HttpClient.Work>,
                                  +ys: List<&2, HttpClient.Work>) -> {L.http_expected_outcomes(http_append_work(xs, ys)) == L.http_append_outcomes(L.http_expected_outcomes(xs), L.http_expected_outcomes(ys)) : List<&2, HttpClient.Outcome>}:
    match xs:
        case Nil{}: {==}
        case work <> tail:
            Equal.cong(List<&2, HttpClient.Outcome>, List<&2, HttpClient.Outcome>, results => L.http_expected_outcome(work) <> results,
                L.http_expected_outcomes(http_append_work(tail, ys)),
                L.http_append_outcomes(L.http_expected_outcomes(tail), L.http_expected_outcomes(ys)),
                http_expected_outcomes_append(tail, ys))

def http_expected_batch_work_order(+batch: HttpClient.Batch) -> {http_expected_batch(batch) == L.http_expected_outcomes(http_batch_work_order(batch)) : List<&2, HttpClient.Outcome>}:
    match batch:
        case HttpClient.Leaf{work}: {==}
        case HttpClient.Fork{+left, +right}:
            Equal.trans(List<&2, HttpClient.Outcome>,
                http_expected_batch(batch),
                L.http_append_outcomes(http_expected_batch(left), http_expected_batch(right)),
                L.http_expected_outcomes(http_batch_work_order(batch)),
                {==},
                Equal.trans(List<&2, HttpClient.Outcome>,
                    L.http_append_outcomes(http_expected_batch(left), http_expected_batch(right)),
                    L.http_append_outcomes(L.http_expected_outcomes(http_batch_work_order(left)), L.http_expected_outcomes(http_batch_work_order(right))),
                    L.http_expected_outcomes(http_batch_work_order(batch)),
                    Equal.trans(List<&2, HttpClient.Outcome>,
                        L.http_append_outcomes(http_expected_batch(left), http_expected_batch(right)),
                        L.http_append_outcomes(L.http_expected_outcomes(http_batch_work_order(left)), http_expected_batch(right)),
                        L.http_append_outcomes(L.http_expected_outcomes(http_batch_work_order(left)), L.http_expected_outcomes(http_batch_work_order(right))),
                        Equal.cong(List<&2, HttpClient.Outcome>, List<&2, HttpClient.Outcome>, xs => L.http_append_outcomes(xs, http_expected_batch(right)),
                            http_expected_batch(left), L.http_expected_outcomes(http_batch_work_order(left)), http_expected_batch_work_order(left)),
                        Equal.cong(List<&2, HttpClient.Outcome>, List<&2, HttpClient.Outcome>, ys => L.http_append_outcomes(L.http_expected_outcomes(http_batch_work_order(left)), ys),
                            http_expected_batch(right), L.http_expected_outcomes(http_batch_work_order(right)), http_expected_batch_work_order(right))),
                    Equal.sym(List<&2, HttpClient.Outcome>,
                        L.http_expected_outcomes(http_batch_work_order(batch)),
                        L.http_append_outcomes(L.http_expected_outcomes(http_batch_work_order(left)), L.http_expected_outcomes(http_batch_work_order(right))),
                        http_expected_outcomes_append(http_batch_work_order(left), http_batch_work_order(right)))))

def http_optional_gpu_expected(batch: Maybe<&2, HttpClient.Batch>,
                               +jobs: List<&2, HttpClient.Work>,
                               batch_order: {http_optional_batch_work_order(batch) == jobs : List<&2, HttpClient.Work>}) -> {L.http_optional_outcomes(HttpClient.run_many_gpu_tree(batch)) == L.http_expected_outcomes(jobs) : List<&2, HttpClient.Outcome>}:
    match batch:
        case None{}:
            Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Outcome>, L.http_expected_outcomes,
                Nil{}, jobs, batch_order)
        case Some{+tree}:
            Equal.trans(List<&2, HttpClient.Outcome>,
                L.http_optional_outcomes(HttpClient.run_many_gpu_tree(batch)),
                http_expected_batch(tree), L.http_expected_outcomes(jobs),
                http_batch_gpu_expected(tree),
                Equal.trans(List<&2, HttpClient.Outcome>,
                    http_expected_batch(tree),
                    L.http_expected_outcomes(http_batch_work_order(tree)),
                    L.http_expected_outcomes(jobs),
                    http_expected_batch_work_order(tree),
                    Equal.cong(List<&2, HttpClient.Work>, List<&2, HttpClient.Outcome>, L.http_expected_outcomes,
                        http_batch_work_order(tree), jobs, batch_order)))

def http_run_many_gpu_expected(+jobs: List<&2, HttpClient.Work>) -> {L.http_optional_outcomes(HttpClient.run_many_gpu(jobs)) == L.http_expected_outcomes(jobs) : List<&2, HttpClient.Outcome>}:
    http_optional_gpu_expected(HttpClient.batch_from_list(jobs), jobs, http_batch_from_list_work_order(jobs))

def http_run_many_tree_parity(tree: Maybe<&2, HttpClient.Batch>) -> {HttpClient.run_many_gpu_tree(tree) == HttpClient.run_many_tree(tree) : Maybe<&2, HttpClient.BatchResult>}:
    match tree:
        case None{}: {==}
        case Some{batch}:
            Equal.cong(HttpClient.BatchResult, Maybe<&2, HttpClient.BatchResult>, result => Some{result},
                HttpClient.run_batch_gpu(batch), HttpClient.run_batch(batch), L.http_gpu_batch_matches_cpu(batch))

def L.http_gpu_many_matches_cpu(jobs):
    http_run_many_tree_parity(HttpClient.batch_from_list(jobs))

def L.http_gpu_batch_preserves_order_and_errors(jobs):
    http_run_many_gpu_expected(jobs)
