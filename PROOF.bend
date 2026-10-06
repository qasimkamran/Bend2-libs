import Base
import ./proof/AES_NistInputProof.bend as AESNistInputProof
import ./LAWS.bend as L
import ./libs/JSON.bend as Json
import ./libs/URL.bend as URL
import ./libs/AES256GCM.bend as AES
import ./libs/AES256GCMCore.bend as Core
import ./proof/AES_EncryptProof.bend as AESEncryptProof
import ./proof/AES_TamperProof.bend as AESTamperProof
import ./proof/AES_CanonicalProof.bend as AESCanonicalProof
import ./proof/AES_ConstructorProof.bend as AESConstructorProof
import ./proof/AES_IdentityProof.bend as AESIdentityProof
import ./proof/AES_NistKeyScheduleProof.bend as AESNistKeyScheduleProof
import ./proof/AES_NistBlockComposeProof.bend as AESNistBlockComposeProof
import ./proof/AES_NistBlockProof.bend as AESNistBlockProof
import ./proof/AES_NistObservationProof.bend as AESNistObservationProof
import ./proof/AES_NistVectorProof.bend as AESNistVectorProof
import ./proof/AES_NistTamperVectorProof.bend as AESNistTamperVectorProof
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

def L.url_component_ascii():
    {==}

def L.url_component_reserved():
    {==}

def L.url_component_utf8():
    {==}

def L.aes256gcm_rejects_empty_envelope():
    {==}

def L.aes256gcm_rejects_unknown_version():
    {==}

def L.aes256gcm_rejects_missing_version():
    {==}

def L.aes256gcm_rejects_short_nonce():
    {==}

def L.aes256gcm_rejects_long_nonce():
    {==}

def L.aes256gcm_rejects_short_tag():
    {==}

def L.aes256gcm_rejects_long_tag():
    {==}

def L.aes256gcm_rejects_odd_ciphertext_hex():
    {==}

def L.aes256gcm_rejects_non_hex_ciphertext():
    {==}

def L.aes256gcm_rejects_non_hex_nonce():
    {==}

def L.aes256gcm_rejects_non_hex_tag():
    {==}

def L.aes256gcm_rejects_uppercase_hex():
    {==}

def L.aes256gcm_rejects_extra_field():
    {==}

def L.aes256gcm_rejects_missing_ciphertext_field():
    {==}

def L.aes256gcm_rejects_trailing_garbage():
    {==}

def L.aes256gcm_rejects_surrounding_whitespace():
    {==}

def aes_nat_tail_ne(+a: Nat, +b: Nat,
    no: {1n+a != 1n+b : Nat}) -> {a != b : Nat}:
    e => no(Equal.cong(Nat, Nat, n => 1n+n, a, b, e))

def aes_nat_pred(n: Nat) -> Nat:
    match n:
        case 0n: 0n
        case 1n+p: p

def aes_nat_zero_ne_succ(+p: Nat) -> {0n != 1n+p : Nat}:
    e => PrimitiveProof.absurd(Empty,
        PrimitiveProof.false_true(Equal.sym(Bool, True{}, False{},
            Equal.cong(Nat, Bool, n => Nat.is_eq(n, 0n),
                0n, 1n+p, e))))

def aes_nat_succ_ne_zero(+p: Nat) -> {1n+p != 0n : Nat}:
    e => PrimitiveProof.absurd(Empty,
        PrimitiveProof.false_true(
            Equal.cong(Nat, Bool, n => Nat.is_eq(n, 0n),
                1n+p, 0n, e)))

def aes_nat_eq_step_status(+a: Nat, +b: Nat,
    result: Maybe<&0, {a == b : Nat}>) ->
    {Maybe.is_some(&0, {1n+a == 1n+b : Nat},
        AES.aes_nat_eq_step(a, b, result)) ==
     Maybe.is_some(&0, {a == b : Nat}, result) : Bool}:
    match result:
        case None{}: {==}
        case Some{proof}: {==}

def aes_nat_eq_refl_is_some(+n: Nat) ->
    {Maybe.is_some(&0, {n == n : Nat},
        AES.aes_nat_eq_proof(n, n)) == True{} : Bool}:
    match n:
        case 0n: {==}
        case 1n+p:
            Equal.trans(Bool,
                Maybe.is_some(&0, {1n+p == 1n+p : Nat},
                    AES.aes_nat_eq_proof(1n+p, 1n+p)),
                Maybe.is_some(&0, {p == p : Nat},
                    AES.aes_nat_eq_proof(p, p)),
                True{},
                aes_nat_eq_step_status(p, p, AES.aes_nat_eq_proof(p, p)),
                aes_nat_eq_refl_is_some(p))

def aes_nat_eq_is_some(+a: Nat, +b: Nat, evidence: {a == b : Nat}) ->
    {Maybe.is_some(&0, {a == b : Nat},
        AES.aes_nat_eq_proof(a, b)) == True{} : Bool}:
    Equal.trans(Bool,
        Maybe.is_some(&0, {a == b : Nat}, AES.aes_nat_eq_proof(a, b)),
        Maybe.is_some(&0, {b == b : Nat}, AES.aes_nat_eq_proof(b, b)),
        True{},
        Equal.cong(Nat, Bool,
            value => Maybe.is_some(&0, {value == b : Nat},
                AES.aes_nat_eq_proof(value, b)),
            a, b, evidence),
        aes_nat_eq_refl_is_some(b))
def aes_nat_eq_none_if_ne(+a: Nat, +b: Nat,
    no: {a != b : Nat}) ->
    {AES.aes_nat_eq_proof(a, b) == None{} : Maybe<&0, {a == b : Nat}>}:
    match a b:
        case 0n 0n:
            PrimitiveProof.absurd({AES.aes_nat_eq_proof(0n, 0n) == None{} :
                Maybe<&0, {0n == 0n : Nat}>}, no({==}))
        case 0n 1n+bp: {==}
        case 1n+ap 0n: {==}
        case 1n+ap 1n+bp:
            recursive = aes_nat_eq_none_if_ne(ap, bp,
                aes_nat_tail_ne(ap, bp, no))
            Equal.trans(Maybe<&0, {1n+ap == 1n+bp : Nat}>,
                AES.aes_nat_eq_step(ap, bp, AES.aes_nat_eq_proof(ap, bp)),
                AES.aes_nat_eq_step(ap, bp, None{}), None{},
                Equal.cong(Maybe<&0, {ap == bp : Nat}>,
                    Maybe<&0, {1n+ap == 1n+bp : Nat}>,
                    result => AES.aes_nat_eq_step(ap, bp, result),
                    AES.aes_nat_eq_proof(ap, bp), None{}, recursive),
                {==})

def aes_bytes_proof_none_if_invalid(+bytes: List<&2, U32>,
    generated: Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>,
    no: {AES.bytes_valid(bytes) == False{} : Bool}) ->
    {generated == None{} : Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>}:
    match generated:
        case None{}: {==}
        case Some{valid}:
            contradiction = Equal.trans(Bool, True{}, AES.bytes_valid(bytes),
                False{}, Equal.sym(Bool, AES.bytes_valid(bytes), True{}, valid),
                no)
            PrimitiveProof.absurd(
                {Some{valid} == None{} :
                  Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>},
                PrimitiveProof.false_true(Equal.sym(Bool, True{}, False{},
                    contradiction)))

def aes_bytes_valid_none_if_false(+bytes: List<&2, U32>,
    no: {AES.bytes_valid(bytes) == False{} : Bool}) ->
    {AES.aes_bytes_valid_proof(bytes) == None{} :
      Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>}:
    aes_bytes_proof_none_if_invalid(bytes,
        AES.aes_bytes_valid_proof(bytes), no)

def aes_bytes_valid_status(+bytes: List<&2, U32>, b: Bool,
    link: {b == AES.bytes_valid(bytes) : Bool}) ->
    {Maybe.is_some(&0, {AES.bytes_valid(bytes) == True{} : Bool},
        AES.aes_bytes_valid_from_bool(bytes, b, link)) == b : Bool}:
    match b:
        case False{}: {==}
        case True{}: {==}

def aes_bytes_cert_is_some(+bytes: List<&2, U32>,
    evidence: {AES.bytes_valid(bytes) == True{} : Bool}) ->
    {Maybe.is_some(&0, {AES.bytes_valid(bytes) == True{} : Bool},
        AES.aes_bytes_valid_proof(bytes)) == True{} : Bool}:
    Equal.trans(Bool,
        Maybe.is_some(&0, {AES.bytes_valid(bytes) == True{} : Bool},
            AES.aes_bytes_valid_proof(bytes)),
        AES.bytes_valid(bytes), True{},
        aes_bytes_valid_status(bytes, AES.bytes_valid(bytes), {==}),
        evidence)
def L.aes256gcm_accepts_32_byte_key(bytes, size, valid):
    +size_copy = size
    +valid_copy = valid
    AESConstructorProof.key_accepts(bytes, size_copy, valid_copy,
      AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 32n),
      AES.aes_bytes_valid_proof(bytes),
      aes_nat_eq_is_some(List.length(&2, U32, bytes), 32n, size_copy),
      aes_bytes_cert_is_some(bytes, valid_copy))

def L.aes256gcm_accepts_12_byte_nonce(bytes, size, valid):
    +size_copy = size
    +valid_copy = valid
    AESConstructorProof.nonce_accepts(bytes, size_copy, valid_copy,
      AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 12n),
      AES.aes_bytes_valid_proof(bytes),
      aes_nat_eq_is_some(List.length(&2, U32, bytes), 12n, size_copy),
      aes_bytes_cert_is_some(bytes, valid_copy))

def L.aes256gcm_encrypts_valid_input(key, nonce, aad, plaintext, aad_ok,
    plaintext_ok):
    AESEncryptProof.valid_input_is_done(key, nonce, aad, plaintext, aad_ok,
        plaintext_ok)

def L.aes256gcm_preserves_nonce(key, nonce, aad, plaintext, envelope,
    encrypted):
    AESEncryptProof.preserves_nonce(key, nonce, aad, plaintext, envelope,
        encrypted)

def L.aes256gcm_preserves_plaintext_length(key, nonce, aad, plaintext,
    envelope, encrypted):
    AESEncryptProof.successful_encrypt_preserves_length(key, nonce, aad,
        plaintext, envelope, encrypted)

def L.aes256gcm_envelope_is_canonical(text, envelope, parsed):
    AESCanonicalProof.canonical_sound(text,
        AES.parse_fields(String.split(text, Chr{46})), envelope, parsed)

def L.aes256gcm_envelope_roundtrip(envelope):
    AESIdentityProof.exact_roundtrip(envelope)

def aes_key_from_no_size(+bytes: List<&2, U32>,
    valid: Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>) ->
    {AES.key_from_proofs(bytes, None{}, valid) == Fail{AES.InvalidKey{}} :
      Result<&2, &2, AES.Error, AES.SecretKey>}:
    {==}

def aes_key_from_no_valid(+bytes: List<&2, U32>,
    size: Maybe<&0, {List.length(&2, U32, bytes) == 32n : Nat}>) ->
    {AES.key_from_proofs(bytes, size, None{}) == Fail{AES.InvalidKey{}} :
      Result<&2, &2, AES.Error, AES.SecretKey>}:
    match size:
        case None{}: {==}
        case Some{size}: {==}

def L.aes256gcm_rejects_wrong_key_length(bytes, size):
    Equal.trans(Result<&2, &2, AES.Error, AES.SecretKey>,
      AES.key_impl(bytes),
      AES.key_from_proofs(bytes, None{}, AES.aes_bytes_valid_proof(bytes)),
      Fail{AES.InvalidKey{}},
      Equal.cong(Maybe<&0, {List.length(&2, U32, bytes) == 32n : Nat}>,
        Result<&2, &2, AES.Error, AES.SecretKey>,
        maybe_size => AES.key_from_proofs(bytes, maybe_size,
          AES.aes_bytes_valid_proof(bytes)),
        AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 32n), None{},
        aes_nat_eq_none_if_ne(List.length(&2, U32, bytes), 32n, size)),
      aes_key_from_no_size(bytes, AES.aes_bytes_valid_proof(bytes)))

def L.aes256gcm_rejects_non_byte_key(bytes, invalid):
    Equal.trans(Result<&2, &2, AES.Error, AES.SecretKey>,
      AES.key_impl(bytes),
      AES.key_from_proofs(bytes,
        AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 32n), None{}),
      Fail{AES.InvalidKey{}},
      Equal.cong(Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>,
        Result<&2, &2, AES.Error, AES.SecretKey>,
        maybe_valid => AES.key_from_proofs(bytes,
          AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 32n),
          maybe_valid),
        AES.aes_bytes_valid_proof(bytes), None{},
        aes_bytes_valid_none_if_false(bytes, invalid)),
      aes_key_from_no_valid(bytes,
        AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 32n)))

def aes_nonce_from_no_size(+bytes: List<&2, U32>,
    valid: Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>) ->
    {AES.nonce_from_proofs(bytes, None{}, valid) == Fail{AES.InvalidNonce{}} :
      Result<&2, &2, AES.Error, AES.Nonce>}:
    {==}

def aes_nonce_from_no_valid(+bytes: List<&2, U32>,
    size: Maybe<&0, {List.length(&2, U32, bytes) == 12n : Nat}>) ->
    {AES.nonce_from_proofs(bytes, size, None{}) == Fail{AES.InvalidNonce{}} :
      Result<&2, &2, AES.Error, AES.Nonce>}:
    match size:
        case None{}: {==}
        case Some{size}: {==}

def L.aes256gcm_rejects_wrong_nonce_length(bytes, size):
    Equal.trans(Result<&2, &2, AES.Error, AES.Nonce>,
      AES.nonce_impl(bytes),
      AES.nonce_from_proofs(bytes, None{}, AES.aes_bytes_valid_proof(bytes)),
      Fail{AES.InvalidNonce{}},
      Equal.cong(Maybe<&0, {List.length(&2, U32, bytes) == 12n : Nat}>,
        Result<&2, &2, AES.Error, AES.Nonce>,
        maybe_size => AES.nonce_from_proofs(bytes, maybe_size,
          AES.aes_bytes_valid_proof(bytes)),
        AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 12n), None{},
        aes_nat_eq_none_if_ne(List.length(&2, U32, bytes), 12n, size)),
      aes_nonce_from_no_size(bytes, AES.aes_bytes_valid_proof(bytes)))

def L.aes256gcm_rejects_non_byte_nonce(bytes, invalid):
    Equal.trans(Result<&2, &2, AES.Error, AES.Nonce>,
      AES.nonce_impl(bytes),
      AES.nonce_from_proofs(bytes,
        AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 12n), None{}),
      Fail{AES.InvalidNonce{}},
      Equal.cong(Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>,
        Result<&2, &2, AES.Error, AES.Nonce>,
        maybe_valid => AES.nonce_from_proofs(bytes,
          AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 12n),
          maybe_valid),
        AES.aes_bytes_valid_proof(bytes), None{},
        aes_bytes_valid_none_if_false(bytes, invalid)),
      aes_nonce_from_no_valid(bytes,
        AES.aes_nat_eq_proof(List.length(&2, U32, bytes), 12n)))

def encrypt_invalid_plaintext(key: AES.SecretKey, nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>, aad_ok: Bool) ->
    {AES.encrypt_checked(key, nonce, aad, plaintext, aad_ok, False{}) ==
      Fail{AES.InvalidBytes{}} : Result<&2, &2, AES.Error, AES.Envelope>}:
    match aad_ok:
        case True{}: {==}
        case False{}: {==}

def encrypt_using_plaintext_validity(key: AES.SecretKey, nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>, plaintext_ok: Bool) ->
    Result<&2, &2, AES.Error, AES.Envelope>:
    AES.encrypt_checked(key, nonce, aad, plaintext,
        AES.aad_valid(aad), plaintext_ok)

def L.aes256gcm_rejects_invalid_plaintext(key, nonce, aad, plaintext, valid):
    Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
      AES.encrypt_impl(key, nonce, aad, plaintext),
      encrypt_using_plaintext_validity(key, nonce, aad, plaintext, False{}),
      Fail{AES.InvalidBytes{}},
      Equal.cong(Bool, Result<&2, &2, AES.Error, AES.Envelope>,
        plaintext_ok => encrypt_using_plaintext_validity(
            key, nonce, aad, plaintext, plaintext_ok),
        AES.plaintext_valid(plaintext), False{}, valid),
      encrypt_invalid_plaintext(key, nonce, aad, plaintext,
        AES.aad_valid(aad)))

def encrypt_invalid_aad(key: AES.SecretKey, nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>, plaintext_ok: Bool) ->
    {AES.encrypt_checked(key, nonce, aad, plaintext, False{}, plaintext_ok) ==
      Fail{AES.InvalidBytes{}} : Result<&2, &2, AES.Error, AES.Envelope>}:
    match plaintext_ok:
        case True{}: {==}
        case False{}: {==}

def encrypt_using_aad_validity(key: AES.SecretKey, nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>, aad_ok: Bool) ->
    Result<&2, &2, AES.Error, AES.Envelope>:
    AES.encrypt_checked(key, nonce, aad, plaintext, aad_ok,
        AES.plaintext_valid(plaintext))

def L.aes256gcm_rejects_invalid_aad(key, nonce, aad, plaintext, valid):
    Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
      AES.encrypt_impl(key, nonce, aad, plaintext),
      encrypt_using_aad_validity(key, nonce, aad, plaintext, False{}),
      Fail{AES.InvalidBytes{}},
      Equal.cong(Bool, Result<&2, &2, AES.Error, AES.Envelope>,
        aad_ok => encrypt_using_aad_validity(key, nonce, aad, plaintext, aad_ok),
        AES.aad_valid(aad), False{}, valid),
      encrypt_invalid_aad(key, nonce, aad, plaintext,
        AES.plaintext_valid(plaintext)))

def decrypt_invalid_aad(key: AES.SecretKey, +aad: List<&2, U32>,
    +envelope: AES.Envelope, ciphertext_ok: Bool) ->
    {AES.decrypt_checked(key, aad, envelope, False{}, ciphertext_ok) ==
      Fail{AES.InvalidBytes{}} :
      Result<&2, &2, AES.Error, List<&2, U32>>}:
    match ciphertext_ok:
        case True{}: {==}
        case False{}: {==}

def decrypt_using_aad_validity(key: AES.SecretKey, +aad: List<&2, U32>,
    +envelope: AES.Envelope, aad_ok: Bool) ->
    Result<&2, &2, AES.Error, List<&2, U32>>:
    AES.decrypt_checked(key, aad, envelope, aad_ok,
        AES.plaintext_valid(AES.ciphertext(envelope)))

def L.aes256gcm_decrypt_rejects_invalid_aad(key, aad, envelope, valid):
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
      AES.decrypt_impl(key, aad, envelope),
      decrypt_using_aad_validity(key, aad, envelope, False{}),
      Fail{AES.InvalidBytes{}},
      Equal.cong(Bool, Result<&2, &2, AES.Error, List<&2, U32>>,
        aad_ok => decrypt_using_aad_validity(key, aad, envelope, aad_ok),
        AES.aad_valid(aad), False{}, valid),
      decrypt_invalid_aad(key, aad, envelope,
        AES.plaintext_valid(AES.ciphertext(envelope))))

def L.aes256gcm_roundtrip(key, nonce, aad, plaintext, envelope, encrypted):
    AESEncryptProof.successful_encrypt_decrypt_roundtrip(key, nonce, aad,
        plaintext, envelope, encrypted)

def L.aes256gcm_rejects_changed_tag(key, nonce, aad, plaintext, envelope,
    tampered, encrypted, same_nonce, same_ciphertext, changed_tag):
    AESTamperProof.rejects_changed_tag(key, nonce, aad, plaintext, envelope,
        tampered, encrypted,
        Equal.cong(AES.Nonce, List<&2, U32>, AES.raw_nonce_bytes,
            AES.envelope_nonce(tampered), AES.envelope_nonce(envelope),
            same_nonce), same_ciphertext, changed_tag)

def L.aes256gcm_nist_canonical_encoding():
    {==}

def L.aes256gcm_nist_empty_encrypt():
    AESNistInputProof.encrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        [], AESNistVectorProof.empty_aad(),
        [], AESNistVectorProof.empty_plaintext(),
        L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_empty()}),
        {==}, {==}, AESNistVectorProof.empty_encrypt())

def L.aes256gcm_nist_empty_decrypt():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [], AESNistVectorProof.empty_aad(),
        L.aes256gcm_nist_empty(), L.aes256gcm_nist_empty(), Done{AESNistVectorProof.empty_plaintext()},
        {==}, {==}, {==}, AESNistVectorProof.empty_decrypt())

def L.aes256gcm_nist_canonical_parsing():
    {==}

# Keep the composed NIST AES block certificate in the law proof book. This
# checkpoint proves the exact J0 AES result used by the empty-message vector.
def aes256gcm_nist_j0_block_checkpoint() ->
    {Core.aes256_encrypt_expanded(AESNistKeyScheduleProof.words_60(),
        AESNistBlockProof.block()) ==
     AESNistBlockProof.result() : List<&2, U32>}:
    AESNistBlockComposeProof.expanded_block_matches()

def L.aes256gcm_nist_multiblock_encrypt():
    AESNistInputProof.encrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        [], AESNistVectorProof.multiblock_aad(),
        [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85], AESNistVectorProof.multiblock_plaintext(),
        L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_multiblock()}),
        {==}, {==}, AESNistVectorProof.multiblock_encrypt())

def L.aes256gcm_nist_multiblock_decrypt():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [], AESNistVectorProof.multiblock_aad(),
        L.aes256gcm_nist_multiblock(), L.aes256gcm_nist_multiblock(), Done{AESNistVectorProof.multiblock_plaintext()},
        {==}, {==}, {==}, AESNistVectorProof.multiblock_decrypt())

def L.aes256gcm_nist_aad_only_encrypt():
    AESNistInputProof.encrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212], AESNistVectorProof.aad_only_aad(),
        [], AESNistVectorProof.aad_only_plaintext(),
        L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_aad_only()}),
        {==}, {==}, AESNistVectorProof.aad_only_encrypt())

def L.aes256gcm_nist_aad_only_decrypt():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212], AESNistVectorProof.aad_only_aad(),
        L.aes256gcm_nist_aad_only(), L.aes256gcm_nist_aad_only(), Done{AESNistVectorProof.aad_only_plaintext()},
        {==}, {==}, {==}, AESNistVectorProof.aad_only_decrypt())

def L.aes256gcm_nist_aad_and_multiblock_encrypt():
    AESNistInputProof.encrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212], AESNistVectorProof.aad_and_multiblock_aad(),
        [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85], AESNistVectorProof.aad_and_multiblock_plaintext(),
        L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_aad_and_multiblock()}),
        {==}, {==}, AESNistVectorProof.aad_and_multiblock_encrypt())

def L.aes256gcm_nist_aad_and_multiblock_decrypt():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212], AESNistVectorProof.aad_and_multiblock_aad(),
        L.aes256gcm_nist_aad_and_multiblock(), L.aes256gcm_nist_aad_and_multiblock(), Done{AESNistVectorProof.aad_and_multiblock_plaintext()},
        {==}, {==}, {==}, AESNistVectorProof.aad_and_multiblock_decrypt())

def L.aes256gcm_nist_partial_block_encrypt():
    AESNistInputProof.encrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133], AESNistVectorProof.partial_block_aad(),
        [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57], AESNistVectorProof.partial_block_plaintext(),
        L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_partial_block()}),
        {==}, {==}, AESNistVectorProof.partial_block_encrypt())

def L.aes256gcm_nist_partial_block_decrypt():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133], AESNistVectorProof.partial_block_aad(),
        L.aes256gcm_nist_partial_block(), L.aes256gcm_nist_partial_block(), Done{AESNistVectorProof.partial_block_plaintext()},
        {==}, {==}, {==}, AESNistVectorProof.partial_block_decrypt())

def L.aes256gcm_nist_rejects_changed_aad():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [1], AESNistTamperVectorProof.changed_aad_aad(),
        L.aes256gcm_nist_empty(), AESNistTamperVectorProof.changed_aad_envelope(),
        Fail{AES.AuthenticationFailed{}}, {==}, {==}, {==},
        AESNistTamperVectorProof.rejects_changed_aad())

def L.aes256gcm_nist_rejects_changed_key():
    AESNistInputProof.decrypt_inputs(AES.SecretKey{List.replicate(U32, 32n, 0), {==}, {==}}, AESNistTamperVectorProof.zero_key(),
        [], AESNistTamperVectorProof.changed_key_aad(),
        L.aes256gcm_nist_empty(), AESNistTamperVectorProof.changed_key_envelope(),
        Fail{AES.AuthenticationFailed{}}, {==}, {==}, {==},
        AESNistTamperVectorProof.rejects_changed_key())

def L.aes256gcm_nist_rejects_changed_nonce():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [], AESNistTamperVectorProof.changed_nonce_aad(),
        AES.Envelope{AES.Nonce{List.replicate(U32, 12n, 0), {==}, {==}},
            [], AES.Tag{[253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126], {==}, {==}}, {==}}, AESNistTamperVectorProof.changed_nonce_envelope(),
        Fail{AES.AuthenticationFailed{}}, {==}, {==}, {==},
        AESNistTamperVectorProof.rejects_changed_nonce())

def L.aes256gcm_nist_rejects_changed_ciphertext():
    AESNistInputProof.decrypt_inputs(L.aes256gcm_nist_key(), L.aes256gcm_nist_key(),
        [], AESNistTamperVectorProof.changed_ciphertext_aad(),
        AES.Envelope{L.aes256gcm_nist_nonce(), [1],
            AES.Tag{[253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126], {==}, {==}}, {==}}, AESNistTamperVectorProof.changed_ciphertext_envelope(),
        Fail{AES.AuthenticationFailed{}}, {==}, {==}, {==},
        AESNistTamperVectorProof.rejects_changed_ciphertext())
