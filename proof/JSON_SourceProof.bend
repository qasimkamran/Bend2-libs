import Base
import ../libs/JSON.bend as J
import ./JSON_AssemblyProof.bend as A
import ./JSON_PrimitiveProof.bend as P
import ./JSON_StringProof.bend as S
import ./JSON_ParallelProof.bend as Par
import ./JSON_NumberLexProof.bend as Num
import ./JSON_LexWhitespaceProof.bend as W
import ./JSON_ListProof.bend as LP

def token_source(xs: List<&2, J.Lexeme>, tail: List<J.Token>) -> List<J.Token>:
    match xs:
        case Nil{}: tail
        case h <> t: J.decode_lexeme(h) <> token_source(t, tail)

def token_source_flat(+xs: List<&2, J.Lexeme>,
                      -tail: List<J.Token>) -> {token_source(xs, tail) == Par.flat(xs, tail) : List<J.Token>}:
    match xs:
        case Nil{}: {==}
        case head <> rest:
            Equal.cong(List<J.Token>, List<J.Token>, tokens => J.decode_lexeme(head) <> tokens,
                token_source(rest, tail), Par.flat(rest, tail), token_source_flat(rest, tail))

def is_members(mode: A.Mode) -> Bool:
    match mode:
        case A.Whole{}: False{}
        case A.Members{}: True{}

def token_string(text: String) -> J.Token:
    J.Atom{Done{J.Str{text}}}

def nested_render_append(+outer: J.Value,
                         +inner: J.Value,
                         +inner_members: Bool,
                         +prefix: String,
                         +suffix: String,
                         +outer_append: {J.render(outer, False{}, J.render(inner, inner_members, prefix)) ++ suffix == J.render(outer, False{}, J.render(inner, inner_members, prefix) ++ suffix) : String},
                         +inner_append: {J.render(inner, inner_members, prefix) ++ suffix == J.render(inner, inner_members, prefix ++ suffix) : String}) -> {J.render(outer, False{}, J.render(inner, inner_members, prefix)) ++ suffix == J.render(outer, False{}, J.render(inner, inner_members, prefix ++ suffix)) : String}:
    Equal.trans(String,
        J.render(outer, False{}, J.render(inner, inner_members, prefix)) ++ suffix,
        J.render(outer, False{}, J.render(inner, inner_members, prefix) ++ suffix),
        J.render(outer, False{}, J.render(inner, inner_members, prefix ++ suffix)),
        outer_append,
        Equal.cong(String, String, text => J.render(outer, False{}, text),
            J.render(inner, inner_members, prefix) ++ suffix,
            J.render(inner, inner_members, prefix ++ suffix),
            inner_append))


def render_object_field_append(+prefix: String,
                               +key: String,
                               +text: String,
                               +suffix: String) -> {J.render_object_field(prefix, key, text) ++ suffix == J.render_object_field(prefix, key, text ++ suffix) : String}:
    S.append_assoc(prefix ++ ("\"" ++ J.escape_string(key) ++ "\":"), text, suffix)

def render_append(+value: J.Value,
                  +members: Bool,
                  +prefix: String,
                  +suffix: String) -> {J.render(value, members, prefix) ++ suffix == J.render(value, members, prefix ++ suffix) : String}:
    match value:
        case J.Null{}: S.append_assoc("null", prefix, suffix)
        case J.Bool{truth}:
            match truth:
                case True{}: S.append_assoc("true", prefix, suffix)
                case False{}: S.append_assoc("false", prefix, suffix)
        case J.Number{lexeme, certificate}: S.append_assoc(lexeme, prefix, suffix)
        case J.Str{text}:
            Equal.cong(String, String, rest => SCon{'"', rest},
                (J.escape_string(text) ++ (SCon{'"', SNil{}} ++ prefix)) ++ suffix,
                J.escape_string(text) ++ (SCon{'"', SNil{}} ++ (prefix ++ suffix)),
                Equal.trans(String,
                    (J.escape_string(text) ++ (SCon{'"', SNil{}} ++ prefix)) ++ suffix,
                    J.escape_string(text) ++ ((SCon{'"', SNil{}} ++ prefix) ++ suffix),
                    J.escape_string(text) ++ (SCon{'"', SNil{}} ++ (prefix ++ suffix)),
                    S.append_assoc(J.escape_string(text), SCon{'"', SNil{}} ++ prefix, suffix),
                    Equal.cong(String, String, value => J.escape_string(text) ++ value,
                        (SCon{'"', SNil{}} ++ prefix) ++ suffix,
                        SCon{'"', SNil{}} ++ (prefix ++ suffix),
                        S.append_assoc(SCon{'"', SNil{}}, prefix, suffix))))
        case J.Arr{Nil{}}:
            match members:
                case False{}: S.append_assoc("[]", prefix, suffix)
                case True{}: S.append_assoc("]", prefix, suffix)
        case J.Arr{head <> tail}:
            match members:
                case False{}:
                    Equal.trans(String, ("[" ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix))) ++ suffix,
                        "[" ++ (J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)) ++ suffix),
                        "[" ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix ++ suffix)),
                        S.append_assoc("[", J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)), suffix),
                        Equal.trans(String, "[" ++ (J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)) ++ suffix),
                            "[" ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix) ++ suffix),
                            "[" ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix ++ suffix)),
                            Equal.cong(String, String, text => "[" ++ text,
                                J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)) ++ suffix,
                                J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix) ++ suffix),
                                render_append(head, False{}, J.render(J.Arr{tail}, True{}, prefix), suffix)),
                            Equal.cong(String, String, text => "[" ++ J.render(head, False{}, text),
                                J.render(J.Arr{tail}, True{}, prefix) ++ suffix,
                                J.render(J.Arr{tail}, True{}, prefix ++ suffix),
                                render_append(J.Arr{tail}, True{}, prefix, suffix))))
                case True{}:
                    Equal.trans(String, ("," ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix))) ++ suffix,
                        "," ++ (J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)) ++ suffix),
                        "," ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix ++ suffix)),
                        S.append_assoc(",", J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)), suffix),
                        Equal.trans(String, "," ++ (J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)) ++ suffix),
                            "," ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix) ++ suffix),
                            "," ++ J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix ++ suffix)),
                            Equal.cong(String, String, text => "," ++ text,
                                J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix)) ++ suffix,
                                J.render(head, False{}, J.render(J.Arr{tail}, True{}, prefix) ++ suffix),
                                render_append(head, False{}, J.render(J.Arr{tail}, True{}, prefix), suffix)),
                            Equal.cong(String, String, text => "," ++ J.render(head, False{}, text),
                                J.render(J.Arr{tail}, True{}, prefix) ++ suffix,
                                J.render(J.Arr{tail}, True{}, prefix ++ suffix),
                                render_append(J.Arr{tail}, True{}, prefix, suffix))))
        case J.Obj{Nil{}}:
            match members:
                case False{}: S.append_assoc("{}", prefix, suffix)
                case True{}: S.append_assoc("}", prefix, suffix)
        case J.Obj{(key, field_value) <> tail}:
            match members:
                case False{}:
                    Equal.trans(String,
                        J.render_object_field("{", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix))) ++ suffix,
                        J.render_object_field("{", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)) ++ suffix),
                        J.render_object_field("{", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix ++ suffix))),
                        render_object_field_append("{", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)), suffix),
                        Equal.cong(String, String, text => J.render_object_field("{", key, text),
                            J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)) ++ suffix,
                            J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix ++ suffix)),
                            nested_render_append(field_value, J.Obj{tail}, True{}, prefix, suffix,
                                render_append(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix), suffix),
                                render_append(J.Obj{tail}, True{}, prefix, suffix))))
                case True{}:
                    Equal.trans(String,
                        J.render_object_field(",", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix))) ++ suffix,
                        J.render_object_field(",", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)) ++ suffix),
                        J.render_object_field(",", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix ++ suffix))),
                        render_object_field_append(",", key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)), suffix),
                        Equal.cong(String, String, text => J.render_object_field(",", key, text),
                            J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)) ++ suffix,
                            J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix ++ suffix)),
                            nested_render_append(field_value, J.Obj{tail}, True{}, prefix, suffix,
                                render_append(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix), suffix),
                                render_append(J.Obj{tail}, True{}, prefix, suffix))))

def render_array_singleton_suffix(+head: J.Value,
                                  +suffix: String) -> {J.render(J.Arr{head <> Nil{}}, False{}, suffix) == "[" ++ (J.render(head, False{}, SNil{}) ++ ("]" ++ suffix)) : String}:
    Equal.cong(String, String, text => "[" ++ text,
        J.render(head, False{}, J.render(J.Arr{Nil{}}, True{}, suffix)),
        J.render(head, False{}, SNil{}) ++ ("]" ++ suffix),
        Equal.trans(String,
            J.render(head, False{}, J.render(J.Arr{Nil{}}, True{}, suffix)),
            J.render(head, False{}, "]") ++ suffix,
            J.render(head, False{}, SNil{}) ++ ("]" ++ suffix),
            Equal.sym(String, J.render(head, False{}, "]") ++ suffix,
                J.render(head, False{}, J.render(J.Arr{Nil{}}, True{}, suffix)),
                nested_render_append(head, J.Arr{Nil{}}, True{}, SNil{}, suffix,
                    render_append(head, False{}, "]", suffix),
                    render_append(J.Arr{Nil{}}, True{}, SNil{}, suffix))),
            Equal.trans(String,
                J.render(head, False{}, "]") ++ suffix,
                (J.render(head, False{}, SNil{}) ++ "]") ++ suffix,
                J.render(head, False{}, SNil{}) ++ ("]" ++ suffix),
                Equal.cong(String, String, text => text ++ suffix,
                    J.render(head, False{}, "]"), J.render(head, False{}, SNil{}) ++ "]",
                    Equal.sym(String, J.render(head, False{}, SNil{}) ++ "]",
                        J.render(head, False{}, "]"), render_append(head, False{}, SNil{}, "]"))),
                S.append_assoc(J.render(head, False{}, SNil{}), "]", suffix))))

def lex_source_number_before_punctuation(+text: String,
                                         +certificate: J.NumberCert<text>,
                                         +punctuation: Char,
                                         +suffix: String,
                                         +acc: List<&2, J.Lexeme>,
                                         action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(J.Number{text, certificate}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{text} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render(J.Number{text, certificate}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(text ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{text} <> acc),
        Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            J.render(J.Number{text, certificate}, False{}, SNil{}), text,
            S.append_nil(text)),
        Num.lex_certified_number_before_punctuation(text, certificate, punctuation, suffix, acc, action))


type AtomicValue is Data:
    AtomicNull{}
    AtomicTrue{}
    AtomicFalse{}
    AtomicNumber{text: String, certificate: J.NumberCert<text>}
    AtomicString{text: String}

type SimpleValue is Data:
    SimpleAtom{atom: AtomicValue}
    SimpleEmptyArray{}
    SimpleEmptyObject{}

def atomic_value(atom: AtomicValue) -> J.Value:
    match atom:
        case AtomicNull{}: J.Null{}
        case AtomicTrue{}: J.Bool{True{}}
        case AtomicFalse{}: J.Bool{False{}}
        case AtomicNumber{text, certificate}: J.Number{text, certificate}
        case AtomicString{text}: J.Str{text}

def simple_value(simple: SimpleValue) -> J.Value:
    match simple:
        case SimpleAtom{atom}: atomic_value(atom)
        case SimpleEmptyArray{}: J.Arr{Nil{}}
        case SimpleEmptyObject{}: J.Obj{Nil{}}

type RenderMode is Data:
    RenderWhole{}
    RenderMembers{}
    RenderAfterSeparator{}

type JsonPunctuation is Data:
    ArrayEnd{}
    ObjectEnd{}
    MemberComma{}
    KeyColon{}

def punctuation_char(mark: JsonPunctuation) -> Char:
    match mark:
        case ArrayEnd{}: ']'
        case ObjectEnd{}: '}'
        case MemberComma{}: ','
        case KeyColon{}: ':'

def punctuation_action(mark: JsonPunctuation,
                       suffix: String) -> {J.lex_seed_action(SCon{punctuation_char(mark), suffix}, J.Outside{}) == J.LexPunctuation{punctuation_char(mark)} : J.LexAction}:
    match mark:
        case ArrayEnd{}: {==}
        case ObjectEnd{}: {==}
        case MemberComma{}: {==}
        case KeyColon{}: {==}

def render_after_separator(value: J.Value, suffix: String) -> String:
    match value:
        case J.Arr{Nil{}}: "]" ++ suffix
        case J.Arr{head <> tail}: J.render(head, False{}, J.render(J.Arr{tail}, True{}, suffix))
        case J.Obj{Nil{}}: "}" ++ suffix
        case J.Obj{(key, field_value) <> tail}:
            J.render_object_field(SNil{}, key, J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, suffix)))
        case _: J.render(value, False{}, suffix)

def render_task(value: J.Value, mode: RenderMode, suffix: String) -> String:
    match mode:
        case RenderWhole{}: J.render(value, False{}, suffix)
        case RenderMembers{}: J.render(value, True{}, suffix)
        case RenderAfterSeparator{}: render_after_separator(value, suffix)

def source_after_separator(value: J.Value, suffix: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match value:
        case J.Arr{Nil{}}: J.Punctuation{']'} <> suffix
        case J.Arr{head <> tail}: J.source(head, False{}, J.source(J.Arr{tail}, True{}, suffix))
        case J.Obj{Nil{}}: J.Punctuation{'}'} <> suffix
        case J.Obj{(key, field_value) <> tail}:
            J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, suffix)))
        case _: J.source(value, False{}, suffix)

def source_task(value: J.Value, mode: RenderMode, suffix: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match mode:
        case RenderWhole{}: J.source(value, False{}, suffix)
        case RenderMembers{}: J.source(value, True{}, suffix)
        case RenderAfterSeparator{}: source_after_separator(value, suffix)

def reverse_source_task(value: J.Value, mode: RenderMode) -> List<&2, J.Lexeme>:
    List.reverse(&2, J.Lexeme, source_task(value, mode, Nil{}))

def source_text_append(+text: String,
                       +first: List<&2, J.Lexeme>,
                       +second: List<&2, J.Lexeme>) -> {J.source_text(text, List.append(&2, J.Lexeme, first, second)) == List.append(&2, J.Lexeme, J.source_text(text, first), second) : List<&2, J.Lexeme>}:
    {==}

def source_append(+value: J.Value,
                  +members: Bool,
                  +first: List<&2, J.Lexeme>,
                  +second: List<&2, J.Lexeme>) -> {J.source(value, members, List.append(&2, J.Lexeme, first, second)) == List.append(&2, J.Lexeme, J.source(value, members, first), second) : List<&2, J.Lexeme>}:
    match value:
        case J.Null{}: source_text_append("null", first, second)
        case J.Bool{truth}:
            match truth:
                case True{}: source_text_append("true", first, second)
                case False{}: source_text_append("false", first, second)
        case J.Number{lexeme, certificate}: source_text_append(lexeme, first, second)
        case J.Str{text}: source_text_append("\"" ++ J.escape_string(text) ++ "\"", first, second)
        case J.Arr{Nil{}}:
            match members:
                case False{}: {==}
                case True{}: {==}
        case J.Arr{head <> tail}:
            match members:
                case False{}:
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.Punctuation{'['} <> xs,
                        J.source(head, False{}, J.source(J.Arr{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                        List.append(&2, J.Lexeme, J.source(head, False{}, J.source(J.Arr{tail}, True{}, first)), second),
                        Equal.trans(List<&2, J.Lexeme>,
                            J.source(head, False{}, J.source(J.Arr{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                            J.source(head, False{}, List.append(&2, J.Lexeme, J.source(J.Arr{tail}, True{}, first), second)),
                            List.append(&2, J.Lexeme, J.source(head, False{}, J.source(J.Arr{tail}, True{}, first)), second),
                            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.source(head, False{}, xs),
                                J.source(J.Arr{tail}, True{}, List.append(&2, J.Lexeme, first, second)),
                                List.append(&2, J.Lexeme, J.source(J.Arr{tail}, True{}, first), second),
                                source_append(J.Arr{tail}, True{}, first, second)),
                            source_append(head, False{}, J.source(J.Arr{tail}, True{}, first), second)))
                case True{}:
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.Punctuation{','} <> xs,
                        J.source(head, False{}, J.source(J.Arr{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                        List.append(&2, J.Lexeme, J.source(head, False{}, J.source(J.Arr{tail}, True{}, first)), second),
                        Equal.trans(List<&2, J.Lexeme>,
                            J.source(head, False{}, J.source(J.Arr{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                            J.source(head, False{}, List.append(&2, J.Lexeme, J.source(J.Arr{tail}, True{}, first), second)),
                            List.append(&2, J.Lexeme, J.source(head, False{}, J.source(J.Arr{tail}, True{}, first)), second),
                            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.source(head, False{}, xs),
                                J.source(J.Arr{tail}, True{}, List.append(&2, J.Lexeme, first, second)),
                                List.append(&2, J.Lexeme, J.source(J.Arr{tail}, True{}, first), second),
                                source_append(J.Arr{tail}, True{}, first, second)),
                            source_append(head, False{}, J.source(J.Arr{tail}, True{}, first), second)))
        case J.Obj{Nil{}}:
            match members:
                case False{}: {==}
                case True{}: {==}
        case J.Obj{(key, field_value) <> tail}:
            match members:
                case False{}:
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.Punctuation{'{'} <> xs,
                        J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second)))),
                        List.append(&2, J.Lexeme, J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, first))), second),
                        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> xs),
                            J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                            List.append(&2, J.Lexeme, J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, first)), second),
                            Equal.trans(List<&2, J.Lexeme>,
                                J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                                J.source(field_value, False{}, List.append(&2, J.Lexeme, J.source(J.Obj{tail}, True{}, first), second)),
                                List.append(&2, J.Lexeme, J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, first)), second),
                                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.source(field_value, False{}, xs),
                                    J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second)),
                                    List.append(&2, J.Lexeme, J.source(J.Obj{tail}, True{}, first), second),
                                    source_append(J.Obj{tail}, True{}, first, second)),
                                source_append(field_value, False{}, J.source(J.Obj{tail}, True{}, first), second))))
                case True{}:
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.Punctuation{','} <> xs,
                        J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second)))),
                        List.append(&2, J.Lexeme, J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, first))), second),
                        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.source_text("\"" ++ J.escape_string(key) ++ "\"", J.Punctuation{':'} <> xs),
                            J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                            List.append(&2, J.Lexeme, J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, first)), second),
                            Equal.trans(List<&2, J.Lexeme>,
                                J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second))),
                                J.source(field_value, False{}, List.append(&2, J.Lexeme, J.source(J.Obj{tail}, True{}, first), second)),
                                List.append(&2, J.Lexeme, J.source(field_value, False{}, J.source(J.Obj{tail}, True{}, first)), second),
                                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => J.source(field_value, False{}, xs),
                                    J.source(J.Obj{tail}, True{}, List.append(&2, J.Lexeme, first, second)),
                                    List.append(&2, J.Lexeme, J.source(J.Obj{tail}, True{}, first), second),
                                    source_append(J.Obj{tail}, True{}, first, second)),
                                source_append(field_value, False{}, J.source(J.Obj{tail}, True{}, first), second))))

def reverse_source_suffix(+value: J.Value,
                          +members: Bool,
                          +suffix: List<&2, J.Lexeme>) -> {List.reverse(&2, J.Lexeme, J.source(value, members, suffix)) == List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, suffix), List.reverse(&2, J.Lexeme, J.source(value, members, Nil{}))) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        List.reverse(&2, J.Lexeme, J.source(value, members, suffix)),
        List.reverse(&2, J.Lexeme, List.append(&2, J.Lexeme, J.source(value, members, Nil{}), suffix)),
        List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, suffix),
            List.reverse(&2, J.Lexeme, J.source(value, members, Nil{}))),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.reverse(&2, J.Lexeme, items),
            J.source(value, members, suffix),
            List.append(&2, J.Lexeme, J.source(value, members, Nil{}), suffix),
            source_append(value, members, Nil{}, suffix)),
        LP.reverse_append(J.Lexeme, J.source(value, members, Nil{}), suffix))

def reverse_source_text(+text: String,
                        +suffix: List<&2, J.Lexeme>) -> {List.reverse(&2, J.Lexeme, J.source_text(text, suffix)) == List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, suffix), J.Payload{text} <> Nil{}) : List<&2, J.Lexeme>}:
    LP.reverse_cons(J.Lexeme, J.Payload{text}, suffix)

def reverse_source_colon_value_tail(+value: J.Value,
                                    +tail: List<&2, Sigma<&2, &2, String, key => J.Value>>) -> {List.reverse(&2, J.Lexeme, J.Punctuation{':'} <> J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))) == List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}), List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        List.reverse(&2, J.Lexeme, J.Punctuation{':'} <> J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
        List.append(&2, J.Lexeme,
            List.reverse(&2, J.Lexeme, J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
            J.Punctuation{':'} <> Nil{}),
        List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
            List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})),
        LP.reverse_cons(J.Lexeme, J.Punctuation{':'}, J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
        Equal.trans(List<&2, J.Lexeme>,
            List.append(&2, J.Lexeme,
                List.reverse(&2, J.Lexeme, J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
                J.Punctuation{':'} <> Nil{}),
            List.append(&2, J.Lexeme,
                List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}), reverse_source_task(value, RenderWhole{})),
                J.Punctuation{':'} <> Nil{}),
            List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs =>
                List.append(&2, J.Lexeme, xs, J.Punctuation{':'} <> Nil{}),
                List.reverse(&2, J.Lexeme, J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
                List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}), reverse_source_task(value, RenderWhole{})),
                reverse_source_suffix(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
            LP.append_assoc(J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})))

def reverse_source_object_after_separator(+key: String,
                                          +value: J.Value,
                                          +tail: List<&2, Sigma<&2, &2, String, key => J.Value>>) -> {reverse_source_task(J.Obj{(key, value) <> tail}, RenderAfterSeparator{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}), List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        reverse_source_task(J.Obj{(key, value) <> tail}, RenderAfterSeparator{}),
        List.append(&2, J.Lexeme,
            List.reverse(&2, J.Lexeme, J.Punctuation{':'} <> J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
            J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
        List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
            List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}),
                J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})),
        reverse_source_text("\"" ++ J.escape_string(key) ++ "\"",
            J.Punctuation{':'} <> J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
        Equal.trans(List<&2, J.Lexeme>,
            List.append(&2, J.Lexeme,
                List.reverse(&2, J.Lexeme, J.Punctuation{':'} <> J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
                J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
            List.append(&2, J.Lexeme,
                List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})),
                J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
            List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}),
                    J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs =>
                List.append(&2, J.Lexeme, xs, J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
                List.reverse(&2, J.Lexeme, J.Punctuation{':'} <> J.source(value, False{}, J.source(J.Obj{tail}, True{}, Nil{}))),
                List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})),
                reverse_source_colon_value_tail(value, tail)),
            Equal.trans(List<&2, J.Lexeme>,
                List.append(&2, J.Lexeme,
                    List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                        List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{})),
                    J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
                List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme,
                        List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{}),
                        J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})),
                List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}),
                        J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})),
                LP.append_assoc(J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{}),
                    J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs =>
                    List.append(&2, J.Lexeme, reverse_source_task(J.Obj{tail}, RenderMembers{}), xs),
                    List.append(&2, J.Lexeme,
                        List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{}),
                        J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{}),
                    List.append(&2, J.Lexeme, reverse_source_task(value, RenderWhole{}),
                        List.append(&2, J.Lexeme, J.Punctuation{':'} <> Nil{}, J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})),
                    LP.append_assoc(J.Lexeme, reverse_source_task(value, RenderWhole{}), J.Punctuation{':'} <> Nil{},
                        J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> Nil{})))))

def reverse_source_object_members_after_separator(+key: String,
                                                  +value: J.Value,
                                                  +tail: List<&2, Sigma<&2, &2, String, key => J.Value>>) -> {reverse_source_task(J.Obj{(key, value) <> tail}, RenderMembers{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Obj{(key, value) <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        reverse_source_task(J.Obj{(key, value) <> tail}, RenderMembers{}),
        List.reverse(&2, J.Lexeme, J.Punctuation{','} <> source_after_separator(J.Obj{(key, value) <> tail}, Nil{})),
        List.append(&2, J.Lexeme, reverse_source_task(J.Obj{(key, value) <> tail}, RenderAfterSeparator{}),
            J.Punctuation{','} <> Nil{}),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.reverse(&2, J.Lexeme, items),
            J.source(J.Obj{(key, value) <> tail}, True{}, Nil{}),
            J.Punctuation{','} <> source_after_separator(J.Obj{(key, value) <> tail}, Nil{}),
            {==}),
        LP.reverse_cons(J.Lexeme, J.Punctuation{','}, source_after_separator(J.Obj{(key, value) <> tail}, Nil{})))

def reverse_source_array_whole(+head: J.Value,
                               +tail: List<&2, J.Value>) -> {reverse_source_task(J.Arr{head <> tail}, RenderWhole{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        reverse_source_task(J.Arr{head <> tail}, RenderWhole{}),
        List.reverse(&2, J.Lexeme, List.append(&2, J.Lexeme,
            J.Punctuation{'['} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{}))),
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
            List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.reverse(&2, J.Lexeme, items),
            J.source(J.Arr{head <> tail}, False{}, Nil{}),
            List.append(&2, J.Lexeme, J.Punctuation{'['} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.Punctuation{'['} <> items,
                J.source(head, False{}, J.source(J.Arr{tail}, True{}, Nil{})),
                List.append(&2, J.Lexeme, J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{})),
                source_append(head, False{}, Nil{}, J.source(J.Arr{tail}, True{}, Nil{})))),
        Equal.trans(List<&2, J.Lexeme>,
            List.reverse(&2, J.Lexeme, List.append(&2, J.Lexeme,
                J.Punctuation{'['} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{}))),
            List.append(&2, J.Lexeme,
                List.reverse(&2, J.Lexeme, J.source(J.Arr{tail}, True{}, Nil{})),
                List.reverse(&2, J.Lexeme, J.Punctuation{'['} <> J.source(head, False{}, Nil{}))),
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})),
            LP.reverse_append(J.Lexeme, J.Punctuation{'['} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), items),
                List.reverse(&2, J.Lexeme, J.Punctuation{'['} <> J.source(head, False{}, Nil{})),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{}),
                LP.reverse_cons(J.Lexeme, J.Punctuation{'['}, J.source(head, False{}, Nil{})))))

def reverse_source_array_members(+head: J.Value,
                                 +tail: List<&2, J.Value>) -> {reverse_source_task(J.Arr{head <> tail}, RenderMembers{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{','} <> Nil{})) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        reverse_source_task(J.Arr{head <> tail}, RenderMembers{}),
        List.reverse(&2, J.Lexeme, List.append(&2, J.Lexeme,
            J.Punctuation{','} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{}))),
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
            List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{','} <> Nil{})),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.reverse(&2, J.Lexeme, items),
            J.source(J.Arr{head <> tail}, True{}, Nil{}),
            List.append(&2, J.Lexeme, J.Punctuation{','} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.Punctuation{','} <> items,
                J.source(head, False{}, J.source(J.Arr{tail}, True{}, Nil{})),
                List.append(&2, J.Lexeme, J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{})),
                source_append(head, False{}, Nil{}, J.source(J.Arr{tail}, True{}, Nil{})))),
        Equal.trans(List<&2, J.Lexeme>,
            List.reverse(&2, J.Lexeme, List.append(&2, J.Lexeme,
                J.Punctuation{','} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{}))),
            List.append(&2, J.Lexeme,
                List.reverse(&2, J.Lexeme, J.source(J.Arr{tail}, True{}, Nil{})),
                List.reverse(&2, J.Lexeme, J.Punctuation{','} <> J.source(head, False{}, Nil{}))),
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{','} <> Nil{})),
            LP.reverse_append(J.Lexeme, J.Punctuation{','} <> J.source(head, False{}, Nil{}), J.source(J.Arr{tail}, True{}, Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), items),
                List.reverse(&2, J.Lexeme, J.Punctuation{','} <> J.source(head, False{}, Nil{})),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{','} <> Nil{}),
                LP.reverse_cons(J.Lexeme, J.Punctuation{','}, J.source(head, False{}, Nil{})))))

def reverse_source_array_after_separator(+head: J.Value,
                                         +tail: List<&2, J.Value>) -> {reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})) : List<&2, J.Lexeme>}:
    reverse_source_suffix(head, False{}, J.source(J.Arr{tail}, True{}, Nil{}))

def reverse_source_array_after_separator_whole(+head: J.Value,
                                               +tail: List<&2, J.Value>) -> {reverse_source_task(J.Arr{head <> tail}, RenderWhole{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{}) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        reverse_source_task(J.Arr{head <> tail}, RenderWhole{}),
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
            List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})),
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{}),
        reverse_source_array_whole(head, tail),
        Equal.trans(List<&2, J.Lexeme>,
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})),
            List.append(&2, J.Lexeme,
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})),
                J.Punctuation{'['} <> Nil{}),
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{}),
            Equal.sym(List<&2, J.Lexeme>,
                List.append(&2, J.Lexeme,
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})),
                    J.Punctuation{'['} <> Nil{}),
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})),
                LP.append_assoc(J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}),
                    reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> Nil{})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items =>
                List.append(&2, J.Lexeme, items, J.Punctuation{'['} <> Nil{}),
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})),
                reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}),
                Equal.sym(List<&2, J.Lexeme>, reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}),
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})),
                    reverse_source_array_after_separator(head, tail)))))

def reverse_source_array_members_after_separator(+head: J.Value,
                                                 +tail: List<&2, J.Value>) -> {reverse_source_task(J.Arr{head <> tail}, RenderMembers{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        reverse_source_task(J.Arr{head <> tail}, RenderMembers{}),
        List.reverse(&2, J.Lexeme, J.Punctuation{','} <> source_after_separator(J.Arr{head <> tail}, Nil{})),
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> tail}, RenderAfterSeparator{}),
            J.Punctuation{','} <> Nil{}),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => List.reverse(&2, J.Lexeme, items),
            J.source(J.Arr{head <> tail}, True{}, Nil{}),
            J.Punctuation{','} <> source_after_separator(J.Arr{head <> tail}, Nil{}),
            {==}),
        LP.reverse_cons(J.Lexeme, J.Punctuation{','}, source_after_separator(J.Arr{head <> tail}, Nil{})))

def source_separator(value: J.Value) -> List<&2, J.Lexeme>:
    match value:
        case J.Arr{Nil{}}: Nil{}
        case J.Arr{_ <> _}: J.Punctuation{','} <> Nil{}
        case J.Obj{Nil{}}: Nil{}
        case J.Obj{_ <> _}: J.Punctuation{','} <> Nil{}
        case _: Nil{}

def separator_text(value: J.Value) -> String:
    match value:
        case J.Arr{Nil{}}: SNil{}
        case J.Arr{_ <> _}: ","
        case J.Obj{Nil{}}: SNil{}
        case J.Obj{_ <> _}: ","
        case _: SNil{}

def render_members_decompose(+value: J.Value,
                             +suffix: String) -> {J.render(value, True{}, suffix) == separator_text(value) ++ render_after_separator(value, suffix) : String}:
    match value:
        case J.Null{}: {==}
        case J.Bool{truth}:
            match truth:
                case True{}: {==}
                case False{}: {==}
        case J.Number{lexeme, certificate}: {==}
        case J.Str{text}: {==}
        case J.Arr{Nil{}}: {==}
        case J.Arr{head <> tail}: {==}
        case J.Obj{Nil{}}: {==}
        case J.Obj{(key, field_value) <> tail}: {==}

def render_after_separator_array_decompose(+head: J.Value,
                                           +tail: List<&2, J.Value>,
                                           +suffix: String) -> {render_after_separator(J.Arr{head <> tail}, suffix) == J.render(head, False{}, SNil{}) ++ (separator_text(J.Arr{tail}) ++ render_after_separator(J.Arr{tail}, suffix)) : String}:
    Equal.trans(String,
        render_after_separator(J.Arr{head <> tail}, suffix),
        J.render(head, False{}, SNil{}) ++ J.render(J.Arr{tail}, True{}, suffix),
        J.render(head, False{}, SNil{}) ++
            (separator_text(J.Arr{tail}) ++ render_after_separator(J.Arr{tail}, suffix)),
        Equal.sym(String,
            J.render(head, False{}, SNil{}) ++ J.render(J.Arr{tail}, True{}, suffix),
            render_after_separator(J.Arr{head <> tail}, suffix),
            render_append(head, False{}, SNil{}, J.render(J.Arr{tail}, True{}, suffix))),
        Equal.cong(String, String, text => J.render(head, False{}, SNil{}) ++ text,
            J.render(J.Arr{tail}, True{}, suffix),
            separator_text(J.Arr{tail}) ++ render_after_separator(J.Arr{tail}, suffix),
            render_members_decompose(J.Arr{tail}, suffix)))

def render_after_separator_object_decompose(+key: String,
                                            +value: J.Value,
                                            +tail: List<&2, Sigma<&2, &2, String, key => J.Value>>, +suffix: String) -> {render_after_separator(J.Obj{(key, value) <> tail}, suffix) == J.render_object_field(SNil{}, key, J.render(value, False{}, SNil{}) ++ (separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix))) : String}:
    Equal.cong(String, String, text => J.render_object_field(SNil{}, key, text),
        J.render(value, False{}, J.render(J.Obj{tail}, True{}, suffix)),
        J.render(value, False{}, SNil{}) ++
            (separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix)),
        Equal.trans(String,
            J.render(value, False{}, J.render(J.Obj{tail}, True{}, suffix)),
            J.render(value, False{}, SNil{}) ++ J.render(J.Obj{tail}, True{}, suffix),
            J.render(value, False{}, SNil{}) ++
                (separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix)),
            Equal.sym(String,
                J.render(value, False{}, SNil{}) ++ J.render(J.Obj{tail}, True{}, suffix),
                J.render(value, False{}, J.render(J.Obj{tail}, True{}, suffix)),
                render_append(value, False{}, SNil{}, J.render(J.Obj{tail}, True{}, suffix))),
            Equal.cong(String, String, text => J.render(value, False{}, SNil{}) ++ text,
                J.render(J.Obj{tail}, True{}, suffix),
                separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix),
                render_members_decompose(J.Obj{tail}, suffix))))

def render_object_whole_decompose(+key: String,
                                  +value: J.Value,
                                  +tail: List<&2, Sigma<&2, &2, String, key => J.Value>>, +suffix: String) -> {J.render(J.Obj{(key, value) <> tail}, False{}, suffix) == J.render_object_field("{", key, J.render(value, False{}, SNil{}) ++ (separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix))) : String}:
    Equal.cong(String, String, text => J.render_object_field("{", key, text),
        J.render(value, False{}, J.render(J.Obj{tail}, True{}, suffix)),
        J.render(value, False{}, SNil{}) ++
            (separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix)),
        Equal.trans(String,
            J.render(value, False{}, J.render(J.Obj{tail}, True{}, suffix)),
            J.render(value, False{}, SNil{}) ++ J.render(J.Obj{tail}, True{}, suffix),
            J.render(value, False{}, SNil{}) ++
                (separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix)),
            Equal.sym(String,
                J.render(value, False{}, SNil{}) ++ J.render(J.Obj{tail}, True{}, suffix),
                J.render(value, False{}, J.render(J.Obj{tail}, True{}, suffix)),
                render_append(value, False{}, SNil{}, J.render(J.Obj{tail}, True{}, suffix))),
            Equal.cong(String, String, text => J.render(value, False{}, SNil{}) ++ text,
                J.render(J.Obj{tail}, True{}, suffix),
                separator_text(J.Obj{tail}) ++ render_after_separator(J.Obj{tail}, suffix),
                render_members_decompose(J.Obj{tail}, suffix))))

def render_array_whole_decompose(+head: J.Value,
                                 +tail: List<&2, J.Value>,
                                 +suffix: String) -> {J.render(J.Arr{head <> tail}, False{}, suffix) == "[" ++ (J.render(head, False{}, SNil{}) ++ (separator_text(J.Arr{tail}) ++ render_after_separator(J.Arr{tail}, suffix))) : String}:
    Equal.cong(String, String, text => "[" ++ text,
        render_after_separator(J.Arr{head <> tail}, suffix),
        J.render(head, False{}, SNil{}) ++
            (separator_text(J.Arr{tail}) ++ render_after_separator(J.Arr{tail}, suffix)),
        render_after_separator_array_decompose(head, tail, suffix))

def render_after_separator_append(+value: J.Value,
                                  +prefix: String,
                                  +suffix: String) -> {render_after_separator(value, prefix) ++ suffix == render_after_separator(value, prefix ++ suffix) : String}:
    match value:
        case J.Arr{Nil{}}: S.append_assoc("]", prefix, suffix)
        case J.Arr{head <> tail}:
            nested_render_append(head, J.Arr{tail}, True{}, prefix, suffix,
                render_append(head, False{}, J.render(J.Arr{tail}, True{}, prefix), suffix),
                render_append(J.Arr{tail}, True{}, prefix, suffix))
        case J.Obj{Nil{}}: S.append_assoc("}", prefix, suffix)
        case J.Obj{(key, field_value) <> tail}:
            Equal.trans(String,
                render_after_separator(J.Obj{(key, field_value) <> tail}, prefix) ++ suffix,
                J.render_object_field(SNil{}, key,
                    J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)) ++ suffix),
                render_after_separator(J.Obj{(key, field_value) <> tail}, prefix ++ suffix),
                render_object_field_append(SNil{}, key,
                    J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)), suffix),
                Equal.cong(String, String, text => J.render_object_field(SNil{}, key, text),
                    J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix)) ++ suffix,
                    J.render(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix ++ suffix)),
                    nested_render_append(field_value, J.Obj{tail}, True{}, prefix, suffix,
                        render_append(field_value, False{}, J.render(J.Obj{tail}, True{}, prefix), suffix),
                        render_append(J.Obj{tail}, True{}, prefix, suffix))))
        case J.Null{}: render_append(J.Null{}, False{}, prefix, suffix)
        case J.Bool{truth}:
            match truth:
                case True{}: render_append(J.Bool{True{}}, False{}, prefix, suffix)
                case False{}: render_append(J.Bool{False{}}, False{}, prefix, suffix)
        case J.Number{lexeme, certificate}:
            render_append(J.Number{lexeme, certificate}, False{}, prefix, suffix)
        case J.Str{text}: render_append(J.Str{text}, False{}, prefix, suffix)

def render_task_append(+value: J.Value,
                       +mode: RenderMode,
                       +prefix: String,
                       +suffix: String) -> {render_task(value, mode, prefix) ++ suffix == render_task(value, mode, prefix ++ suffix) : String}:
    match mode:
        case RenderWhole{}: render_append(value, False{}, prefix, suffix)
        case RenderMembers{}: render_append(value, True{}, prefix, suffix)
        case RenderAfterSeparator{}: render_after_separator_append(value, prefix, suffix)

def render_after_separator_array_single(+head: J.Value,
                                        +suffix: String) -> {render_after_separator(J.Arr{head <> Nil{}}, suffix) == render_task(head, RenderWhole{}, "]" ++ suffix) : String}:
    Equal.trans(String,
        render_after_separator(J.Arr{head <> Nil{}}, suffix),
        J.render(head, False{}, SNil{}) ++ (separator_text(J.Arr{Nil{}}) ++ render_after_separator(J.Arr{Nil{}}, suffix)),
        render_task(head, RenderWhole{}, "]" ++ suffix),
        render_after_separator_array_decompose(head, Nil{}, suffix),
        Equal.trans(String,
            J.render(head, False{}, SNil{}) ++ (separator_text(J.Arr{Nil{}}) ++ render_after_separator(J.Arr{Nil{}}, suffix)),
            J.render(head, False{}, SNil{}) ++ ("]" ++ suffix),
            render_task(head, RenderWhole{}, "]" ++ suffix),
            Equal.cong(String, String, text => J.render(head, False{}, SNil{}) ++ text,
                separator_text(J.Arr{Nil{}}) ++ render_after_separator(J.Arr{Nil{}}, suffix), "]" ++ suffix, {==}),
            render_task_append(head, RenderWhole{}, SNil{}, "]" ++ suffix)))

def render_after_separator_array_many(+head: J.Value,
                                      +next: J.Value,
                                      +tail: List<&2, J.Value>,
                                      +suffix: String) -> {render_after_separator(J.Arr{head <> next <> tail}, suffix) == render_task(head, RenderWhole{}, "," ++ render_after_separator(J.Arr{next <> tail}, suffix)) : String}:
    Equal.trans(String,
        render_after_separator(J.Arr{head <> next <> tail}, suffix),
        J.render(head, False{}, SNil{}) ++
            (separator_text(J.Arr{next <> tail}) ++ render_after_separator(J.Arr{next <> tail}, suffix)),
        render_task(head, RenderWhole{}, "," ++ render_after_separator(J.Arr{next <> tail}, suffix)),
        render_after_separator_array_decompose(head, next <> tail, suffix),
        render_task_append(head, RenderWhole{}, SNil{}, "," ++ render_after_separator(J.Arr{next <> tail}, suffix)))




def source_members_decompose(+value: J.Value,
                             +suffix: List<&2, J.Lexeme>) -> {J.source(value, True{}, suffix) == List.append(&2, J.Lexeme, source_separator(value), source_after_separator(value, suffix)) : List<&2, J.Lexeme>}:
    match value:
        case J.Null{}: {==}
        case J.Bool{truth}:
            match truth:
                case True{}: {==}
                case False{}: {==}
        case J.Number{lexeme, certificate}: {==}
        case J.Str{text}: {==}
        case J.Arr{Nil{}}: {==}
        case J.Arr{head <> tail}: {==}
        case J.Obj{Nil{}}: {==}
        case J.Obj{(key, field_value) <> tail}: {==}

def atomic_source(atom: AtomicValue) -> List<&2, J.Lexeme>:
    match atom:
        case AtomicNull{}: J.Payload{"null"} <> Nil{}
        case AtomicTrue{}: J.Payload{"true"} <> Nil{}
        case AtomicFalse{}: J.Payload{"false"} <> Nil{}
        case AtomicNumber{text, _}: J.Payload{text} <> Nil{}
        case AtomicString{text}: J.Payload{"\"" ++ J.escape_string(text) ++ "\""} <> Nil{}

def atomic_source_reverse(+atom: AtomicValue) -> {atomic_source(atom) == List.reverse(&2, J.Lexeme, J.source(atomic_value(atom), False{}, Nil{})) : List<&2, J.Lexeme>}:
    match atom:
        case AtomicNull{}: {==}
        case AtomicTrue{}: {==}
        case AtomicFalse{}: {==}
        case AtomicNumber{text, certificate}: {==}
        case AtomicString{text}: {==}

def lex_atomic_source_before_punctuation(+atom: AtomicValue,
                                         +punctuation: Char,
                                         +suffix: String,
                                         +acc: List<&2, J.Lexeme>,
                                         action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(atomic_value(atom), False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, atomic_source(atom), acc)) : List<&2, J.Lexeme>}:
    match atom:
        case AtomicNull{}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(J.Null{}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan("null" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, atomic_source(AtomicNull{}), acc)),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                    J.render(J.Null{}, False{}, SNil{}), "null", S.append_nil("null")),
                W.lex_null_before_punctuation(punctuation, suffix, acc, action))
        case AtomicTrue{}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(J.Bool{True{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan("true" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, atomic_source(AtomicTrue{}), acc)),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                    J.render(J.Bool{True{}}, False{}, SNil{}), "true", S.append_nil("true")),
                W.lex_true_before_punctuation(punctuation, suffix, acc, action))
        case AtomicFalse{}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(J.Bool{False{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan("false" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, atomic_source(AtomicFalse{}), acc)),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                    J.render(J.Bool{False{}}, False{}, SNil{}), "false", S.append_nil("false")),
                W.lex_false_before_punctuation(punctuation, suffix, acc, action))
        case AtomicNumber{text, certificate}:
            lex_source_number_before_punctuation(text, certificate, punctuation, suffix, acc, action)
        case AtomicString{text}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(J.Str{text}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan((SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, atomic_source(AtomicString{text}), acc)),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
                    J.render(J.Str{text}, False{}, SNil{}), SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}, {==}),
                W.lex_string_before_punctuation(text, punctuation, suffix, acc, action))

def lex_atomic_reverse_before_punctuation(+atom: AtomicValue,
                                          +punctuation: Char,
                                          +suffix: String,
                                          +acc: List<&2, J.Lexeme>,
                                          action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(atomic_value(atom), False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, J.source(atomic_value(atom), False{}, Nil{})), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render(atomic_value(atom), False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, atomic_source(atom), acc)),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, J.source(atomic_value(atom), False{}, Nil{})), acc)),
        lex_atomic_source_before_punctuation(atom, punctuation, suffix, acc, action),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, items, acc)),
            atomic_source(atom),
            List.reverse(&2, J.Lexeme, J.source(atomic_value(atom), False{}, Nil{})),
            atomic_source_reverse(atom)))

def lex_atomic_value_source(+atom: AtomicValue) -> {J.lex_scan(J.stringify(atomic_value(atom)), J.Outside{}, SNil{}, Nil{}) == J.source(atomic_value(atom), False{}, Nil{}) : List<&2, J.Lexeme>}:
    match atom:
        case AtomicNull{}: {==}
        case AtomicTrue{}: {==}
        case AtomicFalse{}: {==}
        case AtomicNumber{text, certificate}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.stringify(J.Number{text, certificate}), J.Outside{}, SNil{}, Nil{}),
                J.lex_scan(text, J.Outside{}, SNil{}, Nil{}),
                J.source(J.Number{text, certificate}, False{}, Nil{}),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source, J.Outside{}, SNil{}, Nil{}),
                    J.stringify(J.Number{text, certificate}), text, S.append_nil(text)),
                Equal.trans(List<&2, J.Lexeme>, J.lex_scan(text, J.Outside{}, SNil{}, Nil{}),
                    J.Payload{text} <> Nil{}, J.source(J.Number{text, certificate}, False{}, Nil{}),
                    Num.lex_number_payload(text, P.cert_valid(text, certificate)), {==}))
        case AtomicString{text}:
            W.lex_rendered_string(text)


def lex_source_empty_array_before_punctuation(+punctuation: Char,
                                              +suffix: String,
                                              +acc: List<&2, J.Lexeme>,
                                              action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(J.Arr{Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> J.Punctuation{'['} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render(J.Arr{Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan("[]" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> J.Punctuation{'['} <> acc),
        Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            J.render(J.Arr{Nil{}}, False{}, SNil{}), "[]", S.append_nil("[]")),
        W.lex_empty_array_before_punctuation(punctuation, suffix, acc, action))

def lex_source_empty_object_before_punctuation(+punctuation: Char,
                                               +suffix: String,
                                               +acc: List<&2, J.Lexeme>,
                                               action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(J.Obj{Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render(J.Obj{Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan("{}" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc),
        Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            J.render(J.Obj{Nil{}}, False{}, SNil{}), "{}", S.append_nil("{}")),
        W.lex_empty_object_before_punctuation(punctuation, suffix, acc, action))

def lex_empty_array_reverse_before_punctuation(+punctuation: Char,
                                               +suffix: String,
                                               +acc: List<&2, J.Lexeme>,
                                               action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(J.Arr{Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, J.source(J.Arr{Nil{}}, False{}, Nil{})), acc)) : List<&2, J.Lexeme>}:
    lex_source_empty_array_before_punctuation(punctuation, suffix, acc, action)

def lex_empty_object_reverse_before_punctuation(+punctuation: Char,
                                                +suffix: String,
                                                +acc: List<&2, J.Lexeme>,
                                                action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(J.Obj{Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, J.source(J.Obj{Nil{}}, False{}, Nil{})), acc)) : List<&2, J.Lexeme>}:
    lex_source_empty_object_before_punctuation(punctuation, suffix, acc, action)

def lex_simple_before_punctuation(+simple: SimpleValue,
                                  +punctuation: Char,
                                  +suffix: String,
                                  +acc: List<&2, J.Lexeme>,
                                  action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(simple_value(simple), False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, List.reverse(&2, J.Lexeme, J.source(simple_value(simple), False{}, Nil{})), acc)) : List<&2, J.Lexeme>}:
    match simple:
        case SimpleAtom{atom}: lex_atomic_reverse_before_punctuation(atom, punctuation, suffix, acc, action)
        case SimpleEmptyArray{}: lex_empty_array_reverse_before_punctuation(punctuation, suffix, acc, action)
        case SimpleEmptyObject{}: lex_empty_object_reverse_before_punctuation(punctuation, suffix, acc, action)

def lex_close_before_punctuation(+closing: Char,
                                 +punctuation: Char,
                                 +suffix: String,
                                 +acc: List<&2, J.Lexeme>,
                                 close_action: {J.lex_seed_action(SCon{closing, SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}) == J.LexPunctuation{closing} : J.LexAction},
                                 action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(SCon{closing, SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{closing} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(SCon{closing, SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{closing} <> acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{closing} <> acc),
        W.scan_punctuation_char(closing, SCon{punctuation, SNil{}} ++ suffix, SNil{}, acc, close_action),
        W.scan_punctuation_char(punctuation, suffix, SNil{}, J.Punctuation{closing} <> acc, action))

def lex_object_key_before_colon(+key: String,
                                +suffix: String,
                                +acc: List<&2, J.Lexeme>) -> {J.lex_scan(("\"" ++ J.escape_string(key) ++ "\"") ++ (":" ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> acc) : List<&2, J.Lexeme>}:
    W.lex_string_before_punctuation(key, ':', suffix, acc, {==})

def atomic_task_render(atom: AtomicValue,
                       mode: RenderMode) -> {render_task(atomic_value(atom), mode, SNil{}) == J.render(atomic_value(atom), False{}, SNil{}) : String}:
    match atom mode:
        case AtomicNull{} RenderWhole{}: {==}
        case AtomicTrue{} RenderWhole{}: {==}
        case AtomicFalse{} RenderWhole{}: {==}
        case AtomicNumber{text, certificate} RenderWhole{}: {==}
        case AtomicString{text} RenderWhole{}: {==}
        case AtomicNull{} RenderMembers{}: {==}
        case AtomicTrue{} RenderMembers{}: {==}
        case AtomicFalse{} RenderMembers{}: {==}
        case AtomicNumber{text, certificate} RenderMembers{}: {==}
        case AtomicString{text} RenderMembers{}: {==}
        case AtomicNull{} RenderAfterSeparator{}: {==}
        case AtomicTrue{} RenderAfterSeparator{}: {==}
        case AtomicFalse{} RenderAfterSeparator{}: {==}
        case AtomicNumber{text, certificate} RenderAfterSeparator{}: {==}
        case AtomicString{text} RenderAfterSeparator{}: {==}

def atomic_task_source(atom: AtomicValue,
                       mode: RenderMode) -> {reverse_source_task(atomic_value(atom), mode) == reverse_source_task(atomic_value(atom), RenderWhole{}) : List<&2, J.Lexeme>}:
    match atom mode:
        case AtomicNull{} RenderWhole{}: {==}
        case AtomicTrue{} RenderWhole{}: {==}
        case AtomicFalse{} RenderWhole{}: {==}
        case AtomicNumber{text, certificate} RenderWhole{}: {==}
        case AtomicString{text} RenderWhole{}: {==}
        case AtomicNull{} RenderMembers{}: {==}
        case AtomicTrue{} RenderMembers{}: {==}
        case AtomicFalse{} RenderMembers{}: {==}
        case AtomicNumber{text, certificate} RenderMembers{}: {==}
        case AtomicString{text} RenderMembers{}: {==}
        case AtomicNull{} RenderAfterSeparator{}: {==}
        case AtomicTrue{} RenderAfterSeparator{}: {==}
        case AtomicFalse{} RenderAfterSeparator{}: {==}
        case AtomicNumber{text, certificate} RenderAfterSeparator{}: {==}
        case AtomicString{text} RenderAfterSeparator{}: {==}

def lex_atomic_task_before_punctuation(+atom: AtomicValue,
                                       +mode: RenderMode,
                                       +punctuation: Char,
                                       +suffix: String,
                                       +acc: List<&2, J.Lexeme>,
                                       action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(render_task(atomic_value(atom), mode, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, reverse_source_task(atomic_value(atom), mode), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(render_task(atomic_value(atom), mode, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix),
            J.Outside{}, SNil{}, acc),
        J.lex_scan(J.render(atomic_value(atom), False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix),
            J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
            List.append(&2, J.Lexeme, reverse_source_task(atomic_value(atom), mode), acc)),
        Equal.cong(String, List<&2, J.Lexeme>, text =>
            J.lex_scan(text ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            render_task(atomic_value(atom), mode, SNil{}), J.render(atomic_value(atom), False{}, SNil{}),
            atomic_task_render(atom, mode)),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(J.render(atomic_value(atom), False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix),
                J.Outside{}, SNil{}, acc),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
                List.append(&2, J.Lexeme, reverse_source_task(atomic_value(atom), RenderWhole{}), acc)),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
                List.append(&2, J.Lexeme, reverse_source_task(atomic_value(atom), mode), acc)),
            lex_atomic_reverse_before_punctuation(atom, punctuation, suffix, acc, action),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items =>
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
                    List.append(&2, J.Lexeme, items, acc)),
                reverse_source_task(atomic_value(atom), RenderWhole{}),
                reverse_source_task(atomic_value(atom), mode),
                Equal.sym(List<&2, J.Lexeme>, reverse_source_task(atomic_value(atom), mode),
                    reverse_source_task(atomic_value(atom), RenderWhole{}), atomic_task_source(atom, mode)))))

def lex_simple_task_before_punctuation(+simple: SimpleValue,
                                       +mode: RenderMode,
                                       +punctuation: Char,
                                       +suffix: String,
                                       +acc: List<&2, J.Lexeme>,
                                       action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(render_task(simple_value(simple), mode, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(simple), mode), acc)) : List<&2, J.Lexeme>}:
    match simple mode:
        case SimpleAtom{atom} RenderWhole{}:
            lex_atomic_task_before_punctuation(atom, RenderWhole{}, punctuation, suffix, acc, action)
        case SimpleAtom{atom} RenderMembers{}:
            lex_atomic_task_before_punctuation(atom, RenderMembers{}, punctuation, suffix, acc, action)
        case SimpleAtom{atom} RenderAfterSeparator{}:
            lex_atomic_task_before_punctuation(atom, RenderAfterSeparator{}, punctuation, suffix, acc, action)
        case SimpleEmptyArray{} RenderWhole{}:
            lex_empty_array_reverse_before_punctuation(punctuation, suffix, acc, action)
        case SimpleEmptyArray{} RenderMembers{}:
            lex_close_before_punctuation(']', punctuation, suffix, acc, {==}, action)
        case SimpleEmptyArray{} RenderAfterSeparator{}:
            lex_close_before_punctuation(']', punctuation, suffix, acc, {==}, action)
        case SimpleEmptyObject{} RenderWhole{}:
            lex_empty_object_reverse_before_punctuation(punctuation, suffix, acc, action)
        case SimpleEmptyObject{} RenderMembers{}:
            lex_close_before_punctuation('}', punctuation, suffix, acc, {==}, action)
        case SimpleEmptyObject{} RenderAfterSeparator{}:
            lex_close_before_punctuation('}', punctuation, suffix, acc, {==}, action)

def lex_simple_task_suffix_before_punctuation(+simple: SimpleValue,
                                              +mode: RenderMode,
                                              +punctuation: Char,
                                              +suffix: String,
                                              +acc: List<&2, J.Lexeme>,
                                              action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(render_task(simple_value(simple), mode, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(simple), mode), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(render_task(simple_value(simple), mode, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(render_task(simple_value(simple), mode, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
            List.append(&2, J.Lexeme, reverse_source_task(simple_value(simple), mode), acc)),
        Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
            render_task(simple_value(simple), mode, SCon{punctuation, SNil{}} ++ suffix),
            render_task(simple_value(simple), mode, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix),
            Equal.sym(String,
                render_task(simple_value(simple), mode, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix),
                render_task(simple_value(simple), mode, SCon{punctuation, SNil{}} ++ suffix),
                render_task_append(simple_value(simple), mode, SNil{}, SCon{punctuation, SNil{}} ++ suffix))),
        lex_simple_task_before_punctuation(simple, mode, punctuation, suffix, acc, action))

def lex_array_singleton_value_before_punctuation(+head: J.Value,
                                                 +punctuation: Char,
                                                 +suffix: String,
                                                 +acc: List<&2, J.Lexeme>,
                                                 action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction},
                                                 head_lex: {J.lex_scan(J.render(head, False{}, SNil{}) ++ (SCon{']', SCon{punctuation, SNil{}} ++ suffix}), J.Outside{}, SNil{}, J.Punctuation{'['} <> acc) == J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc)) : List<&2, J.Lexeme>}) -> {J.lex_scan(J.render(J.Arr{head <> Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render(J.Arr{head <> Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan("[" ++ (J.render(head, False{}, SNil{}) ++ ("]" ++ (SCon{punctuation, SNil{}} ++ suffix))), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <>
            List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc)),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(J.render(J.Arr{head <> Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            J.lex_scan(J.render(J.Arr{head <> Nil{}}, False{}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            J.lex_scan("[" ++ (J.render(head, False{}, SNil{}) ++ ("]" ++ (SCon{punctuation, SNil{}} ++ suffix))), J.Outside{}, SNil{}, acc),
            Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
                J.render(J.Arr{head <> Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix),
                J.render(J.Arr{head <> Nil{}}, False{}, SCon{punctuation, SNil{}} ++ suffix),
                render_append(J.Arr{head <> Nil{}}, False{}, SNil{}, SCon{punctuation, SNil{}} ++ suffix)),
            Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
                J.render(J.Arr{head <> Nil{}}, False{}, SCon{punctuation, SNil{}} ++ suffix),
                "[" ++ (J.render(head, False{}, SNil{}) ++ ("]" ++ (SCon{punctuation, SNil{}} ++ suffix))),
                render_array_singleton_suffix(head, SCon{punctuation, SNil{}} ++ suffix))),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan("[" ++ (J.render(head, False{}, SNil{}) ++ ("]" ++ (SCon{punctuation, SNil{}} ++ suffix))), J.Outside{}, SNil{}, acc),
            J.lex_scan(J.render(head, False{}, SNil{}) ++ (SCon{']', SCon{punctuation, SNil{}} ++ suffix}), J.Outside{}, SNil{}, J.Punctuation{'['} <> acc),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <>
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc)),
            W.scan_punctuation_char('[', J.render(head, False{}, SNil{}) ++ ("]" ++ (SCon{punctuation, SNil{}} ++ suffix)), SNil{}, acc, {==}),
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(head, False{}, SNil{}) ++ (SCon{']', SCon{punctuation, SNil{}} ++ suffix}), J.Outside{}, SNil{}, J.Punctuation{'['} <> acc),
                J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{']'} <>
                    List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc)),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <>
                    List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc)),
                head_lex,
                W.scan_punctuation_char(punctuation, suffix, SNil{}, J.Punctuation{']'} <>
                    List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), J.Punctuation{'['} <> acc), action))))

def lex_array_singleton_before_punctuation(+head: SimpleValue,
                                           +punctuation: Char,
                                           +suffix: String,
                                           +acc: List<&2, J.Lexeme>,
                                           action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(J.render(J.Arr{simple_value(head) <> Nil{}}, False{}, SNil{}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), J.Punctuation{'['} <> acc)) : List<&2, J.Lexeme>}:
    lex_array_singleton_value_before_punctuation(simple_value(head), punctuation, suffix, acc, action,
        lex_simple_task_before_punctuation(head, RenderWhole{}, ']', SCon{punctuation, SNil{}} ++ suffix,
            J.Punctuation{'['} <> acc, {==}))

def lex_array_after_separator_single(+head: J.Value,
                                     +punctuation: Char,
                                     +suffix: String,
                                     +acc: List<&2, J.Lexeme>,
                                     action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction},
                                     head_lex: {J.lex_scan(render_task(head, RenderWhole{}, "]" ++ (SCon{punctuation, SNil{}} ++ suffix)), J.Outside{}, SNil{}, acc) == J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)) : List<&2,
                                     J.Lexeme>}) -> {J.lex_scan(render_after_separator(J.Arr{head <> Nil{}}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(render_after_separator(J.Arr{head <> Nil{}}, SCon{punctuation, SNil{}} ++ suffix),
            J.Outside{}, SNil{}, acc),
        J.lex_scan(render_task(head, RenderWhole{}, "]" ++ (SCon{punctuation, SNil{}} ++ suffix)),
            J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <>
            List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
        Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
            render_after_separator(J.Arr{head <> Nil{}}, SCon{punctuation, SNil{}} ++ suffix),
            render_task(head, RenderWhole{}, "]" ++ (SCon{punctuation, SNil{}} ++ suffix)),
            render_after_separator_array_single(head, SCon{punctuation, SNil{}} ++ suffix)),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(render_task(head, RenderWhole{}, "]" ++ (SCon{punctuation, SNil{}} ++ suffix)),
                J.Outside{}, SNil{}, acc),
            J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{']'} <>
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <>
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            head_lex,
            W.scan_punctuation_char(punctuation, suffix, SNil{}, J.Punctuation{']'} <>
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc), action)))

def lex_array_after_separator_single_source(+head: J.Value,
                                            +punctuation: Char,
                                            +suffix: String,
                                            +acc: List<&2, J.Lexeme>,
                                            action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction},
                                            head_lex: {J.lex_scan(render_task(head, RenderWhole{}, "]" ++ (SCon{punctuation, SNil{}} ++ suffix)), J.Outside{}, SNil{}, acc) == J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)) : List<&2,
                                            J.Lexeme>}) -> {J.lex_scan(render_after_separator(J.Arr{head <> Nil{}}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> Nil{}}, RenderAfterSeparator{}), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(render_after_separator(J.Arr{head <> Nil{}}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
            J.Punctuation{']'} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> Nil{}}, RenderAfterSeparator{}), acc)),
        lex_array_after_separator_single(head, punctuation, suffix, acc, action, head_lex),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.lex_scan(suffix, J.Outside{}, SNil{},
            J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, items, acc)),
            J.Punctuation{']'} <> reverse_source_task(head, RenderWhole{}),
            reverse_source_task(J.Arr{head <> Nil{}}, RenderAfterSeparator{}),
            Equal.sym(List<&2, J.Lexeme>, reverse_source_task(J.Arr{head <> Nil{}}, RenderAfterSeparator{}),
                J.Punctuation{']'} <> reverse_source_task(head, RenderWhole{}),
                reverse_source_array_after_separator(head, Nil{}))))

def reverse_array_after_separator_acc_many(+head: J.Value,
                                           +next: J.Value,
                                           +tail: List<&2, J.Value>,
                                           +acc: List<&2, J.Lexeme>) -> {List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}),
            J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
        List.append(&2, J.Lexeme,
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}),
            List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc),
        Equal.sym(List<&2, J.Lexeme>,
            List.append(&2, J.Lexeme,
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}),
                J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            LP.append_assoc(J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}),
                J.Punctuation{','} <> Nil{}, List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc))),
        Equal.trans(List<&2, J.Lexeme>,
            List.append(&2, J.Lexeme,
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            List.append(&2, J.Lexeme,
                reverse_source_task(J.Arr{next <> tail}, RenderMembers{}),
                List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs =>
                List.append(&2, J.Lexeme, xs, List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}),
                reverse_source_task(J.Arr{next <> tail}, RenderMembers{}),
                Equal.sym(List<&2, J.Lexeme>, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> Nil{}),
                    reverse_source_array_members_after_separator(next, tail))),
            Equal.trans(List<&2, J.Lexeme>,
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}),
                    List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
                List.append(&2, J.Lexeme,
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})), acc),
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc),
                Equal.sym(List<&2, J.Lexeme>,
                    List.append(&2, J.Lexeme,
                        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})), acc),
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}),
                        List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
                    LP.append_assoc(J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}),
                        reverse_source_task(head, RenderWhole{}), acc)),
                Equal.sym(List<&2, J.Lexeme>,
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc),
                    List.append(&2, J.Lexeme,
                        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})), acc),
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, xs => List.append(&2, J.Lexeme, xs, acc),
                        reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}),
                        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderMembers{}), reverse_source_task(head, RenderWhole{})),
                        reverse_source_array_after_separator(head, next <> tail))))))

def lex_array_after_separator_many(+head: J.Value,
                                   +next: J.Value,
                                   +tail: List<&2, J.Value>,
                                   +punctuation: Char,
                                   +suffix: String,
                                   +acc: List<&2, J.Lexeme>,
                                   action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction},
                                   head_lex: {J.lex_scan(render_task(head, RenderWhole{}, "," ++ render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix)), J.Outside{}, SNil{}, acc) == J.lex_scan(render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)) : List<&2, J.Lexeme>},
                                   tail_lex: {J.lex_scan(render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}), J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc))) : List<&2, J.Lexeme>}) -> {J.lex_scan(render_after_separator(J.Arr{head <> next <> tail}, SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(render_after_separator(J.Arr{head <> next <> tail}, SCon{punctuation, SNil{}} ++ suffix),
            J.Outside{}, SNil{}, acc),
        J.lex_scan(render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix),
            J.Outside{}, SNil{}, J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc)),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(render_after_separator(J.Arr{head <> next <> tail}, SCon{punctuation, SNil{}} ++ suffix),
                J.Outside{}, SNil{}, acc),
            J.lex_scan(render_task(head, RenderWhole{}, "," ++ render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix)),
                J.Outside{}, SNil{}, acc),
            J.lex_scan(render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix),
                J.Outside{}, SNil{}, J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
                render_after_separator(J.Arr{head <> next <> tail}, SCon{punctuation, SNil{}} ++ suffix),
                render_task(head, RenderWhole{}, "," ++ render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix)),
                render_after_separator_array_many(head, next, tail, SCon{punctuation, SNil{}} ++ suffix)),
            head_lex),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(render_after_separator(J.Arr{next <> tail}, SCon{punctuation, SNil{}} ++ suffix),
                J.Outside{}, SNil{}, J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}),
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc))),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <>
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc)),
            tail_lex,
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> items),
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{next <> tail}, RenderAfterSeparator{}),
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(head, RenderWhole{}), acc)),
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{head <> next <> tail}, RenderAfterSeparator{}), acc),
            reverse_array_after_separator_acc_many(head, next, tail, acc))))

def lex_array_after_separator_two_simple(+first: SimpleValue,
                                         +second: SimpleValue,
                                         +mark: JsonPunctuation,
                                         +suffix: String,
                                         +acc: List<&2, J.Lexeme>) -> {J.lex_scan(render_after_separator(J.Arr{simple_value(first) <> simple_value(second) <> Nil{}}, SCon{punctuation_char(mark), SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation_char(mark)} <> List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_value(first) <> simple_value(second) <> Nil{}}, RenderAfterSeparator{}), acc)) : List<&2, J.Lexeme>}:
    lex_array_after_separator_many(simple_value(first), simple_value(second), Nil{}, punctuation_char(mark), suffix, acc, punctuation_action(mark, suffix),
        lex_simple_task_suffix_before_punctuation(first, RenderWhole{}, ',', render_after_separator(J.Arr{simple_value(second) <> Nil{}}, SCon{punctuation_char(mark), SNil{}} ++ suffix), acc, {==}),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(render_after_separator(J.Arr{simple_value(second) <> Nil{}}, SCon{punctuation_char(mark), SNil{}} ++ suffix),
                J.Outside{}, SNil{}, J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(first), RenderWhole{}), acc)),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation_char(mark)} <> J.Punctuation{']'} <>
                List.append(&2, J.Lexeme, reverse_source_task(simple_value(second), RenderWhole{}),
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(first), RenderWhole{}), acc))),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation_char(mark)} <>
                List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_value(second) <> Nil{}}, RenderAfterSeparator{}),
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(first), RenderWhole{}), acc))),
            lex_array_after_separator_single(simple_value(second), punctuation_char(mark), suffix,
                J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(first), RenderWhole{}), acc), punctuation_action(mark, suffix),
                lex_simple_task_suffix_before_punctuation(second, RenderWhole{}, ']', SCon{punctuation_char(mark), SNil{}} ++ suffix,
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(first), RenderWhole{}), acc), {==})),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items =>
                    J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation_char(mark)} <>
                    List.append(&2, J.Lexeme, items, J.Punctuation{','} <>
                        List.append(&2, J.Lexeme, reverse_source_task(simple_value(first), RenderWhole{}), acc))),
                J.Punctuation{']'} <> reverse_source_task(simple_value(second), RenderWhole{}),
                reverse_source_task(J.Arr{simple_value(second) <> Nil{}}, RenderAfterSeparator{}),
                Equal.sym(List<&2, J.Lexeme>, reverse_source_task(J.Arr{simple_value(second) <> Nil{}}, RenderAfterSeparator{}),
                    J.Punctuation{']'} <> reverse_source_task(simple_value(second), RenderWhole{}),
                    reverse_source_array_after_separator(simple_value(second), Nil{})))))

def simple_values(values: List<&2, SimpleValue>) -> List<&2, J.Value>:
    match values:
        case Nil{}: Nil{}
        case head <> tail: simple_value(head) <> simple_values(tail)

def lex_simple_array_after_separator_end(+values: List<&2, SimpleValue>,
                                         +acc: List<&2, J.Lexeme>) -> {J.lex_scan(render_after_separator(J.Arr{simple_values(values)}, SNil{}), J.Outside{}, SNil{}, acc) == J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_values(values)}, RenderAfterSeparator{}), acc)) : List<&2, J.Lexeme>}:
    match values:
        case Nil{}:
            W.scan_punctuation_char(']', SNil{}, SNil{}, acc, {==})
        case head <> Nil{}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(render_after_separator(J.Arr{simple_value(head) <> Nil{}}, SNil{}), J.Outside{}, SNil{}, acc),
                J.lex_scan(render_task(simple_value(head), RenderWhole{}, "]"), J.Outside{}, SNil{}, acc),
                J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                    reverse_source_task(J.Arr{simple_value(head) <> Nil{}}, RenderAfterSeparator{}), acc)),
                Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
                    render_after_separator(J.Arr{simple_value(head) <> Nil{}}, SNil{}),
                    render_task(simple_value(head), RenderWhole{}, "]"),
                    render_after_separator_array_single(simple_value(head), SNil{})),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(render_task(simple_value(head), RenderWhole{}, "]"), J.Outside{}, SNil{}, acc),
                    J.lex_scan(SNil{}, J.Outside{}, SNil{}, J.Punctuation{']'} <>
                        List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)),
                    J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                        reverse_source_task(J.Arr{simple_value(head) <> Nil{}}, RenderAfterSeparator{}), acc)),
                    lex_simple_task_suffix_before_punctuation(head, RenderWhole{}, ']', SNil{}, acc, {==}),
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items =>
                        J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme, items, acc)),
                        J.Punctuation{']'} <> reverse_source_task(simple_value(head), RenderWhole{}),
                        reverse_source_task(J.Arr{simple_value(head) <> Nil{}}, RenderAfterSeparator{}),
                        Equal.sym(List<&2, J.Lexeme>, reverse_source_task(J.Arr{simple_value(head) <> Nil{}}, RenderAfterSeparator{}),
                            J.Punctuation{']'} <> reverse_source_task(simple_value(head), RenderWhole{}),
                            reverse_source_array_after_separator(simple_value(head), Nil{})))))
        case head <> next <> tail:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(render_after_separator(J.Arr{simple_value(head) <> simple_value(next) <> simple_values(tail)}, SNil{}), J.Outside{}, SNil{}, acc),
                J.lex_scan(render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SNil{}), J.Outside{}, SNil{},
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)),
                J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                    reverse_source_task(J.Arr{simple_value(head) <> simple_value(next) <> simple_values(tail)}, RenderAfterSeparator{}), acc)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(render_after_separator(J.Arr{simple_value(head) <> simple_value(next) <> simple_values(tail)}, SNil{}), J.Outside{}, SNil{}, acc),
                    J.lex_scan(render_task(simple_value(head), RenderWhole{}, "," ++ render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SNil{})),
                        J.Outside{}, SNil{}, acc),
                    J.lex_scan(render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SNil{}), J.Outside{}, SNil{},
                        J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)),
                    Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, acc),
                        render_after_separator(J.Arr{simple_value(head) <> simple_value(next) <> simple_values(tail)}, SNil{}),
                        render_task(simple_value(head), RenderWhole{}, "," ++ render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SNil{})),
                        render_after_separator_array_many(simple_value(head), simple_value(next), simple_values(tail), SNil{})),
                    lex_simple_task_suffix_before_punctuation(head, RenderWhole{}, ',',
                        render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SNil{}), acc, {==})),
                Equal.trans(List<&2, J.Lexeme>,
                        J.lex_scan(render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SNil{}), J.Outside{}, SNil{},
                            J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)),
                        J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                            reverse_source_task(J.Arr{simple_value(next) <> simple_values(tail)}, RenderAfterSeparator{}),
                            J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc))),
                        J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                            reverse_source_task(J.Arr{simple_value(head) <> simple_value(next) <> simple_values(tail)}, RenderAfterSeparator{}), acc)),
                        lex_simple_array_after_separator_end(next <> tail,
                            J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)),
                        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.lex_scan(SNil{}, J.Outside{}, SNil{}, items),
                            List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_value(next) <> simple_values(tail)}, RenderAfterSeparator{}),
                                J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)),
                            List.append(&2, J.Lexeme,
                                reverse_source_task(J.Arr{simple_value(head) <> simple_value(next) <> simple_values(tail)}, RenderAfterSeparator{}), acc),
                            reverse_array_after_separator_acc_many(simple_value(head), simple_value(next), simple_values(tail), acc))))

def reverse_source_array_after_separator_whole_list(+values: List<&2, J.Value>) -> {reverse_source_task(J.Arr{values}, RenderWhole{}) == List.append(&2, J.Lexeme, reverse_source_task(J.Arr{values}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{}) : List<&2, J.Lexeme>}:
    match values:
        case Nil{}: {==}
        case head <> tail: reverse_source_array_after_separator_whole(head, tail)

def render_array_whole_after_separator(+values: List<&2, J.Value>,
                                       +suffix: String) -> {J.render(J.Arr{values}, False{}, suffix) == "[" ++ render_after_separator(J.Arr{values}, suffix) : String}:
    match values:
        case Nil{}: {==}
        case head <> tail: {==}

def lex_simple_array_whole(+values: List<&2, SimpleValue>) -> {J.lex_scan(J.render(J.Arr{simple_values(values)}, False{}, SNil{}), J.Outside{}, SNil{}, Nil{}) == J.source(J.Arr{simple_values(values)}, False{}, Nil{}) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render(J.Arr{simple_values(values)}, False{}, SNil{}), J.Outside{}, SNil{}, Nil{}),
        J.lex_scan(render_after_separator(J.Arr{simple_values(values)}, SNil{}), J.Outside{}, SNil{}, J.Punctuation{'['} <> Nil{}),
        J.source(J.Arr{simple_values(values)}, False{}, Nil{}),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(J.render(J.Arr{simple_values(values)}, False{}, SNil{}), J.Outside{}, SNil{}, Nil{}),
            J.lex_scan("[" ++ render_after_separator(J.Arr{simple_values(values)}, SNil{}), J.Outside{}, SNil{}, Nil{}),
            J.lex_scan(render_after_separator(J.Arr{simple_values(values)}, SNil{}), J.Outside{}, SNil{}, J.Punctuation{'['} <> Nil{}),
            Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Outside{}, SNil{}, Nil{}),
                J.render(J.Arr{simple_values(values)}, False{}, SNil{}),
                "[" ++ render_after_separator(J.Arr{simple_values(values)}, SNil{}),
                render_array_whole_after_separator(simple_values(values), SNil{})),
            W.scan_punctuation_char('[', render_after_separator(J.Arr{simple_values(values)}, SNil{}), SNil{}, Nil{}, {==})),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(render_after_separator(J.Arr{simple_values(values)}, SNil{}), J.Outside{}, SNil{}, J.Punctuation{'['} <> Nil{}),
            J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                reverse_source_task(J.Arr{simple_values(values)}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{})),
            J.source(J.Arr{simple_values(values)}, False{}, Nil{}),
            lex_simple_array_after_separator_end(values, J.Punctuation{'['} <> Nil{}),
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SNil{}, J.Outside{}, SNil{}, List.append(&2, J.Lexeme,
                    reverse_source_task(J.Arr{simple_values(values)}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{})),
                J.lex_scan(SNil{}, J.Outside{}, SNil{}, reverse_source_task(J.Arr{simple_values(values)}, RenderWhole{})),
                J.source(J.Arr{simple_values(values)}, False{}, Nil{}),
                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, items => J.lex_scan(SNil{}, J.Outside{}, SNil{}, items),
                    List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_values(values)}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{}),
                    reverse_source_task(J.Arr{simple_values(values)}, RenderWhole{}),
                    Equal.sym(List<&2, J.Lexeme>, reverse_source_task(J.Arr{simple_values(values)}, RenderWhole{}),
                        List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_values(values)}, RenderAfterSeparator{}), J.Punctuation{'['} <> Nil{}),
                        reverse_source_array_after_separator_whole_list(simple_values(values)))),
                LP.reverse_twice(J.Lexeme, J.source(J.Arr{simple_values(values)}, False{}, Nil{})))))

def lex_simple_array_after_separator(+values: List<&2, SimpleValue>,
                                     +mark: JsonPunctuation,
                                     +suffix: String,
                                     +acc: List<&2, J.Lexeme>) -> {J.lex_scan(render_after_separator(J.Arr{simple_values(values)}, SCon{punctuation_char(mark), SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation_char(mark)} <> List.append(&2, J.Lexeme, reverse_source_task(J.Arr{simple_values(values)}, RenderAfterSeparator{}), acc)) : List<&2, J.Lexeme>}:
    match values:
        case Nil{}:
            lex_close_before_punctuation(']', punctuation_char(mark), suffix, acc, {==}, punctuation_action(mark, suffix))
        case head <> Nil{}:
            lex_array_after_separator_single_source(simple_value(head), punctuation_char(mark), suffix, acc,
                punctuation_action(mark, suffix),
                lex_simple_task_suffix_before_punctuation(head, RenderWhole{}, ']', SCon{punctuation_char(mark), SNil{}} ++ suffix, acc, {==}))
        case head <> next <> tail:
            lex_array_after_separator_many(simple_value(head), simple_value(next), simple_values(tail),
                punctuation_char(mark), suffix, acc, punctuation_action(mark, suffix),
                lex_simple_task_suffix_before_punctuation(head, RenderWhole{}, ',',
                    render_after_separator(J.Arr{simple_value(next) <> simple_values(tail)}, SCon{punctuation_char(mark), SNil{}} ++ suffix),
                    acc, {==}),
                lex_simple_array_after_separator(next <> tail, mark, suffix,
                    J.Punctuation{','} <> List.append(&2, J.Lexeme, reverse_source_task(simple_value(head), RenderWhole{}), acc)))

def source_token_string(+text: String,
                        +suffix: List<&2, J.Lexeme>,
                        -tail: List<J.Token>) -> {token_source(J.source_text("\"" ++ J.escape_string(text) ++ "\"", suffix), tail) == token_string(text) <> token_source(suffix, tail) : List<J.Token>}:
    Equal.cong(Result<&1, &1, J.Error, J.Value>, List<J.Token>, result => J.Atom{result} <> token_source(suffix, tail),
        J.decode_payload("\"" ++ J.escape_string(text) ++ "\""), Done{J.Str{text}}, S.string_payload(text))

def source_object_key_prefix(+delimiter: Char,
                             +key: String,
                             +suffix: List<&2, J.Lexeme>,
                             -tail: List<J.Token>) -> {token_source(J.Punctuation{delimiter} <> J.source_text("\"" ++ J.escape_string(key) ++ "\"", suffix), tail) == J.Delimiter{delimiter} <> token_string(key) <> token_source(suffix, tail) : List<J.Token>}:
    Equal.trans(List<J.Token>,
        token_source(J.Punctuation{delimiter} <> J.source_text("\"" ++ J.escape_string(key) ++ "\"", suffix), tail),
        J.Delimiter{delimiter} <> token_source(J.source_text("\"" ++ J.escape_string(key) ++ "\"", suffix), tail),
        J.Delimiter{delimiter} <> token_string(key) <> token_source(suffix, tail),
        {==},
        Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{delimiter} <> xs,
            token_source(J.source_text("\"" ++ J.escape_string(key) ++ "\"", suffix), tail),
            token_string(key) <> token_source(suffix, tail), source_token_string(key, suffix, tail)))

def to_bool(mode: A.Mode) -> Bool:
    match mode:
        case A.Whole{}: False{}
        case A.Members{}: True{}

def canonical(value: J.Value, mode: A.Mode, tail: List<J.Token>) -> List<J.Token>:
    A.tokens(value, mode, tail)

def canonical_tokens(+value: J.Value,
                     +mode: A.Mode,
                     -tail: List<J.Token>) -> {canonical(value, mode, tail) == A.tokens(value, mode, tail) : List<J.Token>}:
    {==}

def source_tokens(+value: J.Value,
                  +mode: A.Mode,
                  +suffix: List<&2, J.Lexeme>,
                  -tail: List<J.Token>) -> {token_source(J.source(value, to_bool(mode), suffix), tail) == canonical(value, mode, token_source(suffix, tail)) : List<J.Token>}:
    match value:
        case J.Null{}: {==}
        case J.Bool{truth}:
            match truth:
                case True{}: {==}
                case False{}: {==}
        case J.Number{lexeme, certificate}: {==}
        case J.Str{text}: {==}
        case J.Arr{values}:
            match values:
                case Nil{}:
                    match mode:
                        case A.Whole{}: {==}
                        case A.Members{}: {==}
                case head <> rest:
                    match mode:
                        case A.Whole{}:
                            Equal.trans(List<J.Token>, token_source(J.source(J.Arr{head <> rest}, False{}, suffix), tail),
                                J.Delimiter{'['} <> canonical(head, A.Whole{}, token_source(J.source(J.Arr{rest}, True{}, suffix), tail)),
                                canonical(J.Arr{head <> rest}, A.Whole{}, token_source(suffix, tail)),
                                Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{'['} <> xs,
                                    token_source(J.source(head, False{}, J.source(J.Arr{rest}, True{}, suffix)), tail),
                                    canonical(head, A.Whole{}, token_source(J.source(J.Arr{rest}, True{}, suffix), tail)),
                                    source_tokens(head, A.Whole{}, J.source(J.Arr{rest}, True{}, suffix), tail)),
                                Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{'['} <> canonical(head, A.Whole{}, xs),
                                    token_source(J.source(J.Arr{rest}, True{}, suffix), tail), canonical(J.Arr{rest}, A.Members{}, token_source(suffix, tail)),
                                    source_tokens(J.Arr{rest}, A.Members{}, suffix, tail)))
                        case A.Members{}:
                            Equal.trans(List<J.Token>, token_source(J.source(J.Arr{head <> rest}, True{}, suffix), tail),
                                J.Delimiter{','} <> canonical(head, A.Whole{}, token_source(J.source(J.Arr{rest}, True{}, suffix), tail)),
                                canonical(J.Arr{head <> rest}, A.Members{}, token_source(suffix, tail)),
                                Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{','} <> xs,
                                    token_source(J.source(head, False{}, J.source(J.Arr{rest}, True{}, suffix)), tail),
                                    canonical(head, A.Whole{}, token_source(J.source(J.Arr{rest}, True{}, suffix), tail)),
                                    source_tokens(head, A.Whole{}, J.source(J.Arr{rest}, True{}, suffix), tail)),
                                Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{','} <> canonical(head, A.Whole{}, xs),
                                    token_source(J.source(J.Arr{rest}, True{}, suffix), tail), canonical(J.Arr{rest}, A.Members{}, token_source(suffix, tail)),
                                    source_tokens(J.Arr{rest}, A.Members{}, suffix, tail)))
        case J.Obj{fields}:
            match fields:
                case Nil{}:
                    match mode:
                        case A.Whole{}: {==}
                        case A.Members{}: {==}
                case (key, field_value) <> rest:
                    match mode:
                        case A.Whole{}:
                            Equal.trans(List<J.Token>, token_source(J.source(J.Obj{(key, field_value) <> rest}, False{}, suffix), tail),
                                J.Delimiter{'{'} <> token_string(key) <> J.Delimiter{':'} <> token_source(J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                canonical(J.Obj{(key, field_value) <> rest}, A.Whole{}, token_source(suffix, tail)),
                                source_object_key_prefix('{', key, J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                Equal.trans(List<J.Token>,
                                    J.Delimiter{'{'} <> token_string(key) <> J.Delimiter{':'} <> token_source(J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                    J.Delimiter{'{'} <> token_string(key) <> J.Delimiter{':'} <> canonical(field_value, A.Whole{}, token_source(J.source(J.Obj{rest}, True{}, suffix), tail)),
                                    canonical(J.Obj{(key, field_value) <> rest}, A.Whole{}, token_source(suffix, tail)),
                                    Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{'{'} <> token_string(key) <> J.Delimiter{':'} <> xs,
                                        token_source(J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                        canonical(field_value, A.Whole{}, token_source(J.source(J.Obj{rest}, True{}, suffix), tail)),
                                        source_tokens(field_value, A.Whole{}, J.source(J.Obj{rest}, True{}, suffix), tail)),
                                    Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{'{'} <> token_string(key) <> J.Delimiter{':'} <> canonical(field_value, A.Whole{}, xs),
                                        token_source(J.source(J.Obj{rest}, True{}, suffix), tail), canonical(J.Obj{rest}, A.Members{}, token_source(suffix, tail)),
                                        source_tokens(J.Obj{rest}, A.Members{}, suffix, tail))))
                        case A.Members{}:
                            Equal.trans(List<J.Token>, token_source(J.source(J.Obj{(key, field_value) <> rest}, True{}, suffix), tail),
                                J.Delimiter{','} <> token_string(key) <> J.Delimiter{':'} <> token_source(J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                canonical(J.Obj{(key, field_value) <> rest}, A.Members{}, token_source(suffix, tail)),
                                source_object_key_prefix(',', key, J.Punctuation{':'} <> J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                Equal.trans(List<J.Token>,
                                    J.Delimiter{','} <> token_string(key) <> J.Delimiter{':'} <> token_source(J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                    J.Delimiter{','} <> token_string(key) <> J.Delimiter{':'} <> canonical(field_value, A.Whole{}, token_source(J.source(J.Obj{rest}, True{}, suffix), tail)),
                                    canonical(J.Obj{(key, field_value) <> rest}, A.Members{}, token_source(suffix, tail)),
                                    Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{','} <> token_string(key) <> J.Delimiter{':'} <> xs,
                                        token_source(J.source(field_value, False{}, J.source(J.Obj{rest}, True{}, suffix)), tail),
                                        canonical(field_value, A.Whole{}, token_source(J.source(J.Obj{rest}, True{}, suffix), tail)),
                                        source_tokens(field_value, A.Whole{}, J.source(J.Obj{rest}, True{}, suffix), tail)),
                                    Equal.cong(List<J.Token>, List<J.Token>, xs => J.Delimiter{','} <> token_string(key) <> J.Delimiter{':'} <> canonical(field_value, A.Whole{}, xs),
                                        token_source(J.source(J.Obj{rest}, True{}, suffix), tail), canonical(J.Obj{rest}, A.Members{}, token_source(suffix, tail)),
                                        source_tokens(J.Obj{rest}, A.Members{}, suffix, tail))))
