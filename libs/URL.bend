import Base

# Encode one byte as a percent escape. The SQL library used this representation;
# keeping it preserves existing query and form-body behavior.
def hex_digit_kind(n: U32, decimal: Bool) -> U32:
    match decimal:
        case True{}: (48 + n : U32)
        case False{}: (55 + n : U32)

def hex_digit(+n: U32) -> U32:
    hex_digit_kind(n, U32.is_lt(n, 10))

def percent_byte(+byte: U32) -> String:
    SCon{Chr{37}, SCon{Chr{hex_digit(U32.div(byte, 16))}, SCon{Chr{hex_digit(U32.mod(byte, 16))}, SNil{}}}}

def percent_codepoint_width(+codepoint: U32, width: U32) -> String:
    match width:
        case 1: percent_byte(codepoint)
        case 2: percent_byte((192 + U32.shrn(codepoint, 6n) : U32)) ++
                percent_byte((128 + U32.and(codepoint, 63) : U32))
        case 3: percent_byte((224 + U32.shrn(codepoint, 12n) : U32)) ++
                percent_byte((128 + U32.and(U32.shrn(codepoint, 6n), 63) : U32)) ++
                percent_byte((128 + U32.and(codepoint, 63) : U32))
        case _: percent_byte((240 + U32.shrn(codepoint, 18n) : U32)) ++
                percent_byte((128 + U32.and(U32.shrn(codepoint, 12n), 63) : U32)) ++
                percent_byte((128 + U32.and(U32.shrn(codepoint, 6n), 63) : U32)) ++
                percent_byte((128 + U32.and(codepoint, 63) : U32))

def percent_codepoint(+codepoint: U32) -> String:
    +width = Bool.pick(U32, U32.is_lt(codepoint, 128), 1,
        Bool.pick(U32, U32.is_lt(codepoint, 2048), 2,
            Bool.pick(U32, U32.is_lt(codepoint, 65536), 3, 4)))
    percent_codepoint_width(codepoint, width)

def percent_characters(text: String) -> String:
    match text:
        case SNil{}: ""
        case SCon{Chr{+codepoint}, tail}:
            percent_codepoint(codepoint) ++ percent_characters(tail)

# Percent-encode a URL component as UTF-8 bytes. This deliberately encodes
# every byte, matching the former SQL.percent_component behavior.
def percent_component(text: String) -> String:
    percent_characters(text)
