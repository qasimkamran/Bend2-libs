import Base
import ./LAWS.bend as L
import ./libs/JSON.bend as Json
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
