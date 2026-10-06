import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_ZipLengthProof.bend as ZipLengthProof
import ./AES_LengthLimitProof.bend as LengthLimitProof
import 0xa7e654f9780078ca65bf9e187da99d3e/proofs/lib/u32.bend as HubU32

def bool_mask_xor_inv(+mask: Bool, +x: Bool, +y: Bool) ->
    {Bool.and(mask,
        Bool.xor(Bool.and(mask, Bool.xor(x, y)), y)) ==
     Bool.and(mask, x) : Bool}:
    match mask x y:
        case False{} False{} False{}: {==}
        case False{} False{} True{}: {==}
        case False{} True{} False{}: {==}
        case False{} True{} True{}: {==}
        case True{} False{} False{}: {==}
        case True{} False{} True{}: {==}
        case True{} True{} False{}: {==}
        case True{} True{} True{}: {==}

def word_mask_xor_inv(+n: Nat, +mask: Word(n), +x: Word(n), +y: Word(n)) ->
    {Word.and(n, mask,
        Word.xor(n, Word.and(n, mask, Word.xor(n, x, y)), y)) ==
     Word.and(n, mask, x) : Word(n)}:
    match n mask x y:
        case 0n WNil{} WNil{} WNil{}: {==}
        case 1n+p WCon{m, mt} WCon{xb, xt} WCon{yb, yt}:
            head = bool_mask_xor_inv(m, xb, yb)
            tail = word_mask_xor_inv(p, mt, xt, yt)
            Equal.trans(Word(1n+p),
                Word.and(1n+p, WCon{m, mt},
                    Word.xor(1n+p,
                        Word.and(1n+p, WCon{m, mt},
                            Word.xor(1n+p, WCon{xb, xt}, WCon{yb, yt})),
                        WCon{yb, yt})),
                WCon{Bool.and(m,
                    Bool.xor(Bool.and(m, Bool.xor(xb, yb)), yb)),
                    Word.and(p, mt,
                        Word.xor(p, Word.and(p, mt,
                            Word.xor(p, xt, yt)), yt))},
                WCon{Bool.and(m, xb), Word.and(p, mt, xt)},
                {==},
                Equal.trans(Word(1n+p),
                    WCon{Bool.and(m,
                        Bool.xor(Bool.and(m, Bool.xor(xb, yb)), yb)),
                        Word.and(p, mt,
                            Word.xor(p, Word.and(p, mt,
                                Word.xor(p, xt, yt)), yt))},
                    WCon{Bool.and(m, xb),
                        Word.and(p, mt,
                            Word.xor(p, Word.and(p, mt,
                                Word.xor(p, xt, yt)), yt))},
                    WCon{Bool.and(m, xb), Word.and(p, mt, xt)},
                    Equal.cong(Bool, Word(1n+p),
                        bit => WCon{bit,
                            Word.and(p, mt,
                                Word.xor(p, Word.and(p, mt,
                                    Word.xor(p, xt, yt)), yt))},
                        Bool.and(m,
                            Bool.xor(Bool.and(m, Bool.xor(xb, yb)), yb)),
                        Bool.and(m, xb), head),
                    Equal.cong(Word(p), Word(1n+p),
                        bits => WCon{Bool.and(m, xb), bits},
                        Word.and(p, mt,
                            Word.xor(p, Word.and(p, mt,
                                Word.xor(p, xt, yt)), yt)),
                        Word.and(p, mt, xt), tail)))

def word_bits(+value: U32) -> Word(32n):
    match value:
        case U32{bits}: bits

def gcm_mask_xor_inv(+x: U32, +y: U32) ->
    {Core.gcm_hex_mask(
        U32.xor(Core.gcm_hex_mask(U32.xor(x, y), 255), y), 255) ==
     Core.gcm_hex_mask(x, 255) : U32}:
    match x y:
        case U32{xb} U32{yb}:
            Equal.cong(Word(32n), U32, bits => U32{bits},
                Word.and(32n, word_bits(255),
                    Word.xor(32n,
                        Word.and(32n, word_bits(255),
                            Word.xor(32n, xb, yb)), yb)),
                Word.and(32n, word_bits(255), xb),
                word_mask_xor_inv(32n, word_bits(255), xb, yb))

def bool_and_comm(+a: Bool, +b: Bool) -> {Bool.and(a, b) == Bool.and(b, a) : Bool}:
    match a b:
        case False{} False{}: {==}
        case False{} True{}: {==}
        case True{} False{}: {==}
        case True{} True{}: {==}

def word_and_comm(+n: Nat, +x: Word(n), +y: Word(n)) ->
    {Word.and(n, x, y) == Word.and(n, y, x) : Word(n)}:
    match n x y:
        case 0n WNil{} WNil{}: {==}
        case 1n+p WCon{xb, xt} WCon{yb, yt}:
            head = bool_and_comm(xb, yb)
            tail = word_and_comm(p, xt, yt)
            Equal.trans(Word(1n+p),
                Word.and(1n+p, WCon{xb, xt}, WCon{yb, yt}),
                WCon{Bool.and(xb, yb), Word.and(p, xt, yt)},
                Word.and(1n+p, WCon{yb, yt}, WCon{xb, xt}),
                {==},
                Equal.trans(Word(1n+p),
                    WCon{Bool.and(xb, yb), Word.and(p, xt, yt)},
                    WCon{Bool.and(yb, xb), Word.and(p, xt, yt)},
                    WCon{Bool.and(yb, xb), Word.and(p, yt, xt)},
                    Equal.cong(Bool, Word(1n+p),
                        bit => WCon{bit, Word.and(p, xt, yt)},
                        Bool.and(xb, yb), Bool.and(yb, xb), head),
                    Equal.cong(Word(p), Word(1n+p),
                        bits => WCon{Bool.and(yb, xb), bits},
                        Word.and(p, xt, yt), Word.and(p, yt, xt), tail)))

def byte_mask_identity(+value: U32,
    below_256: {U32.is_lt(value, 256) == True{} : Bool}) ->
    {Core.gcm_hex_mask(value, 255) == value : U32}:
    match value:
        case U32{bits}:
            nat_below = Equal.trans(Bool,
                Nat.is_lt(U32.to_nat(U32{bits}), U32.to_nat(256)),
                U32.is_lt(U32{bits}, 256),
                True{},
                Equal.sym(Bool,
                    U32.is_lt(U32{bits}, 256),
                    Nat.is_lt(U32.to_nat(U32{bits}), U32.to_nat(256)),
                    HubU32.is_lt_nat(U32{bits}, 256)),
                below_256)
            scaled_below = Equal.trans(Bool,
                Nat.is_lt(U32.to_nat(U32{bits}), U32.to_nat(256)),
                Nat.is_lt(U32.to_nat(U32{bits}), 256n),
                True{},
                Equal.cong(Nat, Bool,
                    bound => Nat.is_lt(U32.to_nat(U32{bits}), bound),
                    U32.to_nat(256), 256n, {==}),
                nat_below)
            masked = HubU32.mask_word(U32{bits}, 255, 8n,
                {==}, scaled_below)
            Equal.trans(U32,
                Core.gcm_hex_mask(U32{bits}, 255),
                U32.and(255, U32{bits}),
                U32{bits}, {==},
                Equal.trans(U32,
                    U32.and(255, U32{bits}),
                    U32.and(U32{bits}, 255),
                    U32{bits},
                    Equal.cong(Word(32n), U32, w => U32{w},
                        Word.and(32n, word_bits(255), bits),
                        Word.and(32n, bits, word_bits(255)),
                        word_and_comm(32n, word_bits(255), bits)),
                    masked))

def bool_and_true_left(+a: Bool, +b: Bool,
    both: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
    match a b:
        case False{} False{}:
            Empty.absurd({False{} == True{} : Bool},
                ZipLengthProof.false_true(both))
        case False{} True{}:
            Empty.absurd({False{} == True{} : Bool},
                ZipLengthProof.false_true(both))
        case True{} False{}: {==}
        case True{} True{}: {==}

def bool_and_true_right(+a: Bool, +b: Bool,
    both: {Bool.and(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
    match a b:
        case False{} False{}:
            Empty.absurd({False{} == True{} : Bool},
                ZipLengthProof.false_true(both))
        case False{} True{}: {==}
        case True{} False{}:
            Empty.absurd({False{} == True{} : Bool},
                ZipLengthProof.false_true(both))
        case True{} True{}: {==}

def mask_bytes_identity(+bytes: List<&2, U32>,
    +valid: {Core.gcm_bytes_valid(bytes) == True{} : Bool}) ->
    {Core.gcm_mask_bytes(bytes) == bytes : List<&2, U32>}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            head_valid = bool_and_true_left(U32.is_lt(byte, 256),
                Core.gcm_bytes_valid(tail), valid)
            tail_valid = bool_and_true_right(U32.is_lt(byte, 256),
                Core.gcm_bytes_valid(tail), valid)
            recursive = mask_bytes_identity(tail, tail_valid)
            Equal.trans(List<&2, U32>,
                Core.gcm_mask_bytes(byte <> tail),
                byte <> Core.gcm_mask_bytes(tail),
                byte <> tail,
                Equal.cong(U32, List<&2, U32>,
                    head => head <> Core.gcm_mask_bytes(tail),
                    Core.gcm_hex_mask(byte, 255), byte,
                    byte_mask_identity(byte, head_valid)),
                Equal.cong(List<&2, U32>, List<&2, U32>,
                    rest => byte <> rest,
                    Core.gcm_mask_bytes(tail), tail, recursive))

def predecessor(n: Nat) -> Nat:
    match n:
        case 0n: 0n
        case 1n+p: p

def zip_xor_involution(+bytes: List<&2, U32>,
    +stream: List<&2, U32>,
    same_length: {List.length(&2, U32, bytes) ==
        List.length(&2, U32, stream) : Nat}) ->
    {Core.gcm_zip_xor(Core.gcm_zip_xor(bytes, stream), stream) ==
     Core.gcm_mask_bytes(bytes) : List<&2, U32>}:
    match bytes stream:
        case Nil{} _:
            +inner = Core.gcm_zip_xor_nil_left(stream)
            Equal.trans(List<&2, U32>,
                Core.gcm_zip_xor(Core.gcm_zip_xor(Nil{}, stream), stream),
                Core.gcm_zip_xor(Nil{}, stream), Nil{},
                Equal.cong(List<&2, U32>, List<&2, U32>,
                    xs => Core.gcm_zip_xor(xs, stream),
                    Core.gcm_zip_xor(Nil{}, stream), Nil{}, inner),
                inner)
        case _ <> _ Nil{}:
            unequal = Equal.cong(Nat, Bool,
                n => Nat.is_eq(n, 0n),
                List.length(&2, U32, bytes),
                List.length(&2, U32, Nil{}), same_length)
            Empty.absurd(
                {Core.gcm_zip_xor(Core.gcm_zip_xor(bytes, Nil{}), Nil{}) ==
                 Core.gcm_mask_bytes(bytes) : List<&2, U32>},
                ZipLengthProof.false_true(unequal))
        case byte <> tail stream_byte <> stream_tail:
            tail_length = Equal.cong(Nat, Nat, predecessor,
                List.length(&2, U32, byte <> tail),
                List.length(&2, U32, stream_byte <> stream_tail),
                same_length)
            recursive = zip_xor_involution(tail, stream_tail, tail_length)
            Equal.trans(List<&2, U32>,
                Core.gcm_zip_xor(
                    Core.gcm_zip_xor(byte <> tail,
                        stream_byte <> stream_tail),
                    stream_byte <> stream_tail),
                Core.gcm_hex_mask(U32.xor(
                    Core.gcm_hex_mask(U32.xor(byte, stream_byte), 255),
                    stream_byte), 255) <>
                    Core.gcm_zip_xor(
                        Core.gcm_zip_xor(tail, stream_tail), stream_tail),
                Core.gcm_mask_bytes(byte <> tail),
                {==},
                Equal.trans(List<&2, U32>,
                    Core.gcm_hex_mask(U32.xor(
                        Core.gcm_hex_mask(U32.xor(byte, stream_byte), 255),
                        stream_byte), 255) <>
                        Core.gcm_zip_xor(
                            Core.gcm_zip_xor(tail, stream_tail), stream_tail),
                    Core.gcm_hex_mask(byte, 255) <>
                        Core.gcm_zip_xor(
                            Core.gcm_zip_xor(tail, stream_tail), stream_tail),
                    Core.gcm_mask_bytes(byte <> tail),
                    Equal.cong(U32, List<&2, U32>,
                        head => head <>
                            Core.gcm_zip_xor(
                                Core.gcm_zip_xor(tail, stream_tail), stream_tail),
                        Core.gcm_hex_mask(U32.xor(
                            Core.gcm_hex_mask(U32.xor(byte, stream_byte), 255),
                            stream_byte), 255),
                        Core.gcm_hex_mask(byte, 255),
                        gcm_mask_xor_inv(byte, stream_byte)),
                    Equal.cong(List<&2, U32>, List<&2, U32>,
                        rest => Core.gcm_hex_mask(byte, 255) <> rest,
                        Core.gcm_zip_xor(
                            Core.gcm_zip_xor(tail, stream_tail), stream_tail),
                        Core.gcm_mask_bytes(tail), recursive)))

def ctr_decrypt_ciphertext_roundtrip(+words: List<&2, U32>,
    +nonce: List<&2, U32>, +plaintext: List<&2, U32>,
    +valid: {Core.gcm_bytes_valid(plaintext) == True{} : Bool}) ->
    {Core.gcm_decrypt_expanded(words, nonce,
        Core.gcm_zip_xor(plaintext,
            Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
                words, Core.gcm_inc32(Core.gcm_j0(nonce))))) ==
     plaintext : List<&2, U32>}:
    +start = Core.gcm_inc32(Core.gcm_j0(nonce))
    +stream = Core.gcm_ctr_stream_exact(
        List.length(&2, U32, plaintext), words, start)
    +same_length = Equal.sym(Nat,
        List.length(&2, U32, stream),
        List.length(&2, U32, plaintext),
        ZipLengthProof.ctr_stream_exact_length(
            List.length(&2, U32, plaintext), words, start))
    cipher_length = ZipLengthProof.zip_length_equal(plaintext, stream,
        same_length)
    decrypt_stream = Equal.cong(Nat, List<&2, U32>,
        fuel => Core.gcm_ctr_stream_exact(fuel, words, start),
        List.length(&2, U32,
            Core.gcm_zip_xor(plaintext, stream)),
        List.length(&2, U32, plaintext), cipher_length)
    Equal.trans(List<&2, U32>,
        Core.gcm_decrypt_expanded(words, nonce,
            Core.gcm_zip_xor(plaintext, stream)),
        Core.gcm_zip_xor(Core.gcm_zip_xor(plaintext, stream), stream),
        plaintext,
        Equal.cong(List<&2, U32>, List<&2, U32>,
            stream2 => Core.gcm_zip_xor(
                Core.gcm_zip_xor(plaintext, stream), stream2),
            Core.gcm_ctr_stream_exact(
                List.length(&2, U32,
                    Core.gcm_zip_xor(plaintext, stream)), words, start),
            stream, decrypt_stream),
        Equal.trans(List<&2, U32>,
            Core.gcm_zip_xor(Core.gcm_zip_xor(plaintext, stream), stream),
            Core.gcm_mask_bytes(plaintext), plaintext,
            zip_xor_involution(plaintext, stream, same_length),
            mask_bytes_identity(plaintext, valid)))

def ctr_ciphertext_plaintext_valid(+plaintext: List<&2, U32>,
    +stream: List<&2, U32>,
    same_length: {List.length(&2, U32, plaintext) ==
        List.length(&2, U32, stream) : Nat},
    +plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool}) ->
    {AES.plaintext_valid(Core.gcm_zip_xor(plaintext, stream)) ==
        True{} : Bool}:
    +ciphertext = Core.gcm_zip_xor(plaintext, stream)
    cipher_length = ZipLengthProof.zip_length_equal(plaintext, stream,
        same_length)
    output_bytes_ok = AES.core_bytes_valid_proof(ciphertext,
        Core.gcm_zip_xor_valid(plaintext, stream))
    plaintext_limit_ok = bool_and_true_right(AES.bytes_valid(plaintext),
        AES.bytes_length_limit(plaintext, 4294967264, 15), plaintext_ok)
    output_limit_eq = LengthLimitProof.bytes_length_limit_same(plaintext,
        ciphertext, 4294967264, 15, Equal.sym(Nat,
            List.length(&2, U32, ciphertext),
            List.length(&2, U32, plaintext), cipher_length))
    output_limit_ok = Equal.trans(Bool,
        AES.bytes_length_limit(ciphertext, 4294967264, 15),
        AES.bytes_length_limit(plaintext, 4294967264, 15),
        True{}, Equal.sym(Bool,
            AES.bytes_length_limit(plaintext, 4294967264, 15),
            AES.bytes_length_limit(ciphertext, 4294967264, 15),
            output_limit_eq), plaintext_limit_ok)
    Equal.trans(Bool, AES.plaintext_valid(ciphertext),
        Bool.and(AES.bytes_valid(ciphertext),
            AES.bytes_length_limit(ciphertext, 4294967264, 15)),
        True{}, {==},
        Equal.trans(Bool,
            Bool.and(AES.bytes_valid(ciphertext),
                AES.bytes_length_limit(ciphertext, 4294967264, 15)),
            Bool.and(True{},
                AES.bytes_length_limit(ciphertext, 4294967264, 15)),
            True{},
            Equal.cong(Bool, Bool,
                byte_ok => Bool.and(byte_ok,
                    AES.bytes_length_limit(ciphertext, 4294967264, 15)),
                AES.bytes_valid(ciphertext), True{}, output_bytes_ok),
            Equal.trans(Bool,
                Bool.and(True{},
                    AES.bytes_length_limit(ciphertext, 4294967264, 15)),
                AES.bytes_length_limit(ciphertext, 4294967264, 15),
                True{}, {==}, output_limit_ok)))
