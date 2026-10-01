import Base

# JSON whitespace is exactly these four characters.
def leading(text: String) -> String:
    match text:
        case SNil{}: SNil{}
        case SCon{' ', tail}: leading(tail)
        case SCon{'\t', tail}: leading(tail)
        case SCon{'\r', tail}: leading(tail)
        case SCon{'\n', tail}: leading(tail)
        case SCon{head, tail}: SCon{head, tail}

def prepend(tail: String, head: Char) -> String:
    match tail:
        case SNil{}:
            match head:
                case ' ': SNil{}
                case '\t': SNil{}
                case '\r': SNil{}
                case '\n': SNil{}
                case _: SCon{head, SNil{}}
        case SCon{x, xs}:
            SCon{head, SCon{x, xs}}

def trailing(text: String) -> String:
    match text:
        case SNil{}: SNil{}
        case SCon{head, tail}: prepend(trailing(tail), head)

def normalize(text: String) -> String:
    leading(trailing(text))

def trailing_suffix(+text: String,
                    +suffix: String,
                    empty: {trailing(suffix) == SNil{} : String}) -> {trailing(text ++ suffix) == trailing(text) : String}:
    match text:
        case SNil{}: empty
        case SCon{head, tail}:
            Equal.cong(String, String, x => prepend(x, head), trailing(tail ++ suffix), trailing(tail), trailing_suffix(tail, suffix, empty))

def leading_space(+tail: String) -> {leading(prepend(tail, ' ')) == leading(tail) : String}:
    match tail:
        case SNil{}: {==}
        case SCon{h, t}: {==}

def leading_surround(+tail: String) -> {leading(prepend(prepend(prepend(prepend(tail, '\r'), '\t'), '\n'), ' ')) == leading(tail) : String}:
    match tail:
        case SNil{}: {==}
        case SCon{h, t}: {==}

def normalize_space(+text: String) -> {normalize(" " ++ text) == normalize(text) : String}:
    leading_space(trailing(text))

def normalize_suffix(+text: String,
                     +suffix: String,
                     empty: {trailing(suffix) == SNil{} : String}) -> {normalize(text ++ suffix) == normalize(text) : String}:
    Equal.cong(String, String, leading, trailing(text ++ suffix), trailing(text), trailing_suffix(text, suffix, empty))

def normalize_surround(+text: String) -> {normalize(" \n\t\r" ++ text ++ "\r\t\n ") == normalize(text) : String}:
    Equal.trans(String, normalize(" \n\t\r" ++ text ++ "\r\t\n "), normalize(" \n\t\r" ++ text), normalize(text), normalize_suffix(" \n\t\r" ++ text, "\r\t\n ", {==}), leading_surround(trailing(text)))
