import Base
import ../libs/AES256GCM.bend as AES
import ./AES_CanonicalProof.bend as Canonical

def aes_hex_mask_15_lt_16(+value: U32) ->
    {U32.is_lt(AES.hex_mask(value, 15), 16) == True{} : Bool}:
    match value:
        case U32{WCon{b0, WCon{b1, WCon{b2, WCon{b3, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def aes_hex_mask_255_lt_256(+value: U32) ->
    {U32.is_lt(AES.hex_mask(value, 255), 256) == True{} : Bool}:
    match value:
        case U32{WCon{b0, WCon{b1, WCon{b2, WCon{b3, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def aes_bool_and_false(b: Bool) -> {Bool.and(b, False{}) == False{} : Bool}:
    match b:
        case False{}: {==}
        case True{}: {==}

def aes_bool_and_true(b: Bool) -> {Bool.and(b, True{}) == b : Bool}:
    match b:
        case False{}: {==}
        case True{}: {==}

def aes_hex_word_and_equiv(n: Nat, mask: Word(n), value: Word(n)) ->
    {AES.hex_word_and(n, mask, value) == Word.and(n, value, mask) : Word(n)}:
    match n mask value:
        case 0n WNil{} WNil{}: {==}
        case 1n+p WCon{False{}, mask_tail} WCon{value_bit, value_tail}:
            recursive = aes_hex_word_and_equiv(p, mask_tail, value_tail)
            Equal.trans(Word(1n+p),
              WCon{False{}, AES.hex_word_and(p, mask_tail, value_tail)},
              WCon{False{}, Word.and(p, value_tail, mask_tail)},
              WCon{Bool.and(value_bit, False{}), Word.and(p, value_tail, mask_tail)},
              Equal.cong(Word(p), Word(1n+p), tail => WCon{False{}, tail},
                AES.hex_word_and(p, mask_tail, value_tail), Word.and(p, value_tail, mask_tail), recursive),
              Equal.cong(Bool, Word(1n+p), bit => WCon{bit, Word.and(p, value_tail, mask_tail)},
                False{}, Bool.and(value_bit, False{}), Equal.sym(Bool,
                  Bool.and(value_bit, False{}), False{}, aes_bool_and_false(value_bit))))
        case 1n+p WCon{True{}, mask_tail} WCon{value_bit, value_tail}:
            recursive = aes_hex_word_and_equiv(p, mask_tail, value_tail)
            Equal.trans(Word(1n+p),
              WCon{value_bit, AES.hex_word_and(p, mask_tail, value_tail)},
              WCon{value_bit, Word.and(p, value_tail, mask_tail)},
              WCon{Bool.and(value_bit, True{}), Word.and(p, value_tail, mask_tail)},
              Equal.cong(Word(p), Word(1n+p), tail => WCon{value_bit, tail},
                AES.hex_word_and(p, mask_tail, value_tail), Word.and(p, value_tail, mask_tail), recursive),
              Equal.cong(Bool, Word(1n+p), bit => WCon{bit, Word.and(p, value_tail, mask_tail)},
                value_bit, Bool.and(value_bit, True{}), Equal.sym(Bool,
                  Bool.and(value_bit, True{}), value_bit, aes_bool_and_true(value_bit))))

def aes_hex_word_and_idempotent(n: Nat, mask: Word(n), +value: Word(n)) ->
    {AES.hex_word_and(n, mask, AES.hex_word_and(n, mask, value)) ==
     AES.hex_word_and(n, mask, value) : Word(n)}:
    match n mask value:
        case 0n WNil{} WNil{}: {==}
        case 1n+p WCon{False{}, mask_tail} WCon{value_bit, value_tail}:
            recursive = aes_hex_word_and_idempotent(p, mask_tail, value_tail)
            Equal.cong(Word(p), Word(1n+p), tail => WCon{False{}, tail},
                AES.hex_word_and(p, mask_tail,
                    AES.hex_word_and(p, mask_tail, value_tail)),
                AES.hex_word_and(p, mask_tail, value_tail), recursive)
        case 1n+p WCon{True{}, mask_tail} WCon{False{}, value_tail}:
            recursive = aes_hex_word_and_idempotent(p, mask_tail, value_tail)
            Equal.cong(Word(p), Word(1n+p), tail => WCon{False{}, tail},
                AES.hex_word_and(p, mask_tail,
                    AES.hex_word_and(p, mask_tail, value_tail)),
                AES.hex_word_and(p, mask_tail, value_tail), recursive)
        case 1n+p WCon{True{}, mask_tail} WCon{True{}, value_tail}:
            recursive = aes_hex_word_and_idempotent(p, mask_tail, value_tail)
            Equal.cong(Word(p), Word(1n+p), tail => WCon{True{}, tail},
                AES.hex_word_and(p, mask_tail,
                    AES.hex_word_and(p, mask_tail, value_tail)),
                AES.hex_word_and(p, mask_tail, value_tail), recursive)

def aes_hex_mask_idempotent(+value: U32, mask: U32) ->
    {AES.hex_mask(AES.hex_mask(value, mask), mask) ==
     AES.hex_mask(value, mask) : U32}:
    match value mask:
        case U32{value_word} U32{mask_word}:
            Equal.cong(Word(32n), U32,
                word => U32{word},
                AES.hex_word_and(32n, mask_word,
                    AES.hex_word_and(32n, mask_word, value_word)),
                AES.hex_word_and(32n, mask_word, value_word),
                aes_hex_word_and_idempotent(32n, mask_word, value_word))

def aes_hex_digit_inverse(+value: U32) ->
    {AES.hex_nibble(Char.to_u32(AES.hex_digit(value))) ==
      Some{AES.hex_mask(value, 15)} : Maybe<&2, U32>}:
    match value:
        case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def aes_hex_digit_no_dot(+value: U32) ->
    {Char.is_eq(AES.hex_digit(value), Chr{46}) == False{} : Bool}:
    match value:
        case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}
        case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def aes_split_hex_digit_no_dot(value: U32, +parts: List<&2, String>) ->
    {String.split.fin(AES.hex_digit(value), parts,
        Char.is_eq(AES.hex_digit(value), Chr{46})) ==
     String.split.push(AES.hex_digit(value), parts) : List<&2, String>}:
    Equal.cong(Bool, List<&2, String>,
        cut => String.split.fin(AES.hex_digit(value), parts, cut),
        Char.is_eq(AES.hex_digit(value), Chr{46}), False{},
        aes_hex_digit_no_dot(value))

def aes_hex_join_shift_mask(+value: U32) ->
    {AES.hex_join(U32.shrn(value, 4n), AES.hex_mask(value, 15)) ==
      AES.hex_mask(value, 255) : U32}:
    match value:
        case U32{WCon{b0, WCon{b1, WCon{b2, WCon{b3, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def aes_hex_join_masked_shift_mask(+value: U32) ->
    {AES.hex_join(AES.hex_mask(U32.shrn(value, 4n), 15), AES.hex_mask(value, 15)) ==
      AES.hex_mask(value, 255) : U32}:
    match value:
        case U32{WCon{b0, WCon{b1, WCon{b2, WCon{b3, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def aes_hex_byte_prefix_idempotent(+byte: U32, +tail: String) ->
    {SCon{AES.hex_digit(U32.shrn(AES.hex_mask(AES.hex_mask(byte, 255), 255), 4n)),
       SCon{AES.hex_digit(AES.hex_mask(AES.hex_mask(byte, 255), 255)), tail}} ==
     SCon{AES.hex_digit(U32.shrn(AES.hex_mask(byte, 255), 4n)),
       SCon{AES.hex_digit(AES.hex_mask(byte, 255)), tail}} : String}:
    +normalized = AES.hex_mask(byte, 255)
    +twice = AES.hex_mask(normalized, 255)
    +mask_equal = aes_hex_mask_idempotent(byte, 255)
    low_equal = Equal.cong(U32, Char, value => AES.hex_digit(value),
        twice, normalized,
        mask_equal)
    high_equal = Equal.cong(U32, Char,
        value => AES.hex_digit(U32.shrn(value, 4n)), twice, normalized,
        mask_equal)
    inner_equal = Equal.cong(Char, String,
        value => SCon{value, tail}, AES.hex_digit(twice),
        AES.hex_digit(normalized), low_equal)
    inner_path = Equal.cong(String, String,
        rest => SCon{AES.hex_digit(U32.shrn(twice, 4n)), rest},
        SCon{AES.hex_digit(twice), tail},
        SCon{AES.hex_digit(normalized), tail}, inner_equal)
    high_path = Equal.cong(Char, String,
        value => SCon{value, SCon{AES.hex_digit(normalized), tail}},
        AES.hex_digit(U32.shrn(twice, 4n)),
        AES.hex_digit(U32.shrn(normalized, 4n)), high_equal)
    Equal.trans(String,
        SCon{AES.hex_digit(U32.shrn(twice, 4n)),
            SCon{AES.hex_digit(twice), tail}},
        SCon{AES.hex_digit(U32.shrn(twice, 4n)),
            SCon{AES.hex_digit(normalized), tail}},
        SCon{AES.hex_digit(U32.shrn(normalized, 4n)),
            SCon{AES.hex_digit(normalized), tail}},
        inner_path, high_path)

def aes_hex_mask_bytes(+bytes: List<&2, U32>) -> List<&2, U32>:
    match bytes:
        case Nil{}: Nil{}
        case byte <> tail: AES.hex_mask(byte, 255) <> aes_hex_mask_bytes(tail)

def aes_hex_bytes_mask_idempotent(+bytes: List<&2, U32>) ->
    {AES.hex_bytes(aes_hex_mask_bytes(bytes)) == AES.hex_bytes(bytes) : String}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            +left_tail = AES.hex_bytes(aes_hex_mask_bytes(tail))
            +right_tail = AES.hex_bytes(tail)
            tail_equal = aes_hex_bytes_mask_idempotent(tail)
            prefix_equal = aes_hex_byte_prefix_idempotent(byte, left_tail)
            tail_congruent = Equal.cong(String, String,
                rest => SCon{AES.hex_digit(U32.shrn(AES.hex_mask(byte, 255), 4n)),
                    SCon{AES.hex_digit(AES.hex_mask(byte, 255)), rest}},
                left_tail, right_tail, tail_equal)
            Equal.trans(String,
                SCon{AES.hex_digit(U32.shrn(
                    AES.hex_mask(AES.hex_mask(byte, 255), 255), 4n)),
                    SCon{AES.hex_digit(AES.hex_mask(
                        AES.hex_mask(byte, 255), 255)), left_tail}},
                SCon{AES.hex_digit(U32.shrn(AES.hex_mask(byte, 255), 4n)),
                    SCon{AES.hex_digit(AES.hex_mask(byte, 255)), left_tail}},
                SCon{AES.hex_digit(U32.shrn(AES.hex_mask(byte, 255), 4n)),
                    SCon{AES.hex_digit(AES.hex_mask(byte, 255)), right_tail}},
                prefix_equal, tail_congruent)


def aes_hex_pair_roundtrip(+byte: U32) ->
    {AES.hex_pair(
        AES.hex_digit(U32.shrn(AES.hex_mask(byte, 255), 4n)),
        AES.hex_digit(AES.hex_mask(byte, 255))) ==
     Some{AES.hex_mask(byte, 255)} : Maybe<&2, U32>}:
    +normalized = AES.hex_mask(byte, 255)
    +high = U32.shrn(normalized, 4n)
    +low = normalized
    high_decoded = AES.hex_nibble(Char.to_u32(AES.hex_digit(high)))
    low_decoded = AES.hex_nibble(Char.to_u32(AES.hex_digit(low)))
    high_inverse = aes_hex_digit_inverse(high)
    low_inverse = aes_hex_digit_inverse(low)
    low_changed = Equal.cong(Maybe<&2, U32>, Maybe<&2, U32>,
        nibble => AES.hex_pair.combine(high_decoded, nibble),
        low_decoded, Some{AES.hex_mask(low, 15)}, low_inverse)
    high_changed = Equal.cong(Maybe<&2, U32>, Maybe<&2, U32>,
        nibble => AES.hex_pair.combine(nibble, Some{AES.hex_mask(low, 15)}),
        high_decoded, Some{AES.hex_mask(high, 15)}, high_inverse)
    pair_changed = Equal.trans(Maybe<&2, U32>,
        AES.hex_pair.combine(high_decoded, low_decoded),
        AES.hex_pair.combine(high_decoded, Some{AES.hex_mask(low, 15)}),
        AES.hex_pair.combine(Some{AES.hex_mask(high, 15)}, Some{AES.hex_mask(low, 15)}),
        low_changed, high_changed)
    join_equal = aes_hex_join_masked_shift_mask(normalized)
    normalized_equal = aes_hex_mask_idempotent(byte, 255)
    joined_to_byte = Equal.trans(U32,
        AES.hex_join(AES.hex_mask(high, 15), AES.hex_mask(low, 15)),
        AES.hex_mask(normalized, 255), normalized,
        join_equal, normalized_equal)
    joined_some = Equal.cong(U32, Maybe<&2, U32>, value => Some{value},
        AES.hex_join(AES.hex_mask(high, 15), AES.hex_mask(low, 15)),
        normalized, joined_to_byte)
    Equal.trans(Maybe<&2, U32>, AES.hex_pair(
        AES.hex_digit(U32.shrn(normalized, 4n)), AES.hex_digit(normalized)),
        AES.hex_pair.combine(high_decoded, low_decoded), Some{normalized},
        {==},
        Equal.trans(Maybe<&2, U32>,
            AES.hex_pair.combine(high_decoded, low_decoded),
            AES.hex_pair.combine(Some{AES.hex_mask(high, 15)},
                Some{AES.hex_mask(low, 15)}),
            Some{normalized}, pair_changed,
            Equal.trans(Maybe<&2, U32>,
                AES.hex_pair.combine(Some{AES.hex_mask(high, 15)},
                    Some{AES.hex_mask(low, 15)}),
                Some{AES.hex_join(AES.hex_mask(high, 15), AES.hex_mask(low, 15))},
                Some{normalized}, {==}, joined_some)))

def aes_decode_hex_bytes(+bytes: List<&2, U32>) ->
    {AES.decode_hex(AES.hex_bytes(bytes)) == Some{aes_hex_mask_bytes(bytes)} : Maybe<&2, List<&2, U32>>}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            +normalized = AES.hex_mask(byte, 255)
            +rest_pairs = AES.hex_pairs(String.to_list(AES.hex_bytes(tail)))
            +rest_decoded = AES.collect_hex(rest_pairs)
            tail_proof = aes_decode_hex_bytes(tail)
            pair_proof = aes_hex_pair_roundtrip(byte)
            pair_changed = Equal.cong(Maybe<&2, U32>,
                Maybe<&2, List<&2, U32>>,
                pair => AES.collect_hex.cons(pair, rest_decoded),
                AES.hex_pair(
                    AES.hex_digit(U32.shrn(normalized, 4n)),
                    AES.hex_digit(normalized)),
                Some{normalized}, pair_proof)
            tail_changed = Equal.cong(Maybe<&2, List<&2, U32>>,
                Maybe<&2, List<&2, U32>>,
                result => AES.collect_hex.cons(Some{normalized}, result),
                rest_decoded, Some{aes_hex_mask_bytes(tail)}, tail_proof)
            Equal.trans(Maybe<&2, List<&2, U32>>,
                AES.collect_hex.cons(
                    AES.hex_pair(
                        AES.hex_digit(U32.shrn(normalized, 4n)),
                        AES.hex_digit(normalized)), rest_decoded),
                AES.collect_hex.cons(Some{normalized}, rest_decoded),
                Some{normalized <> aes_hex_mask_bytes(tail)},
                pair_changed,
                Equal.trans(Maybe<&2, List<&2, U32>>,
                    AES.collect_hex.cons(Some{normalized}, rest_decoded),
                    Some{normalized <> aes_hex_mask_bytes(tail)},
                    Some{normalized <> aes_hex_mask_bytes(tail)},
                    tail_changed, {==}))
def aes_split_push_single(value: U32, +suffix: String) ->
    {String.split.push(AES.hex_digit(value), [suffix]) ==
     [SCon{AES.hex_digit(value), suffix}] : List<&2, String>}:
    {==}

def aes_hex_bytes_split_single(+bytes: List<&2, U32>) ->
    {String.split(AES.hex_bytes(bytes), Chr{46}) == [AES.hex_bytes(bytes)] : List<&2, String>}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            +normalized = AES.hex_mask(byte, 255)
            +encoded_tail = AES.hex_bytes(tail)
            +high = U32.shrn(normalized, 4n)
            +low = normalized
            tail_proof = aes_hex_bytes_split_single(tail)
            low_shift = Equal.cong(List<&2, String>, List<&2, String>,
                parts => String.split.fin(AES.hex_digit(low), parts,
                    Char.is_eq(AES.hex_digit(low), Chr{46})),
                String.split(encoded_tail, Chr{46}), [encoded_tail], tail_proof)
            low_join = Equal.trans(List<&2, String>,
                String.split.fin(AES.hex_digit(low), String.split(encoded_tail, Chr{46}),
                    Char.is_eq(AES.hex_digit(low), Chr{46})),
                String.split.push(AES.hex_digit(low), [encoded_tail]),
                [SCon{AES.hex_digit(low), encoded_tail}],
                Equal.trans(List<&2, String>,
                    String.split.fin(AES.hex_digit(low), String.split(encoded_tail, Chr{46}),
                        Char.is_eq(AES.hex_digit(low), Chr{46})),
                    String.split.fin(AES.hex_digit(low), [encoded_tail],
                        Char.is_eq(AES.hex_digit(low), Chr{46})),
                    String.split.push(AES.hex_digit(low), [encoded_tail]),
                    low_shift, aes_split_hex_digit_no_dot(low, [encoded_tail])),
                aes_split_push_single(low, encoded_tail))
            inner_split = Equal.trans(List<&2, String>,
                String.split(SCon{AES.hex_digit(low), encoded_tail}, Chr{46}),
                String.split.fin(AES.hex_digit(low), String.split(encoded_tail, Chr{46}),
                    Char.is_eq(AES.hex_digit(low), Chr{46})),
                [SCon{AES.hex_digit(low), encoded_tail}],
                {==}, low_join)
            high_shift = Equal.cong(List<&2, String>, List<&2, String>,
                parts => String.split.fin(AES.hex_digit(high), parts,
                    Char.is_eq(AES.hex_digit(high), Chr{46})),
                String.split(SCon{AES.hex_digit(low), encoded_tail}, Chr{46}),
                [SCon{AES.hex_digit(low), encoded_tail}], inner_split)
            high_join = Equal.trans(List<&2, String>,
                String.split.fin(AES.hex_digit(high),
                    String.split(SCon{AES.hex_digit(low), encoded_tail}, Chr{46}),
                    Char.is_eq(AES.hex_digit(high), Chr{46})),
                String.split.push(AES.hex_digit(high),
                    [SCon{AES.hex_digit(low), encoded_tail}]),
                [SCon{AES.hex_digit(high), SCon{AES.hex_digit(low), encoded_tail}}],
                Equal.trans(List<&2, String>,
                    String.split.fin(AES.hex_digit(high),
                        String.split(SCon{AES.hex_digit(low), encoded_tail}, Chr{46}),
                        Char.is_eq(AES.hex_digit(high), Chr{46})),
                    String.split.fin(AES.hex_digit(high),
                        [SCon{AES.hex_digit(low), encoded_tail}],
                        Char.is_eq(AES.hex_digit(high), Chr{46})),
                    String.split.push(AES.hex_digit(high),
                        [SCon{AES.hex_digit(low), encoded_tail}]),
                    high_shift, aes_split_hex_digit_no_dot(high,
                        [SCon{AES.hex_digit(low), encoded_tail}])),
                aes_split_push_single(high,
                    SCon{AES.hex_digit(low), encoded_tail}))
            Equal.trans(List<&2, String>,
                String.split(AES.hex_bytes(byte <> tail), Chr{46}),
                String.split(SCon{AES.hex_digit(high),
                    SCon{AES.hex_digit(low), encoded_tail}}, Chr{46}),
                [AES.hex_bytes(byte <> tail)],
                {==},
                Equal.trans(List<&2, String>,
                    String.split(SCon{AES.hex_digit(high),
                        SCon{AES.hex_digit(low), encoded_tail}}, Chr{46}),
                    [SCon{AES.hex_digit(high),
                        SCon{AES.hex_digit(low), encoded_tail}}],
                    [AES.hex_bytes(byte <> tail)], high_join,
                    {==}))

def aes_split_push_cons(value: U32, +head: String, +tail: List<&2, String>) ->
    {String.split.push(AES.hex_digit(value), head <> tail) ==
     SCon{AES.hex_digit(value), head} <> tail : List<&2, String>}:
    {==}

def aes_hex_bytes_split_before_period(+bytes: List<&2, U32>, +suffix: String) ->
    {String.split(AES.hex_bytes(bytes) ++ "." ++ suffix, Chr{46}) ==
     AES.hex_bytes(bytes) <> String.split(suffix, Chr{46}) : List<&2, String>}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            +normalized = AES.hex_mask(byte, 255)
            +encoded_tail = AES.hex_bytes(tail)
            +suffix_fields = String.split(suffix, Chr{46})
            +tail_text = encoded_tail ++ "." ++ suffix
            +high = U32.shrn(normalized, 4n)
            +low = normalized
            tail_proof = aes_hex_bytes_split_before_period(tail, suffix)
            low_shift = Equal.cong(List<&2, String>, List<&2, String>,
                parts => String.split.fin(AES.hex_digit(low), parts,
                    Char.is_eq(AES.hex_digit(low), Chr{46})),
                String.split(tail_text, Chr{46}), encoded_tail <> suffix_fields,
                tail_proof)
            low_join = Equal.trans(List<&2, String>,
                String.split.fin(AES.hex_digit(low), String.split(tail_text, Chr{46}),
                    Char.is_eq(AES.hex_digit(low), Chr{46})),
                String.split.push(AES.hex_digit(low), encoded_tail <> suffix_fields),
                SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields,
                Equal.trans(List<&2, String>,
                    String.split.fin(AES.hex_digit(low), String.split(tail_text, Chr{46}),
                        Char.is_eq(AES.hex_digit(low), Chr{46})),
                    String.split.fin(AES.hex_digit(low), encoded_tail <> suffix_fields,
                        Char.is_eq(AES.hex_digit(low), Chr{46})),
                    String.split.push(AES.hex_digit(low), encoded_tail <> suffix_fields),
                    low_shift, aes_split_hex_digit_no_dot(low,
                        encoded_tail <> suffix_fields)),
                aes_split_push_cons(low, encoded_tail, suffix_fields))
            inner_split = Equal.trans(List<&2, String>,
                String.split(SCon{AES.hex_digit(low), tail_text}, Chr{46}),
                String.split.fin(AES.hex_digit(low), String.split(tail_text, Chr{46}),
                    Char.is_eq(AES.hex_digit(low), Chr{46})),
                SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields,
                {==}, low_join)
            high_shift = Equal.cong(List<&2, String>, List<&2, String>,
                parts => String.split.fin(AES.hex_digit(high), parts,
                    Char.is_eq(AES.hex_digit(high), Chr{46})),
                String.split(SCon{AES.hex_digit(low), tail_text}, Chr{46}),
                SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields,
                inner_split)
            high_join = Equal.trans(List<&2, String>,
                String.split.fin(AES.hex_digit(high),
                    String.split(SCon{AES.hex_digit(low), tail_text}, Chr{46}),
                    Char.is_eq(AES.hex_digit(high), Chr{46})),
                String.split.push(AES.hex_digit(high),
                    SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields),
                SCon{AES.hex_digit(high), SCon{AES.hex_digit(low), encoded_tail}} <> suffix_fields,
                Equal.trans(List<&2, String>,
                    String.split.fin(AES.hex_digit(high),
                        String.split(SCon{AES.hex_digit(low), tail_text}, Chr{46}),
                        Char.is_eq(AES.hex_digit(high), Chr{46})),
                    String.split.fin(AES.hex_digit(high),
                        SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields,
                        Char.is_eq(AES.hex_digit(high), Chr{46})),
                    String.split.push(AES.hex_digit(high),
                        SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields),
                    high_shift, aes_split_hex_digit_no_dot(high,
                        SCon{AES.hex_digit(low), encoded_tail} <> suffix_fields)),
                aes_split_push_cons(high,
                    SCon{AES.hex_digit(low), encoded_tail}, suffix_fields))
            Equal.trans(List<&2, String>,
                String.split(AES.hex_bytes(byte <> tail) ++ "." ++ suffix, Chr{46}),
                String.split(SCon{AES.hex_digit(high), SCon{AES.hex_digit(low), tail_text}}, Chr{46}),
                AES.hex_bytes(byte <> tail) <> suffix_fields,
                {==}, Equal.trans(List<&2, String>,
                    String.split(SCon{AES.hex_digit(high), SCon{AES.hex_digit(low), tail_text}}, Chr{46}),
                    SCon{AES.hex_digit(high), SCon{AES.hex_digit(low), encoded_tail}} <> suffix_fields,
                    AES.hex_bytes(byte <> tail) <> suffix_fields,
                    high_join, {==}))

def aes_split_leading_dot(+suffix: String) ->
    {String.split("." ++ suffix, Chr{46}) ==
     "" <> String.split(suffix, Chr{46}) : List<&2, String>}:
    {==}

def aes_split_v1_prefix(+suffix: String) ->
    {String.split("v1." ++ suffix, Chr{46}) ==
     "v1" <> String.split(suffix, Chr{46}) : List<&2, String>}:
    {==}

def aes_string_append_assoc(+a: String, +b: String, +c: String) ->
    {a ++ b ++ c == a ++ (b ++ c) : String}:
    match a:
        case SNil{}: {==}
        case SCon{head, tail}:
            Equal.cong(String, String, rest => SCon{head, rest},
                tail ++ b ++ c, tail ++ (b ++ c),
                aes_string_append_assoc(tail, b, c))

def aes_split_v1_hex_fields(+nonce: List<&2, U32>, +tag: List<&2, U32>,
    +ciphertext: List<&2, U32>) ->
    {String.split("v1." ++ AES.hex_bytes(nonce) ++ "." ++
        AES.hex_bytes(tag) ++ "." ++ AES.hex_bytes(ciphertext), Chr{46}) ==
     ["v1", AES.hex_bytes(nonce), AES.hex_bytes(tag), AES.hex_bytes(ciphertext)] : List<&2, String>}:
    +nonce_hex = AES.hex_bytes(nonce)
    +tag_hex = AES.hex_bytes(tag)
    +cipher_hex = AES.hex_bytes(ciphertext)
    +tag_suffix = tag_hex ++ "." ++ cipher_hex
    +nonce_suffix = nonce_hex ++ "." ++ tag_suffix
    cipher_split = aes_hex_bytes_split_single(ciphertext)
    tag_split = aes_hex_bytes_split_before_period(tag, cipher_hex)
    nonce_split = aes_hex_bytes_split_before_period(nonce, tag_suffix)
    tag_final = Equal.cong(List<&2, String>, List<&2, String>,
        fields => tag_hex <> fields,
        String.split(cipher_hex, Chr{46}), [cipher_hex], cipher_split)
    tag_complete = Equal.trans(List<&2, String>,
        String.split(tag_suffix, Chr{46}),
        tag_hex <> String.split(cipher_hex, Chr{46}),
        tag_hex <> [cipher_hex], tag_split, tag_final)
    nonce_final = Equal.cong(List<&2, String>, List<&2, String>,
        fields => nonce_hex <> fields,
        String.split(tag_suffix, Chr{46}), tag_hex <> [cipher_hex], tag_complete)
    rest_fields = Equal.cong(List<&2, String>, List<&2, String>,
        fields => "v1" <> fields,
        String.split(nonce_suffix, Chr{46}), nonce_hex <> (tag_hex <> [cipher_hex]),
        Equal.trans(List<&2, String>,
            String.split(nonce_suffix, Chr{46}),
            nonce_hex <> String.split(tag_suffix, Chr{46}),
            nonce_hex <> (tag_hex <> [cipher_hex]),
            nonce_split, nonce_final))
    Equal.trans(List<&2, String>,
        String.split("v1." ++ nonce_suffix, Chr{46}),
        "v1" <> String.split(nonce_suffix, Chr{46}),
        ["v1", nonce_hex, tag_hex, cipher_hex],
        aes_split_v1_prefix(nonce_suffix),
        Equal.trans(List<&2, String>,
            "v1" <> String.split(nonce_suffix, Chr{46}),
            "v1" <> (nonce_hex <> (tag_hex <> [cipher_hex])),
            ["v1", nonce_hex, tag_hex, cipher_hex],
            rest_fields, {==}))

def aes_encode_fields_split(+envelope: AES.Envelope) ->
    {String.split(AES.encode_impl(envelope), Chr{46}) ==
     ["v1", AES.hex_bytes(AES.fixed_bytes(12n,
            AES.nonce_bytes(AES.envelope_nonce(envelope)))),
       AES.hex_bytes(AES.fixed_bytes(16n,
            AES.tag_bytes(AES.envelope_tag(envelope)))),
       AES.hex_bytes(AES.ciphertext(envelope))] : List<&2, String>}:
    match envelope:
        case AES.Envelope{nonce, ciphertext, tag, valid}:
            match nonce:
                case AES.Nonce{nonce_bytes, size, valid}:
                    aes_split_v1_hex_fields(
                        AES.fixed_bytes(12n, nonce_bytes),
                        AES.fixed_bytes(16n, AES.tag_bytes(tag)), ciphertext)


def aes_false_type(b: Bool) -> Data:
    match b:
        case False{}: Unit
        case True{}: Empty

def aes_false_true(e: {False{} == True{} : Bool}) -> Empty:
    %e : aes_false_type(_)
    Unit{}

def aes_nat_predecessor(n: Nat) -> Nat:
    match n:
        case 0n: 0n
        case 1n+p: p

def aes_fixed_bytes_length(+n: Nat, +bytes: List<&2, U32>) ->
    {List.length(&2, U32, AES.fixed_bytes(n, bytes)) == n : Nat}:
    match n bytes:
        case 0n _: {==}
        case 1n+p Nil{}:
            Equal.cong(Nat, Nat, x => 1n+x,
                List.length(&2, U32, AES.fixed_bytes(p, Nil{})), p,
                aes_fixed_bytes_length(p, Nil{}))
        case 1n+p byte <> tail:
            Equal.cong(Nat, Nat, x => 1n+x,
                List.length(&2, U32, AES.fixed_bytes(p, tail)), p,
                aes_fixed_bytes_length(p, tail))

def aes_fixed_bytes_identity(+n: Nat, +bytes: List<&2, U32>,
    size: {List.length(&2, U32, bytes) == n : Nat}) ->
    {AES.fixed_bytes(n, bytes) == bytes : List<&2, U32>}:
    match n bytes:
        case 0n Nil{}: {==}
        case 0n byte <> tail:
            contradiction = Equal.cong(Nat, Bool,
                x => Nat.is_eq(x, 0n),
                1n+List.length(&2, U32, tail), 0n, size)
            Empty.absurd({AES.fixed_bytes(0n, byte <> tail) ==
                byte <> tail : List<&2, U32>},
                aes_false_true(contradiction))
        case 1n+p Nil{}:
            contradiction = Equal.cong(Nat, Bool,
                x => Nat.is_eq(x, 0n), 0n, 1n+p, size)
            Empty.absurd({AES.fixed_bytes(1n+p, Nil{}) == Nil{} :
                List<&2, U32>},
                aes_false_true(Equal.sym(Bool, True{}, False{},
                    contradiction)))
        case 1n+p byte <> tail:
            tail_size = Equal.cong(Nat, Nat, aes_nat_predecessor,
                1n+List.length(&2, U32, tail), 1n+p, size)
            Equal.cong(List<&2, U32>, List<&2, U32>,
                xs => byte <> xs,
                AES.fixed_bytes(p, tail), tail,
                aes_fixed_bytes_identity(p, tail, tail_size))

def aes_parse_decoded_masked_map(+nonce: List<&2, U32>, +tag: List<&2, U32>,
    +ciphertext: List<&2, U32>,
    nonce_size: {List.length(&2, U32, aes_hex_mask_bytes(nonce)) == 12n : Nat},
    tag_size: {List.length(&2, U32, aes_hex_mask_bytes(tag)) == 16n : Nat},
    nonce_valid: {AES.bytes_valid(aes_hex_mask_bytes(nonce)) == True{} : Bool},
    tag_valid: {AES.bytes_valid(aes_hex_mask_bytes(tag)) == True{} : Bool},
    ciphertext_valid: {AES.bytes_valid(aes_hex_mask_bytes(ciphertext)) == True{} : Bool}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_decoded(aes_hex_mask_bytes(nonce), aes_hex_mask_bytes(tag),
            aes_hex_mask_bytes(ciphertext),
            Some{nonce_size}, Some{tag_size}, Some{nonce_valid},
            Some{tag_valid}, Some{ciphertext_valid})) ==
     Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++ "." ++
        AES.hex_bytes(ciphertext)} : Result<&2, &2, AES.Error, String>}:
    +masked_nonce = aes_hex_mask_bytes(nonce)
    +masked_tag = aes_hex_mask_bytes(tag)
    +masked_ciphertext = aes_hex_mask_bytes(ciphertext)
    encoded_fixed = "v1." ++
        AES.hex_bytes(AES.fixed_bytes(12n, masked_nonce)) ++ "." ++
        AES.hex_bytes(AES.fixed_bytes(16n, masked_tag)) ++ "." ++
        AES.hex_bytes(masked_ciphertext)
    encoded_masked = "v1." ++ AES.hex_bytes(masked_nonce) ++ "." ++
        AES.hex_bytes(masked_tag) ++ "." ++ AES.hex_bytes(masked_ciphertext)
    encoded_raw = "v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
        "." ++ AES.hex_bytes(ciphertext)
    cipher_equal = aes_hex_bytes_mask_idempotent(ciphertext)
    tag_equal = aes_hex_bytes_mask_idempotent(tag)
    nonce_equal = aes_hex_bytes_mask_idempotent(nonce)
    cipher_path = Equal.cong(String, String,
        last => ("v1." ++ AES.hex_bytes(masked_nonce) ++ "." ++
            AES.hex_bytes(masked_tag) ++ "." ++ last),
        AES.hex_bytes(masked_ciphertext), AES.hex_bytes(ciphertext), cipher_equal)
    tag_path = Equal.cong(String, String,
        value => ("v1." ++ AES.hex_bytes(masked_nonce) ++ "." ++ value ++
            "." ++ AES.hex_bytes(ciphertext)),
        AES.hex_bytes(masked_tag), AES.hex_bytes(tag), tag_equal)
    nonce_path = Equal.cong(String, String,
        value => ("v1." ++ value ++ "." ++ AES.hex_bytes(tag) ++ "." ++
            AES.hex_bytes(ciphertext)),
        AES.hex_bytes(masked_nonce), AES.hex_bytes(nonce), nonce_equal)
    cipher_intermediate = "v1." ++ AES.hex_bytes(masked_nonce) ++ "." ++
        AES.hex_bytes(masked_tag) ++ "." ++ AES.hex_bytes(ciphertext)
    tag_intermediate = "v1." ++ AES.hex_bytes(masked_nonce) ++ "." ++
        AES.hex_bytes(tag) ++ "." ++ AES.hex_bytes(ciphertext)
    cipher_tag_path = Equal.trans(String, encoded_masked,
        cipher_intermediate, tag_intermediate, cipher_path, tag_path)
    encode_fields_equal = Equal.trans(String, encoded_masked,
        tag_intermediate, encoded_raw, cipher_tag_path, nonce_path)
    fixed_nonce_equal = Equal.cong(List<&2, U32>, String,
        xs => AES.hex_bytes(xs),
        AES.fixed_bytes(12n, masked_nonce), masked_nonce,
        aes_fixed_bytes_identity(12n, masked_nonce, nonce_size))
    fixed_tag_equal = Equal.cong(List<&2, U32>, String,
        xs => AES.hex_bytes(xs),
        AES.fixed_bytes(16n, masked_tag), masked_tag,
        aes_fixed_bytes_identity(16n, masked_tag, tag_size))
    fixed_tag_intermediate = "v1." ++
        AES.hex_bytes(AES.fixed_bytes(12n, masked_nonce)) ++ "." ++
        AES.hex_bytes(masked_tag) ++ "." ++
        AES.hex_bytes(masked_ciphertext)
    fixed_tag_path = Equal.cong(String, String,
        value => "v1." ++
            AES.hex_bytes(AES.fixed_bytes(12n, masked_nonce)) ++ "." ++
            value ++ "." ++ AES.hex_bytes(masked_ciphertext),
        AES.hex_bytes(AES.fixed_bytes(16n, masked_tag)),
        AES.hex_bytes(masked_tag), fixed_tag_equal)
    fixed_nonce_path = Equal.cong(String, String,
        value => "v1." ++ value ++ "." ++ AES.hex_bytes(masked_tag) ++
            "." ++ AES.hex_bytes(masked_ciphertext),
        AES.hex_bytes(AES.fixed_bytes(12n, masked_nonce)),
        AES.hex_bytes(masked_nonce), fixed_nonce_equal)
    fixed_to_masked = Equal.trans(String, encoded_fixed,
        fixed_tag_intermediate, encoded_masked,
        fixed_tag_path, fixed_nonce_path)
    fixed_to_raw = Equal.trans(String, encoded_fixed,
        encoded_masked, encoded_raw,
        fixed_to_masked, encode_fields_equal)
    Equal.cong(String, Result<&2, &2, AES.Error, String>,
        text => Done{text}, encoded_fixed, encoded_raw, fixed_to_raw)


def aes_hex_mask_bytes_length(+bytes: List<&2, U32>) ->
    {List.length(&2, U32, aes_hex_mask_bytes(bytes)) ==
     List.length(&2, U32, bytes) : Nat}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            Equal.cong(Nat, Nat, n => 1n+n,
                List.length(&2, U32, aes_hex_mask_bytes(tail)),
                List.length(&2, U32, tail), aes_hex_mask_bytes_length(tail))

def aes_hex_mask_bytes_valid(+bytes: List<&2, U32>) ->
    {AES.bytes_valid(aes_hex_mask_bytes(bytes)) == True{} : Bool}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            recursive = aes_hex_mask_bytes_valid(tail)
            range = aes_hex_mask_255_lt_256(byte)
            head_changed = Equal.cong(Bool, Bool,
                head => Bool.and(head, AES.bytes_valid(aes_hex_mask_bytes(tail))),
                U32.is_lt(AES.hex_mask(byte, 255), 256), True{}, range)
            tail_changed = Equal.cong(Bool, Bool,
                valid => Bool.and(True{}, valid),
                AES.bytes_valid(aes_hex_mask_bytes(tail)), True{}, recursive)
            Equal.trans(Bool,
                Bool.and(U32.is_lt(AES.hex_mask(byte, 255), 256),
                    AES.bytes_valid(aes_hex_mask_bytes(tail))),
                Bool.and(True{}, AES.bytes_valid(aes_hex_mask_bytes(tail))),
                True{}, head_changed,
                Equal.trans(Bool,
                    Bool.and(True{}, AES.bytes_valid(aes_hex_mask_bytes(tail))),
                    Bool.and(True{}, True{}), True{}, tail_changed, {==}))

def aes_nat_eq_self(+n: Nat) ->
    {AES.aes_nat_eq_proof(n, n) == Some{{==}} :
        Maybe<&0, {n == n : Nat}>}:
    match n:
        case 0n: {==}
        case 1n+p:
            Equal.cong(Maybe<&0, {p == p : Nat}>,
                Maybe<&0, {1n+p == 1n+p : Nat}>,
                result => AES.aes_nat_eq_step(p, p, result),
                AES.aes_nat_eq_proof(p, p), Some{{==}},
                aes_nat_eq_self(p))

def aes_bytes_valid_status(+bytes: List<&2, U32>, b: Bool,
    link: {b == AES.bytes_valid(bytes) : Bool}) ->
    {Maybe.is_some(&0, {AES.bytes_valid(bytes) == True{} : Bool},
        AES.aes_bytes_valid_from_bool(bytes, b, link)) == b : Bool}:
    match b:
        case False{}: {==}
        case True{}: {==}

def aes_masked_bytes_cert_is_some(+bytes: List<&2, U32>) ->
    {Maybe.is_some(&0,
        {AES.bytes_valid(aes_hex_mask_bytes(bytes)) == True{} : Bool},
        AES.aes_bytes_valid_proof(aes_hex_mask_bytes(bytes))) == True{} : Bool}:
    +masked = aes_hex_mask_bytes(bytes)
    Equal.trans(Bool,
        Maybe.is_some(&0, {AES.bytes_valid(masked) == True{} : Bool},
            AES.aes_bytes_valid_proof(masked)),
        AES.bytes_valid(masked), True{},
        aes_bytes_valid_status(masked, AES.bytes_valid(masked), {==}),
        aes_hex_mask_bytes_valid(bytes))

def aes_nat_eq_is_some(+a: Nat, +b: Nat,
    evidence: {a == b : Nat}) ->
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
        Equal.cong(Maybe<&0, {b == b : Nat}>, Bool,
            result => Maybe.is_some(&0, {b == b : Nat}, result),
            AES.aes_nat_eq_proof(b, b), Some{{==}},
            aes_nat_eq_self(b)))

def aes_masked_size_is_some(+bytes: List<&2, U32>, +expected: Nat,
    size: {List.length(&2, U32, bytes) == expected : Nat}) ->
    {Maybe.is_some(&0,
        {List.length(&2, U32, aes_hex_mask_bytes(bytes)) == expected : Nat},
        AES.aes_nat_eq_proof(
            List.length(&2, U32, aes_hex_mask_bytes(bytes)), expected)) ==
        True{} : Bool}:
    aes_nat_eq_is_some(
        List.length(&2, U32, aes_hex_mask_bytes(bytes)),
        expected,
        Equal.trans(Nat,
            List.length(&2, U32, aes_hex_mask_bytes(bytes)),
            List.length(&2, U32, bytes), expected,
            aes_hex_mask_bytes_length(bytes), size))

def aes_maybe_cert_value(A: Type, cert: Maybe<&0, A>,
    present: {Maybe.is_some(&0, A, cert) == True{} : Bool}) -> A:
    match cert:
        case None{}: Empty.absurd(A, aes_false_true(present))
        case Some{value}: value

def aes_maybe_cert_reconstruct(A: Type, cert: Maybe<&0, A>,
    present: {Maybe.is_some(&0, A, cert) == True{} : Bool}) ->
    {cert == Some{aes_maybe_cert_value(A, cert, present)} : Maybe<&0, A>}:
    match cert:
        case None{}:
            Empty.absurd({None{} ==
                Some{aes_maybe_cert_value(A, None{}, present)} :
                Maybe<&0, A>}, aes_false_true(present))
        case Some{value}: {==}

def aes_parse_decoded_map_goal(nonce: List<&2, U32>,
    tag: List<&2, U32>, ciphertext: List<&2, U32>,
    ns: Maybe<&0, {List.length(&2, U32,
        aes_hex_mask_bytes(nonce)) == 12n : Nat}>,
    ts: Maybe<&0, {List.length(&2, U32,
        aes_hex_mask_bytes(tag)) == 16n : Nat}>,
    nv: Maybe<&0, {AES.bytes_valid(aes_hex_mask_bytes(nonce)) ==
        True{} : Bool}>,
    tv: Maybe<&0, {AES.bytes_valid(aes_hex_mask_bytes(tag)) ==
        True{} : Bool}>,
    cv: Maybe<&0, {AES.bytes_valid(aes_hex_mask_bytes(ciphertext)) ==
        True{} : Bool}>) -> Type:
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_decoded(aes_hex_mask_bytes(nonce),
            aes_hex_mask_bytes(tag), aes_hex_mask_bytes(ciphertext),
            ns, ts, nv, tv, cv)) ==
     Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
         "." ++ AES.hex_bytes(ciphertext)} :
        Result<&2, &2, AES.Error, String>}

def aes_parse_decoded_if_some(+nonce: List<&2, U32>,
    +tag: List<&2, U32>, +ciphertext: List<&2, U32>,
    ns: Maybe<&0, {List.length(&2, U32,
        aes_hex_mask_bytes(nonce)) == 12n : Nat}>,
    ts: Maybe<&0, {List.length(&2, U32,
        aes_hex_mask_bytes(tag)) == 16n : Nat}>,
    nv: Maybe<&0, {AES.bytes_valid(aes_hex_mask_bytes(nonce)) ==
        True{} : Bool}>,
    tv: Maybe<&0, {AES.bytes_valid(aes_hex_mask_bytes(tag)) ==
        True{} : Bool}>,
    cv: Maybe<&0, {AES.bytes_valid(aes_hex_mask_bytes(ciphertext)) ==
        True{} : Bool}>,
    ns_present: {Maybe.is_some(&0,
        {List.length(&2, U32, aes_hex_mask_bytes(nonce)) == 12n : Nat},
        ns) == True{} : Bool},
    ts_present: {Maybe.is_some(&0,
        {List.length(&2, U32, aes_hex_mask_bytes(tag)) == 16n : Nat},
        ts) == True{} : Bool},
    nv_present: {Maybe.is_some(&0,
        {AES.bytes_valid(aes_hex_mask_bytes(nonce)) == True{} : Bool},
        nv) == True{} : Bool},
    tv_present: {Maybe.is_some(&0,
        {AES.bytes_valid(aes_hex_mask_bytes(tag)) == True{} : Bool},
        tv) == True{} : Bool},
    cv_present: {Maybe.is_some(&0,
        {AES.bytes_valid(aes_hex_mask_bytes(ciphertext)) == True{} : Bool},
        cv) == True{} : Bool}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_decoded(aes_hex_mask_bytes(nonce),
            aes_hex_mask_bytes(tag), aes_hex_mask_bytes(ciphertext),
            ns, ts, nv, tv, cv)) ==
     Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
         "." ++ AES.hex_bytes(ciphertext)} :
        Result<&2, &2, AES.Error, String>}:
    match ns:
        case None{}:
            Empty.absurd(aes_parse_decoded_map_goal(nonce, tag,
                ciphertext, None{}, ts, nv, tv, cv),
                aes_false_true(ns_present))
        case Some{ns_proof}:
            match ts:
                case None{}:
                    Empty.absurd(aes_parse_decoded_map_goal(nonce, tag,
                        ciphertext, Some{ns_proof}, None{}, nv, tv, cv),
                        aes_false_true(ts_present))
                case Some{ts_proof}:
                    match nv:
                        case None{}:
                            Empty.absurd(aes_parse_decoded_map_goal(nonce,
                                tag, ciphertext, Some{ns_proof},
                                Some{ts_proof}, None{}, tv, cv),
                                aes_false_true(nv_present))
                        case Some{nv_proof}:
                            match tv:
                                case None{}:
                                    Empty.absurd(aes_parse_decoded_map_goal(
                                        nonce, tag, ciphertext,
                                        Some{ns_proof}, Some{ts_proof},
                                        Some{nv_proof}, None{}, cv),
                                        aes_false_true(tv_present))
                                case Some{tv_proof}:
                                    match cv:
                                        case None{}:
                                            Empty.absurd(
                                                aes_parse_decoded_map_goal(
                                                    nonce, tag, ciphertext,
                                                    Some{ns_proof},
                                                    Some{ts_proof},
                                                    Some{nv_proof},
                                                    Some{tv_proof}, None{}),
                                                aes_false_true(cv_present))
                                        case Some{cv_proof}:
                                            aes_parse_decoded_masked_map(
                                                nonce, tag, ciphertext,
                                                ns_proof, ts_proof,
                                                nv_proof, tv_proof,
                                                cv_proof)

def aes_parse_decoded_checked_map(+nonce: List<&2, U32>,
    +tag: List<&2, U32>, +ciphertext: List<&2, U32>,
    nonce_size: {List.length(&2, U32, nonce) == 12n : Nat},
    tag_size: {List.length(&2, U32, tag) == 16n : Nat}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_decoded(aes_hex_mask_bytes(nonce),
            aes_hex_mask_bytes(tag), aes_hex_mask_bytes(ciphertext),
            AES.aes_nat_eq_proof(
                List.length(&2, U32, aes_hex_mask_bytes(nonce)), 12n),
            AES.aes_nat_eq_proof(
                List.length(&2, U32, aes_hex_mask_bytes(tag)), 16n),
            AES.aes_bytes_valid_proof(aes_hex_mask_bytes(nonce)),
            AES.aes_bytes_valid_proof(aes_hex_mask_bytes(tag)),
            AES.aes_bytes_valid_proof(aes_hex_mask_bytes(ciphertext)))) ==
     Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
         "." ++ AES.hex_bytes(ciphertext)} :
        Result<&2, &2, AES.Error, String>}:
    aes_parse_decoded_if_some(nonce, tag, ciphertext,
        AES.aes_nat_eq_proof(
            List.length(&2, U32, aes_hex_mask_bytes(nonce)), 12n),
        AES.aes_nat_eq_proof(
            List.length(&2, U32, aes_hex_mask_bytes(tag)), 16n),
        AES.aes_bytes_valid_proof(aes_hex_mask_bytes(nonce)),
        AES.aes_bytes_valid_proof(aes_hex_mask_bytes(tag)),
        AES.aes_bytes_valid_proof(aes_hex_mask_bytes(ciphertext)),
        aes_masked_size_is_some(nonce, 12n, nonce_size),
        aes_masked_size_is_some(tag, 16n, tag_size),
        aes_masked_bytes_cert_is_some(nonce),
        aes_masked_bytes_cert_is_some(tag),
        aes_masked_bytes_cert_is_some(ciphertext))

def aes_parse_decoded_hex_map(+nonce: List<&2, U32>,
    +tag: List<&2, U32>, +ciphertext: List<&2, U32>,
    nonce_size: {List.length(&2, U32, nonce) == 12n : Nat},
    tag_size: {List.length(&2, U32, tag) == 16n : Nat}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_decoded_hex(AES.decode_hex(AES.hex_bytes(nonce)),
            AES.decode_hex(AES.hex_bytes(tag)),
            AES.decode_hex(AES.hex_bytes(ciphertext)))) ==
     Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
        "." ++ AES.hex_bytes(ciphertext)} :
        Result<&2, &2, AES.Error, String>}:
    +n = aes_hex_mask_bytes(nonce)
    +t = aes_hex_mask_bytes(tag)
    +c = aes_hex_mask_bytes(ciphertext)
    nonce_step = Equal.cong(Maybe<&2, List<&2, U32>>,
        Result<&2, &2, AES.Error, String>,
        value => Result.map(&2, &2, AES.Error, AES.Envelope, String,
            AES.encode, AES.parse_decoded_hex(value,
                AES.decode_hex(AES.hex_bytes(tag)),
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        AES.decode_hex(AES.hex_bytes(nonce)), Some{n},
        aes_decode_hex_bytes(nonce))
    tag_step = Equal.cong(Maybe<&2, List<&2, U32>>,
        Result<&2, &2, AES.Error, String>,
        value => Result.map(&2, &2, AES.Error, AES.Envelope, String,
            AES.encode, AES.parse_decoded_hex(Some{n}, value,
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        AES.decode_hex(AES.hex_bytes(tag)), Some{t},
        aes_decode_hex_bytes(tag))
    cipher_step = Equal.cong(Maybe<&2, List<&2, U32>>,
        Result<&2, &2, AES.Error, String>,
        value => Result.map(&2, &2, AES.Error, AES.Envelope, String,
            AES.encode, AES.parse_decoded_hex(Some{n}, Some{t}, value)),
        AES.decode_hex(AES.hex_bytes(ciphertext)), Some{c},
        aes_decode_hex_bytes(ciphertext))
    first_two = Equal.trans(Result<&2, &2, AES.Error, String>,
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(AES.decode_hex(AES.hex_bytes(nonce)),
                AES.decode_hex(AES.hex_bytes(tag)),
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(Some{n},
                AES.decode_hex(AES.hex_bytes(tag)),
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(Some{n}, Some{t},
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        nonce_step, tag_step)
    all_three = Equal.trans(Result<&2, &2, AES.Error, String>,
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(AES.decode_hex(AES.hex_bytes(nonce)),
                AES.decode_hex(AES.hex_bytes(tag)),
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(Some{n}, Some{t},
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(Some{n}, Some{t}, Some{c})),
        first_two, cipher_step)
    Equal.trans(Result<&2, &2, AES.Error, String>,
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(AES.decode_hex(AES.hex_bytes(nonce)),
                AES.decode_hex(AES.hex_bytes(tag)),
                AES.decode_hex(AES.hex_bytes(ciphertext)))),
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_decoded_hex(Some{n}, Some{t}, Some{c})),
        Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
            "." ++ AES.hex_bytes(ciphertext)},
        all_three,
        aes_parse_decoded_checked_map(nonce, tag, ciphertext,
            nonce_size, tag_size))

def aes_parse_fields_hex_map(+nonce: List<&2, U32>,
    +tag: List<&2, U32>, +ciphertext: List<&2, U32>,
    nonce_size: {List.length(&2, U32, nonce) == 12n : Nat},
    tag_size: {List.length(&2, U32, tag) == 16n : Nat}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_fields(["v1", AES.hex_bytes(nonce),
            AES.hex_bytes(tag), AES.hex_bytes(ciphertext)])) ==
     Done{"v1." ++ AES.hex_bytes(nonce) ++ "." ++ AES.hex_bytes(tag) ++
        "." ++ AES.hex_bytes(ciphertext)} :
        Result<&2, &2, AES.Error, String>}:
    aes_parse_decoded_hex_map(nonce, tag, ciphertext,
        nonce_size, tag_size)

def aes_parse_encoder_fields_map(+envelope: AES.Envelope) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_fields(["v1",
            AES.hex_bytes(AES.fixed_bytes(12n,
                AES.nonce_bytes(AES.envelope_nonce(envelope)))),
            AES.hex_bytes(AES.fixed_bytes(16n,
                AES.tag_bytes(AES.envelope_tag(envelope)))),
            AES.hex_bytes(AES.ciphertext(envelope))])) ==
     Done{AES.encode(envelope)} :
        Result<&2, &2, AES.Error, String>}:
    match envelope:
        case AES.Envelope{nonce, ciphertext, tag, valid}:
            match nonce:
                case AES.Nonce{nonce_bytes, nonce_size, nonce_valid}:
                    aes_parse_fields_hex_map(
                        AES.fixed_bytes(12n, nonce_bytes),
                        AES.fixed_bytes(16n, AES.tag_bytes(tag)), ciphertext,
                        aes_fixed_bytes_length(12n, nonce_bytes),
                        aes_fixed_bytes_length(16n, AES.tag_bytes(tag)))

def aes_parse_fields_encoded_map(+envelope: AES.Envelope) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse_fields(String.split(AES.encode(envelope), Chr{46}))) ==
     Done{AES.encode(envelope)} :
        Result<&2, &2, AES.Error, String>}:
    fields: List<&2, String> = "v1" <>
        AES.hex_bytes(AES.fixed_bytes(12n,
            AES.nonce_bytes(AES.envelope_nonce(envelope)))) <>
        AES.hex_bytes(AES.fixed_bytes(16n,
            AES.tag_bytes(AES.envelope_tag(envelope)))) <>
        AES.hex_bytes(AES.ciphertext(envelope)) <> Nil{}
    Equal.trans(Result<&2, &2, AES.Error, String>,
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_fields(String.split(AES.encode(envelope), Chr{46}))),
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse_fields(fields)),
        Done{AES.encode(envelope)},
        Equal.cong(List<&2, String>,
            Result<&2, &2, AES.Error, String>,
            parts => Result.map(&2, &2, AES.Error, AES.Envelope,
                String, AES.encode, AES.parse_fields(parts)),
            String.split(AES.encode(envelope), Chr{46}), fields,
            aes_encode_fields_split(envelope)),
        aes_parse_encoder_fields_map(envelope))

def aes_envelope_roundtrip(+envelope: AES.Envelope) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse(AES.encode(envelope))) == Done{AES.encode(envelope)} :
        Result<&2, &2, AES.Error, String>}:
    Canonical.canonical_map_from_encoded(AES.encode(envelope),
        AES.parse_fields(String.split(AES.encode(envelope), Chr{46})),
        aes_parse_fields_encoded_map(envelope))



