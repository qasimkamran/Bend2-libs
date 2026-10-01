import Base
import ../libs/JSON.bend as J
import ./JSON_PrimitiveProof.bend as P
import ./JSON_StringProof.bend as S
import ./JSON_LexWhitespaceProof.bend as W

def false_true(e: {False{} == True{} : Bool}) -> Empty:
    %e : P.false_type(_)
    Unit{}

def number_valid_cons(+character: Char,
                      +tail: String,
                      +state: J.NumberState,
                      evidence: {J.number_valid_end(J.number_valid_step(SCon{character, tail}, state)) == True{} : Bool}) -> {J.number_valid_end(J.number_valid_step(tail, J.number_next(state, character))) == True{} : Bool}:
    match state:
        case J.NumberInvalid{}:
            Empty.absurd({J.number_valid_end(J.number_valid_step(tail, J.NumberInvalid{})) == True{} : Bool}, false_true(evidence))
        case J.NumberStart{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberStart{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberStart{})), True{}, {==}, evidence)
        case J.NumberMinus{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberMinus{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberMinus{})), True{}, {==}, evidence)
        case J.NumberZero{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberZero{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberZero{})), True{}, {==}, evidence)
        case J.NumberInteger{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberInteger{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberInteger{})), True{}, {==}, evidence)
        case J.NumberDot{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberDot{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberDot{})), True{}, {==}, evidence)
        case J.NumberFraction{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberFraction{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberFraction{})), True{}, {==}, evidence)
        case J.NumberExponent{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberExponent{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberExponent{})), True{}, {==}, evidence)
        case J.NumberExponentSign{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberExponentSign{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberExponentSign{})), True{}, {==}, evidence)
        case J.NumberExponentDigits{}:
            Equal.trans(Bool, J.number_valid_end(J.number_valid_step(tail, J.number_next(J.NumberExponentDigits{}, character))), J.number_valid_end(J.number_valid_step(SCon{character, tail}, J.NumberExponentDigits{})), True{}, {==}, evidence)

def number_other_invalid(state: J.NumberState) -> {J.number_step(J.NOther{}, state) == J.NumberInvalid{} : J.NumberState}:
    match state:
        case J.NumberStart{}: {==}
        case J.NumberMinus{}: {==}
        case J.NumberZero{}: {==}
        case J.NumberInteger{}: {==}
        case J.NumberDot{}: {==}
        case J.NumberFraction{}: {==}
        case J.NumberExponent{}: {==}
        case J.NumberExponentSign{}: {==}
        case J.NumberExponentDigits{}: {==}
        case J.NumberInvalid{}: {==}

def number_next_other(+character: Char,
                      +state: J.NumberState,
                      evidence: {J.number_char(character) == J.NOther{} : J.NumberChar}) -> {J.number_next(state, character) == J.NumberInvalid{} : J.NumberState}:
    match state:
        case J.NumberInvalid{}: {==}
        case J.NumberStart{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberStart{}, character), J.number_step(J.NOther{}, J.NumberStart{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberStart{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberStart{}))
        case J.NumberMinus{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberMinus{}, character), J.number_step(J.NOther{}, J.NumberMinus{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberMinus{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberMinus{}))
        case J.NumberZero{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberZero{}, character), J.number_step(J.NOther{}, J.NumberZero{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberZero{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberZero{}))
        case J.NumberInteger{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberInteger{}, character), J.number_step(J.NOther{}, J.NumberInteger{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberInteger{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberInteger{}))
        case J.NumberDot{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberDot{}, character), J.number_step(J.NOther{}, J.NumberDot{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberDot{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberDot{}))
        case J.NumberFraction{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberFraction{}, character), J.number_step(J.NOther{}, J.NumberFraction{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberFraction{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberFraction{}))
        case J.NumberExponent{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberExponent{}, character), J.number_step(J.NOther{}, J.NumberExponent{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberExponent{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberExponent{}))
        case J.NumberExponentSign{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberExponentSign{}, character), J.number_step(J.NOther{}, J.NumberExponentSign{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberExponentSign{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberExponentSign{}))
        case J.NumberExponentDigits{}:
            Equal.trans(J.NumberState, J.number_next(J.NumberExponentDigits{}, character), J.number_step(J.NOther{}, J.NumberExponentDigits{}), J.NumberInvalid{},
                Equal.cong(J.NumberChar, J.NumberState, c => J.number_step(c, J.NumberExponentDigits{}), J.number_char(character), J.NOther{}, evidence), number_other_invalid(J.NumberExponentDigits{}))

def invalid_valid_tail(+tail: String,
                       +state: J.NumberState,
                       +character: Char,
                       other: {J.number_char(character) == J.NOther{} : J.NumberChar},
                       evidence: {J.number_valid_end(J.number_valid_step(SCon{character, tail}, state)) == True{} : Bool}) -> Empty:
    false_true(Equal.trans(Bool, False{},
        J.number_valid_end(J.number_valid_step(tail, J.NumberInvalid{})), True{},
        Equal.sym(Bool, J.number_valid_end(J.number_valid_step(tail, J.NumberInvalid{})), False{}, P.invalid_end(tail)),
        Equal.trans(Bool,
            J.number_valid_end(J.number_valid_step(tail, J.NumberInvalid{})),
            J.number_valid_end(J.number_valid_step(tail, J.number_next(state, character))), True{},
            Equal.sym(Bool,
                J.number_valid_end(J.number_valid_step(tail, J.number_next(state, character))),
                J.number_valid_end(J.number_valid_step(tail, J.NumberInvalid{})),
                Equal.cong(J.NumberState, Bool, s => J.number_valid_end(J.number_valid_step(tail, s)),
                    J.number_next(state, character), J.NumberInvalid{}, number_next_other(character, state, other))),
            number_valid_cons(character, tail, state, evidence))))

def plain_lexemes(+text: String, reversed: String, acc: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match text:
        case SNil{}: List.reverse(&2, J.Lexeme, J.flush_lexeme(reversed, acc))
        case SCon{head, tail}: plain_lexemes(tail, SCon{head, reversed}, acc)

def number_char_action(+character: Char,
                       +class: J.NumberChar,
                       class_eq: {J.number_char(character) == class : J.NumberChar},
                       +tail: String,
                       +state: J.NumberState,
                       evidence: {J.number_valid_end(J.number_valid_step(SCon{character, tail}, state)) == True{} : Bool}) -> {J.lex_outside_action(character, class) == J.LexRaw{} : J.LexAction}:
    match class:
        case J.NOther{}:
            Empty.absurd({J.lex_outside_action(character, J.NOther{}) == J.LexRaw{} : J.LexAction},
                invalid_valid_tail(tail, state, character, class_eq, evidence))
        case J.NMinus{}: {==}
        case J.NPlus{}: {==}
        case J.NDot{}: {==}
        case J.NExp{}: {==}
        case J.NZero{}: {==}
        case J.NDigit{}: {==}

def number_prefix_mode(+text: String,
                       +state: J.NumberState,
                       +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {W.prefix_mode(text, J.Outside{}) == J.Outside{} : J.LexMode}:
    match text:
        case SNil{}: {==}
        case SCon{+head, +tail}:
            Equal.trans(J.LexMode, W.prefix_mode(SCon{head, tail}, J.Outside{}),
                W.prefix_mode(tail, W.after_mode(J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.Outside{})), J.Outside{},
                {==},
                Equal.trans(J.LexMode,
                    W.prefix_mode(tail, W.after_mode(J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.Outside{})),
                    W.prefix_mode(tail, J.Outside{}), J.Outside{},
                    Equal.cong(J.LexAction, J.LexMode, action => W.prefix_mode(tail, W.after_mode(action, J.Outside{})),
                        J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.LexRaw{},
                        number_char_action(head, J.number_char(head), {==}, tail, state, evidence)),
                    number_prefix_mode(tail, J.number_next(state, head), number_valid_cons(head, tail, state, evidence))))

def number_prefix_acc(+text: String,
                      +state: J.NumberState,
                      +reversed: String,
                      +acc: List<&2, J.Lexeme>,
                      +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {W.prefix_acc(text, J.Outside{}, reversed, acc) == acc : List<&2, J.Lexeme>}:
    match text:
        case SNil{}: {==}
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>, W.prefix_acc(SCon{head, tail}, J.Outside{}, reversed, acc),
                W.prefix_acc(tail, J.Outside{}, SCon{head, reversed}, acc), acc,
                Equal.trans(List<&2, J.Lexeme>,
                    W.prefix_acc(SCon{head, tail}, J.Outside{}, reversed, acc),
                    W.prefix_acc(tail, W.after_mode(J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.Outside{}),
                        W.after_reversed(J.lex_seed_action(SCon{head, tail}, J.Outside{}), head, reversed),
                        W.after_acc(J.lex_seed_action(SCon{head, tail}, J.Outside{}), head, reversed, acc)),
                    W.prefix_acc(tail, J.Outside{}, SCon{head, reversed}, acc),
                    {==},
                    Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => W.prefix_acc(tail, W.after_mode(action, J.Outside{}),
                        W.after_reversed(action, head, reversed), W.after_acc(action, head, reversed, acc)),
                        J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.LexRaw{},
                        number_char_action(head, J.number_char(head), {==}, tail, state, evidence))),
                number_prefix_acc(tail, J.number_next(state, head), SCon{head, reversed}, acc,
                    number_valid_cons(head, tail, state, evidence)))

def number_prefix_reversed(+text: String,
                           +state: J.NumberState,
                           +reversed: String,
                           +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {W.prefix_reversed(text, J.Outside{}, reversed) == String.reverse(text) ++ reversed : String}:
    match text:
        case SNil{}: {==}
        case SCon{+head, +tail}:
            Equal.trans(String, W.prefix_reversed(SCon{head, tail}, J.Outside{}, reversed),
                W.prefix_reversed(tail, J.Outside{}, SCon{head, reversed}),
                String.reverse(SCon{head, tail}) ++ reversed,
                Equal.trans(String,
                    W.prefix_reversed(SCon{head, tail}, J.Outside{}, reversed),
                    W.prefix_reversed(tail, W.after_mode(J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.Outside{}),
                        W.after_reversed(J.lex_seed_action(SCon{head, tail}, J.Outside{}), head, reversed)),
                    W.prefix_reversed(tail, J.Outside{}, SCon{head, reversed}),
                    {==},
                    Equal.cong(J.LexAction, String, action => W.prefix_reversed(tail, W.after_mode(action, J.Outside{}),
                        W.after_reversed(action, head, reversed)),
                        J.lex_seed_action(SCon{head, tail}, J.Outside{}), J.LexRaw{},
                        number_char_action(head, J.number_char(head), {==}, tail, state, evidence))),
                Equal.trans(String,
                    W.prefix_reversed(tail, J.Outside{}, SCon{head, reversed}),
                    String.reverse(tail) ++ SCon{head, reversed},
                    String.reverse(SCon{head, tail}) ++ reversed,
                    number_prefix_reversed(tail, J.number_next(state, head), SCon{head, reversed},
                        number_valid_cons(head, tail, state, evidence)),
                    Equal.trans(String,
                        String.reverse(tail) ++ SCon{head, reversed},
                        (String.reverse(tail) ++ SCon{head, SNil{}}) ++ reversed,
                        String.reverse(SCon{head, tail}) ++ reversed,
                        Equal.sym(String, (String.reverse(tail) ++ SCon{head, SNil{}}) ++ reversed,
                            String.reverse(tail) ++ SCon{head, reversed},
                            S.append_assoc(String.reverse(tail), SCon{head, SNil{}}, reversed)),
                        Equal.cong(String, String, value => value ++ reversed,
                            String.reverse(tail) ++ SCon{head, SNil{}}, String.reverse(SCon{head, tail}),
                            Equal.sym(String, String.reverse(SCon{head, tail}), String.reverse(tail) ++ SCon{head, SNil{}},
                                S.reverse_cons(head, tail))))))


def lex_number_valid(+text: String,
                     +state: J.NumberState,
                     +reversed: String,
                     +acc: List<&2, J.Lexeme>,
                     +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {J.lex_scan(text, J.Outside{}, reversed, acc) == plain_lexemes(text, reversed, acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}: {==}
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(text, J.Outside{}, reversed, acc),
                J.lexemes(text, J.Outside{}, reversed, acc, J.LexRaw{}),
                plain_lexemes(text, reversed, acc),
                Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lexemes(text, J.Outside{}, reversed, acc, action),
                    J.lex_seed_action(text, J.Outside{}), J.LexRaw{},
                    number_char_action(head, J.number_char(head), {==}, tail, state, evidence)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lexemes(text, J.Outside{}, reversed, acc, J.LexRaw{}),
                    J.lexemes(tail, J.Outside{}, SCon{head, reversed}, acc, J.lex_seed_action(tail, J.Outside{})),
                    plain_lexemes(text, reversed, acc),
                    {==},
                    lex_number_valid(tail, J.number_next(state, head), SCon{head, reversed}, acc,
                        number_valid_cons(head, tail, state, evidence))))

def lex_number_tail(+text: String,
                    +state: J.NumberState,
                    +rev_head: Char,
                    +rev_tail: String,
                    +first: Char,
                    +prefix_tail: String,
                    +reverse_prefix: {String.reverse(SCon{rev_head, rev_tail}) == SCon{first, prefix_tail} : String},
                    +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {J.lex_scan(text, J.Outside{}, SCon{rev_head, rev_tail}, Nil{}) == (J.Payload{SCon{first, prefix_tail} ++ text} <> Nil{}) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SNil{}, J.Outside{}, SCon{rev_head, rev_tail}, Nil{}),
                J.Payload{String.reverse(SCon{rev_head, rev_tail})} <> Nil{},
                J.Payload{SCon{first, prefix_tail} ++ SNil{}} <> Nil{},
                {==},
                Equal.trans(List<&2, J.Lexeme>,
                    J.Payload{String.reverse(SCon{rev_head, rev_tail})} <> Nil{},
                    J.Payload{SCon{first, prefix_tail}} <> Nil{},
                    J.Payload{SCon{first, prefix_tail} ++ SNil{}} <> Nil{},
                    Equal.cong(String, List<&2, J.Lexeme>, s => J.Payload{s} <> Nil{},
                        String.reverse(SCon{rev_head, rev_tail}), SCon{first, prefix_tail}, reverse_prefix),
                    Equal.cong(String, List<&2, J.Lexeme>, s => J.Payload{s} <> Nil{},
                        SCon{first, prefix_tail}, SCon{first, prefix_tail} ++ SNil{},
                        Equal.sym(String, SCon{first, prefix_tail} ++ SNil{}, SCon{first, prefix_tail}, S.append_nil(SCon{first, prefix_tail})))))
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(text, J.Outside{}, SCon{rev_head, rev_tail}, Nil{}),
                J.lexemes(text, J.Outside{}, SCon{rev_head, rev_tail}, Nil{}, J.LexRaw{}),
                J.Payload{SCon{first, prefix_tail} ++ text} <> Nil{},
                Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lexemes(text, J.Outside{}, SCon{rev_head, rev_tail}, Nil{}, action),
                    J.lex_seed_action(text, J.Outside{}), J.LexRaw{},
                    number_char_action(head, J.number_char(head), {==}, tail, state, evidence)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lexemes(text, J.Outside{}, SCon{rev_head, rev_tail}, Nil{}, J.LexRaw{}),
                    J.lex_scan(tail, J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, Nil{}),
                    J.Payload{SCon{first, prefix_tail} ++ text} <> Nil{},
                    {==},
                    Equal.trans(List<&2, J.Lexeme>,
                        J.lex_scan(tail, J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, Nil{}),
                        J.Payload{(SCon{first, prefix_tail} ++ SCon{head, SNil{}}) ++ tail} <> Nil{},
                        J.Payload{SCon{first, prefix_tail} ++ text} <> Nil{},
                        lex_number_tail(tail, J.number_next(state, head), head, SCon{rev_head, rev_tail}, first,
                            prefix_tail ++ SCon{head, SNil{}},
                            Equal.trans(String,
                                String.reverse(SCon{head, SCon{rev_head, rev_tail}}),
                                String.reverse(SCon{rev_head, rev_tail}) ++ SCon{head, SNil{}},
                                SCon{first, prefix_tail} ++ SCon{head, SNil{}},
                                S.reverse_cons(head, SCon{rev_head, rev_tail}),
                                Equal.cong(String, String, x => x ++ SCon{head, SNil{}},
                                    String.reverse(SCon{rev_head, rev_tail}), SCon{first, prefix_tail}, reverse_prefix)),
                            number_valid_cons(head, tail, state, evidence)),
                        Equal.cong(String, List<&2, J.Lexeme>, s => J.Payload{s} <> Nil{},
                            (SCon{first, prefix_tail} ++ SCon{head, SNil{}}) ++ tail,
                            SCon{first, prefix_tail} ++ text,
                            S.append_assoc(SCon{first, prefix_tail}, SCon{head, SNil{}}, tail)))))

def lex_number_payload(+text: String,
                       +evidence: {J.number_valid(text) == True{} : Bool}) -> {J.lex_scan(text, J.Outside{}, SNil{}, Nil{}) == (J.Payload{text} <> Nil{}) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            Empty.absurd({J.lex_scan(SNil{}, J.Outside{}, SNil{}, Nil{}) == (J.Payload{SNil{}} <> Nil{}) : List<&2, J.Lexeme>},
                false_true(Equal.trans(Bool, False{}, J.number_valid(SNil{}), True{}, {==}, evidence)))
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(text, J.Outside{}, SNil{}, Nil{}),
                J.lexemes(text, J.Outside{}, SNil{}, Nil{}, J.LexRaw{}),
                J.Payload{text} <> Nil{},
                Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lexemes(text, J.Outside{}, SNil{}, Nil{}, action),
                    J.lex_seed_action(text, J.Outside{}), J.LexRaw{},
                    number_char_action(head, J.number_char(head), {==}, tail, J.NumberStart{}, evidence)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lexemes(text, J.Outside{}, SNil{}, Nil{}, J.LexRaw{}),
                    J.lex_scan(tail, J.Outside{}, SCon{head, SNil{}}, Nil{}),
                    J.Payload{text} <> Nil{},
                    {==},
                    Equal.trans(List<&2, J.Lexeme>,
                        J.lex_scan(tail, J.Outside{}, SCon{head, SNil{}}, Nil{}),
                        J.Payload{SCon{head, SNil{}} ++ tail} <> Nil{},
                        J.Payload{text} <> Nil{},
                        lex_number_tail(tail, J.number_next(J.NumberStart{}, head), head, SNil{}, head, SNil{}, {==},
                            number_valid_cons(head, tail, J.NumberStart{}, evidence)),
                        Equal.cong(String, List<&2, J.Lexeme>, s => J.Payload{s} <> Nil{},
                            SCon{head, SNil{}} ++ tail, text, {==}))))

def lex_number_delimited_tail(+text: String,
                              +state: J.NumberState,
                              +rev_head: Char,
                              +rev_tail: String,
                              +payload: String,
                              +punctuation: Char,
                              +suffix: String,
                              +acc: List<&2, J.Lexeme>,
                              reverse_buffer: {String.reverse(SCon{rev_head, rev_tail}) == payload : String},
                              action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction},
                              +evidence: {J.number_valid_end(J.number_valid_step(text, state)) == True{} : Bool}) -> {J.lex_scan(text ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{rev_head, rev_tail}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload ++ text} <> acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SCon{rev_head, rev_tail}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload} <> acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload ++ SNil{}} <> acc),
                Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SCon{rev_head, rev_tail}, acc),
                    J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.flush_lexeme(SCon{rev_head, rev_tail}, acc)),
                    J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload} <> acc),
                    W.scan_punctuation_char(punctuation, suffix, SCon{rev_head, rev_tail}, acc, action),
                    Equal.trans(List<&2, J.Lexeme>, J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.flush_lexeme(SCon{rev_head, rev_tail}, acc)),
                        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{String.reverse(SCon{rev_head, rev_tail})} <> acc),
                        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload} <> acc),
                        {==},
                        Equal.cong(String, List<&2, J.Lexeme>, value => J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{value} <> acc),
                            String.reverse(SCon{rev_head, rev_tail}), payload, reverse_buffer))),
                Equal.cong(String, List<&2, J.Lexeme>, value => J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{value} <> acc),
                    payload, payload ++ SNil{}, Equal.sym(String, payload ++ SNil{}, payload, S.append_nil(payload))))
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{rev_head, rev_tail}, acc),
                J.lex_scan(tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload ++ SCon{head, tail}} <> acc),
                Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{rev_head, rev_tail}, acc),
                    J.lex_scan(tail ++ (SCon{punctuation, SNil{}} ++ suffix),
                        W.after_mode(J.lex_seed_action(SCon{head, tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), J.Outside{}),
                        W.after_reversed(J.lex_seed_action(SCon{head, tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), head, SCon{rev_head, rev_tail}),
                        W.after_acc(J.lex_seed_action(SCon{head, tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), head, SCon{rev_head, rev_tail}, acc)),
                    J.lex_scan(tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, acc),
                    W.lex_scan_step(head, tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{rev_head, rev_tail}, acc),
                    Equal.cong(J.LexAction, List<&2, J.Lexeme>, lex_action => J.lex_scan(tail ++ (SCon{punctuation, SNil{}} ++ suffix),
                        W.after_mode(lex_action, J.Outside{}), W.after_reversed(lex_action, head, SCon{rev_head, rev_tail}),
                        W.after_acc(lex_action, head, SCon{rev_head, rev_tail}, acc)),
                        J.lex_seed_action(SCon{head, tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), J.LexRaw{},
                        number_char_action(head, J.number_char(head), {==}, tail, state, evidence))),
                Equal.trans(List<&2, J.Lexeme>, J.lex_scan(tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{head, SCon{rev_head, rev_tail}}, acc),
                    J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{(payload ++ SCon{head, SNil{}}) ++ tail} <> acc),
                    J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{payload ++ SCon{head, tail}} <> acc),
                    lex_number_delimited_tail(tail, J.number_next(state, head), head, SCon{rev_head, rev_tail}, payload ++ SCon{head, SNil{}},
                        punctuation, suffix, acc,
                        Equal.trans(String, String.reverse(SCon{head, SCon{rev_head, rev_tail}}),
                            String.reverse(SCon{rev_head, rev_tail}) ++ SCon{head, SNil{}}, payload ++ SCon{head, SNil{}},
                            S.reverse_cons(head, SCon{rev_head, rev_tail}),
                            Equal.cong(String, String, value => value ++ SCon{head, SNil{}}, String.reverse(SCon{rev_head, rev_tail}), payload, reverse_buffer)),
                        action, number_valid_cons(head, tail, state, evidence)),
                    Equal.cong(String, List<&2, J.Lexeme>, value => J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{value} <> acc),
                        (payload ++ SCon{head, SNil{}}) ++ tail, payload ++ SCon{head, tail},
                        S.append_assoc(payload, SCon{head, SNil{}}, tail))))

def lex_number_before_punctuation(+first: Char,
                                  +number_tail: String,
                                  +punctuation: Char,
                                  +suffix: String,
                                  +acc: List<&2, J.Lexeme>,
                                  action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction},
                                  +evidence: {J.number_valid(SCon{first, number_tail}) == True{} : Bool}) -> {J.lex_scan(SCon{first, number_tail} ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{SCon{first, number_tail}} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(SCon{first, number_tail} ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(number_tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{first, SNil{}}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{SCon{first, number_tail}} <> acc),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(SCon{first, number_tail} ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            J.lex_scan(number_tail ++ (SCon{punctuation, SNil{}} ++ suffix),
                W.after_mode(J.lex_seed_action(SCon{first, number_tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), J.Outside{}),
                W.after_reversed(J.lex_seed_action(SCon{first, number_tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), first, SNil{}),
                W.after_acc(J.lex_seed_action(SCon{first, number_tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), first, SNil{}, acc)),
            J.lex_scan(number_tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SCon{first, SNil{}}, acc),
            W.lex_scan_step(first, number_tail ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
            Equal.cong(J.LexAction, List<&2, J.Lexeme>, lex_action => J.lex_scan(number_tail ++ (SCon{punctuation, SNil{}} ++ suffix),
                W.after_mode(lex_action, J.Outside{}), W.after_reversed(lex_action, first, SNil{}), W.after_acc(lex_action, first, SNil{}, acc)),
                J.lex_seed_action(SCon{first, number_tail ++ (SCon{punctuation, SNil{}} ++ suffix)}, J.Outside{}), J.LexRaw{},
                number_char_action(first, J.number_char(first), {==}, number_tail, J.NumberStart{}, evidence))),
            lex_number_delimited_tail(number_tail, J.number_next(J.NumberStart{}, first), first, SNil{}, SCon{first, SNil{}},
                punctuation, suffix, acc,
                Equal.trans(String, String.reverse(SCon{first, SNil{}}), String.reverse(SNil{}) ++ SCon{first, SNil{}}, SCon{first, SNil{}},
                    S.reverse_cons(first, SNil{}), S.append_nil(SCon{first, SNil{}})),
                action, number_valid_cons(first, number_tail, J.NumberStart{}, evidence)))

def lex_certified_number_before_punctuation(+text: String,
                                            +certificate: J.NumberCert<text>,
                                            +punctuation: Char,
                                            +suffix: String,
                                            +acc: List<&2, J.Lexeme>,
                                            action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan(text ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{text} <> acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            Empty.absurd({J.lex_scan(SNil{} ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) ==
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{SNil{}} <> acc) : List<&2, J.Lexeme>},
                false_true(Equal.trans(Bool, False{}, J.number_valid(SNil{}), True{}, {==}, P.cert_valid(SNil{}, certificate))))
        case SCon{head, tail}:
            lex_number_before_punctuation(head, tail, punctuation, suffix, acc, action, P.cert_valid(text, certificate))
