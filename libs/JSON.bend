import Base

# JSON values preserve number lexemes as strings. This keeps integers and
# fractional/exponent forms lossless without imposing a fixed numeric width.
# Number carries grammar evidence so every constructible number is valid JSON.
# Use number(text) or parse(text) to create numbers from runtime strings.
def BoolType() -> Data:
    Bool

type NumberCert<-s: String> is Data:
    Certified{witness: NumberProof(s)}

type Value is Data:
    Null{}
    Bool{value: BoolType()}
    Number{lexeme: String, certificate: NumberCert<lexeme>}
    Str{value: String}
    Arr{values: List<&2, Value>}
    Obj{fields: List<&2, Sigma<&2, &2, String, key => Value>>}

type Error is Data:
    Error{}

type Parsed is Type:
    Parsed{value: Value, rest: String}

type StringScan is Data:
    StringScan{value: String, rest: String}

type StringScanState is Type:
    ScanText{input: String, reversed: String}
    ScanControl{character: Char, rest: String, reversed: String, control: BoolType()}
    ScanUnicode{parsed: Result<&1, &1, Error, HexScan>, reversed: String}
    ScanUnicodeHigh{code: U32, rest: String, reversed: String, is_high: BoolType()}
    ScanUnicodeLow{high: U32, original: String, parsed: Result<&1, &1, Error, HexScan>, reversed: String}
    ScanUnicodeLowClass{high: U32, low: U32, rest: String, original: String, reversed: String, valid: BoolType()}

type NumberState is Data:
    NumberStart{}
    NumberMinus{}
    NumberZero{}
    NumberInteger{}
    NumberDot{}
    NumberFraction{}
    NumberExponent{}
    NumberExponentSign{}
    NumberExponentDigits{}
    NumberInvalid{}

def whitespace(s: String) -> String:
    match s:
        case SNil{}:
            SNil{}
        case SCon{+h, t}:
            match h:
                case ' ':
                    whitespace(t)
                case '\t':
                    whitespace(t)
                case '\r':
                    whitespace(t)
                case '\n':
                    whitespace(t)
                case _:
                    SCon{h, t}

def is_control(c: Char) -> BoolType():
    match c:
        case '\u{0}': True{}
        case '\u{1}': True{}
        case '\u{2}': True{}
        case '\u{3}': True{}
        case '\u{4}': True{}
        case '\u{5}': True{}
        case '\u{6}': True{}
        case '\u{7}': True{}
        case '\u{8}': True{}
        case '\u{9}': True{}
        case '\u{a}': True{}
        case '\u{b}': True{}
        case '\u{c}': True{}
        case '\u{d}': True{}
        case '\u{e}': True{}
        case '\u{f}': True{}
        case '\u{10}': True{}
        case '\u{11}': True{}
        case '\u{12}': True{}
        case '\u{13}': True{}
        case '\u{14}': True{}
        case '\u{15}': True{}
        case '\u{16}': True{}
        case '\u{17}': True{}
        case '\u{18}': True{}
        case '\u{19}': True{}
        case '\u{1a}': True{}
        case '\u{1b}': True{}
        case '\u{1c}': True{}
        case '\u{1d}': True{}
        case '\u{1e}': True{}
        case '\u{1f}': True{}
        case _: False{}

def escape_char_special(c: Char) -> String:
    match c:
        case '\u{0}': "\\u0000"
        case '\u{1}': "\\u0001"
        case '\u{2}': "\\u0002"
        case '\u{3}': "\\u0003"
        case '\u{4}': "\\u0004"
        case '\u{5}': "\\u0005"
        case '\u{6}': "\\u0006"
        case '\u{7}': "\\u0007"
        case '\u{8}': "\\b"
        case '\u{9}': "\\t"
        case '\u{a}': "\\n"
        case '\u{b}': "\\u000b"
        case '\u{c}': "\\f"
        case '\u{d}': "\\r"
        case '\u{e}': "\\u000e"
        case '\u{f}': "\\u000f"
        case '\u{10}': "\\u0010"
        case '\u{11}': "\\u0011"
        case '\u{12}': "\\u0012"
        case '\u{13}': "\\u0013"
        case '\u{14}': "\\u0014"
        case '\u{15}': "\\u0015"
        case '\u{16}': "\\u0016"
        case '\u{17}': "\\u0017"
        case '\u{18}': "\\u0018"
        case '\u{19}': "\\u0019"
        case '\u{1a}': "\\u001a"
        case '\u{1b}': "\\u001b"
        case '\u{1c}': "\\u001c"
        case '\u{1d}': "\\u001d"
        case '\u{1e}': "\\u001e"
        case '\u{1f}': "\\u001f"
        case '\u{22}': "\\\""
        case '\u{5c}': "\\\\"
        case _: SCon{c, SNil{}}

type EscapeClass is Data:
    Raw{}
    Backslash{}
    Quote{}
    Control0{}
    Control1{}
    Control2{}
    Control3{}
    Control4{}
    Control5{}
    Control6{}
    Control7{}
    Control8{}
    Control9{}
    Control10{}
    Control11{}
    Control12{}
    Control13{}
    Control14{}
    Control15{}
    Control16{}
    Control17{}
    Control18{}
    Control19{}
    Control20{}
    Control21{}
    Control22{}
    Control23{}
    Control24{}
    Control25{}
    Control26{}
    Control27{}
    Control28{}
    Control29{}
    Control30{}
    Control31{}

def escape_class(character: Char) -> EscapeClass:
    match character:
        case '\u{0}': Control0{}
        case '\u{1}': Control1{}
        case '\u{2}': Control2{}
        case '\u{3}': Control3{}
        case '\u{4}': Control4{}
        case '\u{5}': Control5{}
        case '\u{6}': Control6{}
        case '\u{7}': Control7{}
        case '\u{8}': Control8{}
        case '\u{9}': Control9{}
        case '\u{a}': Control10{}
        case '\u{b}': Control11{}
        case '\u{c}': Control12{}
        case '\u{d}': Control13{}
        case '\u{e}': Control14{}
        case '\u{f}': Control15{}
        case '\u{10}': Control16{}
        case '\u{11}': Control17{}
        case '\u{12}': Control18{}
        case '\u{13}': Control19{}
        case '\u{14}': Control20{}
        case '\u{15}': Control21{}
        case '\u{16}': Control22{}
        case '\u{17}': Control23{}
        case '\u{18}': Control24{}
        case '\u{19}': Control25{}
        case '\u{1a}': Control26{}
        case '\u{1b}': Control27{}
        case '\u{1c}': Control28{}
        case '\u{1d}': Control29{}
        case '\u{1e}': Control30{}
        case '\u{1f}': Control31{}
        case '"': Quote{}
        case '\\': Backslash{}
        case _: Raw{}

type QuoteAction is Data:
    QuoteBackslash{}
    QuoteEnd{}
    QuotePlain{}

def quote_action_from_class(class: EscapeClass) -> QuoteAction:
    match class:
        case Backslash{}: QuoteBackslash{}
        case Quote{}: QuoteEnd{}
        case _: QuotePlain{}

def quote_action(character: Char) -> QuoteAction:
    quote_action_from_class(escape_class(character))

def quote_lex_action(action: QuoteAction) -> LexAction:
    match action:
        case QuoteBackslash{}: LexBackslash{}
        case QuoteEnd{}: LexStringEnd{}
        case QuotePlain{}: LexStringChar{}

def escape_char_from_class(character: Char, class: EscapeClass) -> String:
    match class:
        case Raw{}: SCon{character, SNil{}}
        case Backslash{}: "\\\\"
        case Quote{}: "\\\""
        case Control0{}: "\\u0000"
        case Control1{}: "\\u0001"
        case Control2{}: "\\u0002"
        case Control3{}: "\\u0003"
        case Control4{}: "\\u0004"
        case Control5{}: "\\u0005"
        case Control6{}: "\\u0006"
        case Control7{}: "\\u0007"
        case Control8{}: "\\b"
        case Control9{}: "\\t"
        case Control10{}: "\\n"
        case Control11{}: "\\u000b"
        case Control12{}: "\\f"
        case Control13{}: "\\r"
        case Control14{}: "\\u000e"
        case Control15{}: "\\u000f"
        case Control16{}: "\\u0010"
        case Control17{}: "\\u0011"
        case Control18{}: "\\u0012"
        case Control19{}: "\\u0013"
        case Control20{}: "\\u0014"
        case Control21{}: "\\u0015"
        case Control22{}: "\\u0016"
        case Control23{}: "\\u0017"
        case Control24{}: "\\u0018"
        case Control25{}: "\\u0019"
        case Control26{}: "\\u001a"
        case Control27{}: "\\u001b"
        case Control28{}: "\\u001c"
        case Control29{}: "\\u001d"
        case Control30{}: "\\u001e"
        case Control31{}: "\\u001f"

def escape_char(+character: Char) -> String:
    escape_char_from_class(character, escape_class(character))

def escape_string(s: String) -> String:
    match s:
        case SNil{}:
            ""
        case SCon{h, t}:
            escape_char(h) ++ escape_string(t)

# Structural rendering has no fuel limit. Tail mode emits the comma before
# each subsequent member and the closing delimiter at the empty tail.
def render_object_field(prefix: String, key: String, value_text: String) -> String:
    (prefix ++ ("\"" ++ escape_string(key) ++ "\":")) ++ value_text

def render(value: Value, members: BoolType(), suffix: String) -> String:
    match value:
        case Null{}: "null" ++ suffix
        case Bool{truth}:
            match truth:
                case True{}: "true" ++ suffix
                case False{}: "false" ++ suffix
        case Number{lexeme, certificate}: lexeme ++ suffix
        case Str{text}: "\"" ++ escape_string(text) ++ "\"" ++ suffix
        case Arr{Nil{}}:
            match members:
                case False{}: "[]" ++ suffix
                case True{}: "]" ++ suffix
        case Arr{head <> tail}:
            match members:
                case False{}: "[" ++ render(head, False{}, render(Arr{tail}, True{}, suffix))
                case True{}: "," ++ render(head, False{}, render(Arr{tail}, True{}, suffix))
        case Obj{Nil{}}:
            match members:
                case False{}: "{}" ++ suffix
                case True{}: "}" ++ suffix
        case Obj{(key, value) <> tail}:
            match members:
                case False{}: render_object_field("{", key, render(value, False{}, render(Obj{tail}, True{}, suffix)))
                case True{}: render_object_field(",", key, render(value, False{}, render(Obj{tail}, True{}, suffix)))

def stringify(value: Value) -> String:
    render(value, False{}, SNil{})

# A hexadecimal escape is exactly four digits. The code preserves standalone
# UTF-16 surrogate escapes and combines adjacent high/low pairs into a scalar.
# This accepts the JSON string grammar without silently replacing code units.
type HexScan is Data:
    HexScan{code: U32, rest: String}

def hex_digit(c: Char) -> Maybe<&2, U32>:
    match c:
        case '0': Some{0}
        case '1': Some{1}
        case '2': Some{2}
        case '3': Some{3}
        case '4': Some{4}
        case '5': Some{5}
        case '6': Some{6}
        case '7': Some{7}
        case '8': Some{8}
        case '9': Some{9}
        case 'a': Some{10}
        case 'b': Some{11}
        case 'c': Some{12}
        case 'd': Some{13}
        case 'e': Some{14}
        case 'f': Some{15}
        case 'A': Some{10}
        case 'B': Some{11}
        case 'C': Some{12}
        case 'D': Some{13}
        case 'E': Some{14}
        case 'F': Some{15}
        case _: None{}

def scan_hex(n: Nat, s: String, acc: U32) -> Result<&1, &1, Error, HexScan>:
    match n:
        case 0n:
            Done{HexScan{acc, s}}
        case 1n+p:
            match s:
                case SNil{}:
                    Fail{Error{}}
                case SCon{'0', t}:
                    scan_hex(p, t, (acc * 16 + 0 : U32))
                case SCon{'1', t}:
                    scan_hex(p, t, (acc * 16 + 1 : U32))
                case SCon{'2', t}:
                    scan_hex(p, t, (acc * 16 + 2 : U32))
                case SCon{'3', t}:
                    scan_hex(p, t, (acc * 16 + 3 : U32))
                case SCon{'4', t}:
                    scan_hex(p, t, (acc * 16 + 4 : U32))
                case SCon{'5', t}:
                    scan_hex(p, t, (acc * 16 + 5 : U32))
                case SCon{'6', t}:
                    scan_hex(p, t, (acc * 16 + 6 : U32))
                case SCon{'7', t}:
                    scan_hex(p, t, (acc * 16 + 7 : U32))
                case SCon{'8', t}:
                    scan_hex(p, t, (acc * 16 + 8 : U32))
                case SCon{'9', t}:
                    scan_hex(p, t, (acc * 16 + 9 : U32))
                case SCon{'a', t}:
                    scan_hex(p, t, (acc * 16 + 10 : U32))
                case SCon{'b', t}:
                    scan_hex(p, t, (acc * 16 + 11 : U32))
                case SCon{'c', t}:
                    scan_hex(p, t, (acc * 16 + 12 : U32))
                case SCon{'d', t}:
                    scan_hex(p, t, (acc * 16 + 13 : U32))
                case SCon{'e', t}:
                    scan_hex(p, t, (acc * 16 + 14 : U32))
                case SCon{'f', t}:
                    scan_hex(p, t, (acc * 16 + 15 : U32))
                case SCon{'A', t}:
                    scan_hex(p, t, (acc * 16 + 10 : U32))
                case SCon{'B', t}:
                    scan_hex(p, t, (acc * 16 + 11 : U32))
                case SCon{'C', t}:
                    scan_hex(p, t, (acc * 16 + 12 : U32))
                case SCon{'D', t}:
                    scan_hex(p, t, (acc * 16 + 13 : U32))
                case SCon{'E', t}:
                    scan_hex(p, t, (acc * 16 + 14 : U32))
                case SCon{'F', t}:
                    scan_hex(p, t, (acc * 16 + 15 : U32))
                case _:
                    Fail{Error{}}

def string_push(c: Char,
                result: Result<&1, &1, Error, StringScan>) -> Result<&1, &1, Error, StringScan>:
    match result:
        case Fail{e}:
            Fail{e}
        case Done{scan}:
            match scan:
                case StringScan{s, rest}:
                    Done{StringScan{SCon{c, s}, rest}}

def scan_string_machine(fuel: Nat, state: StringScanState) -> Result<&1, &1, Error, StringScan>:
    match fuel:
        case 0n:
            Fail{Error{}}
        case 1n+p:
            match state:
                case ScanText{input, reversed}:
                    match input:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{+h, +t}:
                            match h:
                                case '"':
                                    Done{StringScan{String.reverse(reversed), t}}
                                case '\\':
                                    match t:
                                        case SNil{}:
                                            Fail{Error{}}
                                        case SCon{e, et}:
                                            match e:
                                                case '"': scan_string_machine(p, ScanText{et, SCon{'"', reversed}})
                                                case '\\': scan_string_machine(p, ScanText{et, SCon{'\\', reversed}})
                                                case '/': scan_string_machine(p, ScanText{et, SCon{'/', reversed}})
                                                case 'b': scan_string_machine(p, ScanText{et, SCon{'\u{8}', reversed}})
                                                case 'f': scan_string_machine(p, ScanText{et, SCon{'\u{c}', reversed}})
                                                case 'n': scan_string_machine(p, ScanText{et, SCon{'\n', reversed}})
                                                case 'r': scan_string_machine(p, ScanText{et, SCon{'\r', reversed}})
                                                case 't': scan_string_machine(p, ScanText{et, SCon{'\t', reversed}})
                                                case 'u': scan_string_machine(p, ScanUnicode{scan_hex(4n, et, 0), reversed})
                                                case _: Fail{Error{}}
                                case _:
                                    scan_string_machine(p, ScanControl{h, t, reversed, is_control(h)})
                case ScanControl{character, rest, reversed, control}:
                    match control:
                        case True{}:
                            Fail{Error{}}
                        case False{}:
                            scan_string_machine(p, ScanText{rest, SCon{character, reversed}})
                case ScanUnicode{parsed, reversed}:
                    match parsed:
                        case Fail{e}:
                            Fail{e}
                        case Done{scan}:
                            match scan:
                                case HexScan{+code, +rest}:
                                    scan_string_machine(p, ScanUnicodeHigh{code, rest, reversed, U32.is_ge(code, 55296) && U32.is_le(code, 56319)})
                case ScanUnicodeHigh{code, +rest, +reversed, is_high}:
                    match rest:
                        case SCon{'\\', SCon{'u', t}}:
                            match is_high:
                                case True{}:
                                    scan_string_machine(p, ScanUnicodeLow{code, rest, scan_hex(4n, t, 0), reversed})
                                case False{}:
                                    scan_string_machine(p, ScanText{rest, SCon{Char.from_u32(code), reversed}})
                        case _:
                            scan_string_machine(p, ScanText{rest, SCon{Char.from_u32(code), reversed}})
                case ScanUnicodeLow{high, original, parsed, reversed}:
                    match parsed:
                        case Fail{e}:
                            scan_string_machine(p, ScanText{original, SCon{Char.from_u32(high), reversed}})
                        case Done{scan}:
                            match scan:
                                case HexScan{+low, +rest}:
                                    scan_string_machine(p, ScanUnicodeLowClass{high, low, rest, original, reversed, U32.is_ge(low, 56320) && U32.is_le(low, 57343)})
                case ScanUnicodeLowClass{high, low, rest, original, reversed, valid}:
                    match valid:
                        case True{}:
                            scan_string_machine(p, ScanText{rest, SCon{Char.from_u32((65536 + (high - 55296) * 1024 + (low - 56320) : U32)), reversed}})
                        case False{}:
                            scan_string_machine(p, ScanText{original, SCon{Char.from_u32(high), reversed}})

def scan_string(+s: String) -> Result<&1, &1, Error, StringScan>:
    scan_string_machine((String.length(s) * 2n + 16n : Nat), ScanText{s, SNil{}})

def scan_number(s: String, acc: String) -> StringScan:
    match s:
        case SNil{}:
            StringScan{String.reverse(acc), SNil{}}
        case SCon{h, t}:
            match h:
                case '-': scan_number(t, SCon{h, acc})
                case '+': scan_number(t, SCon{h, acc})
                case '.': scan_number(t, SCon{h, acc})
                case 'e': scan_number(t, SCon{h, acc})
                case 'E': scan_number(t, SCon{h, acc})
                case '0': scan_number(t, SCon{h, acc})
                case '1': scan_number(t, SCon{h, acc})
                case '2': scan_number(t, SCon{h, acc})
                case '3': scan_number(t, SCon{h, acc})
                case '4': scan_number(t, SCon{h, acc})
                case '5': scan_number(t, SCon{h, acc})
                case '6': scan_number(t, SCon{h, acc})
                case '7': scan_number(t, SCon{h, acc})
                case '8': scan_number(t, SCon{h, acc})
                case '9': scan_number(t, SCon{h, acc})
                case _: StringScan{String.reverse(acc), SCon{h, t}}

type NumberChar is Data:
    NMinus{}
    NPlus{}
    NDot{}
    NExp{}
    NZero{}
    NDigit{}
    NOther{}

def number_char(c: Char) -> NumberChar:
    match c:
        case '-': NMinus{}
        case '+': NPlus{}
        case '.': NDot{}
        case 'e': NExp{}
        case 'E': NExp{}
        case '0': NZero{}
        case '1': NDigit{}
        case '2': NDigit{}
        case '3': NDigit{}
        case '4': NDigit{}
        case '5': NDigit{}
        case '6': NDigit{}
        case '7': NDigit{}
        case '8': NDigit{}
        case '9': NDigit{}
        case _: NOther{}

def number_step(character: NumberChar, state: NumberState) -> NumberState:
    match character state:
        case NOther{} _: NumberInvalid{}
        case NMinus{} NumberStart{}: NumberMinus{}
        case NMinus{} NumberExponent{}: NumberExponentSign{}
        case NPlus{} NumberExponent{}: NumberExponentSign{}
        case NDot{} NumberZero{}: NumberDot{}
        case NDot{} NumberInteger{}: NumberDot{}
        case NExp{} NumberZero{}: NumberExponent{}
        case NExp{} NumberInteger{}: NumberExponent{}
        case NExp{} NumberFraction{}: NumberExponent{}
        case NZero{} NumberStart{}: NumberZero{}
        case NZero{} NumberMinus{}: NumberZero{}
        case NZero{} NumberInteger{}: NumberInteger{}
        case NZero{} NumberDot{}: NumberFraction{}
        case NZero{} NumberFraction{}: NumberFraction{}
        case NZero{} NumberExponent{}: NumberExponentDigits{}
        case NZero{} NumberExponentSign{}: NumberExponentDigits{}
        case NZero{} NumberExponentDigits{}: NumberExponentDigits{}
        case NDigit{} NumberStart{}: NumberInteger{}
        case NDigit{} NumberMinus{}: NumberInteger{}
        case NDigit{} NumberInteger{}: NumberInteger{}
        case NDigit{} NumberDot{}: NumberFraction{}
        case NDigit{} NumberFraction{}: NumberFraction{}
        case NDigit{} NumberExponent{}: NumberExponentDigits{}
        case NDigit{} NumberExponentSign{}: NumberExponentDigits{}
        case NDigit{} NumberExponentDigits{}: NumberExponentDigits{}
        case _ _: NumberInvalid{}

def number_next(state: NumberState, c: Char) -> NumberState:
    match state:
        case NumberInvalid{}: NumberInvalid{}
        case _: number_step(number_char(c), state)

def number_valid_end(state: NumberState) -> BoolType():
    match state:
        case NumberZero{}:
            True{}
        case NumberInteger{}:
            True{}
        case NumberFraction{}:
            True{}
        case NumberExponentDigits{}:
            True{}
        case _:
            False{}

def number_valid_step(s: String, state: NumberState) -> NumberState:
    match s state:
        case _ NumberInvalid{}:
            NumberInvalid{}
        case SNil{} _:
            state
        case SCon{h, t} _:
            number_valid_step(t, number_next(state, h))

def number_valid(+s: String) -> BoolType():
    number_valid_end(number_valid_step(s, NumberStart{}))

def NumberProofFrom(valid: BoolType()) -> Data:
    match valid:
        case True{}:
            Unit
        case False{}:
            Empty

def NumberProof(s: String) -> Data:
    NumberProofFrom(number_valid(s))

def null_token(s: String, matches: BoolType()) -> Result<&1, &1, Error, Parsed>:
    match matches:
        case True{}:
            Done{Parsed{Null{}, String.drop(s, 4n)}}
        case False{}:
            Fail{Error{}}

def true_token(s: String, matches: BoolType()) -> Result<&1, &1, Error, Parsed>:
    match matches:
        case True{}:
            Done{Parsed{Bool{True{}}, String.drop(s, 4n)}}
        case False{}:
            Fail{Error{}}

def false_token(s: String, matches: BoolType()) -> Result<&1, &1, Error, Parsed>:
    match matches:
        case True{}:
            Done{Parsed{Bool{False{}}, String.drop(s, 5n)}}
        case False{}:
            Fail{Error{}}

def from_string_scan(scanned: Result<&1, &1, Error, StringScan>) -> Result<&1, &1, Error, Parsed>:
    match scanned:
        case Fail{e}:
            Fail{e}
        case Done{scan}:
            match scan:
                case StringScan{value, rest}:
                    Done{Parsed{Str{value}, rest}}

def number_proof(+lexeme: String,
                 evidence: {number_valid(lexeme) == True{} : BoolType()}) -> NumberProof(lexeme):
    %Equal.sym(BoolType(), number_valid(lexeme), True{}, evidence) : NumberProofFrom(_)
    Unit{}

def number_lexeme(+lexeme: String,
                  rest: String,
                  valid: BoolType(),
                  evidence: {number_valid(lexeme) == valid : BoolType()}) -> Result<&1, &1, Error, Parsed>:
    match valid:
        case True{}:
            Done{Parsed{Number{lexeme, Certified{number_proof(lexeme, evidence)}}, rest}}
        case False{}:
            Fail{Error{}}

def from_number_scan(scan: StringScan) -> Result<&1, &1, Error, Parsed>:
    match scan:
        case StringScan{+lexeme, rest}:
            number_lexeme(lexeme, rest, number_valid(lexeme), {==})

def parse_number(s: String) -> Result<&1, &1, Error, Parsed>:
    from_number_scan(scan_number(s, SNil{}))

def number_from_digit(s: String, digit: BoolType()) -> Result<&1, &1, Error, Parsed>:
    match digit:
        case True{}:
            parse_number(s)
        case False{}:
            Fail{Error{}}

# The parser is an explicit machine. Its fuel decreases on every state
# transition, including transitions between container contexts.
type ParserKont is Data:
    Top{}
    InArray{acc: List<&2, Value>, parent: ParserKont}
    InObject{key: String, acc: List<&2, Sigma<&2, &2, String, key => Value>>, parent: ParserKont}

type ParserState is Type:
    ParseValue{clean: String, kont: ParserKont}
    ParsedResult{result: Result<&1, &1, Error, Parsed>, kont: ParserKont}
    StringResult{result: Result<&1, &1, Error, StringScan>, kont: ParserKont}
    ArrayStart{clean: String, acc: List<&2, Value>, empty_allowed: BoolType(), kont: ParserKont}
    ArrayAfter{value: Value, clean: String, acc: List<&2, Value>, kont: ParserKont}
    ObjectStart{clean: String, acc: List<&2, Sigma<&2, &2, String, key => Value>>, empty_allowed: BoolType(), kont: ParserKont}
    ObjectKey{result: Result<&1, &1, Error, StringScan>, acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont}
    ObjectColon{key: String, clean: String, acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont}
    ObjectAfter{key: String, value: Value, clean: String, acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont}
    Complete{parsed: Parsed}

def resume_value(value: Value, rest: String, kont: ParserKont) -> ParserState:
    match kont:
        case Top{}:
            Complete{Parsed{value, rest}}
        case InArray{acc, parent}:
            ArrayAfter{value, whitespace(rest), acc, parent}
        case InObject{key, acc, parent}:
            ObjectAfter{key, value, whitespace(rest), acc, parent}

def parse_machine(fuel: Nat, state: ParserState) -> Result<&1, &1, Error, Parsed>:
    match fuel:
        case 0n:
            Fail{Error{}}
        case 1n+p:
            match state:
                case Complete{parsed}:
                    Done{parsed}
                case ParseValue{+clean, +kont}:
                    match clean:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{+h, +t}:
                            match h:
                                case 'n':
                                    parse_machine(p, ParsedResult{null_token(clean, String.starts_with(clean, "null")), kont})
                                case 't':
                                    parse_machine(p, ParsedResult{true_token(clean, String.starts_with(clean, "true")), kont})
                                case 'f':
                                    parse_machine(p, ParsedResult{false_token(clean, String.starts_with(clean, "false")), kont})
                                case '"':
                                    +budget = p
                                    parse_machine(budget, StringResult{scan_string_machine(budget, ScanText{t, SNil{}}), kont})
                                case '[':
                                    parse_machine(p, ArrayStart{whitespace(t), Nil{}, True{}, kont})
                                case '{':
                                    parse_machine(p, ObjectStart{whitespace(t), Nil{}, True{}, kont})
                                case '-':
                                    parse_machine(p, ParsedResult{parse_number(clean), kont})
                                case _:
                                    parse_machine(p, ParsedResult{number_from_digit(clean, Char.is_digit(h)), kont})
                case ParsedResult{result, kont}:
                    match result:
                        case Fail{e}:
                            Fail{e}
                        case Done{parsed}:
                            match parsed:
                                case Parsed{value, rest}:
                                    parse_machine(p, resume_value(value, rest, kont))
                case StringResult{result, kont}:
                    match result:
                        case Fail{e}:
                            Fail{e}
                        case Done{scan}:
                            match scan:
                                case StringScan{value, rest}:
                                    parse_machine(p, resume_value(Str{value}, rest, kont))
                case ArrayStart{clean, acc, empty_allowed, kont}:
                    match clean:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{h, t}:
                            match h:
                                case ']':
                                    match empty_allowed:
                                        case True{}:
                                            parse_machine(p, resume_value(Arr{List.reverse(&2, Value, acc)}, t, kont))
                                        case False{}:
                                            Fail{Error{}}
                                case _:
                                    parse_machine(p, ParseValue{clean, InArray{acc, kont}})
                case ArrayAfter{value, clean, acc, kont}:
                    match clean:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{h, t}:
                            match h:
                                case ']':
                                    parse_machine(p, resume_value(Arr{List.reverse(&2, Value, value <> acc)}, t, kont))
                                case ',':
                                    parse_machine(p, ArrayStart{whitespace(t), value <> acc, False{}, kont})
                                case _:
                                    Fail{Error{}}
                case ObjectStart{clean, acc, empty_allowed, kont}:
                    match clean:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{h, t}:
                            match h:
                                case '}':
                                    match empty_allowed:
                                        case True{}:
                                            parse_machine(p, resume_value(Obj{List.reverse(&2, Sigma<&2, &2, String, key => Value>, acc)}, t, kont))
                                        case False{}:
                                            Fail{Error{}}
                                case '"':
                                    +budget = p
                                    parse_machine(budget, ObjectKey{scan_string_machine(budget, ScanText{t, SNil{}}), acc, kont})
                                case _:
                                    Fail{Error{}}
                case ObjectKey{result, acc, kont}:
                    match result:
                        case Fail{e}:
                            Fail{e}
                        case Done{scan}:
                            match scan:
                                case StringScan{key, rest}:
                                    parse_machine(p, ObjectColon{key, whitespace(rest), acc, kont})
                case ObjectColon{key, clean, acc, kont}:
                    match clean:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{h, t}:
                            match h:
                                case ':':
                                    parse_machine(p, ParseValue{whitespace(t), InObject{key, acc, kont}})
                                case _:
                                    Fail{Error{}}
                case ObjectAfter{key, value, clean, acc, kont}:
                    match clean:
                        case SNil{}:
                            Fail{Error{}}
                        case SCon{h, t}:
                            match h:
                                case '}':
                                    parse_machine(p, resume_value(Obj{List.reverse(&2, Sigma<&2, &2, String, key => Value>, (key, value) <> acc)}, t, kont))
                                case ',':
                                    parse_machine(p, ObjectStart{whitespace(t), (key, value) <> acc, False{}, kont})
                                case _:
                                    Fail{Error{}}

def parse_value(+s: String) -> Result<&1, &1, Error, Parsed>:
    parse_machine((String.length(s) * 8n + 16n : Nat), ParseValue{whitespace(s), Top{}})

def finish_rest_clean(value: Value, clean: String) -> Result<&1, &1, Error, Value>:
    match clean:
        case SNil{}:
            Done{value}
        case _:
            Fail{Error{}}

def finish_rest(value: Value, rest: String) -> Result<&1, &1, Error, Value>:
    finish_rest_clean(value, whitespace(rest))

def finish(r: Result<&1, &1, Error, Parsed>) -> Result<&1, &1, Error, Value>:
    match r:
        case Fail{e}:
            Fail{e}
        case Done{parsed}:
            match parsed:
                case Parsed{value, rest}:
                    finish_rest(value, rest)

# Common JSON escapes have a structural decoder. Less common Unicode
# escape spellings use the complete UTF-16 decoder below through the fallback.
type FastString is Data:
    Decoded{text: String}
    InvalidString{}
    UnicodeFallback{}

def fast_push(result: FastString, character: Char) -> FastString:
    match result:
        case Decoded{text}: Decoded{SCon{character, text}}
        case InvalidString{}: InvalidString{}
        case UnicodeFallback{}: UnicodeFallback{}

def fast_raw(control: BoolType(), result: FastString, character: Char) -> FastString:
    match control:
        case True{}: InvalidString{}
        case False{}: fast_push(result, character)

def fast_string(text: String) -> FastString:
    match text:
        case SCon{'"', SNil{}}: Decoded{SNil{}}
        case SCon{'\\', SCon{'"', tail}}: fast_push(fast_string(tail), '\u{22}')
        case SCon{'\\', SCon{'\\', tail}}: fast_push(fast_string(tail), '\u{5c}')
        case SCon{'\\', SCon{'/', tail}}: fast_push(fast_string(tail), '/')
        case SCon{'\\', SCon{'b', tail}}: fast_push(fast_string(tail), '\u{8}')
        case SCon{'\\', SCon{'f', tail}}: fast_push(fast_string(tail), '\u{c}')
        case SCon{'\\', SCon{'n', tail}}: fast_push(fast_string(tail), '\n')
        case SCon{'\\', SCon{'r', tail}}: fast_push(fast_string(tail), '\r')
        case SCon{'\\', SCon{'t', tail}}: fast_push(fast_string(tail), '\t')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'0', tail}}}}}}: fast_push(fast_string(tail), '\u{0}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'1', tail}}}}}}: fast_push(fast_string(tail), '\u{1}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'2', tail}}}}}}: fast_push(fast_string(tail), '\u{2}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'3', tail}}}}}}: fast_push(fast_string(tail), '\u{3}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'4', tail}}}}}}: fast_push(fast_string(tail), '\u{4}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'5', tail}}}}}}: fast_push(fast_string(tail), '\u{5}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'6', tail}}}}}}: fast_push(fast_string(tail), '\u{6}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'7', tail}}}}}}: fast_push(fast_string(tail), '\u{7}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'8', tail}}}}}}: fast_push(fast_string(tail), '\u{8}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'9', tail}}}}}}: fast_push(fast_string(tail), '\u{9}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'a', tail}}}}}}: fast_push(fast_string(tail), '\u{a}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'b', tail}}}}}}: fast_push(fast_string(tail), '\u{b}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'c', tail}}}}}}: fast_push(fast_string(tail), '\u{c}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'d', tail}}}}}}: fast_push(fast_string(tail), '\u{d}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'e', tail}}}}}}: fast_push(fast_string(tail), '\u{e}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'0', SCon{'f', tail}}}}}}: fast_push(fast_string(tail), '\u{f}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'0', tail}}}}}}: fast_push(fast_string(tail), '\u{10}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'1', tail}}}}}}: fast_push(fast_string(tail), '\u{11}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'2', tail}}}}}}: fast_push(fast_string(tail), '\u{12}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'3', tail}}}}}}: fast_push(fast_string(tail), '\u{13}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'4', tail}}}}}}: fast_push(fast_string(tail), '\u{14}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'5', tail}}}}}}: fast_push(fast_string(tail), '\u{15}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'6', tail}}}}}}: fast_push(fast_string(tail), '\u{16}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'7', tail}}}}}}: fast_push(fast_string(tail), '\u{17}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'8', tail}}}}}}: fast_push(fast_string(tail), '\u{18}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'9', tail}}}}}}: fast_push(fast_string(tail), '\u{19}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'a', tail}}}}}}: fast_push(fast_string(tail), '\u{1a}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'b', tail}}}}}}: fast_push(fast_string(tail), '\u{1b}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'c', tail}}}}}}: fast_push(fast_string(tail), '\u{1c}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'d', tail}}}}}}: fast_push(fast_string(tail), '\u{1d}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'e', tail}}}}}}: fast_push(fast_string(tail), '\u{1e}')
        case SCon{'\\', SCon{'u', SCon{'0', SCon{'0', SCon{'1', SCon{'f', tail}}}}}}: fast_push(fast_string(tail), '\u{1f}')
        case SCon{'\\', SCon{'u', _}}: UnicodeFallback{}
        case SCon{'\\', _}: InvalidString{}
        case SCon{'"', _}: InvalidString{}
        case SNil{}: InvalidString{}
        case SCon{+c, tail}: fast_raw(is_control(c), fast_string(tail), c)

def fast_result(result: FastString, original: String) -> Result<&1, &1, Error, Value>:
    match result:
        case Decoded{text}: Done{Str{text}}
        case InvalidString{}: Fail{Error{}}
        case UnicodeFallback{}: finish(parse_value(original))

def payload_other(text: String) -> Result<&1, &1, Error, Value>:
    match text:
        case "null": Done{Null{}}
        case "true": Done{Bool{True{}}}
        case "false": Done{Bool{False{}}}
        case SCon{'"', +tail}: fast_result(fast_string(tail), SCon{'"', tail})
        case _: Fail{Error{}}

def payload_number(+text: String,
                   valid: BoolType(),
                   evidence: {number_valid(text) == valid : BoolType()}) -> Result<&1, &1, Error, Value>:
    match valid:
        case True{}: Done{Number{text, Certified{number_proof(text, evidence)}}}
        case False{}: payload_other(text)

def decode_payload(+text: String) -> Result<&1, &1, Error, Value>:
    payload_number(text, number_valid(text), {==})

# Lexical boundaries are found once. Token payloads are then parsed on a
# balanced fork tree, so strings and numbers in one document can use different
# GPU lanes. Delimiter assembly follows token order.
type Lexeme is Data:
    Punctuation{character: Char}
    Payload{text: String}

def flush_lexeme(reversed: String, acc: List<&2, Lexeme>) -> List<&2, Lexeme>:
    match reversed:
        case SNil{}: acc
        case SCon{h, t}: Payload{String.reverse(SCon{h, t})} <> acc

type LexMode is Data:
    Outside{}
    Quoted{}
    Escaped{}

type LexAction is Data:
    LexStop{}
    LexEscapedChar{}
    LexBackslash{}
    LexStringEnd{}
    LexStringChar{}
    LexQuote{}
    LexWhitespace{}
    LexPunctuation{character: Char}
    LexRaw{}

def lex_outside_other(character: Char) -> LexAction:
    match character:
        case '"': LexQuote{}
        case ' ': LexWhitespace{}
        case '\t': LexWhitespace{}
        case '\r': LexWhitespace{}
        case '\n': LexWhitespace{}
        case '[': LexPunctuation{'['}
        case ']': LexPunctuation{']'}
        case '{': LexPunctuation{'{'}
        case '}': LexPunctuation{'}'}
        case ':': LexPunctuation{':' }
        case ',': LexPunctuation{','}
        case _: LexRaw{}

def lex_outside_action(character: Char, number_kind: NumberChar) -> LexAction:
    match number_kind:
        case NOther{}: lex_outside_other(character)
        case _: LexRaw{}

def lex_action(mode: LexMode, character: Char, number_kind: NumberChar) -> LexAction:
    match mode:
        case Escaped{}: LexEscapedChar{}
        case Quoted{}: quote_lex_action(quote_action(character))
        case Outside{}: lex_outside_action(character, number_kind)

def lex_seed_action(text: String, mode: LexMode) -> LexAction:
    match text:
        case SNil{}: LexStop{}
        case SCon{+character, _}: lex_action(mode, character, number_char(character))

def lex_end(+mode: LexMode, reversed: String, acc: List<&2, Lexeme>) -> List<&2, Lexeme>:
    match mode:
        case Outside{}: List.reverse(&2, Lexeme, flush_lexeme(reversed, acc))
        case Quoted{}: List.reverse(&2, Lexeme, Payload{"\""} <> acc)
        case Escaped{}: List.reverse(&2, Lexeme, Payload{"\""} <> acc)

def lexemes(text: String,
            +mode: LexMode,
            reversed: String,
            acc: List<&2, Lexeme>,
            action: LexAction) -> List<&2, Lexeme>:
    match text action:
        case SNil{} LexStop{}:
            lex_end(mode, reversed, acc)
        case SNil{} _:
            List.reverse(&2, Lexeme, flush_lexeme(reversed, acc))
        case SCon{h, +t} LexStop{}:
            lexemes(t, mode, SCon{h, reversed}, acc, lex_seed_action(t, mode))
        case SCon{h, +t} LexEscapedChar{}:
            lexemes(t, Quoted{}, SCon{h, reversed}, acc, lex_seed_action(t, Quoted{}))
        case SCon{_, +t} LexBackslash{}:
            lexemes(t, Escaped{}, SCon{'\\', reversed}, acc, lex_seed_action(t, Escaped{}))
        case SCon{_, +t} LexStringEnd{}:
            lexemes(t, Outside{}, SNil{}, Payload{String.reverse(SCon{'"', reversed})} <> acc, lex_seed_action(t, Outside{}))
        case SCon{h, +t} LexStringChar{}:
            lexemes(t, Quoted{}, SCon{h, reversed}, acc, lex_seed_action(t, Quoted{}))
        case SCon{_, +t} LexQuote{}:
            lexemes(t, Quoted{}, SCon{'"', SNil{}}, flush_lexeme(reversed, acc), lex_seed_action(t, Quoted{}))
        case SCon{_, +t} LexWhitespace{}:
            lexemes(t, Outside{}, SNil{}, flush_lexeme(reversed, acc), lex_seed_action(t, Outside{}))
        case SCon{_, +t} LexPunctuation{character}:
            lexemes(t, Outside{}, SNil{}, Punctuation{character} <> flush_lexeme(reversed, acc), lex_seed_action(t, Outside{}))
        case SCon{h, +t} LexRaw{}:
            lexemes(t, Outside{}, SCon{h, reversed}, acc, lex_seed_action(t, Outside{}))

def lex_scan(+text: String,
             +mode: LexMode,
             reversed: String,
             acc: List<&2, Lexeme>) -> List<&2, Lexeme>:
    lexemes(text, mode, reversed, acc, lex_seed_action(text, mode))

# The reverse token stream that corresponds to render(value, mode, suffix).
# It is used for the structural parser/renderer proof.
def source_text(text: String, acc: List<&2, Lexeme>) -> List<&2, Lexeme>:
    Payload{text} <> acc

def source(value: Value, members: BoolType(), acc: List<&2, Lexeme>) -> List<&2, Lexeme>:
    match value:
        case Null{}: source_text("null", acc)
        case Bool{truth}:
            match truth:
                case True{}: source_text("true", acc)
                case False{}: source_text("false", acc)
        case Number{lexeme, certificate}: source_text(lexeme, acc)
        case Str{text}: source_text("\"" ++ escape_string(text) ++ "\"", acc)
        case Arr{Nil{}}:
            match members:
                case False{}: Punctuation{'['} <> Punctuation{']'} <> acc
                case True{}: Punctuation{']'} <> acc
        case Arr{head <> tail}:
            match members:
                case False{}: Punctuation{'['} <> source(head, False{}, source(Arr{tail}, True{}, acc))
                case True{}: Punctuation{','} <> source(head, False{}, source(Arr{tail}, True{}, acc))
        case Obj{Nil{}}:
            match members:
                case False{}: Punctuation{'{'} <> Punctuation{'}'} <> acc
                case True{}: Punctuation{'}'} <> acc
        case Obj{(key, value) <> tail}:
            match members:
                case False{}: Punctuation{'{'} <> source_text("\"" ++ escape_string(key) ++ "\"", Punctuation{':'} <> source(value, False{}, source(Obj{tail}, True{}, acc)))
                case True{}: Punctuation{','} <> source_text("\"" ++ escape_string(key) ++ "\"", Punctuation{':'} <> source(value, False{}, source(Obj{tail}, True{}, acc)))

type LexTree is Data:
    LexEmpty{}
    LexLeaf{lexeme: Lexeme}
    LexBranch{left: LexTree, right: LexTree}

type Token is Type:
    Delimiter{character: Char}
    Atom{result: Result<&1, &1, Error, Value>}

type TokenTree is Type:
    TokensEmpty{}
    TokenLeaf{token: Token}
    TokenBranch{left: TokenTree, right: TokenTree}

def lex_leaves(items: List<&2, Lexeme>) -> List<&2, LexTree>:
    match items:
        case Nil{}: Nil{}
        case h <> t: LexLeaf{h} <> lex_leaves(t)

def lex_pairs(trees: List<&2, LexTree>) -> List<&2, LexTree>:
    match trees:
        case Nil{}: Nil{}
        case h <> Nil{}: h <> Nil{}
        case a <> b <> t: LexBranch{a, b} <> lex_pairs(t)

def lex_join(trees: List<&2, LexTree>) -> LexTree:
    match trees:
        case Nil{}: LexEmpty{}
        case head <> tail: LexBranch{head, lex_join(tail)}

def lex_balance(fuel: Nat, trees: List<&2, LexTree>) -> LexTree:
    match fuel:
        case 0n: lex_join(trees)
        case 1n+p:
            match trees:
                case Nil{}: LexEmpty{}
                case h <> Nil{}: h
                case a <> b <> t: lex_balance(p, lex_pairs(a <> b <> t))

def lex_tree(+items: List<&2, Lexeme>) -> LexTree:
    lex_balance(1n+List.length(&2, Lexeme, items), lex_leaves(items))

def decode_lexeme(lexeme: Lexeme) -> Token:
    match lexeme:
        case Punctuation{c}: Delimiter{c}
        case Payload{text}: Atom{decode_payload(text)}

def decode_tree(tree: LexTree) -> TokenTree:
    match tree:
        case LexEmpty{}: TokensEmpty{}
        case LexLeaf{lexeme}: TokenLeaf{decode_lexeme(lexeme)}
        case LexBranch{left, right}:
            l r = decode_tree(left) decode_tree(right)
            TokenBranch{l, r}

def token_list(tree: TokenTree, tail: List<Token>) -> List<Token>:
    match tree:
        case TokensEmpty{}: tail
        case TokenLeaf{token}: token <> tail
        case TokenBranch{left, right}: token_list(left, token_list(right, tail))

type Assembly is Type:
    NeedValue{kont: ParserKont}
    ArrayFirst{kont: ParserKont}
    ArrayNext{acc: List<&2, Value>, kont: ParserKont}
    ArrayComma{acc: List<&2, Value>, kont: ParserKont}
    ObjectFirst{kont: ParserKont}
    ObjectNext{acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont}
    NeedColon{key: String, acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont}
    ObjectComma{acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont}
    Assembled{value: Value}
    AssemblyError{}

def assembly_resume(kont: ParserKont, value: Value) -> Assembly:
    match kont:
        case Top{}: Assembled{value}
        case InArray{acc, parent}: ArrayComma{value <> acc, parent}
        case InObject{key, acc, parent}: ObjectComma{(key, value) <> acc, parent}

def assembly_atom(result: Result<&1, &1, Error, Value>, kont: ParserKont) -> Assembly:
    match result:
        case Fail{_}: AssemblyError{}
        case Done{value}: assembly_resume(kont, value)

def assembly_value(token: Token, kont: ParserKont) -> Assembly:
    match token:
        case Atom{result}: assembly_atom(result, kont)
        case Delimiter{'['}: ArrayFirst{kont}
        case Delimiter{'{'}: ObjectFirst{kont}
        case _: AssemblyError{}

def assembly_key_value(result: Result<&1, &1, Error, Value>,
                       acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont) -> Assembly:
    match result:
        case Done{Str{key}}: NeedColon{key, acc, kont}
        case _: AssemblyError{}

def assembly_key(token: Token,
                 acc: List<&2, Sigma<&2, &2, String, key => Value>>, kont: ParserKont) -> Assembly:
    match token:
        case Atom{result}: assembly_key_value(result, acc, kont)
        case _: AssemblyError{}

def assembly_step(state: Assembly, token: Token) -> Assembly:
    match state:
        case NeedValue{kont}: assembly_value(token, kont)
        case ArrayFirst{kont}:
            match token:
                case Delimiter{']'}: assembly_resume(kont, Arr{Nil{}})
                case _: assembly_value(token, InArray{Nil{}, kont})
        case ArrayNext{acc, kont}: assembly_value(token, InArray{acc, kont})
        case ArrayComma{acc, kont}:
            match token:
                case Delimiter{','}: ArrayNext{acc, kont}
                case Delimiter{']'}: assembly_resume(kont, Arr{List.reverse(&2, Value, acc)})
                case _: AssemblyError{}
        case ObjectFirst{kont}:
            match token:
                case Delimiter{'}'}: assembly_resume(kont, Obj{Nil{}})
                case _: assembly_key(token, Nil{}, kont)
        case ObjectNext{acc, kont}: assembly_key(token, acc, kont)
        case NeedColon{key, acc, kont}:
            match token:
                case Delimiter{':'}: NeedValue{InObject{key, acc, kont}}
                case _: AssemblyError{}
        case ObjectComma{acc, kont}:
            match token:
                case Delimiter{','}: ObjectNext{acc, kont}
                case Delimiter{'}'}: assembly_resume(kont, Obj{List.reverse(&2, Sigma<&2, &2, String, key => Value>, acc)})
                case _: AssemblyError{}
        case _: AssemblyError{}

def assembly_finish(state: Assembly) -> Result<&1, &1, Error, Value>:
    match state:
        case Assembled{value}: Done{value}
        case _: Fail{Error{}}

def assemble(tokens: List<Token>, state: Assembly) -> Result<&1, &1, Error, Value>:
    match tokens:
        case Nil{}: assembly_finish(state)
        case token <> tail: assemble(tail, assembly_step(state, token))

def parse_normalized(text: String) -> Result<&1, &1, Error, Value>:
    assemble(token_list(decode_tree(lex_tree(lex_scan(text, Outside{}, SNil{}, Nil{}))), Nil{}), NeedValue{Top{}})

# Call as parse!(text) to place the complete parse on Bend's GPU scheduler
# when one is available. The ordinary call remains useful on small inputs.
def parse(+text: String) -> Result<&1, &1, Error, Value>:
    parse_normalized(text)

# Smart constructor. Validation evidence is checked by Bend and is not an
# unchecked assertion supplied by callers.
def number(+text: String) -> Result<&1, &1, Error, Value>:
    finish(number_lexeme(text, SNil{}, number_valid(text), {==}))

# Independent documents form a fork/join tree. Keep sibling subtrees similar
# in total input size to distribute work across GPU lanes (or CPU workers).
type Batch is Data:
    Document{text: String}
    Documents{left: Batch, right: Batch}

type BatchResult is Type:
    DocumentResult{result: Result<&1, &1, Error, Value>}
    DocumentResults{left: BatchResult, right: BatchResult}

def parse_batch(batch: Batch) -> BatchResult:
    match batch:
        case Document{text}:
            DocumentResult{parse(text)}
        case Documents{left, right}:
            l r = parse_batch(left) parse_batch(right)
            DocumentResults{l, r}

# The ! entry points request GPU execution; Bend provides the CPU fallback.
# A single document has sequential grammar dependencies. For parallel work,
# use parse_batch_gpu with independent documents.
def parse_gpu(text: String) -> Result<&1, &1, Error, Value>:
    parse!(text)

def parse_batch_gpu(batch: Batch) -> BatchResult:
    parse_batch!(batch)

# Build a balanced fork tree from documents in source order. Pairing adjacent
# trees on each pass keeps the depth logarithmic without copying input text.
# For best lane balance, supply documents of similar lengths/complexity.
def batch_leaves(texts: List<&2, String>) -> List<&2, Batch>:
    match texts:
        case Nil{}:
            Nil{}
        case text <> tail:
            Document{text} <> batch_leaves(tail)

def batch_pairs(trees: List<&2, Batch>) -> List<&2, Batch>:
    match trees:
        case Nil{}:
            Nil{}
        case tree <> Nil{}:
            tree <> Nil{}
        case left <> right <> tail:
            Documents{left, right} <> batch_pairs(tail)

def batch_build(fuel: Nat, trees: List<&2, Batch>) -> Maybe<&2, Batch>:
    match fuel:
        case 0n:
            List.head(&2, Batch, trees)
        case 1n+p:
            match trees:
                case Nil{}:
                    None{}
                case tree <> Nil{}:
                    Some{tree}
                case left <> right <> tail:
                    batch_build(p, batch_pairs(left <> right <> tail))

def batch_from_list(+texts: List<&2, String>) -> Maybe<&2, Batch>:
    batch_build(List.length(&2, String, texts), batch_leaves(texts))

def parse_optional_batch_gpu(batch: Maybe<&2, Batch>) -> Maybe<&1, BatchResult>:
    match batch:
        case None{}:
            None{}
        case Some{tree}:
            Some{parse_batch!(tree)}

# Build the fork tree before entering the device. None represents an empty
# input list; each document's parse failure remains at its own result leaf.
def parse_many_gpu(texts: List<&2, String>) -> Maybe<&1, BatchResult>:
    parse_optional_batch_gpu(batch_from_list(texts))
