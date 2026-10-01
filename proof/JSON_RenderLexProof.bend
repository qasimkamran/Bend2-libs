# Lexer/renderer bridge. All recursion follows the JSON value structure.
import Base
import ../libs/JSON.bend as J
import ./JSON_SourceProof.bend as SP
import ./JSON_NumberLexProof.bend as Num
import ./JSON_PrimitiveProof.bend as P
import ./JSON_ListProof.bend as LP
import ./JSON_StringProof.bend as S
import ./JSON_LexWhitespaceProof.bend as W

def reverse_concat(+xs: List<&2, J.Lexeme>,
                   +ys: List<&2, J.Lexeme>,
                   +acc: List<&2, J.Lexeme>) -> {List.reverse.go(&2, J.Lexeme, List.append(&2, J.Lexeme, xs, ys), acc) == List.reverse.go(&2, J.Lexeme, ys, List.reverse.go(&2, J.Lexeme, xs, acc)) : List<&2, J.Lexeme>}:
    match xs:
        case Nil{}: {==}
        case h <> t: reverse_concat(t, ys, h <> acc)

def push(value: J.Value, mode: SP.RenderMode, acc: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    List.reverse.go(&2, J.Lexeme, SP.source_task(value, mode, Nil{}), acc)

def push_append(+value: J.Value,
                +mode: SP.RenderMode,
                +acc: List<&2, J.Lexeme>) -> {push(value, mode, acc) == List.append(&2, J.Lexeme, SP.reverse_source_task(value, mode), acc) : List<&2, J.Lexeme>}:
    LP.reverse_go_append(J.Lexeme, SP.source_task(value, mode, Nil{}), Nil{}, acc)

def push_source(+value: J.Value,
                +members: Bool,
                +suffix: List<&2, J.Lexeme>,
                +acc: List<&2, J.Lexeme>) -> {List.reverse.go(&2, J.Lexeme, J.source(value, members, suffix), acc) == List.reverse.go(&2, J.Lexeme, suffix, List.reverse.go(&2, J.Lexeme, J.source(value, members, Nil{}), acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        List.reverse.go(&2, J.Lexeme, J.source(value, members, suffix), acc),
        List.reverse.go(&2, J.Lexeme, List.append(&2, J.Lexeme, J.source(value, members, Nil{}), suffix), acc),
        List.reverse.go(&2, J.Lexeme, suffix, List.reverse.go(&2, J.Lexeme, J.source(value, members, Nil{}), acc)),
        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>,
            x => List.reverse.go(&2, J.Lexeme, x, acc),
            J.source(value, members, suffix),
            List.append(&2, J.Lexeme, J.source(value, members, Nil{}), suffix),
            SP.source_append(value, members, Nil{}, suffix)),
        reverse_concat(J.source(value, members, Nil{}), suffix, acc))

type Container is Data:
    ArrayKind{}
    ObjectKind{}

def opening(kind: Container) -> Char:
    match kind:
        case ArrayKind{}: '['
        case ObjectKind{}: '{'

def prefix_text(kind: Container, mode: SP.RenderMode, text: String) -> String:
    match mode:
        case SP.RenderWhole{}: SCon{opening(kind), text}
        case SP.RenderMembers{}: SCon{',', text}
        case SP.RenderAfterSeparator{}: text

def prefix_acc(kind: Container, mode: SP.RenderMode, acc: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match mode:
        case SP.RenderWhole{}: J.Punctuation{opening(kind)} <> acc
        case SP.RenderMembers{}: J.Punctuation{','} <> acc
        case SP.RenderAfterSeparator{}: acc

def scan_prefix(+kind: Container,
                +mode: SP.RenderMode,
                +text: String,
                +acc: List<&2, J.Lexeme>) -> {J.lex_scan(prefix_text(kind, mode, text), J.Outside{}, SNil{}, acc) == J.lex_scan(text, J.Outside{}, SNil{}, prefix_acc(kind, mode, acc)) : List<&2, J.Lexeme>}:
    match kind mode:
        case ArrayKind{} SP.RenderWhole{}: W.scan_punctuation_char('[', text, SNil{}, acc, {==})
        case ObjectKind{} SP.RenderWhole{}: W.scan_punctuation_char('{', text, SNil{}, acc, {==})
        case _ SP.RenderMembers{}: W.scan_punctuation_char(',', text, SNil{}, acc, {==})
        case _ SP.RenderAfterSeparator{}: {==}

def push_array(+head: J.Value,
               +tail: List<&2, J.Value>,
               +mode: SP.RenderMode,
               +acc: List<&2, J.Lexeme>) -> {push(J.Arr{head <> tail}, mode, acc) == push(J.Arr{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))) : List<&2, J.Lexeme>}:
    match mode:
        case SP.RenderWhole{}: push_source(head, False{}, J.source(J.Arr{tail}, True{}, Nil{}), prefix_acc(ArrayKind{}, SP.RenderWhole{}, acc))
        case SP.RenderMembers{}: push_source(head, False{}, J.source(J.Arr{tail}, True{}, Nil{}), prefix_acc(ArrayKind{}, SP.RenderMembers{}, acc))
        case SP.RenderAfterSeparator{}: push_source(head, False{}, J.source(J.Arr{tail}, True{}, Nil{}), prefix_acc(ArrayKind{}, SP.RenderAfterSeparator{}, acc))

def push_object(+key: String,
                +head: J.Value,
                +tail: List<&2, Sigma<&2, &2, String, k => J.Value>>, +mode: SP.RenderMode, +acc: List<&2,
                J.Lexeme>) -> {push(J.Obj{(key, head) <> tail}, mode, acc) == push(J.Obj{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))) : List<&2, J.Lexeme>}:
    match mode:
        case SP.RenderWhole{}: push_source(head, False{}, J.source(J.Obj{tail}, True{}, Nil{}), J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, SP.RenderWhole{}, acc))
        case SP.RenderMembers{}: push_source(head, False{}, J.source(J.Obj{tail}, True{}, Nil{}), J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, SP.RenderMembers{}, acc))
        case SP.RenderAfterSeparator{}: push_source(head, False{}, J.source(J.Obj{tail}, True{}, Nil{}), J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, SP.RenderAfterSeparator{}, acc))

def number_tail_acc(+text: String,
                    +state: J.NumberState,
                    +rev_head: Char,
                    +rev_tail: String,
                    +first: Char,
                    +prefix_tail: String,
                    +acc: List<&2, J.Lexeme>,
                    +reverse_prefix: {String.reverse(SCon{rev_head, rev_tail}) == SCon{first, prefix_tail} : String},
                    +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {J.lex_scan(text, J.Outside{}, SCon{rev_head, rev_tail}, acc) == (List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail} ++ text} <> acc)) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SNil{}, J.Outside{}, SCon{rev_head, rev_tail}, acc),
                List.reverse(&2, J.Lexeme, J.Payload{String.reverse(SCon{rev_head, rev_tail})} <> acc),
                List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail} ++ SNil{}} <> acc),
                {==},
                Equal.trans(List<&2, J.Lexeme>,
                    List.reverse(&2, J.Lexeme, J.Payload{String.reverse(SCon{rev_head, rev_tail})} <> acc),
                    List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail}} <> acc),
                    List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail} ++ SNil{}} <> acc),
                    Equal.cong(String, List<&2, J.Lexeme>, s => List.reverse(&2, J.Lexeme, J.Payload{s} <> acc),
                        String.reverse(SCon{rev_head, rev_tail}), SCon{first, prefix_tail}, reverse_prefix),
                    Equal.cong(String, List<&2, J.Lexeme>, s => List.reverse(&2, J.Lexeme, J.Payload{s} <> acc),
                        SCon{first, prefix_tail}, SCon{first, prefix_tail} ++ SNil{},
                        Equal.sym(String, SCon{first, prefix_tail} ++ SNil{}, SCon{first, prefix_tail}, S.append_nil(SCon{first, prefix_tail})))))
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(text, J.Outside{}, SCon{rev_head, rev_tail}, acc),
                J.lexemes(text, J.Outside{}, SCon{rev_head, rev_tail}, acc, J.LexRaw{}),
                List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail} ++ text} <> acc),
                Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lexemes(text, J.Outside{}, SCon{rev_head, rev_tail}, acc, action),
                    J.lex_seed_action(text, J.Outside{}), J.LexRaw{},
                    Num.number_char_action(head, J.number_char(head), {==}, tail, state, evidence)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lexemes(text, J.Outside{}, SCon{rev_head, rev_tail}, acc, J.LexRaw{}),
                    J.lex_scan(tail, J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, acc),
                    List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail} ++ text} <> acc),
                    {==},
                    Equal.trans(List<&2, J.Lexeme>,
                        J.lex_scan(tail, J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, acc),
                        List.reverse(&2, J.Lexeme, J.Payload{(SCon{first, prefix_tail} ++ SCon{head, SNil{}}) ++ tail} <> acc),
                        List.reverse(&2, J.Lexeme, J.Payload{SCon{first, prefix_tail} ++ text} <> acc),
                        number_tail_acc(tail, J.number_next(state, head), head, SCon{rev_head, rev_tail}, first,
                            prefix_tail ++ SCon{head, SNil{}}, acc,
                            Equal.trans(String,
                                String.reverse(SCon{head, SCon{rev_head, rev_tail}}),
                                String.reverse(SCon{rev_head, rev_tail}) ++ SCon{head, SNil{}},
                                SCon{first, prefix_tail} ++ SCon{head, SNil{}},
                                S.reverse_cons(head, SCon{rev_head, rev_tail}),
                                Equal.cong(String, String, x => x ++ SCon{head, SNil{}},
                                    String.reverse(SCon{rev_head, rev_tail}), SCon{first, prefix_tail}, reverse_prefix)),
                            Num.number_valid_cons(head, tail, state, evidence)),
                        Equal.cong(String, List<&2, J.Lexeme>, s => List.reverse(&2, J.Lexeme, J.Payload{s} <> acc),
                            (SCon{first, prefix_tail} ++ SCon{head, SNil{}}) ++ tail,
                            SCon{first, prefix_tail} ++ text,
                            S.append_assoc(SCon{first, prefix_tail}, SCon{head, SNil{}}, tail)))))

def number_end(+text: String,
               +acc: List<&2, J.Lexeme>,
               +evidence: {J.number_valid(text) == True{} : Bool}) -> {J.lex_scan(text, J.Outside{}, SNil{}, acc) == (List.reverse(&2, J.Lexeme, J.Payload{text} <> acc)) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            Empty.absurd({J.lex_scan(SNil{}, J.Outside{}, SNil{}, acc) == (List.reverse(&2, J.Lexeme, J.Payload{SNil{}} <> acc)) : List<&2, J.Lexeme>},
                Num.false_true(Equal.trans(Bool, False{}, J.number_valid(SNil{}), True{}, {==}, evidence)))
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(text, J.Outside{}, SNil{}, acc),
                J.lexemes(text, J.Outside{}, SNil{}, acc, J.LexRaw{}),
                List.reverse(&2, J.Lexeme, J.Payload{text} <> acc),
                Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lexemes(text, J.Outside{}, SNil{}, acc, action),
                    J.lex_seed_action(text, J.Outside{}), J.LexRaw{},
                    Num.number_char_action(head, J.number_char(head), {==}, tail, J.NumberStart{}, evidence)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lexemes(text, J.Outside{}, SNil{}, acc, J.LexRaw{}),
                    J.lex_scan(tail, J.Outside{}, SCon{head, SNil{}}, acc),
                    List.reverse(&2, J.Lexeme, J.Payload{text} <> acc),
                    {==},
                    Equal.trans(List<&2, J.Lexeme>,
                        J.lex_scan(tail, J.Outside{}, SCon{head, SNil{}}, acc),
                        List.reverse(&2, J.Lexeme, J.Payload{SCon{head, SNil{}} ++ tail} <> acc),
                        List.reverse(&2, J.Lexeme, J.Payload{text} <> acc),
                        number_tail_acc(tail, J.number_next(J.NumberStart{}, head), head, SNil{}, head, SNil{}, acc, {==},
                            Num.number_valid_cons(head, tail, J.NumberStart{}, evidence)),
                        Equal.cong(String, List<&2, J.Lexeme>, s => List.reverse(&2, J.Lexeme, J.Payload{s} <> acc),
                            SCon{head, SNil{}} ++ tail, text, {==}))))

# A rendered value is followed either by end of input or a JSON delimiter.
type Boundary is Data:
    End{}
    Delimited{mark: SP.JsonPunctuation, suffix: String}

def boundary_text(boundary: Boundary) -> String:
    match boundary:
        case End{}: SNil{}
        case Delimited{mark, suffix}: SCon{SP.punctuation_char(mark), suffix}

def finish(boundary: Boundary, acc: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match boundary:
        case End{}: J.lex_scan(SNil{}, J.Outside{}, SNil{}, acc)
        case Delimited{mark, suffix}:
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{SP.punctuation_char(mark)} <> acc)

def scan_boundary(+boundary: Boundary,
                  +acc: List<&2, J.Lexeme>) -> {J.lex_scan(boundary_text(boundary), J.Outside{}, SNil{}, acc) == finish(boundary, acc) : List<&2, J.Lexeme>}:
    match boundary:
        case End{}: {==}
        case Delimited{mark, suffix}:
            W.scan_punctuation_char(SP.punctuation_char(mark), suffix, SNil{}, acc, SP.punctuation_action(mark, suffix))

def atomic_end(+atom: SP.AtomicValue,
               +acc: List<&2, J.Lexeme>) -> {J.lex_scan(J.render(SP.atomic_value(atom), False{}, SNil{}), J.Outside{}, SNil{}, acc) == finish(End{}, push(SP.atomic_value(atom), SP.RenderWhole{}, acc)) : List<&2, J.Lexeme>}:
    match atom:
        case SP.AtomicNull{}: {==}
        case SP.AtomicTrue{}: {==}
        case SP.AtomicFalse{}: {==}
        case SP.AtomicNumber{text, certificate}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(J.Number{text, certificate}, False{}, SNil{}), J.Outside{}, SNil{}, acc),
                J.lex_scan(text, J.Outside{}, SNil{}, acc),
                finish(End{}, push(J.Number{text, certificate}, SP.RenderWhole{}, acc)),
                Equal.cong(String, List<&2, J.Lexeme>,
                    x => J.lex_scan(x, J.Outside{}, SNil{}, acc),
                    text ++ SNil{},
                    text,
                    S.append_nil(text)),
                number_end(text, acc, P.cert_valid(text, certificate)))
        case SP.AtomicString{text}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render(J.Str{text}, False{}, SNil{}), J.Outside{}, SNil{}, acc),
                J.lex_scan(J.render(J.Str{text}, False{}, SNil{}) ++ SNil{}, J.Outside{}, SNil{}, acc),
                finish(End{}, push(J.Str{text}, SP.RenderWhole{}, acc)),
                Equal.cong(String, List<&2, J.Lexeme>,
                    x => J.lex_scan(x, J.Outside{}, SNil{}, acc),
                    J.render(J.Str{text}, False{}, SNil{}),
                    J.render(J.Str{text}, False{}, SNil{}) ++ SNil{},
                    Equal.sym(String,
                        J.render(J.Str{text}, False{}, SNil{}) ++ SNil{},
                        J.render(J.Str{text}, False{}, SNil{}),
                        S.append_nil(J.render(J.Str{text}, False{}, SNil{})))),
                W.lex_rendered_string_suffix(text, SNil{}, acc))

def atomic_mode_end(+atom: SP.AtomicValue,
                    +mode: SP.RenderMode,
                    +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(SP.atomic_value(atom), mode, SNil{}), J.Outside{}, SNil{}, acc) == finish(End{}, push(SP.atomic_value(atom), mode, acc)) : List<&2, J.Lexeme>}:
    match atom mode:
        case SP.AtomicNull{} SP.RenderWhole{}: atomic_end(SP.AtomicNull{}, acc)
        case SP.AtomicNull{} SP.RenderMembers{}: atomic_end(SP.AtomicNull{}, acc)
        case SP.AtomicNull{} SP.RenderAfterSeparator{}: atomic_end(SP.AtomicNull{}, acc)
        case SP.AtomicTrue{} SP.RenderWhole{}: atomic_end(SP.AtomicTrue{}, acc)
        case SP.AtomicTrue{} SP.RenderMembers{}: atomic_end(SP.AtomicTrue{}, acc)
        case SP.AtomicTrue{} SP.RenderAfterSeparator{}: atomic_end(SP.AtomicTrue{}, acc)
        case SP.AtomicFalse{} SP.RenderWhole{}: atomic_end(SP.AtomicFalse{}, acc)
        case SP.AtomicFalse{} SP.RenderMembers{}: atomic_end(SP.AtomicFalse{}, acc)
        case SP.AtomicFalse{} SP.RenderAfterSeparator{}: atomic_end(SP.AtomicFalse{}, acc)
        case SP.AtomicNumber{text, certificate} SP.RenderWhole{}: atomic_end(SP.AtomicNumber{text, certificate}, acc)
        case SP.AtomicNumber{text, certificate} SP.RenderMembers{}: atomic_end(SP.AtomicNumber{text, certificate}, acc)
        case SP.AtomicNumber{text, certificate} SP.RenderAfterSeparator{}: atomic_end(SP.AtomicNumber{text, certificate}, acc)
        case SP.AtomicString{text} SP.RenderWhole{}: atomic_end(SP.AtomicString{text}, acc)
        case SP.AtomicString{text} SP.RenderMembers{}: atomic_end(SP.AtomicString{text}, acc)
        case SP.AtomicString{text} SP.RenderAfterSeparator{}: atomic_end(SP.AtomicString{text}, acc)

def atomic_lex(+atom: SP.AtomicValue,
               +mode: SP.RenderMode,
               +boundary: Boundary,
               +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(SP.atomic_value(atom), mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc) == finish(boundary, push(SP.atomic_value(atom), mode, acc)) : List<&2, J.Lexeme>}:
    match boundary:
        case End{}: atomic_mode_end(atom, mode, acc)
        case Delimited{mark, suffix}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SP.render_task(SP.atomic_value(atom), mode, boundary_text(Delimited{mark, suffix})), J.Outside{}, SNil{}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{SP.punctuation_char(mark)} <> List.append(&2, J.Lexeme, SP.reverse_source_task(SP.atomic_value(atom), mode), acc)),
                finish(Delimited{mark, suffix}, push(SP.atomic_value(atom), mode, acc)),
                SP.lex_simple_task_suffix_before_punctuation(SP.SimpleAtom{atom}, mode, SP.punctuation_char(mark), suffix, acc, SP.punctuation_action(mark, suffix)),
                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>,
                    x => finish(Delimited{mark, suffix}, x),
                    List.append(&2, J.Lexeme, SP.reverse_source_task(SP.atomic_value(atom), mode), acc),
                    push(SP.atomic_value(atom), mode, acc),
                    Equal.sym(List<&2, J.Lexeme>,
                        push(SP.atomic_value(atom), mode, acc),
                        List.append(&2, J.Lexeme, SP.reverse_source_task(SP.atomic_value(atom), mode), acc),
                        push_append(SP.atomic_value(atom), mode, acc))))

def array_continuation(values: List<&2, J.Value>, boundary: Boundary) -> Boundary:
    match values:
        case Nil{}: Delimited{SP.ArrayEnd{}, boundary_text(boundary)}
        case head <> tail:
            Delimited{SP.MemberComma{}, SP.render_task(J.Arr{values}, SP.RenderAfterSeparator{}, boundary_text(boundary))}

def array_continuation_text(+values: List<&2, J.Value>,
                            +boundary: Boundary) -> {SP.render_task(J.Arr{values}, SP.RenderMembers{}, boundary_text(boundary)) == boundary_text(array_continuation(values, boundary)) : String}:
    match values:
        case Nil{}: {==}
        case head <> tail: {==}

def array_resume(+values: List<&2, J.Value>,
                 +boundary: Boundary,
                 +acc: List<&2, J.Lexeme>,
                 tail_lex: {J.lex_scan(SP.render_task(J.Arr{values}, SP.RenderAfterSeparator{}, boundary_text(boundary)), J.Outside{}, SNil{}, J.Punctuation{','} <> acc) == finish(boundary, push(J.Arr{values}, SP.RenderAfterSeparator{}, J.Punctuation{','} <> acc)) : List<&2, J.Lexeme>}) -> {finish(array_continuation(values, boundary), acc) == finish(boundary, push(J.Arr{values}, SP.RenderMembers{}, acc)) : List<&2, J.Lexeme>}:
    match values:
        case Nil{}: scan_boundary(boundary, J.Punctuation{']'} <> acc)
        case head <> tail: tail_lex

def object_continuation(values: List<&2, Sigma<&2, &2, String, k => J.Value>>, boundary: Boundary) -> Boundary:
    match values:
        case Nil{}: Delimited{SP.ObjectEnd{}, boundary_text(boundary)}
        case (key, head) <> tail:
            Delimited{SP.MemberComma{}, SP.render_task(J.Obj{values}, SP.RenderAfterSeparator{}, boundary_text(boundary))}

def object_continuation_text(+values: List<&2, Sigma<&2, &2, String, k => J.Value>>, +boundary: Boundary) -> {SP.render_task(J.Obj{values}, SP.RenderMembers{}, boundary_text(boundary)) == boundary_text(object_continuation(values, boundary)) : String}:
    match values:
        case Nil{}: {==}
        case (key, head) <> tail: {==}

def object_resume(+values: List<&2, Sigma<&2, &2, String, k => J.Value>>, +boundary: Boundary, +acc: List<&2,
                  J.Lexeme>, tail_lex: {J.lex_scan(SP.render_task(J.Obj{values}, SP.RenderAfterSeparator{}, boundary_text(boundary)), J.Outside{}, SNil{}, J.Punctuation{','} <> acc) == finish(boundary, push(J.Obj{values}, SP.RenderAfterSeparator{}, J.Punctuation{','} <> acc)) : List<&2, J.Lexeme>}) -> {finish(object_continuation(values, boundary), acc) == finish(boundary, push(J.Obj{values}, SP.RenderMembers{}, acc)) : List<&2, J.Lexeme>}:
    match values:
        case Nil{}: scan_boundary(boundary, J.Punctuation{'}'} <> acc)
        case (key, head) <> tail: tail_lex

def field_text(+key: String,
               +text: String) -> {J.render_object_field(SNil{}, key, text) == ("\"" ++ J.escape_string(key) ++ "\"") ++ (":" ++ text) : String}:
    Equal.trans(String,
        J.render_object_field(SNil{}, key, text),
        SCon{'"', J.escape_string(key) ++ ("\":" ++ text)},
        ("\"" ++ J.escape_string(key) ++ "\"") ++ (":" ++ text),
        Equal.cong(String, String,
            x => SCon{'"', x},
            (J.escape_string(key) ++ "\":") ++ text,
            J.escape_string(key) ++ ("\":" ++ text),
            S.append_assoc(J.escape_string(key), "\":", text)),
        Equal.sym(String,
            ("\"" ++ J.escape_string(key) ++ "\"") ++ (":" ++ text),
            SCon{'"', J.escape_string(key) ++ ("\":" ++ text)},
            Equal.cong(String, String,
                x => SCon{'"', x},
                (J.escape_string(key) ++ "\"") ++ (":" ++ text),
                J.escape_string(key) ++ ("\"" ++ (":" ++ text)),
                S.append_assoc(J.escape_string(key), "\"", ":" ++ text))))

def scan_field(+key: String,
               +text: String,
               +acc: List<&2, J.Lexeme>) -> {J.lex_scan(J.render_object_field(SNil{}, key, text), J.Outside{}, SNil{}, acc) == J.lex_scan(text, J.Outside{}, SNil{}, J.Punctuation{':'} <> J.Payload{("\"" ++ J.escape_string(key) ++ "\"")} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.render_object_field(SNil{}, key, text), J.Outside{}, SNil{}, acc),
        J.lex_scan(("\"" ++ J.escape_string(key) ++ "\"") ++ (":" ++ text), J.Outside{}, SNil{}, acc),
        J.lex_scan(text, J.Outside{}, SNil{}, J.Punctuation{':'} <> J.Payload{("\"" ++ J.escape_string(key) ++ "\"")} <> acc),
        Equal.cong(String, List<&2, J.Lexeme>,
            x => J.lex_scan(x, J.Outside{}, SNil{}, acc),
            J.render_object_field(SNil{}, key, text),
            ("\"" ++ J.escape_string(key) ++ "\"") ++ (":" ++ text),
            field_text(key, text)),
        SP.lex_object_key_before_colon(key, text, acc))

def empty_array_end(+mode: SP.RenderMode,
                    +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(J.Arr{Nil{}}, mode, SNil{}), J.Outside{}, SNil{}, acc) == finish(End{}, push(J.Arr{Nil{}}, mode, acc)) : List<&2, J.Lexeme>}:
    match mode:
        case SP.RenderWhole{}: {==}
        case SP.RenderMembers{}: {==}
        case SP.RenderAfterSeparator{}: {==}

def empty_array_lex(+mode: SP.RenderMode,
                    +boundary: Boundary,
                    +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(J.Arr{Nil{}}, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc) == finish(boundary, push(J.Arr{Nil{}}, mode, acc)) : List<&2, J.Lexeme>}:
    match boundary:
        case End{}: empty_array_end(mode, acc)
        case Delimited{mark, suffix}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SP.render_task(J.Arr{Nil{}}, mode, boundary_text(Delimited{mark, suffix})), J.Outside{}, SNil{}, acc),
                finish(Delimited{mark, suffix}, List.append(&2, J.Lexeme, SP.reverse_source_task(J.Arr{Nil{}}, mode), acc)),
                finish(Delimited{mark, suffix}, push(J.Arr{Nil{}}, mode, acc)),
                SP.lex_simple_task_suffix_before_punctuation(SP.SimpleEmptyArray{}, mode, SP.punctuation_char(mark), suffix, acc, SP.punctuation_action(mark, suffix)),
                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>,
                    x => finish(Delimited{mark, suffix}, x),
                    List.append(&2, J.Lexeme, SP.reverse_source_task(J.Arr{Nil{}}, mode), acc),
                    push(J.Arr{Nil{}}, mode, acc),
                    Equal.sym(List<&2, J.Lexeme>,
                        push(J.Arr{Nil{}}, mode, acc),
                        List.append(&2, J.Lexeme, SP.reverse_source_task(J.Arr{Nil{}}, mode), acc),
                        push_append(J.Arr{Nil{}}, mode, acc))))

def empty_object_end(+mode: SP.RenderMode,
                     +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(J.Obj{Nil{}}, mode, SNil{}), J.Outside{}, SNil{}, acc) == finish(End{}, push(J.Obj{Nil{}}, mode, acc)) : List<&2, J.Lexeme>}:
    match mode:
        case SP.RenderWhole{}: {==}
        case SP.RenderMembers{}: {==}
        case SP.RenderAfterSeparator{}: {==}

def empty_object_lex(+mode: SP.RenderMode,
                     +boundary: Boundary,
                     +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(J.Obj{Nil{}}, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc) == finish(boundary, push(J.Obj{Nil{}}, mode, acc)) : List<&2, J.Lexeme>}:
    match boundary:
        case End{}: empty_object_end(mode, acc)
        case Delimited{mark, suffix}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SP.render_task(J.Obj{Nil{}}, mode, boundary_text(Delimited{mark, suffix})), J.Outside{}, SNil{}, acc),
                finish(Delimited{mark, suffix}, List.append(&2, J.Lexeme, SP.reverse_source_task(J.Obj{Nil{}}, mode), acc)),
                finish(Delimited{mark, suffix}, push(J.Obj{Nil{}}, mode, acc)),
                SP.lex_simple_task_suffix_before_punctuation(SP.SimpleEmptyObject{}, mode, SP.punctuation_char(mark), suffix, acc, SP.punctuation_action(mark, suffix)),
                Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>,
                    x => finish(Delimited{mark, suffix}, x),
                    List.append(&2, J.Lexeme, SP.reverse_source_task(J.Obj{Nil{}}, mode), acc),
                    push(J.Obj{Nil{}}, mode, acc),
                    Equal.sym(List<&2, J.Lexeme>,
                        push(J.Obj{Nil{}}, mode, acc),
                        List.append(&2, J.Lexeme, SP.reverse_source_task(J.Obj{Nil{}}, mode), acc),
                        push_append(J.Obj{Nil{}}, mode, acc))))

def render_array(+head: J.Value,
                 +tail: List<&2, J.Value>,
                 +mode: SP.RenderMode,
                 +boundary: Boundary,
                 +acc: List<&2, J.Lexeme>) -> {SP.render_task(J.Arr{head <> tail}, mode, boundary_text(boundary)) == prefix_text(ArrayKind{}, mode, SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary)))) : String}:
    match mode:
        case SP.RenderWhole{}:
            Equal.cong(String, String,
                x => prefix_text(ArrayKind{}, SP.RenderWhole{}, SP.render_task(head, SP.RenderWhole{}, x)),
                SP.render_task(J.Arr{tail}, SP.RenderMembers{}, boundary_text(boundary)),
                boundary_text(array_continuation(tail, boundary)),
                array_continuation_text(tail, boundary))
        case SP.RenderMembers{}:
            Equal.cong(String, String,
                x => prefix_text(ArrayKind{}, SP.RenderMembers{}, SP.render_task(head, SP.RenderWhole{}, x)),
                SP.render_task(J.Arr{tail}, SP.RenderMembers{}, boundary_text(boundary)),
                boundary_text(array_continuation(tail, boundary)),
                array_continuation_text(tail, boundary))
        case SP.RenderAfterSeparator{}:
            Equal.cong(String, String,
                x => prefix_text(ArrayKind{}, SP.RenderAfterSeparator{}, SP.render_task(head, SP.RenderWhole{}, x)),
                SP.render_task(J.Arr{tail}, SP.RenderMembers{}, boundary_text(boundary)),
                boundary_text(array_continuation(tail, boundary)),
                array_continuation_text(tail, boundary))

def lex_array(+head: J.Value,
              +tail: List<&2, J.Value>,
              +mode: SP.RenderMode,
              +boundary: Boundary,
              +acc: List<&2, J.Lexeme>,
              head_lex: {J.lex_scan(SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary))), J.Outside{}, SNil{}, prefix_acc(ArrayKind{}, mode, acc)) == finish(array_continuation(tail, boundary), push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))) : List<&2, J.Lexeme>},
              tail_lex: {J.lex_scan(SP.render_task(J.Arr{tail}, SP.RenderAfterSeparator{}, boundary_text(boundary)), J.Outside{}, SNil{}, J.Punctuation{','} <> push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))) == finish(boundary, push(J.Arr{tail}, SP.RenderAfterSeparator{}, J.Punctuation{','} <> push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc)))) : List<&2, J.Lexeme>}) -> {J.lex_scan(SP.render_task(J.Arr{head <> tail}, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc) == finish(boundary, push(J.Arr{head <> tail}, mode, acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(SP.render_task(J.Arr{head <> tail}, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc),
        J.lex_scan(prefix_text(ArrayKind{}, mode, SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary)))), J.Outside{}, SNil{}, acc),
        finish(boundary, push(J.Arr{head <> tail}, mode, acc)),
        Equal.cong(String, List<&2, J.Lexeme>,
            x => J.lex_scan(x, J.Outside{}, SNil{}, acc),
            SP.render_task(J.Arr{head <> tail}, mode, boundary_text(boundary)),
            prefix_text(ArrayKind{}, mode, SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary)))),
            render_array(head, tail, mode, boundary, acc)),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(prefix_text(ArrayKind{}, mode, SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary)))), J.Outside{}, SNil{}, acc),
            J.lex_scan(SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary))), J.Outside{}, SNil{}, prefix_acc(ArrayKind{}, mode, acc)),
            finish(boundary, push(J.Arr{head <> tail}, mode, acc)),
            scan_prefix(ArrayKind{}, mode, SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary))), acc),
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SP.render_task(head, SP.RenderWhole{}, boundary_text(array_continuation(tail, boundary))), J.Outside{}, SNil{}, prefix_acc(ArrayKind{}, mode, acc)),
                finish(array_continuation(tail, boundary), push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))),
                finish(boundary, push(J.Arr{head <> tail}, mode, acc)),
                head_lex,
                Equal.trans(List<&2, J.Lexeme>,
                    finish(array_continuation(tail, boundary), push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))),
                    finish(boundary, push(J.Arr{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc)))),
                    finish(boundary, push(J.Arr{head <> tail}, mode, acc)),
                    array_resume(tail, boundary, push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc)), tail_lex),
                    Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>,
                        x => finish(boundary, x),
                        push(J.Arr{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))),
                        push(J.Arr{head <> tail}, mode, acc),
                        Equal.sym(List<&2, J.Lexeme>,
                            push(J.Arr{head <> tail}, mode, acc),
                            push(J.Arr{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))),
                            push_array(head, tail, mode, acc)))))))

def render_object(+key: String,
                  +head: J.Value,
                  +tail: List<&2, Sigma<&2, &2, String, k => J.Value>>, +mode: SP.RenderMode, +boundary: Boundary, +acc: List<&2,
                  J.Lexeme>) -> {SP.render_task(J.Obj{(key, head) <> tail}, mode, boundary_text(boundary)) == prefix_text(ObjectKind{}, mode, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))))) : String}:
    match mode:
        case SP.RenderWhole{}:
            Equal.cong(String, String,
                x => prefix_text(ObjectKind{}, SP.RenderWhole{}, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, x))),
                SP.render_task(J.Obj{tail}, SP.RenderMembers{}, boundary_text(boundary)),
                boundary_text(object_continuation(tail, boundary)),
                object_continuation_text(tail, boundary))
        case SP.RenderMembers{}:
            Equal.cong(String, String,
                x => prefix_text(ObjectKind{}, SP.RenderMembers{}, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, x))),
                SP.render_task(J.Obj{tail}, SP.RenderMembers{}, boundary_text(boundary)),
                boundary_text(object_continuation(tail, boundary)),
                object_continuation_text(tail, boundary))
        case SP.RenderAfterSeparator{}:
            Equal.cong(String, String,
                x => prefix_text(ObjectKind{}, SP.RenderAfterSeparator{}, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, x))),
                SP.render_task(J.Obj{tail}, SP.RenderMembers{}, boundary_text(boundary)),
                boundary_text(object_continuation(tail, boundary)),
                object_continuation_text(tail, boundary))

def lex_object(+key: String,
               +head: J.Value,
               +tail: List<&2, Sigma<&2, &2, String, k => J.Value>>, +mode: SP.RenderMode, +boundary: Boundary, +acc: List<&2,
               J.Lexeme>, head_lex: {J.lex_scan(SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))), J.Outside{}, SNil{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)) == finish(object_continuation(tail, boundary), push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))) : List<&2, J.Lexeme>}, tail_lex: {J.lex_scan(SP.render_task(J.Obj{tail}, SP.RenderAfterSeparator{}, boundary_text(boundary)), J.Outside{}, SNil{}, J.Punctuation{','} <> push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))) == finish(boundary, push(J.Obj{tail}, SP.RenderAfterSeparator{}, J.Punctuation{','} <> push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)))) : List<&2, J.Lexeme>}) -> {J.lex_scan(SP.render_task(J.Obj{(key, head) <> tail}, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc) == finish(boundary, push(J.Obj{(key, head) <> tail}, mode, acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(SP.render_task(J.Obj{(key, head) <> tail}, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc),
        J.lex_scan(prefix_text(ObjectKind{}, mode, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))))), J.Outside{}, SNil{}, acc),
        finish(boundary, push(J.Obj{(key, head) <> tail}, mode, acc)),
        Equal.cong(String, List<&2, J.Lexeme>,
            x => J.lex_scan(x, J.Outside{}, SNil{}, acc),
            SP.render_task(J.Obj{(key, head) <> tail}, mode, boundary_text(boundary)),
            prefix_text(ObjectKind{}, mode, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))))),
            render_object(key, head, tail, mode, boundary, acc)),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(prefix_text(ObjectKind{}, mode, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))))), J.Outside{}, SNil{}, acc),
            J.lex_scan(J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary)))), J.Outside{}, SNil{}, prefix_acc(ObjectKind{}, mode, acc)),
            finish(boundary, push(J.Obj{(key, head) <> tail}, mode, acc)),
            scan_prefix(ObjectKind{}, mode, J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary)))), acc),
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(J.render_object_field(SNil{}, key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary)))), J.Outside{}, SNil{}, prefix_acc(ObjectKind{}, mode, acc)),
                J.lex_scan(SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))), J.Outside{}, SNil{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)),
                finish(boundary, push(J.Obj{(key, head) <> tail}, mode, acc)),
                scan_field(key, SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))), prefix_acc(ObjectKind{}, mode, acc)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(SP.render_task(head, SP.RenderWhole{}, boundary_text(object_continuation(tail, boundary))), J.Outside{}, SNil{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)),
                    finish(object_continuation(tail, boundary), push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))),
                    finish(boundary, push(J.Obj{(key, head) <> tail}, mode, acc)),
                    head_lex,
                    Equal.trans(List<&2, J.Lexeme>,
                        finish(object_continuation(tail, boundary), push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))),
                        finish(boundary, push(J.Obj{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)))),
                        finish(boundary, push(J.Obj{(key, head) <> tail}, mode, acc)),
                        object_resume(tail, boundary, push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)), tail_lex),
                        Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>,
                            x => finish(boundary, x),
                            push(J.Obj{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))),
                            push(J.Obj{(key, head) <> tail}, mode, acc),
                            Equal.sym(List<&2, J.Lexeme>,
                                push(J.Obj{(key, head) <> tail}, mode, acc),
                                push(J.Obj{tail}, SP.RenderMembers{}, push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))),
                                push_object(key, head, tail, mode, acc))))))))

def lex_value(+value: J.Value,
              +mode: SP.RenderMode,
              +boundary: Boundary,
              +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SP.render_task(value, mode, boundary_text(boundary)), J.Outside{}, SNil{}, acc) == finish(boundary, push(value, mode, acc)) : List<&2, J.Lexeme>}:
    match value:
        case J.Null{}: atomic_lex(SP.AtomicNull{}, mode, boundary, acc)
        case J.Bool{truth}:
            match truth:
                case True{}: atomic_lex(SP.AtomicTrue{}, mode, boundary, acc)
                case False{}: atomic_lex(SP.AtomicFalse{}, mode, boundary, acc)
        case J.Number{text, certificate}: atomic_lex(SP.AtomicNumber{text, certificate}, mode, boundary, acc)
        case J.Str{text}: atomic_lex(SP.AtomicString{text}, mode, boundary, acc)
        case J.Arr{Nil{}}: empty_array_lex(mode, boundary, acc)
        case J.Obj{Nil{}}: empty_object_lex(mode, boundary, acc)
        case J.Arr{head <> tail}:
            lex_array(head, tail, mode, boundary, acc,
                lex_value(head, SP.RenderWhole{}, array_continuation(tail, boundary), prefix_acc(ArrayKind{}, mode, acc)),
                lex_value(J.Arr{tail}, SP.RenderAfterSeparator{}, boundary, J.Punctuation{','} <> push(head, SP.RenderWhole{}, prefix_acc(ArrayKind{}, mode, acc))))
        case J.Obj{(key, head) <> tail}:
            lex_object(key, head, tail, mode, boundary, acc,
                lex_value(head, SP.RenderWhole{}, object_continuation(tail, boundary), J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc)),
                lex_value(J.Obj{tail}, SP.RenderAfterSeparator{}, boundary, J.Punctuation{','} <> push(head, SP.RenderWhole{}, J.Punctuation{':'} <> J.Payload{"\"" ++ J.escape_string(key) ++ "\""} <> prefix_acc(ObjectKind{}, mode, acc))))

def lex_source(+value: J.Value) -> {J.lex_scan(J.stringify(value), J.Outside{}, SNil{}, Nil{}) == J.source(value, False{}, Nil{}) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(J.stringify(value), J.Outside{}, SNil{}, Nil{}),
        finish(End{}, push(value, SP.RenderWhole{}, Nil{})),
        J.source(value, False{}, Nil{}),
        lex_value(value, SP.RenderWhole{}, End{}, Nil{}),
        LP.reverse_twice(J.Lexeme, J.source(value, False{}, Nil{})))
