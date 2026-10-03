import Base

# Byte arithmetic. Inputs and outputs are represented by U32 values in [0,255].
def xor_if(a: U32, b: U32, yes: Bool) -> U32:
    match yes:
        case False{}: a
        case True{}: U32.xor(a, b)

def gf8_xtime.high(+a: U32, high: Bool) -> U32:
    xor_if(U32.and(U32.shln(a, 1n), 255), 27, high)

def gf8_xtime(+a: U32) -> U32:
    gf8_xtime.high(a, U32.is_ne(U32.and(a, 128), 0))

def gf8_mul.go(fuel: Nat, +a: U32, +b: U32, acc: U32) -> U32:
    match fuel:
        case 0n: acc
        case 1n+p:
            bit = U32.is_ne(U32.and(b, 1), 0)
            next = xor_if(acc, a, bit)
            gf8_mul.go(p, gf8_xtime(a), U32.shrn(b, 1n), next)

def gf8_mul(a: U32, b: U32) -> U32:
    gf8_mul.go(8n, a, b, 0)

def gf8_pow.go(fuel: Nat, +base: U32, +exp: U32, +acc: U32) -> U32:
    match fuel:
        case 0n: acc
        case 1n+p:
            next = Bool.pick(U32, U32.is_ne(U32.and(exp, 1), 0), gf8_mul(acc, base), acc)
            gf8_pow.go(p, gf8_mul(base, base), U32.shrn(exp, 1n), next)

def gf8_pow(a: U32, exp: U32) -> U32:
    gf8_pow.go(8n, a, exp, 1)

def rotl8(+a: U32, +shift: Nat) -> U32:
    U32.and(U32.or(U32.shln(a, shift), U32.shrn(a, (8n - shift : Nat))), 255)

def aes_sbox(+x: U32) -> U32:
    +inv = gf8_pow(x, 254)
    U32.xor(U32.xor(U32.xor(U32.xor(inv, rotl8(inv, 1n)),
        rotl8(inv, 2n)), rotl8(inv, 3n)),
        U32.xor(rotl8(inv, 4n), 99))

def aes_subword(+w: U32) -> U32:
    U32.or(U32.or(U32.shln(aes_sbox(U32.shrn(w, 24n)), 24n),
        U32.shln(aes_sbox(U32.and(U32.shrn(w, 16n), 255)), 16n)),
        U32.or(U32.shln(aes_sbox(U32.and(U32.shrn(w, 8n), 255)), 8n),
            aes_sbox(U32.and(w, 255))))

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

def aes256_expand(+key: List<&2, U32>) -> List<&2, U32>:
    aes_expand.go(52n, 8, 1, aes_words(key))

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
            keybyte = U32.and(U32.shrn(word, shift), 255)
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

def aes_mix_state(+state: List<&2, U32>) -> List<&2, U32>:
    [aes_mix_byte(state, 0n, 0n), aes_mix_byte(state, 1n, 0n), aes_mix_byte(state, 2n, 0n), aes_mix_byte(state, 3n, 0n),
     aes_mix_byte(state, 0n, 1n), aes_mix_byte(state, 1n, 1n), aes_mix_byte(state, 2n, 1n), aes_mix_byte(state, 3n, 1n),
     aes_mix_byte(state, 0n, 2n), aes_mix_byte(state, 1n, 2n), aes_mix_byte(state, 2n, 2n), aes_mix_byte(state, 3n, 2n),
     aes_mix_byte(state, 0n, 3n), aes_mix_byte(state, 1n, 3n), aes_mix_byte(state, 2n, 3n), aes_mix_byte(state, 3n, 3n)]

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
type GcmOutput is Data:
    GcmOutput{ciphertext: List<&2, U32>, tag: List<&2, U32>}

def ghash_first_byte(first: U32, reduce: Bool) -> U32:
    match reduce:
        case True{}: U32.xor(first, 225)
        case False{}: first

def ghash_shift_right(+v: List<&2, U32>) -> List<&2, U32>:
    last = aes_byte_at(v, 15n)
    first = ghash_first_byte(U32.shrn(aes_byte_at(v, 0n), 1n),
        U32.is_ne(U32.and(last, 1), 0))
    [first,
     U32.or(U32.shrn(aes_byte_at(v, 1n), 1n), U32.shln(U32.and(aes_byte_at(v, 0n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 2n), 1n), U32.shln(U32.and(aes_byte_at(v, 1n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 3n), 1n), U32.shln(U32.and(aes_byte_at(v, 2n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 4n), 1n), U32.shln(U32.and(aes_byte_at(v, 3n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 5n), 1n), U32.shln(U32.and(aes_byte_at(v, 4n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 6n), 1n), U32.shln(U32.and(aes_byte_at(v, 5n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 7n), 1n), U32.shln(U32.and(aes_byte_at(v, 6n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 8n), 1n), U32.shln(U32.and(aes_byte_at(v, 7n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 9n), 1n), U32.shln(U32.and(aes_byte_at(v, 8n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 10n), 1n), U32.shln(U32.and(aes_byte_at(v, 9n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 11n), 1n), U32.shln(U32.and(aes_byte_at(v, 10n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 12n), 1n), U32.shln(U32.and(aes_byte_at(v, 11n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 13n), 1n), U32.shln(U32.and(aes_byte_at(v, 12n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 14n), 1n), U32.shln(U32.and(aes_byte_at(v, 13n), 1), 7n)),
     U32.or(U32.shrn(aes_byte_at(v, 15n), 1n), U32.shln(U32.and(aes_byte_at(v, 14n), 1), 7n))]

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

def ghash_mul.go(fuel: Nat, +x: List<&2, U32>, +v: List<&2, U32>,
                 +z: List<&2, U32>, +bit_index: Nat) -> List<&2, U32>:
    match fuel:
        case 0n: z
        case 1n+p:
            input_byte = aes_byte_at(x, (bit_index / 8n : Nat))
            shift = (7n - (bit_index % 8n : Nat) : Nat)
            set = U32.is_ne(U32.and(input_byte, U32.shln(1, shift)), 0)
            next_z = ghash_xor_list(z, v, set)
            ghash_mul.go(p, x, ghash_shift_right(v), next_z, (bit_index + 1n : Nat))

def ghash_mul(x: List<&2, U32>, h: List<&2, U32>) -> List<&2, U32>:
    ghash_mul.go(128n, x, h, [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], 0n)

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
            ghash_update(y, h,
                ghash_zero_pad.go(space, List.reverse(&2, U32, block_rev)))

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

def ghash_auth(key: List<&2, U32>, +aad: List<&2, U32>, +ciphertext: List<&2, U32>) -> List<&2, U32>:
    +h = aes256_encrypt_block(key, ([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] : List<&2, U32>))
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
        [U32.and(U32.shrn(word, 24n), 255), U32.and(U32.shrn(word, 16n), 255),
         U32.and(U32.shrn(word, 8n), 255), U32.and(word, 255)])

def gcm_ctr_stream.go(fuel: Nat, +key: List<&2, U32>, +counter: List<&2, U32>,
                      +acc: List<&2, U32>) -> List<&2, U32>:
    match fuel:
        case 0n: List.reverse(&2, U32, acc)
        case 1n+p:
            stream = aes256_encrypt_block(key, counter)
            next_acc = List.append(&2, U32, List.reverse(&2, U32, stream), acc)
            gcm_ctr_stream.go(p, key, gcm_inc32(counter), next_acc)

def gcm_zip_xor(+bytes: List<&2, U32>, +stream: List<&2, U32>) -> List<&2, U32>:
    match bytes stream:
        case Nil{} _: Nil{}
        case _ Nil{}: Nil{}
        case byte <> tail stream_byte <> stream_tail:
            U32.xor(byte, stream_byte) <> gcm_zip_xor(tail, stream_tail)

def gcm_encrypt_raw(+key: List<&2, U32>, nonce: List<&2, U32>,
                    +aad: List<&2, U32>, +plaintext: List<&2, U32>) -> GcmOutput:
    +j0 = gcm_j0(nonce)
    start = gcm_inc32(j0)
    blocks = Nat.div((List.length(&2, U32, plaintext) + 15n : Nat), 16n)
    +stream = gcm_ctr_stream.go(blocks, key, start, Nil{})
    +ciphertext = gcm_zip_xor(plaintext, stream)
    auth = ghash_auth(key, aad, ciphertext)
    tag_mask = aes256_encrypt_block(key, j0)
    GcmOutput{ciphertext, ghash_xor_list(tag_mask, auth, True{})}

def gcm_decrypt_raw(+key: List<&2, U32>, nonce: List<&2, U32>, +ciphertext: List<&2, U32>) -> List<&2, U32>:
    start = gcm_inc32(gcm_j0(nonce))
    blocks = Nat.div((List.length(&2, U32, ciphertext) + 15n : Nat), 16n)
    +stream = gcm_ctr_stream.go(blocks, key, start, Nil{})
    gcm_zip_xor(ciphertext, stream)
