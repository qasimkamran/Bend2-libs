import Base
import ../libs/JSON.bend as J
import ./JSON_StringProof.bend as S

def after_mode(action: J.LexAction, mode: J.LexMode) -> J.LexMode:
    match action:
        case J.LexBackslash{}: J.Escaped{}
        case J.LexEscapedChar{}: J.Quoted{}
        case J.LexStringEnd{}: J.Outside{}
        case J.LexStringChar{}: J.Quoted{}
        case J.LexQuote{}: J.Quoted{}
        case J.LexWhitespace{}: J.Outside{}
        case J.LexPunctuation{_}: J.Outside{}
        case J.LexRaw{}: J.Outside{}
        case J.LexStop{}: mode

def after_reversed(action: J.LexAction, head: Char, reversed: String) -> String:
    match action:
        case J.LexBackslash{}: SCon{'\\', reversed}
        case J.LexEscapedChar{}: SCon{head, reversed}
        case J.LexStringEnd{}: SNil{}
        case J.LexStringChar{}: SCon{head, reversed}
        case J.LexQuote{}: SCon{'"', SNil{}}
        case J.LexWhitespace{}: SNil{}
        case J.LexPunctuation{_}: SNil{}
        case J.LexRaw{}: SCon{head, reversed}
        case J.LexStop{}: SCon{head, reversed}

def after_acc(action: J.LexAction,
              head: Char,
              reversed: String,
              acc: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match action:
        case J.LexBackslash{}: acc
        case J.LexEscapedChar{}: acc
        case J.LexStringEnd{}: J.Payload{String.reverse(SCon{'"', reversed})} <> acc
        case J.LexStringChar{}: acc
        case J.LexQuote{}: J.flush_lexeme(reversed, acc)
        case J.LexWhitespace{}: J.flush_lexeme(reversed, acc)
        case J.LexPunctuation{character}: J.Punctuation{character} <> J.flush_lexeme(reversed, acc)
        case J.LexRaw{}: acc
        case J.LexStop{}: acc

def lexemes_step(+head: Char,
                 +tail: String,
                 +mode: J.LexMode,
                 +reversed: String,
                 +acc: List<&2, J.Lexeme>,
                 action: J.LexAction) -> {J.lexemes(SCon{head, tail}, mode, reversed, acc, action) == J.lex_scan(tail, after_mode(action, mode), after_reversed(action, head, reversed), after_acc(action, head, reversed, acc)) : List<&2, J.Lexeme>}:
    match action:
        case J.LexStop{}: {==}
        case J.LexEscapedChar{}: {==}
        case J.LexBackslash{}: {==}
        case J.LexStringEnd{}: {==}
        case J.LexStringChar{}: {==}
        case J.LexQuote{}: {==}
        case J.LexWhitespace{}: {==}
        case J.LexPunctuation{character}: {==}
        case J.LexRaw{}: {==}

def lex_scan_step(+head: Char,
                  +tail: String,
                  +mode: J.LexMode,
                  +reversed: String,
                  +acc: List<&2, J.Lexeme>) -> {J.lex_scan(SCon{head, tail}, mode, reversed, acc) == J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode), after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed), after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail}, mode, reversed, acc),
        J.lexemes(SCon{head, tail}, mode, reversed, acc, J.lex_seed_action(SCon{head, tail}, mode)),
        J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
            after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
            after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
        {==}, lexemes_step(head, tail, mode, reversed, acc, J.lex_seed_action(SCon{head, tail}, mode)))

def prefix_mode(text: String, +mode: J.LexMode) -> J.LexMode:
    match text:
        case SNil{}: mode
        case SCon{+head, +tail}:
            prefix_mode(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode))

def prefix_reversed(text: String, +mode: J.LexMode, +reversed: String) -> String:
    match text:
        case SNil{}: reversed
        case SCon{+head, +tail}:
            prefix_reversed(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed))

def prefix_acc(text: String,
               +mode: J.LexMode,
               +reversed: String,
               +acc: List<&2, J.Lexeme>) -> List<&2, J.Lexeme>:
    match text:
        case SNil{}: acc
        case SCon{+head, +tail}:
            prefix_acc(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc))

def prefix_mode_append(+text: String,
                       +suffix: String,
                       +mode: J.LexMode) -> {prefix_mode(text ++ suffix, mode) == prefix_mode(suffix, prefix_mode(text, mode)) : J.LexMode}:
    match text:
        case SNil{}: {==}
        case SCon{head, tail}:
            prefix_mode_append(tail, suffix, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode))

def prefix_reversed_append(+text: String,
                           +suffix: String,
                           +mode: J.LexMode,
                           +reversed: String) -> {prefix_reversed(text ++ suffix, mode, reversed) == prefix_reversed(suffix, prefix_mode(text, mode), prefix_reversed(text, mode, reversed)) : String}:
    match text:
        case SNil{}: {==}
        case SCon{head, tail}:
            prefix_reversed_append(tail, suffix, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed))

def prefix_acc_append(+text: String,
                      +suffix: String,
                      +mode: J.LexMode,
                      +reversed: String,
                      +acc: List<&2, J.Lexeme>) -> {prefix_acc(text ++ suffix, mode, reversed, acc) == prefix_acc(suffix, prefix_mode(text, mode), prefix_reversed(text, mode, reversed), prefix_acc(text, mode, reversed, acc)) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}: {==}
        case SCon{head, tail}:
            prefix_acc_append(tail, suffix, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc))

def lex_scan_append(+text: String,
                    +suffix: String,
                    +mode: J.LexMode,
                    +reversed: String,
                    +acc: List<&2, J.Lexeme>) -> {J.lex_scan(text ++ suffix, mode, reversed, acc) == J.lex_scan(suffix, prefix_mode(text, mode), prefix_reversed(text, mode, reversed), prefix_acc(text, mode, reversed, acc)) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}: {==}
        case SCon{head, tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ suffix, mode, reversed, acc),
                J.lex_scan(tail ++ suffix, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                    after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                    after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                J.lex_scan(suffix, prefix_mode(SCon{head, tail}, mode), prefix_reversed(SCon{head, tail}, mode, reversed),
                    prefix_acc(SCon{head, tail}, mode, reversed, acc)),
                lex_scan_step(head, tail ++ suffix, mode, reversed, acc),
                lex_scan_append(tail, suffix, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                    after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                    after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)))

def lex_scan_context(+text: String,
                     +mode1: J.LexMode,
                     +reversed1: String,
                     +acc1: List<&2, J.Lexeme>,
                     +mode2: J.LexMode,
                     +reversed2: String,
                     +acc2: List<&2, J.Lexeme>,
                     mode_eq: {mode1 == mode2 : J.LexMode},
                     reversed_eq: {reversed1 == reversed2 : String},
                     acc_eq: {acc1 == acc2 : List<&2, J.Lexeme>}) -> {J.lex_scan(text, mode1, reversed1, acc1) == J.lex_scan(text, mode2, reversed2, acc2) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>, J.lex_scan(text, mode1, reversed1, acc1),
        J.lex_scan(text, mode2, reversed1, acc1), J.lex_scan(text, mode2, reversed2, acc2),
        Equal.cong(J.LexMode, List<&2, J.Lexeme>, mode => J.lex_scan(text, mode, reversed1, acc1), mode1, mode2, mode_eq),
        Equal.trans(List<&2, J.Lexeme>, J.lex_scan(text, mode2, reversed1, acc1),
            J.lex_scan(text, mode2, reversed2, acc1), J.lex_scan(text, mode2, reversed2, acc2),
            Equal.cong(String, List<&2, J.Lexeme>, reversed => J.lex_scan(text, mode2, reversed, acc1),
                reversed1, reversed2, reversed_eq),
            Equal.cong(List<&2, J.Lexeme>, List<&2, J.Lexeme>, acc => J.lex_scan(text, mode2, reversed2, acc),
                acc1, acc2, acc_eq)))

def scan_punctuation_char(+character: Char,
                          +tail: String,
                          +reversed: String,
                          +acc: List<&2, J.Lexeme>,
                          action: {J.lex_seed_action(SCon{character, tail}, J.Outside{}) == J.LexPunctuation{character} : J.LexAction}) -> {J.lex_scan(SCon{character, tail}, J.Outside{}, reversed, acc) == J.lex_scan(tail, J.Outside{}, SNil{}, J.Punctuation{character} <> J.flush_lexeme(reversed, acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{character, tail}, J.Outside{}, reversed, acc),
        J.lex_scan(tail, after_mode(J.LexPunctuation{character}, J.Outside{}),
            after_reversed(J.LexPunctuation{character}, character, reversed),
            after_acc(J.LexPunctuation{character}, character, reversed, acc)),
        J.lex_scan(tail, J.Outside{}, SNil{}, J.Punctuation{character} <> J.flush_lexeme(reversed, acc)),
        Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{character, tail}, J.Outside{}, reversed, acc),
            J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{character, tail}, J.Outside{}), J.Outside{}),
                after_reversed(J.lex_seed_action(SCon{character, tail}, J.Outside{}), character, reversed),
                after_acc(J.lex_seed_action(SCon{character, tail}, J.Outside{}), character, reversed, acc)),
            J.lex_scan(tail, after_mode(J.LexPunctuation{character}, J.Outside{}),
                after_reversed(J.LexPunctuation{character}, character, reversed),
                after_acc(J.LexPunctuation{character}, character, reversed, acc)),
            lex_scan_step(character, tail, J.Outside{}, reversed, acc),
            Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lex_scan(tail, after_mode(action, J.Outside{}),
                after_reversed(action, character, reversed), after_acc(action, character, reversed, acc)),
                J.lex_seed_action(SCon{character, tail}, J.Outside{}), J.LexPunctuation{character}, action)),
        {==})

def raw_string_seed(+character: Char,
                    +tail: String,
                    classifier: {J.Raw{} == J.escape_class(character) : J.EscapeClass}) -> {J.lex_seed_action(SCon{character, tail}, J.Quoted{}) == J.LexStringChar{} : J.LexAction}:
    Equal.trans(J.LexAction, J.lex_seed_action(SCon{character, tail}, J.Quoted{}),
        J.quote_lex_action(J.quote_action_from_class(J.escape_class(character))), J.LexStringChar{},
        {==},
        Equal.cong(J.EscapeClass, J.LexAction, class => J.quote_lex_action(J.quote_action_from_class(class)),
            J.escape_class(character), J.Raw{}, Equal.sym(J.EscapeClass, J.Raw{}, J.escape_class(character), classifier)))

def scan_raw_string_char(+character: Char,
                         +tail: String,
                         +reversed: String,
                         +acc: List<&2, J.Lexeme>,
                         classifier: {J.Raw{} == J.escape_class(character) : J.EscapeClass}) -> {J.lex_scan(SCon{character, tail}, J.Quoted{}, reversed, acc) == J.lex_scan(tail, J.Quoted{}, SCon{character, reversed}, acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{character, tail}, J.Quoted{}, reversed, acc),
        J.lex_scan(tail, after_mode(J.LexStringChar{}, J.Quoted{}), after_reversed(J.LexStringChar{}, character, reversed), after_acc(J.LexStringChar{}, character, reversed, acc)),
        J.lex_scan(tail, J.Quoted{}, SCon{character, reversed}, acc),
        Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{character, tail}, J.Quoted{}, reversed, acc),
            J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{character, tail}, J.Quoted{}), J.Quoted{}),
                after_reversed(J.lex_seed_action(SCon{character, tail}, J.Quoted{}), character, reversed),
                after_acc(J.lex_seed_action(SCon{character, tail}, J.Quoted{}), character, reversed, acc)),
            J.lex_scan(tail, after_mode(J.LexStringChar{}, J.Quoted{}), after_reversed(J.LexStringChar{}, character, reversed), after_acc(J.LexStringChar{}, character, reversed, acc)),
            lex_scan_step(character, tail, J.Quoted{}, reversed, acc),
            Equal.cong(J.LexAction, List<&2, J.Lexeme>, action => J.lex_scan(tail, after_mode(action, J.Quoted{}), after_reversed(action, character, reversed), after_acc(action, character, reversed, acc)),
                J.lex_seed_action(SCon{character, tail}, J.Quoted{}), J.LexStringChar{}, raw_string_seed(character, tail, classifier))),
        {==})

def scan_escape_char(+character: Char,
                     +tail: String,
                     +reversed: String,
                     +acc: List<&2, J.Lexeme>,
                     +class: J.EscapeClass,
                     classifier: {class == J.escape_class(character) : J.EscapeClass}) -> {J.lex_scan(J.escape_char_from_class(character, class) ++ tail, J.Quoted{}, reversed, acc) == J.lex_scan(tail, J.Quoted{}, String.reverse(J.escape_char_from_class(character, class)) ++ reversed, acc) : List<&2, J.Lexeme>}:
    match class:
        case J.Raw{}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(J.escape_char_from_class(character, J.Raw{}) ++ tail, J.Quoted{}, reversed, acc),
                J.lex_scan(SCon{character, tail}, J.Quoted{}, reversed, acc),
                J.lex_scan(tail, J.Quoted{}, SCon{character, reversed}, acc),
                Equal.cong(String, List<&2, J.Lexeme>, text => J.lex_scan(text, J.Quoted{}, reversed, acc),
                    J.escape_char_from_class(character, J.Raw{}) ++ tail, SCon{character, tail}, {==}),
                scan_raw_string_char(character, tail, reversed, acc, classifier))
        case J.Backslash{}: {==}
        case J.Quote{}: {==}
        case J.Control0{}: {==}
        case J.Control1{}: {==}
        case J.Control2{}: {==}
        case J.Control3{}: {==}
        case J.Control4{}: {==}
        case J.Control5{}: {==}
        case J.Control6{}: {==}
        case J.Control7{}: {==}
        case J.Control8{}: {==}
        case J.Control9{}: {==}
        case J.Control10{}: {==}
        case J.Control11{}: {==}
        case J.Control12{}: {==}
        case J.Control13{}: {==}
        case J.Control14{}: {==}
        case J.Control15{}: {==}
        case J.Control16{}: {==}
        case J.Control17{}: {==}
        case J.Control18{}: {==}
        case J.Control19{}: {==}
        case J.Control20{}: {==}
        case J.Control21{}: {==}
        case J.Control22{}: {==}
        case J.Control23{}: {==}
        case J.Control24{}: {==}
        case J.Control25{}: {==}
        case J.Control26{}: {==}
        case J.Control27{}: {==}
        case J.Control28{}: {==}
        case J.Control29{}: {==}
        case J.Control30{}: {==}
        case J.Control31{}: {==}

def escape_reverse(text: String, reversed: String) -> String:
    match text:
        case SNil{}: reversed
        case SCon{head, tail}:
            escape_reverse(tail, String.reverse(J.escape_char(head)) ++ reversed)

def escape_reverse_shape(+text: String,
                         +reversed: String) -> {String.reverse(escape_reverse(text, reversed)) == String.reverse(reversed) ++ J.escape_string(text) : String}:
    match text:
        case SNil{}: Equal.sym(String, String.reverse(reversed) ++ J.escape_string(SNil{}), String.reverse(reversed), S.append_nil(String.reverse(reversed)))
        case SCon{head, tail}:
            Equal.trans(String,
                String.reverse(escape_reverse(tail, String.reverse(J.escape_char(head)) ++ reversed)),
                String.reverse(String.reverse(J.escape_char(head)) ++ reversed) ++ J.escape_string(tail),
                String.reverse(reversed) ++ J.escape_string(SCon{head, tail}),
                escape_reverse_shape(tail, String.reverse(J.escape_char(head)) ++ reversed),
                Equal.trans(String,
                    String.reverse(String.reverse(J.escape_char(head)) ++ reversed) ++ J.escape_string(tail),
                    (String.reverse(reversed) ++ String.reverse(String.reverse(J.escape_char(head)))) ++ J.escape_string(tail),
                    String.reverse(reversed) ++ (J.escape_char(head) ++ J.escape_string(tail)),
                    Equal.cong(String, String, value => value ++ J.escape_string(tail),
                        String.reverse(String.reverse(J.escape_char(head)) ++ reversed),
                        String.reverse(reversed) ++ String.reverse(String.reverse(J.escape_char(head))),
                        S.reverse_append(String.reverse(J.escape_char(head)), reversed)),
                    Equal.trans(String,
                        (String.reverse(reversed) ++ String.reverse(String.reverse(J.escape_char(head)))) ++ J.escape_string(tail),
                        String.reverse(reversed) ++ (String.reverse(String.reverse(J.escape_char(head))) ++ J.escape_string(tail)),
                        String.reverse(reversed) ++ (J.escape_char(head) ++ J.escape_string(tail)),
                        S.append_assoc(String.reverse(reversed), String.reverse(String.reverse(J.escape_char(head))), J.escape_string(tail)),
                        Equal.cong(String, String, value => String.reverse(reversed) ++ (value ++ J.escape_string(tail)),
                            String.reverse(String.reverse(J.escape_char(head))), J.escape_char(head), S.reverse_twice(J.escape_char(head))))))

def scan_escape_string(+text: String,
                       +suffix: String,
                       +reversed: String,
                       +acc: List<&2, J.Lexeme>) -> {J.lex_scan(J.escape_string(text) ++ suffix, J.Quoted{}, reversed, acc) == J.lex_scan(suffix, J.Quoted{}, escape_reverse(text, reversed), acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}: {==}
        case SCon{+head, +tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(J.escape_string(text) ++ suffix, J.Quoted{}, reversed, acc),
                J.lex_scan(J.escape_char(head) ++ (J.escape_string(tail) ++ suffix), J.Quoted{}, reversed, acc),
                J.lex_scan(suffix, J.Quoted{}, escape_reverse(text, reversed), acc),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source, J.Quoted{}, reversed, acc),
                    J.escape_string(text) ++ suffix, J.escape_char(head) ++ (J.escape_string(tail) ++ suffix),
                    S.append_assoc(J.escape_char(head), J.escape_string(tail), suffix)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(J.escape_char(head) ++ (J.escape_string(tail) ++ suffix), J.Quoted{}, reversed, acc),
                    J.lex_scan(J.escape_string(tail) ++ suffix, J.Quoted{}, String.reverse(J.escape_char(head)) ++ reversed, acc),
                    J.lex_scan(suffix, J.Quoted{}, escape_reverse(text, reversed), acc),
                    scan_escape_char(head, J.escape_string(tail) ++ suffix, reversed, acc, J.escape_class(head), {==}),
                    scan_escape_string(tail, suffix, String.reverse(J.escape_char(head)) ++ reversed, acc)))

def quoted_buffer_payload(+text: String) -> {String.reverse(SCon{'"', escape_reverse(text, SCon{'"', SNil{}})}) == SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}} : String}:
    Equal.trans(String,
        String.reverse(SCon{'"', escape_reverse(text, SCon{'"', SNil{}})}),
        String.reverse(escape_reverse(text, SCon{'"', SNil{}})) ++ SCon{'"', SNil{}},
        SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}},
        S.reverse_cons('"', escape_reverse(text, SCon{'"', SNil{}})),
        Equal.trans(String,
            String.reverse(escape_reverse(text, SCon{'"', SNil{}})) ++ SCon{'"', SNil{}},
            (SCon{'"', SNil{}} ++ J.escape_string(text)) ++ SCon{'"', SNil{}},
            SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}},
            Equal.cong(String, String, value => value ++ SCon{'"', SNil{}},
                String.reverse(escape_reverse(text, SCon{'"', SNil{}})),
                SCon{'"', SNil{}} ++ J.escape_string(text),
                escape_reverse_shape(text, SCon{'"', SNil{}})),
            S.append_assoc(SCon{'"', SNil{}}, J.escape_string(text), SCon{'"', SNil{}})))

def lex_rendered_string(+text: String) -> {J.lex_scan(SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}, J.Outside{}, SNil{}, Nil{}) == J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> Nil{} : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan(SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}, J.Outside{}, SNil{}, Nil{}),
        J.lex_scan(J.escape_string(text) ++ SCon{'"', SNil{}}, J.Quoted{}, SCon{'"', SNil{}}, Nil{}),
        J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> Nil{},
        lex_scan_step('"', J.escape_string(text) ++ SCon{'"', SNil{}}, J.Outside{}, SNil{}, Nil{}),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(J.escape_string(text) ++ SCon{'"', SNil{}}, J.Quoted{}, SCon{'"', SNil{}}, Nil{}),
            J.lex_scan(SCon{'"', SNil{}}, J.Quoted{}, escape_reverse(text, SCon{'"', SNil{}}), Nil{}),
            J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> Nil{},
            scan_escape_string(text, SCon{'"', SNil{}}, SCon{'"', SNil{}}, Nil{}),
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan(SCon{'"', SNil{}}, J.Quoted{}, escape_reverse(text, SCon{'"', SNil{}}), Nil{}),
                J.Payload{String.reverse(SCon{'"', escape_reverse(text, SCon{'"', SNil{}})})} <> Nil{},
                J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> Nil{},
                lex_scan_step('"', SNil{}, J.Quoted{}, escape_reverse(text, SCon{'"', SNil{}}), Nil{}),
                Equal.cong(String, List<&2, J.Lexeme>, payload => J.Payload{payload} <> Nil{},
                    String.reverse(SCon{'"', escape_reverse(text, SCon{'"', SNil{}})}),
                    SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}, quoted_buffer_payload(text)))))

def lex_rendered_string_suffix(+text: String,
                               +suffix: String,
                               +acc: List<&2, J.Lexeme>) -> {J.lex_scan((SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}) ++ suffix, J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan((SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}) ++ suffix, J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{'"', (J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix}, J.Outside{}, SNil{}, acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
        Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source, J.Outside{}, SNil{}, acc),
            (SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}) ++ suffix,
            SCon{'"', (J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix}, {==}),
        Equal.trans(List<&2, J.Lexeme>,
            J.lex_scan(SCon{'"', (J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix}, J.Outside{}, SNil{}, acc),
            J.lex_scan((J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix, J.Quoted{}, SCon{'"', SNil{}}, acc),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
            lex_scan_step('"', (J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix, J.Outside{}, SNil{}, acc),
            Equal.trans(List<&2, J.Lexeme>,
                J.lex_scan((J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix, J.Quoted{}, SCon{'"', SNil{}}, acc),
                J.lex_scan(J.escape_string(text) ++ (SCon{'"', SNil{}} ++ suffix), J.Quoted{}, SCon{'"', SNil{}}, acc),
                J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
                Equal.cong(String, List<&2, J.Lexeme>, source => J.lex_scan(source, J.Quoted{}, SCon{'"', SNil{}}, acc),
                    (J.escape_string(text) ++ SCon{'"', SNil{}}) ++ suffix,
                    J.escape_string(text) ++ (SCon{'"', SNil{}} ++ suffix),
                    S.append_assoc(J.escape_string(text), SCon{'"', SNil{}}, suffix)),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(J.escape_string(text) ++ (SCon{'"', SNil{}} ++ suffix), J.Quoted{}, SCon{'"', SNil{}}, acc),
                    J.lex_scan(SCon{'"', SNil{}} ++ suffix, J.Quoted{}, escape_reverse(text, SCon{'"', SNil{}}), acc),
                    J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
                    scan_escape_string(text, SCon{'"', SNil{}} ++ suffix, SCon{'"', SNil{}}, acc),
                    Equal.trans(List<&2, J.Lexeme>,
                        J.lex_scan(SCon{'"', SNil{}} ++ suffix, J.Quoted{}, escape_reverse(text, SCon{'"', SNil{}}), acc),
                        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{String.reverse(SCon{'"', escape_reverse(text, SCon{'"', SNil{}})})} <> acc),
                        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
                        lex_scan_step('"', suffix, J.Quoted{}, escape_reverse(text, SCon{'"', SNil{}}), acc),
                        Equal.cong(String, List<&2, J.Lexeme>, payload => J.lex_scan(suffix, J.Outside{}, SNil{}, J.Payload{payload} <> acc),
                            String.reverse(SCon{'"', escape_reverse(text, SCon{'"', SNil{}})}),
                            SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}, quoted_buffer_payload(text)))))))

def lex_string_before_punctuation(+text: String,
                                  +punctuation: Char,
                                  +suffix: String,
                                  +acc: List<&2, J.Lexeme>,
                                  action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan((SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, (J.Punctuation{punctuation} <> J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc)) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan((SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}) ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc),
        lex_rendered_string_suffix(text, SCon{punctuation, SNil{}} ++ suffix, acc),
        scan_punctuation_char(punctuation, suffix, SNil{}, J.Payload{SCon{'"', J.escape_string(text) ++ SCon{'"', SNil{}}}} <> acc, action))

def lex_null_before_punctuation(+punctuation: Char,
                                +suffix: String,
                                +acc: List<&2, J.Lexeme>,
                                action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan("null" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{"null"} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan("null" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, "llun", acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{"null"} <> acc),
        {==},
        scan_punctuation_char(punctuation, suffix, "llun", acc, action))

def lex_true_before_punctuation(+punctuation: Char,
                                +suffix: String,
                                +acc: List<&2, J.Lexeme>,
                                action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan("true" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{"true"} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan("true" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, "eurt", acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{"true"} <> acc),
        {==},
        scan_punctuation_char(punctuation, suffix, "eurt", acc, action))

def lex_false_before_punctuation(+punctuation: Char,
                                 +suffix: String,
                                 +acc: List<&2, J.Lexeme>,
                                 action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan("false" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{"false"} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>,
        J.lex_scan("false" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, "eslaf", acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Payload{"false"} <> acc),
        {==},
        scan_punctuation_char(punctuation, suffix, "eslaf", acc, action))

def lex_empty_array_before_punctuation(+punctuation: Char,
                                       +suffix: String,
                                       +acc: List<&2, J.Lexeme>,
                                       action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan("[]" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> J.Punctuation{'['} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>, J.lex_scan("[]" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{']', SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}, SNil{}, J.Punctuation{'['} <> acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> J.Punctuation{'['} <> acc),
        scan_punctuation_char('[', SCon{']', SCon{punctuation, SNil{}} ++ suffix}, SNil{}, acc, {==}),
        Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{']', SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}, SNil{}, J.Punctuation{'['} <> acc),
            J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{']'} <> J.Punctuation{'['} <> acc),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{']'} <> J.Punctuation{'['} <> acc),
            scan_punctuation_char(']', SCon{punctuation, SNil{}} ++ suffix, SNil{}, J.Punctuation{'['} <> acc, {==}),
            scan_punctuation_char(punctuation, suffix, SNil{}, J.Punctuation{']'} <> J.Punctuation{'['} <> acc, action)))

def lex_empty_object_before_punctuation(+punctuation: Char,
                                        +suffix: String,
                                        +acc: List<&2, J.Lexeme>,
                                        action: {J.lex_seed_action(SCon{punctuation, suffix}, J.Outside{}) == J.LexPunctuation{punctuation} : J.LexAction}) -> {J.lex_scan("{}" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc) == J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc) : List<&2, J.Lexeme>}:
    Equal.trans(List<&2, J.Lexeme>, J.lex_scan("{}" ++ (SCon{punctuation, SNil{}} ++ suffix), J.Outside{}, SNil{}, acc),
        J.lex_scan(SCon{'}', SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}, SNil{}, J.Punctuation{'{'} <> acc),
        J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc),
        scan_punctuation_char('{', SCon{'}', SCon{punctuation, SNil{}} ++ suffix}, SNil{}, acc, {==}),
        Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{'}', SCon{punctuation, SNil{}} ++ suffix}, J.Outside{}, SNil{}, J.Punctuation{'{'} <> acc),
            J.lex_scan(SCon{punctuation, SNil{}} ++ suffix, J.Outside{}, SNil{}, J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc),
            J.lex_scan(suffix, J.Outside{}, SNil{}, J.Punctuation{punctuation} <> J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc),
            scan_punctuation_char('}', SCon{punctuation, SNil{}} ++ suffix, SNil{}, J.Punctuation{'{'} <> acc, {==}),
            scan_punctuation_char(punctuation, suffix, SNil{}, J.Punctuation{'}'} <> J.Punctuation{'{'} <> acc, action)))

def trailing_space(+text: String,
                   +mode: J.LexMode,
                   +reversed: String,
                   +acc: List<&2, J.Lexeme>) -> {J.lex_scan(text ++ " ", mode, reversed, acc) == J.lex_scan(text, mode, reversed, acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            match mode:
                case J.Outside{}: {==}
                case J.Quoted{}: {==}
                case J.Escaped{}: {==}
        case SCon{head, tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ " ", mode, reversed, acc),
                J.lex_scan(tail ++ " ", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                    after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                    after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                lex_scan_step(head, tail ++ " ", mode, reversed, acc),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(tail ++ " ", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                    trailing_space(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    Equal.sym(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                        J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                            after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                            after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                        lex_scan_step(head, tail, mode, reversed, acc))))

def trailing_tab(+text: String,
                 +mode: J.LexMode,
                 +reversed: String,
                 +acc: List<&2, J.Lexeme>) -> {J.lex_scan(text ++ "\t", mode, reversed, acc) == J.lex_scan(text, mode, reversed, acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            match mode:
                case J.Outside{}: {==}
                case J.Quoted{}: {==}
                case J.Escaped{}: {==}
        case SCon{head, tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ "\t", mode, reversed, acc),
                J.lex_scan(tail ++ "\t", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                    after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                    after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                lex_scan_step(head, tail ++ "\t", mode, reversed, acc),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(tail ++ "\t", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                    trailing_tab(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    Equal.sym(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                        J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                            after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                            after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                        lex_scan_step(head, tail, mode, reversed, acc))))

def trailing_return(+text: String,
                    +mode: J.LexMode,
                    +reversed: String,
                    +acc: List<&2, J.Lexeme>) -> {J.lex_scan(text ++ "\r", mode, reversed, acc) == J.lex_scan(text, mode, reversed, acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            match mode:
                case J.Outside{}: {==}
                case J.Quoted{}: {==}
                case J.Escaped{}: {==}
        case SCon{head, tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ "\r", mode, reversed, acc),
                J.lex_scan(tail ++ "\r", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                    after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                    after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                lex_scan_step(head, tail ++ "\r", mode, reversed, acc),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(tail ++ "\r", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                    trailing_return(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    Equal.sym(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                        J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                            after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                            after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                        lex_scan_step(head, tail, mode, reversed, acc))))

def trailing_newline(+text: String,
                     +mode: J.LexMode,
                     +reversed: String,
                     +acc: List<&2, J.Lexeme>) -> {J.lex_scan(text ++ "\n", mode, reversed, acc) == J.lex_scan(text, mode, reversed, acc) : List<&2, J.Lexeme>}:
    match text:
        case SNil{}:
            match mode:
                case J.Outside{}: {==}
                case J.Quoted{}: {==}
                case J.Escaped{}: {==}
        case SCon{head, tail}:
            Equal.trans(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail} ++ "\n", mode, reversed, acc),
                J.lex_scan(tail ++ "\n", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                    after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                    after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                lex_scan_step(head, tail ++ "\n", mode, reversed, acc),
                Equal.trans(List<&2, J.Lexeme>,
                    J.lex_scan(tail ++ "\n", after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                    trailing_newline(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                        after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                        after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                    Equal.sym(List<&2, J.Lexeme>, J.lex_scan(SCon{head, tail}, mode, reversed, acc),
                        J.lex_scan(tail, after_mode(J.lex_seed_action(SCon{head, tail}, mode), mode),
                            after_reversed(J.lex_seed_action(SCon{head, tail}, mode), head, reversed),
                            after_acc(J.lex_seed_action(SCon{head, tail}, mode), head, reversed, acc)),
                        lex_scan_step(head, tail, mode, reversed, acc))))
