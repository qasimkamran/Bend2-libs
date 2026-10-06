import Base

# Byte arithmetic. Inputs and outputs are represented by U32 values in [0,255].
# Turn a boolean into an all-zero or all-one word to keep field arithmetic branchless.
def xor_if(a: U32, b: U32, yes: Bool) -> U32:
    mask = U32.sub(0, Bool.to_u32(yes))
    U32.xor(a, U32.and(mask, b))

def gf8_xtime.high(+a: U32, high: Bool) -> U32:
    xor_if(U32.and(255, U32.shln(a, 1n)), 27, high)

def gf8_xtime(+a: U32) -> U32:
    gf8_xtime.high(a, U32.is_ne(U32.and(128, a), 0))

def gf8_mul.go(fuel: Nat, +a: U32, +b: U32, acc: U32) -> U32:
    match fuel:
        case 0n: acc
        case 1n+p:
            bit = U32.is_ne(U32.and(1, b), 0)
            next = xor_if(acc, a, bit)
            gf8_mul.go(p, gf8_xtime(a), U32.shrn(b, 1n), next)

def gf8_mul(a: U32, b: U32) -> U32:
    gf8_mul.go(8n, a, b, 0)

def gf8_pow.go(fuel: Nat, +base: U32, +exp: U32, +acc: U32) -> U32:
    match fuel:
        case 0n: acc
        case 1n+p:
            next = Bool.pick(U32, U32.is_ne(U32.and(1, exp), 0), gf8_mul(acc, base), acc)
            gf8_pow.go(p, gf8_mul(base, base), U32.shrn(exp, 1n), next)

def gf8_pow(a: U32, exp: U32) -> U32:
    gf8_pow.go(8n, a, exp, 1)

def rotl8(+a: U32, +shift: Nat) -> U32:
    U32.and(255, U32.or(U32.shln(a, shift), U32.shrn(a, (8n - shift : Nat))))

def aes_sbox(+x: U32) -> U32:
    +inv = gf8_pow(x, 254)
    U32.xor(U32.xor(U32.xor(U32.xor(inv, rotl8(inv, 1n)),
        rotl8(inv, 2n)), rotl8(inv, 3n)),
        U32.xor(rotl8(inv, 4n), 99))

def aes_subword(+w: U32) -> U32:
    a b c d = aes_sbox(U32.shrn(w, 24n)) aes_sbox(U32.and(255, U32.shrn(w, 16n)))
        aes_sbox(U32.and(255, U32.shrn(w, 8n))) aes_sbox(U32.and(255, w))
    U32.or(U32.or(U32.shln(a, 24n), U32.shln(b, 16n)),
        U32.or(U32.shln(c, 8n), d))

def aes_rotword(+w: U32) -> U32:
    U32.or(U32.shln(w, 8n), U32.shrn(w, 24n))

def aes_rcon_step(r: U32) -> U32:
    gf8_xtime(r)

def aes_word(a: U32, b: U32, c: U32, d: U32) -> U32:
    U32.or(U32.or(U32.shln(a, 24n), U32.shln(b, 16n)),
        U32.or(U32.shln(c, 8n), d))

def aes_words(bytes: List<&2, U32>) -> List<&2, U32>:
    match bytes:
        case a <> b <> c <> d <> tail:
            aes_word(a, b, c, d) <> aes_words(tail)
        case _: Nil{}

def aes_word_from_maybe(value: Maybe<&2, U32>) -> U32:
    match value:
        case None{}: 0
        case Some{w}: w

def aes_word_at(words: List<&2, U32>, i: Nat) -> U32:
    aes_word_from_maybe(List.get(&2, U32, words, i))

def aes_key_word_kind.step(previous: U32, rcon: U32, mod4: Bool) -> U32:
    match mod4:
        case True{}: aes_subword(previous)
        case False{}: previous

def aes_key_word_kind.rcon(previous: U32, rcon: U32, mod4: Bool) -> U32:
    U32.xor(aes_subword(aes_rotword(previous)), U32.shln(rcon, 24n))

def aes_key_word_kind(previous: U32, rcon: U32, mod0: Bool, mod4: Bool) -> U32:
    match mod0:
        case True{}: aes_key_word_kind.rcon(previous, rcon, mod4)
        case False{}: aes_key_word_kind.step(previous, rcon, mod4)

def aes_rcon_kind(rcon: U32, advance: Bool) -> U32:
    match advance:
        case True{}: aes_rcon_step(rcon)
        case False{}: rcon

def aes_expand.go(fuel: Nat, +i: U32, +rcon: U32,
                  +words: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: words
        case 1n+p:
            previous = aes_word_at(words, U32.to_nat(U32.sub(i, 1)))
            back8 = aes_word_at(words, U32.to_nat(U32.sub(i, 8)))
            part = aes_key_word_kind(previous, rcon, U32.is_eq(U32.mod(i, 8), 0), U32.is_eq(U32.mod(i, 8), 4))
            next = U32.xor(back8, part)
            next_rcon = aes_rcon_kind(rcon, U32.is_eq(U32.mod(i, 8), 0))
            aes_expand.go(p, U32.add(i, 1), next_rcon,
                List.append(&2, U32, words, [next]))

def aes256_expand_impl(+key: List<&2, U32>) -> List<&2, U32>:
    aes_expand.go(52n, 8, 1, aes_words(key))

# An abstract key remains neutral. The explicit fuel parameter also lets
# computation certificates compose without unfolding all 52 expansion steps.
def aes_expand_key(+fuel: Nat, +key: List<&2, U32>) -> List<&2, U32>:
    match key:
        case Nil{}: aes_expand.go(fuel, 8, 1, aes_words(key))
        case head <> tail: aes_expand.go(fuel, 8, 1, aes_words(key))

def aes256_expand(+key: List<&2, U32>) -> List<&2, U32>:
    aes_expand_key(52n, key)

def aes_add_key.go(+state: List<&2, U32>, +words: List<&2, U32>,
                   +round: Nat, +index: Nat, fuel: Nat,
                   acc: List<&2, U32>) -> List<&2, U32>:
    match state fuel:
        case Nil{} _: List.reverse(&2, U32, acc)
        case byte <> tail 0n: List.reverse(&2, U32, acc)
        case +byte <> tail 1n+p:
            word_index = ((round * 4n + (index / 4n : Nat)) : Nat)
            word = aes_word_at(words, word_index)
            shift = ((3n - (index % 4n : Nat)) * 8n : Nat)
            keybyte = U32.and(255, U32.shrn(word, shift))
            aes_add_key.go(tail, words, round, (index + 1n : Nat), p,
                U32.xor(byte, keybyte) <> acc)

def aes_add_key(state: List<&2, U32>, words: List<&2, U32>, round: Nat) -> List<&2, U32>:
    aes_add_key.go(state, words, round, 0n, 16n, Nil{})

def aes_sub_state.go(+state: List<&2, U32>, +acc: List<&2, U32>) -> List<&2, U32>:
    match state:
        case Nil{}: List.reverse(&2, U32, acc)
        case byte <> tail:
            aes_sub_state.go(tail, aes_sbox(byte) <> acc)

def aes_sub_state(state: List<&2, U32>) -> List<&2, U32>:
    aes_sub_state.go(state, Nil{})

def aes_byte_from_maybe(value: Maybe<&2, U32>) -> U32:
    match value:
        case None{}: 0
        case Some{byte}: byte

def aes_byte_at(state: List<&2, U32>, index: Nat) -> U32:
    aes_byte_from_maybe(List.get(&2, U32, state, index))

def aes_shift_rows(+state: List<&2, U32>) -> List<&2, U32>:
    [aes_byte_at(state, 0n), aes_byte_at(state, 5n), aes_byte_at(state, 10n), aes_byte_at(state, 15n),
     aes_byte_at(state, 4n), aes_byte_at(state, 9n), aes_byte_at(state, 14n), aes_byte_at(state, 3n),
     aes_byte_at(state, 8n), aes_byte_at(state, 13n), aes_byte_at(state, 2n), aes_byte_at(state, 7n),
     aes_byte_at(state, 12n), aes_byte_at(state, 1n), aes_byte_at(state, 6n), aes_byte_at(state, 11n)]

type AesColumn is Data:
    AesColumn{a: U32, b: U32, c: U32, d: U32}

def aes_mix_column(col: AesColumn) -> AesColumn:
    match col:
        case AesColumn{+a, +b, +c, +d}:
            AesColumn{
                U32.xor(U32.xor(U32.xor(gf8_mul(a, 2), gf8_mul(b, 3)), c), d),
                U32.xor(U32.xor(U32.xor(a, gf8_mul(b, 2)), gf8_mul(c, 3)), d),
                U32.xor(U32.xor(U32.xor(a, b), gf8_mul(c, 2)), gf8_mul(d, 3)),
                U32.xor(U32.xor(U32.xor(gf8_mul(a, 3), b), c), gf8_mul(d, 2))}

def aes_mix_column.first(col: AesColumn) -> U32:
    match col:
        case AesColumn{+a, +b, +c, +d}:
            U32.xor(U32.xor(U32.xor(gf8_mul(a, 2), gf8_mul(b, 3)), c), d)

def aes_mix_column.second(col: AesColumn) -> U32:
    match col:
        case AesColumn{+a, +b, +c, +d}:
            U32.xor(U32.xor(U32.xor(a, gf8_mul(b, 2)), gf8_mul(c, 3)), d)

def aes_mix_column.third(col: AesColumn) -> U32:
    match col:
        case AesColumn{+a, +b, +c, +d}:
            U32.xor(U32.xor(U32.xor(a, b), gf8_mul(c, 2)), gf8_mul(d, 3))

def aes_mix_column.fourth(col: AesColumn) -> U32:
    match col:
        case AesColumn{+a, +b, +c, +d}:
            U32.xor(U32.xor(U32.xor(gf8_mul(a, 3), b), c), gf8_mul(d, 2))

def aes_mix_row(col: AesColumn, row: Nat) -> U32:
    match row:
        case 0n: aes_mix_column.first(col)
        case 1n: aes_mix_column.second(col)
        case 2n: aes_mix_column.third(col)
        case _: aes_mix_column.fourth(col)

def aes_mix_byte(+state: List<&2, U32>, row: Nat, +col: Nat) -> U32:
    column: AesColumn = AesColumn{
        aes_byte_at(state, (col * 4n : Nat)),
        aes_byte_at(state, (col * 4n + 1n : Nat)),
        aes_byte_at(state, (col * 4n + 2n : Nat)),
        aes_byte_at(state, (col * 4n + 3n : Nat))}
    aes_mix_row(column, row)

def aes_mix_state.finish(col0: AesColumn, col1: AesColumn, col2: AesColumn, col3: AesColumn) -> List<&2, U32>:
    match col0 col1 col2 col3:
        case AesColumn{a0, b0, c0, d0} AesColumn{a1, b1, c1, d1} AesColumn{a2, b2, c2, d2} AesColumn{a3, b3, c3, d3}:
            [a0,b0,c0,d0,a1,b1,c1,d1,a2,b2,c2,d2,a3,b3,c3,d3]

def aes_mix_state(+state: List<&2, U32>) -> List<&2, U32>:
    col0 col1 col2 col3 =
        aes_mix_column(AesColumn{aes_byte_at(state, 0n), aes_byte_at(state, 1n), aes_byte_at(state, 2n), aes_byte_at(state, 3n)})
        aes_mix_column(AesColumn{aes_byte_at(state, 4n), aes_byte_at(state, 5n), aes_byte_at(state, 6n), aes_byte_at(state, 7n)})
        aes_mix_column(AesColumn{aes_byte_at(state, 8n), aes_byte_at(state, 9n), aes_byte_at(state, 10n), aes_byte_at(state, 11n)})
        aes_mix_column(AesColumn{aes_byte_at(state, 12n), aes_byte_at(state, 13n), aes_byte_at(state, 14n), aes_byte_at(state, 15n)})
    aes_mix_state.finish(col0, col1, col2, col3)

def aes_middle_round(state: List<&2, U32>, words: List<&2, U32>, round: Nat) -> List<&2, U32>:
    aes_add_key(aes_mix_state(aes_shift_rows(aes_sub_state(state))), words, round)

def aes_final_round(state: List<&2, U32>, words: List<&2, U32>) -> List<&2, U32>:
    aes_add_key(aes_shift_rows(aes_sub_state(state)), words, 14n)

def aes_rounds.go(fuel: Nat, +state: List<&2, U32>, +words: List<&2, U32>, +round: Nat) -> List<&2, U32>:
    match fuel:
        case 0n: aes_final_round(state, words)
        case 1n+p:
            aes_rounds.go(p, aes_middle_round(state, words, round), words, (round + 1n : Nat))

def aes256_encrypt_expanded(+words: List<&2, U32>, block: List<&2, U32>) -> List<&2, U32>:
    aes_rounds.go(13n, aes_add_key(block, words, 0n), words, 1n)

def aes256_encrypt_block(key: List<&2, U32>, block: List<&2, U32>) -> List<&2, U32>:
    aes256_encrypt_expanded(aes256_expand(key), block)

# GCM counter mode and GHASH use 16-byte blocks in network byte order.
def gcm_hex_mask(value: U32, mask: U32) -> U32:
    U32.and(mask, value)

def gcm_mask_byte_valid(+value: U32) ->
    {U32.is_lt(gcm_hex_mask(value, 255), 256) == True{} : Bool}:
    match value:
        case U32{WCon{b0, WCon{b1, WCon{b2, WCon{b3, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def gcm_bytes_valid(bytes: List<&2, U32>) -> Bool:
    match bytes:
        case Nil{}: True{}
        case byte <> tail:
            U32.is_lt(byte, 256) && gcm_bytes_valid(tail)

def gcm_mask_bytes(+bytes: List<&2, U32>) -> List<&2, U32>:
    match bytes:
        case Nil{}: Nil{}
        case byte <> tail:
            gcm_hex_mask(byte, 255) <> gcm_mask_bytes(tail)

def gcm_mask_bytes_valid(+bytes: List<&2, U32>) ->
    {gcm_bytes_valid(gcm_mask_bytes(bytes)) == True{} : Bool}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            Equal.trans(Bool,
                gcm_bytes_valid(gcm_mask_bytes(byte <> tail)),
                Bool.and(True{}, gcm_bytes_valid(gcm_mask_bytes(tail))),
                True{},
                Equal.cong(Bool, Bool,
                    head => Bool.and(head,
                        gcm_bytes_valid(gcm_mask_bytes(tail))),
                    U32.is_lt(gcm_hex_mask(byte, 255), 256), True{},
                    gcm_mask_byte_valid(byte)),
                Equal.cong(Bool, Bool, tail_ok => Bool.and(True{}, tail_ok),
                    gcm_bytes_valid(gcm_mask_bytes(tail)), True{},
                    gcm_mask_bytes_valid(tail)))

def gcm_mask_bytes_length(+bytes: List<&2, U32>) ->
    {List.length(&2, U32, gcm_mask_bytes(bytes)) ==
     List.length(&2, U32, bytes) : Nat}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            Equal.cong(Nat, Nat, n => 1n+n,
                List.length(&2, U32, gcm_mask_bytes(tail)),
                List.length(&2, U32, tail),
                gcm_mask_bytes_length(tail))

type GcmTag is Data:
    GcmTag{
        bytes: List<&2, U32>,
        valid: {gcm_bytes_valid(bytes) == True{} : Bool},
        size: {List.length(&2, U32, bytes) == 16n : Nat}
    }

type GcmCiphertext is Data:
    GcmCiphertext{
        bytes: List<&2, U32>,
        valid: {gcm_bytes_valid(bytes) == True{} : Bool}
    }

def gcm_ciphertext_bytes(ciphertext: GcmCiphertext) -> List<&2, U32>:
    match ciphertext:
        case GcmCiphertext{bytes, valid}: bytes


def ghash_xor_if(a: U32, b: U32, yes: Bool) -> U32:
    match yes:
        case True{}: U32.xor(a, b)
        case False{}: a

def ghash_xor_list.go(a: List<&2, U32>, b: List<&2, U32>, +yes: Bool,
                      +acc: List<&2, U32>) -> List<&2, U32>:
    match a b:
        case Nil{} _: List.reverse(&2, U32, acc)
        case _ Nil{}: List.reverse(&2, U32, acc)
        case x <> xt y <> yt:
            ghash_xor_list.go(xt, yt, yes, ghash_xor_if(x, y, yes) <> acc)

def ghash_xor_list(a: List<&2, U32>, b: List<&2, U32>, yes: Bool) -> List<&2, U32>:
    ghash_xor_list.go(a, b, yes, Nil{})

# Keep the 128-bit GHASH accumulator in four machine words during its hot loop.
type GhashField is Data:
    GhashField{w0: U32, w1: U32, w2: U32, w3: U32}

def ghash_field(+bytes: List<&2, U32>) -> GhashField:
    +words = aes_words(bytes)
    GhashField{aes_word_at(words, 0n), aes_word_at(words, 1n),
        aes_word_at(words, 2n), aes_word_at(words, 3n)}

def ghash_field_bytes(value: GhashField) -> List<&2, U32>:
    match value:
        case GhashField{+w0, +w1, +w2, +w3}:
            [U32.and(255, U32.shrn(w0, 24n)), U32.and(255, U32.shrn(w0, 16n)),
             U32.and(255, U32.shrn(w0, 8n)), U32.and(255, w0),
             U32.and(255, U32.shrn(w1, 24n)), U32.and(255, U32.shrn(w1, 16n)),
             U32.and(255, U32.shrn(w1, 8n)), U32.and(255, w1),
             U32.and(255, U32.shrn(w2, 24n)), U32.and(255, U32.shrn(w2, 16n)),
             U32.and(255, U32.shrn(w2, 8n)), U32.and(255, w2),
             U32.and(255, U32.shrn(w3, 24n)), U32.and(255, U32.shrn(w3, 16n)),
             U32.and(255, U32.shrn(w3, 8n)), U32.and(255, w3)]

def ghash_field_word(value: GhashField, index: Nat) -> U32:
    match value index:
        case GhashField{w0, _, _, _} 0n: w0
        case GhashField{_, w1, _, _} 1n: w1
        case GhashField{_, _, w2, _} 2n: w2
        case GhashField{_, _, _, w3} _: w3

def ghash_field_shift_top(w0: U32, reduce: Bool) -> U32:
    reduction_mask = U32.sub(0, Bool.to_u32(reduce))
    U32.xor(U32.shrn(w0, 1n), U32.and(3774873600, reduction_mask))

def ghash_field_shift_right(value: GhashField) -> GhashField:
    match value:
        case GhashField{+w0, +w1, +w2, +w3}:
            GhashField{
                ghash_field_shift_top(w0, U32.is_ne(U32.and(1, w3), 0)),
                U32.or(U32.shrn(w1, 1n), U32.shln(U32.and(1, w0), 31n)),
                U32.or(U32.shrn(w2, 1n), U32.shln(U32.and(1, w1), 31n)),
                U32.or(U32.shrn(w3, 1n), U32.shln(U32.and(1, w2), 31n))}

def ghash_field_xor_if(a: U32, b: U32, yes: Bool) -> U32:
    mask = U32.sub(0, Bool.to_u32(yes))
    U32.xor(a, U32.and(mask, b))

def ghash_field_xor_if.all(a: GhashField, b: GhashField, +yes: Bool) -> GhashField:
    match a b:
        case GhashField{a0, a1, a2, a3} GhashField{b0, b1, b2, b3}:
            GhashField{ghash_field_xor_if(a0, b0, yes), ghash_field_xor_if(a1, b1, yes),
                ghash_field_xor_if(a2, b2, yes), ghash_field_xor_if(a3, b3, yes)}

def ghash_mul.go(fuel: Nat, +x: GhashField, +v: GhashField,
                 +z: GhashField, +bit_index: Nat) -> GhashField:
    match fuel:
        case 0n: z
        case 1n+p:
            input_word = ghash_field_word(x, (bit_index / 32n : Nat))
            shift = (31n - (bit_index % 32n : Nat) : Nat)
            set = U32.is_ne(U32.and(1, U32.shrn(input_word, shift)), 0)
            next_z = ghash_field_xor_if.all(z, v, set)
            ghash_mul.go(p, x, ghash_field_shift_right(v), next_z, (bit_index + 1n : Nat))

def ghash_mul(x: List<&2, U32>, h: List<&2, U32>) -> List<&2, U32>:
    ghash_field_bytes(ghash_mul.go(128n, ghash_field(x), ghash_field(h),
        GhashField{0,0,0,0}, 0n))

def ghash_update(y: List<&2, U32>, h: List<&2, U32>, block: List<&2, U32>) -> List<&2, U32>:
    ghash_mul(ghash_xor_list(y, block, True{}), h)

def ghash_zero_pad.go(fuel: Nat, +bytes: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: bytes
        case 1n+p: ghash_zero_pad.go(p, List.append(&2, U32, bytes, [0]))

def ghash_finish(space: Nat, block_rev: List<&2, U32>, h: List<&2, U32>, y: List<&2, U32>) -> List<&2, U32>:
    match space:
        case 16n: y
        case 0n: ghash_update(y, h, List.reverse(&2, U32, block_rev))
        case 1n+p:
            ghash_update(y, h, ghash_zero_pad.go(space, List.reverse(&2, U32, block_rev)))

def ghash_bytes.go(fuel: Nat, bytes: List<&2, U32>, space: Nat,
                   +block_rev: List<&2, U32>, +h: List<&2, U32>, +y: List<&2, U32>) -> List<&2, U32>:
    match fuel bytes space:
        case 0n Nil{} _: ghash_finish(space, block_rev, h, y)
        case 0n _ _: ghash_finish(space, block_rev, h, y)
        case 1n+p Nil{} _: ghash_finish(space, block_rev, h, y)
        case 1n+p byte <> tail 0n:
            y2 = ghash_update(y, h, List.reverse(&2, U32, block_rev))
            ghash_bytes.go(p, tail, 15n, [byte], h, y2)
        case 1n+p byte <> tail 1n+s:
            ghash_bytes.go(p, tail, s, byte <> block_rev, h, y)

def ghash_bytes(+bytes: List<&2, U32>, h: List<&2, U32>, y: List<&2, U32>) -> List<&2, U32>:
    ghash_bytes.go(List.length(&2, U32, bytes), bytes, 16n, Nil{}, h, y)

def ghash_nat_bytes.go(fuel: Nat, qr: Nat & Nat, +acc: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: acc
        case 1n+p:
            (q, r) = qr
            ghash_nat_bytes.go(p, Nat.divmod(q, 256n), U32.from_nat(r) <> acc)

def ghash_nat_bytes(n: Nat) -> List<&2, U32>:
    ghash_nat_bytes.go(8n, Nat.divmod(n, 256n), Nil{})

def ghash_auth_expanded(words: List<&2, U32>, +aad: List<&2, U32>, +ciphertext: List<&2, U32>) -> List<&2, U32>:
    +h = aes256_encrypt_expanded(words, ([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] : List<&2, U32>))
    y0: List<&2, U32> = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    y1 = ghash_bytes(aad, h, y0)
    y2 = ghash_bytes(ciphertext, h, y1)
    aad_bits = ghash_nat_bytes((List.length(&2, U32, aad) * 8n : Nat))
    ct_bits = ghash_nat_bytes((List.length(&2, U32, ciphertext) * 8n : Nat))
    ghash_update(y2, h, List.append(&2, U32, aad_bits, ct_bits))

def gcm_j0(nonce: List<&2, U32>) -> List<&2, U32>:
    List.append(&2, U32, nonce, [0,0,0,1])

def gcm_inc32(+counter: List<&2, U32>) -> List<&2, U32>:
    hi = U32.shln(aes_byte_at(counter, 12n), 24n)
    mid1 = U32.shln(aes_byte_at(counter, 13n), 16n)
    mid2 = U32.shln(aes_byte_at(counter, 14n), 8n)
    lo = aes_byte_at(counter, 15n)
    +word = U32.add(U32.or(U32.or(hi, mid1), U32.or(mid2, lo)), 1)
    List.append(&2, U32, List.take(&2, U32, counter, 12n),
        [U32.and(255, U32.shrn(word, 24n)), U32.and(255, U32.shrn(word, 16n)),
         U32.and(255, U32.shrn(word, 8n)), U32.and(255, word)])

def gcm_ctr_stream.go(fuel: Nat, +words: List<&2, U32>, +counter: List<&2, U32>,
                      +acc: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: List.reverse(&2, U32, acc)
        case 1n+p:
            stream = aes256_encrypt_expanded(words, counter)
            next_acc = List.append(&2, U32, List.reverse(&2, U32, stream), acc)
            gcm_ctr_stream.go(p, words, gcm_inc32(counter), next_acc)

def gcm_ctr_advance(fuel: Nat, +counter: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: counter
        case 1n+p: gcm_ctr_advance(p, gcm_inc32(counter))

type GcmCtrStep is Data:
    GcmCtrStep{byte: U32, counter: List<&2, U32>, rest: List<&2, U32>}

def gcm_ctr_step(+words: List<&2, U32>, +counter: List<&2, U32>,
    block: List<&2, U32>) -> GcmCtrStep:
    match block:
        case Nil{}:
            +next_block = aes256_encrypt_expanded(words, counter)
            GcmCtrStep{aes_byte_at(next_block, 0n), gcm_inc32(counter),
                List.tail(&2, U32, next_block)}
        case byte <> rest: GcmCtrStep{byte, counter, rest}

def gcm_ctr_step_byte(step: GcmCtrStep) -> U32:
    match step:
        case GcmCtrStep{byte, _, _}: byte

def gcm_ctr_step_counter(step: GcmCtrStep) -> List<&2, U32>:
    match step:
        case GcmCtrStep{_, counter, _}: counter

def gcm_ctr_step_rest(step: GcmCtrStep) -> List<&2, U32>:
    match step:
        case GcmCtrStep{_, _, rest}: rest

# Generate each AES counter block once and consume all of its bytes. Fuel is
# still a byte count, so partial final blocks have exactly the requested length.
def gcm_ctr_stream_exact.go(fuel: Nat, +words: List<&2, U32>,
    counter: List<&2, U32>, block: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: Nil{}
        case 1n+p:
            +step = gcm_ctr_step(words, counter, block)
            gcm_ctr_step_byte(step) <>
                gcm_ctr_stream_exact.go(p, words, gcm_ctr_step_counter(step),
                    gcm_ctr_step_rest(step))

def gcm_ctr_stream_exact(fuel: Nat, +words: List<&2, U32>,
    +start: List<&2, U32>) -> List<&2, U32>:
    gcm_ctr_stream_exact.go(fuel, words, start, Nil{})

def gcm_zip_xor(+bytes: List<&2, U32>, +stream: List<&2, U32>) -> List<&2, U32>:
    match bytes stream:
        case Nil{} _: Nil{}
        case _ Nil{}: Nil{}
        case byte <> tail stream_byte <> stream_tail:
            gcm_hex_mask(U32.xor(byte, stream_byte), 255) <>
                gcm_zip_xor(tail, stream_tail)

def gcm_zip_xor_nil_left(+stream: List<&2, U32>) ->
    {gcm_zip_xor(Nil{}, stream) == Nil{} : List<&2, U32>}:
    match stream:
        case Nil{}: {==}
        case _ <> _: {==}

def gcm_zip_xor_nil_right(+bytes: List<&2, U32>) ->
    {gcm_zip_xor(bytes, Nil{}) == Nil{} : List<&2, U32>}:
    match bytes:
        case Nil{}: {==}
        case _ <> _: {==}

def gcm_zip_xor_valid(+bytes: List<&2, U32>, +stream: List<&2, U32>) ->
    {gcm_bytes_valid(gcm_zip_xor(bytes, stream)) == True{} : Bool}:
    match bytes stream:
        case Nil{} _:
            Equal.trans(Bool,
                gcm_bytes_valid(gcm_zip_xor(Nil{}, stream)),
                gcm_bytes_valid(Nil{}), True{},
                Equal.cong(List<&2, U32>, Bool, gcm_bytes_valid,
                    gcm_zip_xor(Nil{}, stream), Nil{},
                    gcm_zip_xor_nil_left(stream)),
                {==})
        case _ Nil{}:
            Equal.trans(Bool,
                gcm_bytes_valid(gcm_zip_xor(bytes, Nil{})),
                gcm_bytes_valid(Nil{}), True{},
                Equal.cong(List<&2, U32>, Bool, gcm_bytes_valid,
                    gcm_zip_xor(bytes, Nil{}), Nil{},
                    gcm_zip_xor_nil_right(bytes)),
                {==})
        case byte <> tail stream_byte <> stream_tail:
            recursive = gcm_zip_xor_valid(tail, stream_tail)
            range = gcm_mask_byte_valid(U32.xor(byte, stream_byte))
            head_changed = Equal.cong(Bool, Bool,
                head => Bool.and(head,
                    gcm_bytes_valid(gcm_zip_xor(tail, stream_tail))),
                U32.is_lt(gcm_hex_mask(U32.xor(byte, stream_byte), 255), 256),
                True{}, range)
            tail_changed = Equal.cong(Bool, Bool,
                valid => Bool.and(True{}, valid),
                gcm_bytes_valid(gcm_zip_xor(tail, stream_tail)), True{},
                recursive)
            Equal.trans(Bool,
                Bool.and(
                    U32.is_lt(gcm_hex_mask(U32.xor(byte, stream_byte), 255), 256),
                    gcm_bytes_valid(gcm_zip_xor(tail, stream_tail))),
                Bool.and(True{}, gcm_bytes_valid(gcm_zip_xor(tail, stream_tail))),
                True{}, head_changed,
                Equal.trans(Bool,
                    Bool.and(True{}, gcm_bytes_valid(gcm_zip_xor(tail, stream_tail))),
                    Bool.and(True{}, True{}), True{}, tail_changed, {==}))

def gcm_tag_output_impl(+words: List<&2, U32>, nonce: List<&2, U32>,
                   aad: List<&2, U32>, ciphertext: List<&2, U32>) -> GcmTag:
    auth mask = ghash_auth_expanded(words, aad, ciphertext)
        aes256_encrypt_expanded(words, gcm_j0(nonce))
    +raw_tag = ghash_xor_list(mask, auth, True{})
    GcmTag{gcm_mask_bytes(raw_tag), gcm_mask_bytes_valid(raw_tag), {==}}

# Keep an abstract key schedule abstract during proof normalization. Both
# branches run the same tag calculation, including the total empty-key case.
def gcm_tag_output(+words: List<&2, U32>, nonce: List<&2, U32>,
                   aad: List<&2, U32>, ciphertext: List<&2, U32>) -> GcmTag:
    match words:
        case Nil{}: gcm_tag_output_impl(words, nonce, aad, ciphertext)
        case head <> tail: gcm_tag_output_impl(words, nonce, aad, ciphertext)

def gcm_tag_bytes(tag_output: GcmTag) -> List<&2, U32>:
    match tag_output:
        case GcmTag{bytes, valid, size}: bytes

def gcm_tag_valid(tag_output: GcmTag) ->
    {gcm_bytes_valid(gcm_tag_bytes(tag_output)) == True{} : Bool}:
    match tag_output:
        case GcmTag{bytes, valid, size}: valid

def gcm_tag_size(tag_output: GcmTag) ->
    {List.length(&2, U32, gcm_tag_bytes(tag_output)) == 16n : Nat}:
    match tag_output:
        case GcmTag{bytes, valid, size}: size

type GcmOutput is Data:
    GcmOutput{
        ciphertext: List<&2, U32>,
        ciphertext_valid: {gcm_bytes_valid(ciphertext) == True{} : Bool},
        tag_bytes: List<&2, U32>,
        tag_valid: {gcm_bytes_valid(tag_bytes) == True{} : Bool},
        tag_size: {List.length(&2, U32, tag_bytes) == 16n : Nat},
        tag_words: List<&2, U32>,
        tag_nonce: List<&2, U32>,
        tag_aad: List<&2, U32>,
        tag_matches: {tag_bytes == gcm_tag_bytes(
            gcm_tag_output(tag_words, tag_nonce, tag_aad, ciphertext)) :
            List<&2, U32>}
    }

def gcm_output_tag_bytes(output: GcmOutput) -> List<&2, U32>:
    match output:
        case GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_bytes

def gcm_output_tag_valid(output: GcmOutput) ->
    {gcm_bytes_valid(gcm_output_tag_bytes(output)) == True{} : Bool}:
    match output:
        case GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_valid

def gcm_output_tag_size(output: GcmOutput) ->
    {List.length(&2, U32, gcm_output_tag_bytes(output)) == 16n : Nat}:
    match output:
        case GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_size

def gcm_output_from_tag(+words: List<&2, U32>, +nonce: List<&2, U32>,
    +aad: List<&2, U32>, +ciphertext: List<&2, U32>,
    ciphertext_valid: {gcm_bytes_valid(ciphertext) == True{} : Bool}) ->
    GcmOutput:
    +tag_output = gcm_tag_output(words, nonce, aad, ciphertext)
    GcmOutput{ciphertext, ciphertext_valid, gcm_tag_bytes(tag_output),
        gcm_tag_valid(tag_output), gcm_tag_size(tag_output), words, nonce,
        aad, {==}}

def gcm_output_from_ciphertext(+words: List<&2, U32>,
    nonce: List<&2, U32>, aad: List<&2, U32>,
    cipher_output: GcmCiphertext) -> GcmOutput:
    match cipher_output:
        case GcmCiphertext{+ciphertext, valid}:
            gcm_output_from_tag(words, nonce, aad, ciphertext, valid)

def gcm_ctr_encrypt(+words: List<&2, U32>, nonce: List<&2, U32>,
    +plaintext: List<&2, U32>) -> GcmCiphertext:
    +start = gcm_inc32(gcm_j0(nonce))
    +stream = gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
        words, start)
    GcmCiphertext{gcm_zip_xor(plaintext, stream),
        gcm_zip_xor_valid(plaintext, stream)}

def gcm_encrypt_raw(+key: List<&2, U32>, +nonce: List<&2, U32>,
                    +aad: List<&2, U32>, +plaintext: List<&2, U32>) -> GcmOutput:
    +words = aes256_expand(key)
    gcm_output_from_ciphertext(words, nonce, aad,
        gcm_ctr_encrypt(words, nonce, plaintext))

def gcm_decrypt_expanded(+words: List<&2, U32>, nonce: List<&2, U32>, +ciphertext: List<&2, U32>) -> List<&2, U32>:
    +start = gcm_inc32(gcm_j0(nonce))
    +stream = gcm_ctr_stream_exact(List.length(&2, U32, ciphertext),
        words, start)
    gcm_zip_xor(ciphertext, stream)

def gcm_decrypt_raw(+key: List<&2, U32>, nonce: List<&2, U32>, +ciphertext: List<&2, U32>) -> List<&2, U32>:
    gcm_decrypt_expanded(aes256_expand(key), nonce, ciphertext)

# Authenticate ciphertext directly; expand the key once for both AES calls.
def gcm_tag_expanded(+words: List<&2, U32>, nonce: List<&2, U32>, aad: List<&2, U32>, ciphertext: List<&2, U32>) -> List<&2, U32>:
    gcm_tag_bytes(gcm_tag_output(words, nonce, aad, ciphertext))

def gcm_tag(+key: List<&2, U32>, nonce: List<&2, U32>, aad: List<&2, U32>, ciphertext: List<&2, U32>) -> List<&2, U32>:
    gcm_tag_expanded(aes256_expand(key), nonce, aad, ciphertext)

def ghash_auth(key: List<&2, U32>, aad: List<&2, U32>, ciphertext: List<&2, U32>) -> List<&2, U32>:
    ghash_auth_expanded(aes256_expand(key), aad, ciphertext)
