import Base
import ./AES256GCMCore.bend as Core

# AES-256-GCM with validated inputs and canonical envelope serialization.
# Bytes use U32 storage, with validation certificates excluding values above 255.
def bytes_valid(bytes: List<&2, U32>) -> Bool:
    match bytes:
        case Nil{}: True{}
        case head <> tail:
            U32.is_lt(head, 256) && bytes_valid(tail)

def core_bytes_valid_eq(+bytes: List<&2, U32>) ->
    {bytes_valid(bytes) == Core.gcm_bytes_valid(bytes) : Bool}:
    match bytes:
        case Nil{}: {==}
        case head <> tail:
            recursive = core_bytes_valid_eq(tail)
            Equal.cong(Bool, Bool,
                valid => Bool.and(U32.is_lt(head, 256), valid),
                bytes_valid(tail), Core.gcm_bytes_valid(tail), recursive)

def core_bytes_valid_proof(bytes: List<&2, U32>,
    valid: {Core.gcm_bytes_valid(bytes) == True{} : Bool}) ->
    {bytes_valid(bytes) == True{} : Bool}:
    Equal.trans(Bool, bytes_valid(bytes), Core.gcm_bytes_valid(bytes), True{},
        core_bytes_valid_eq(bytes), valid)

# Count at most the supported byte bound with two wrapping words. This avoids
# constructing or dividing enormous Peano Nat bounds for symbolic lists.

def length_pair_high(low: U32, high_cmp: Cmp, max_low: U32) -> Bool:
    match high_cmp:
        case LT{}: True{}
        case EQ{}: U32.is_le(low, max_low)
        case GT{}: False{}

def length_pair_within(low: U32, high: U32, max_low: U32, max_high: U32) -> Bool:
    length_pair_high(low, U32.cmp(high, max_high), max_low)

def bytes_length_limit.go(fuel: Nat, bytes: List<&2, U32>,
                          low: U32, +high: U32, +max_low: U32, +max_high: U32,
                          within: Bool) -> Bool:
    match fuel bytes within:
        case 0n Nil{} _: within
        case 0n _ <> _ _: False{}
        case 1n+p Nil{} _: False{}
        case 1n+p _ <> _ False{}: False{}
        case 1n+p _ <> tail True{}:
            +next_low = U32.add(low, 1)
            +next_high = Bool.pick(U32, U32.is_eq(next_low, 0), U32.add(high, 1), high)
            bytes_length_limit.go(p, tail, next_low, next_high,
                max_low, max_high,
                length_pair_within(next_low, next_high, max_low, max_high))

def bytes_length_limit(+bytes: List<&2, U32>, max_low: U32, max_high: U32) -> Bool:
    bytes_length_limit.go(List.length(&2, U32, bytes), bytes,
        0, 0, max_low, max_high, True{})

# GCM limits are expressed in bytes after requiring byte-aligned input.
def plaintext_valid(+bytes: List<&2, U32>) -> Bool:
    bytes_valid(bytes) && bytes_length_limit(bytes, 4294967264, 15)

def aad_valid(+bytes: List<&2, U32>) -> Bool:
    bytes_valid(bytes) && bytes_length_limit(bytes, 4294967295, 536870911)

type SecretKey is Data:
    SecretKey{
        bytes: List<&2, U32>,
        -size: {List.length(&2, U32, bytes) == 32n : Nat},
        -valid: {bytes_valid(bytes) == True{} : Bool}
    }

type Nonce is Data:
    Nonce{
        bytes: List<&2, U32>,
        size: {List.length(&2, U32, bytes) == 12n : Nat},
        valid: {bytes_valid(bytes) == True{} : Bool}
    }

type Tag is Data:
    Tag{
        bytes: List<&2, U32>,
        size: {List.length(&2, U32, bytes) == 16n : Nat},
        valid: {bytes_valid(bytes) == True{} : Bool}
    }

type Envelope is Data:
    Envelope{
        nonce: Nonce,
        ciphertext: List<&2, U32>,
        tag: Tag,
        valid: {bytes_valid(ciphertext) == True{} : Bool}
    }

type Error is Data:
    InvalidKey{}
    InvalidNonce{}
    InvalidBytes{}
    InvalidEnvelope{}
    AuthenticationFailed{}

# Constructors validate raw input; SecretKey/Nonce/Tag certificates enforce sizes.
law key:
    for bytes: List<&2, U32>
    Result<&2, &2, Error, SecretKey>

law nonce:
    for bytes: List<&2, U32>
    Result<&2, &2, Error, Nonce>

# Deterministic primitive: the caller supplies a nonce unique for this key.
# The eventual effectful wrapper must generate nonces using an OS CSPRNG.
law encrypt:
    for key: SecretKey
    for nonce: Nonce
    for aad: List<&2, U32>
    for plaintext: List<&2, U32>
    Result<&2, &2, Error, Envelope>

# Fail contains only an Error, never unauthenticated or partial plaintext.
law decrypt:
    for key: SecretKey
    for aad: List<&2, U32>
    for envelope: Envelope
    Result<&2, &2, Error, List<&2, U32>>

# Canonical envelope: v1.<lowercase nonce hex>.<lowercase tag hex>.<ciphertext hex>.
# The nonce has 24 hex characters, the tag 32, ciphertext an even number (or 0).
# AAD is external and must be supplied unchanged when decrypting.
law encode:
    for envelope: Envelope
    String

law parse:
    for text: String
    Result<&2, &2, Error, Envelope>

# Read-only projections needed to state the contract.
def nonce_bytes(nonce: Nonce) -> List<&2, U32>:
    match nonce:
        case Nonce{bytes, size, valid}: bytes

def tag_bytes(tag: Tag) -> List<&2, U32>:
    match tag:
        case Tag{bytes, size, valid}: bytes

def tag_bytes_size(tag: Tag) ->
    {List.length(&2, U32, tag_bytes(tag)) == 16n : Nat}:
    match tag:
        case Tag{bytes, size, valid}: size

def tag_bytes_valid(tag: Tag) ->
    {bytes_valid(tag_bytes(tag)) == True{} : Bool}:
    match tag:
        case Tag{bytes, size, valid}: valid

def ciphertext(envelope: Envelope) -> List<&2, U32>:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: ciphertext

def envelope_ciphertext_valid(envelope: Envelope) ->
    {bytes_valid(ciphertext(envelope)) == True{} : Bool}:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: valid

def envelope_nonce(envelope: Envelope) -> Nonce:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: nonce

def envelope_tag(envelope: Envelope) -> Tag:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: tag

# Canonical lowercase hexadecimal envelope serialization.
def hex_digit_kind(+n: U32, decimal: Bool) -> Char:
    match decimal:
        case True{}: Chr{U32.add(48, n)}
        case False{}: Chr{U32.add(87, n)}

# The mask-first implementation keeps zero mask bits visibly false to Bend's
# checker, which supports the nibble range proofs used by the codec.
def hex_word_and(n: Nat, mask: Word(n), +value: Word(n)) -> Word(n):
    match n:
        case 0n: WNil{}
        case 1n+p:
            match mask:
                case WCon{False{}, mask_tail}:
                    match value:
                        case WCon{_, value_tail}:
                            WCon{False{}, hex_word_and(p, mask_tail, value_tail)}
                case WCon{True{}, mask_tail}:
                    match value:
                        case WCon{bit, value_tail}:
                            WCon{bit, hex_word_and(p, mask_tail, value_tail)}

def hex_mask(value: U32, mask: U32) -> U32:
    match value mask:
        case U32{value_word} U32{mask_word}:
            U32{hex_word_and(32n, mask_word, value_word)}

def hex_digit.nibble(+n: U32) -> Char:
    match n:
        case 0: Chr{48}
        case 1: Chr{49}
        case 2: Chr{50}
        case 3: Chr{51}
        case 4: Chr{52}
        case 5: Chr{53}
        case 6: Chr{54}
        case 7: Chr{55}
        case 8: Chr{56}
        case 9: Chr{57}
        case 10: Chr{97}
        case 11: Chr{98}
        case 12: Chr{99}
        case 13: Chr{100}
        case 14: Chr{101}
        case 15: Chr{102}
        case _: hex_digit_kind(n, U32.is_lt(n, 10))

def hex_digit(+n: U32) -> Char:
    hex_digit.nibble(hex_mask(n, 15))

def hex_bytes(+bytes: List<&2, U32>) -> String:
    match bytes:
        case Nil{}: ""
        case +byte <> tail:
            +normalized = hex_mask(byte, 255)
            SCon{hex_digit(U32.shrn(normalized, 4n)),
                SCon{hex_digit(normalized), hex_bytes(tail)}}

# Serialize validated fixed-size fields through a fixed-size byte view. This
# makes the wire length structural even when the constructor certificate is
# erased from runtime storage.
def fixed_bytes(n: Nat, bytes: List<&2, U32>) -> List<&2, U32>:
    match n:
        case 0n: Nil{}
        case 1n+p:
            match bytes:
                case Nil{}: 0 <> fixed_bytes(p, Nil{})
                case byte <> tail: byte <> fixed_bytes(p, tail)

def encode_impl(envelope: Envelope) -> String:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}:
            match nonce:
                case Nonce{nonce_bytes, size, valid}:
                    "v1." ++ hex_bytes(fixed_bytes(12n, nonce_bytes)) ++ "." ++
                        hex_bytes(fixed_bytes(16n, tag_bytes(tag))) ++ "." ++
                        hex_bytes(ciphertext)

# Match the ASCII code point directly so each accepted nibble normalizes to a literal.
def hex_nibble(+code: U32) -> Maybe<&2, U32>:
    match code:
        case 48: Some{0}
        case 49: Some{1}
        case 50: Some{2}
        case 51: Some{3}
        case 52: Some{4}
        case 53: Some{5}
        case 54: Some{6}
        case 55: Some{7}
        case 56: Some{8}
        case 57: Some{9}
        case 97: Some{10}
        case 98: Some{11}
        case 99: Some{12}
        case 100: Some{13}
        case 101: Some{14}
        case 102: Some{15}
        case _: None{}

def hex_join(high: U32, low: U32) -> U32:
    match high low:
        case U32{WCon{h0, WCon{h1, WCon{h2, WCon{h3, _}}}}}
             U32{WCon{l0, WCon{l1, WCon{l2, WCon{l3, _}}}}}:
            U32{WCon{l0, WCon{l1, WCon{l2, WCon{l3,
                WCon{h0, WCon{h1, WCon{h2, WCon{h3, Word.zero(24n)}}}}}}}}}

def hex_pair.combine(high: Maybe<&2, U32>, low: Maybe<&2, U32>) -> Maybe<&2, U32>:
    match high low:
        case None{} _: None{}
        case Some{high} None{}: None{}
        case Some{high} Some{low}: Some{hex_join(high, low)}

def hex_pair(first: Char, second: Char) -> Maybe<&2, U32>:
    hex_pair.combine(hex_nibble(Char.to_u32(first)),
        hex_nibble(Char.to_u32(second)))

def hex_pairs(chars: List<&2, Char>) -> List<&2, Maybe<&2, U32>>:
    match chars:
        case Nil{}: Nil{}
        case first <> Nil{}: [None{}]
        case first <> second <> tail:
            hex_pair(first, second) <> hex_pairs(tail)

def collect_hex.cons(pair: Maybe<&2, U32>, result: Maybe<&2, List<&2, U32>>) ->
    Maybe<&2, List<&2, U32>>:
    match pair result:
        case None{} _: None{}
        case Some{_} None{}: None{}
        case Some{byte} Some{bytes}: Some{byte <> bytes}

def collect_hex(pairs: List<&2, Maybe<&2, U32>>) -> Maybe<&2, List<&2, U32>>:
    match pairs:
        case Nil{}: Some{Nil{}}
        case pair <> tail: collect_hex.cons(pair, collect_hex(tail))

def decode_hex(text: String) -> Maybe<&2, List<&2, U32>>:
    collect_hex(hex_pairs(String.to_list(text)))

def aes_nat_eq_step(+a: Nat, +b: Nat,
                    result: Maybe<&0, {a == b : Nat}>) -> Maybe<&0, {1n+a == 1n+b : Nat}>:
    match result:
        case None{}: None{}
        case Some{proof}: Some{Equal.cong(Nat, Nat, n => 1n+n, a, b, proof)}

def aes_nat_eq_proof(+a: Nat, +b: Nat) -> Maybe<&0, {a == b : Nat}>:
    match a b:
        case 0n 0n: Some{{==}}
        case 0n 1n+p: None{}
        case 1n+p 0n: None{}
        case 1n+pa 1n+pb: aes_nat_eq_step(pa, pb, aes_nat_eq_proof(pa, pb))

def aes_bool_true_proof(+x: U32, b: Bool,
                        link: {b == U32.is_lt(x, 256) : Bool}) -> Maybe<&0, {U32.is_lt(x, 256) == True{} : Bool}>:
    match b:
        case False{}: None{}
        case True{}:
            Some{Equal.trans(Bool, U32.is_lt(x, 256), b, True{},
                Equal.sym(Bool, b, U32.is_lt(x, 256), link), {==})}

def aes_bytes_valid_cons_proof(x: U32, tail: List<&2, U32>,
    head_proof: Maybe<&0, {U32.is_lt(x, 256) == True{} : Bool}>,
    tail_proof: Maybe<&0, {bytes_valid(tail) == True{} : Bool}>) ->
    Maybe<&0, {bytes_valid(x <> tail) == True{} : Bool}>:
    match head_proof tail_proof:
        case None{} _: None{}
        case _ None{}: None{}
        case Some{hp} Some{tp}:
            Some{Equal.trans(Bool, Bool.and(U32.is_lt(x, 256), bytes_valid(tail)),
                Bool.and(True{}, bytes_valid(tail)), True{},
                Equal.cong(Bool, Bool, b => Bool.and(b, bytes_valid(tail)),
                    U32.is_lt(x, 256), True{}, hp),
                Equal.trans(Bool, Bool.and(True{}, bytes_valid(tail)),
                    bytes_valid(tail), True{}, {==}, tp))}

def aes_bytes_valid_from_bool(+bytes: List<&2, U32>, b: Bool,
    link: {b == bytes_valid(bytes) : Bool}) ->
    Maybe<&0, {bytes_valid(bytes) == True{} : Bool}>:
    match b:
        case False{}: None{}
        case True{}:
            Some{Equal.sym(Bool, True{}, bytes_valid(bytes), link)}

def aes_bytes_valid_proof(+bytes: List<&2, U32>) ->
    Maybe<&0, {bytes_valid(bytes) == True{} : Bool}>:
    aes_bytes_valid_from_bool(bytes, bytes_valid(bytes), {==})

def key_checked(bytes: List<&2, U32>, -size: {List.length(&2, U32, bytes) == 32n : Nat},
                -valid: {bytes_valid(bytes) == True{} : Bool}) -> Result<&2, &2, Error, SecretKey>:
    Done{SecretKey{bytes, size, valid}}

def key_from_proofs(+bytes: List<&2, U32>,
    size: Maybe<&0, {List.length(&2, U32, bytes) == 32n : Nat}>,
    valid: Maybe<&0, {bytes_valid(bytes) == True{} : Bool}>) -> Result<&2, &2, Error, SecretKey>:
    match size valid:
        case Some{size} Some{valid}: Done{SecretKey{bytes, size, valid}}
        case _ _: Fail{InvalidKey{}}

def key_impl(+bytes: List<&2, U32>) -> Result<&2, &2, Error, SecretKey>:
    key_from_proofs(bytes, aes_nat_eq_proof(List.length(&2, U32, bytes), 32n),
        aes_bytes_valid_proof(bytes))

def nonce_checked(bytes: List<&2, U32>, size: {List.length(&2, U32, bytes) == 12n : Nat},
                  valid: {bytes_valid(bytes) == True{} : Bool}) -> Result<&2, &2, Error, Nonce>:
    Done{Nonce{bytes, size, valid}}

def nonce_from_proofs(+bytes: List<&2, U32>,
    size: Maybe<&0, {List.length(&2, U32, bytes) == 12n : Nat}>,
    valid: Maybe<&0, {bytes_valid(bytes) == True{} : Bool}>) -> Result<&2, &2, Error, Nonce>:
    match size valid:
        case Some{size} Some{valid}: Done{Nonce{bytes, size, valid}}
        case _ _: Fail{InvalidNonce{}}

def nonce_impl(+bytes: List<&2, U32>) -> Result<&2, &2, Error, Nonce>:
    nonce_from_proofs(bytes, aes_nat_eq_proof(List.length(&2, U32, bytes), 12n),
        aes_bytes_valid_proof(bytes))

def secret_key_bytes(key: SecretKey) -> List<&2, U32>:
    match key:
        case SecretKey{bytes, size, valid}: bytes

def raw_nonce_bytes(nonce: Nonce) -> List<&2, U32>:
    match nonce:
        case Nonce{bytes, size, valid}: bytes

def tag_from_proofs(bytes: List<&2, U32>,
    size: Maybe<&0, {List.length(&2, U32, bytes) == 16n : Nat}>,
    valid: Maybe<&0, {bytes_valid(bytes) == True{} : Bool}>) -> Maybe<&2, Tag>:
    match size valid:
        case Some{size} Some{valid}: Some{Tag{bytes, size, valid}}
        case _ _: None{}

def envelope_from_proofs(nonce: Nonce, +ciphertext: List<&2, U32>, tag: Tag,
    valid: Maybe<&0, {bytes_valid(ciphertext) == True{} : Bool}>) -> Maybe<&2, Envelope>:
    match valid:
        case Some{valid}: Some{Envelope{nonce, ciphertext, tag, valid}}
        case None{}: None{}

def envelope_from_tag_proof(nonce: Nonce, +ciphertext: List<&2, U32>, tag_bytes: List<&2, U32>,
    tag: Maybe<&2, Tag>, valid: Maybe<&0, {bytes_valid(ciphertext) == True{} : Bool}>) -> Maybe<&2, Envelope>:
    match tag:
        case None{}: None{}
        case Some{tag}: envelope_from_proofs(nonce, ciphertext, tag, valid)

def envelope_from_gcm(nonce: Nonce, output: Core.GcmOutput) -> Maybe<&2, Envelope>:
    match output:
        case Core.GcmOutput{+ciphertext, ciphertext_valid,
            +tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            Some{Envelope{nonce, ciphertext,
                Tag{tag_bytes, tag_size, core_bytes_valid_proof(tag_bytes, tag_valid)},
                core_bytes_valid_proof(ciphertext, ciphertext_valid)}}

def envelope_from_gcm_checked(nonce: Nonce, output: Core.GcmOutput) -> Envelope:
    match output:
        case Core.GcmOutput{+ciphertext, ciphertext_valid,
            +tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            Envelope{nonce, ciphertext,
                Tag{tag_bytes, tag_size, core_bytes_valid_proof(tag_bytes, tag_valid)},
                core_bytes_valid_proof(ciphertext, ciphertext_valid)}

def encrypt_output(nonce: Nonce, maybe_envelope: Maybe<&2, Envelope>) -> Result<&2, &2, Error, Envelope>:
    match maybe_envelope:
        case Some{envelope}: Done{envelope}
        case None{}: Fail{InvalidBytes{}}

def encrypt_output_from_gcm(+nonce: Nonce, output: Core.GcmOutput) ->
    Result<&2, &2, Error, Envelope>:
    Done{envelope_from_gcm_checked(nonce, output)}

def encrypt_valid_output(key: SecretKey, +nonce: Nonce,
                         aad: List<&2, U32>, plaintext: List<&2, U32>) ->
    Core.GcmOutput:
    Core.gcm_encrypt_raw(secret_key_bytes(key), raw_nonce_bytes(nonce), aad, plaintext)

def encrypt_valid(key: SecretKey, +nonce: Nonce, aad: List<&2, U32>,
                  plaintext: List<&2, U32>) -> Result<&2, &2, Error, Envelope>:
    encrypt_output_from_gcm(nonce,
        encrypt_valid_output(key, nonce, aad, plaintext))

def encrypt_checked(key: SecretKey, nonce: Nonce, aad: List<&2, U32>,
                    plaintext: List<&2, U32>, aad_ok: Bool, plaintext_ok: Bool) -> Result<&2, &2, Error, Envelope>:
    match aad_ok plaintext_ok:
        case True{} True{}: encrypt_valid(key, nonce, aad, plaintext)
        case _ _: Fail{InvalidBytes{}}

def encrypt_impl(key: SecretKey, nonce: Nonce, +aad: List<&2, U32>,
            +plaintext: List<&2, U32>) -> Result<&2, &2, Error, Envelope>:
    encrypt_checked(key, nonce, aad, plaintext, aad_valid(aad), plaintext_valid(plaintext))

def bytes_difference.go(a: List<&2, U32>, b: List<&2, U32>, +difference: U32) -> U32:
    match a b:
        case Nil{} Nil{}: difference
        case x <> xs y <> ys:
            bytes_difference.go(xs, ys, U32.or(difference, U32.xor(x, y)))
        case _ _: 1

def bytes_equal_full_scan(a: List<&2, U32>, b: List<&2, U32>) -> Bool:
    U32.is_eq(bytes_difference.go(a, b, 0), 0)

def decrypt_payload(words: List<&2, U32>, envelope: Envelope) -> Result<&2, &2, Error, List<&2, U32>>:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}:
            Done{Core.gcm_decrypt_expanded(words, raw_nonce_bytes(nonce), ciphertext)}

def decrypt_auth_result(words: List<&2, U32>, envelope: Envelope, authenticated: Bool) -> Result<&2, &2, Error, List<&2, U32>>:
    match authenticated:
        case False{}: Fail{AuthenticationFailed{}}
        case True{}: decrypt_payload(words, envelope)

def decrypt_authenticated_tag(+words: List<&2, U32>,
    +nonce: List<&2, U32>, +aad: List<&2, U32>,
    +ciphertext: List<&2, U32>, +envelope: Envelope, tag: Tag) ->
    Result<&2, &2, Error, List<&2, U32>>:
    match tag:
        case Tag{tag_bytes, size, valid}:
            authenticated = bytes_equal_full_scan(tag_bytes,
                Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad,
                    ciphertext)))
            decrypt_auth_result(words, envelope, authenticated)

def decrypt_authenticated(key: SecretKey, +aad: List<&2, U32>, +envelope: Envelope) -> Result<&2, &2, Error, List<&2, U32>>:
    match key envelope:
        case SecretKey{+key_bytes, _, _} Envelope{nonce, ciphertext, +tag, _}:
            +words = Core.aes256_expand(key_bytes)
            decrypt_authenticated_tag(words, raw_nonce_bytes(nonce), aad,
                ciphertext, envelope, tag)

def decrypt_checked(+key: SecretKey, aad: List<&2, U32>, +envelope: Envelope,
                    aad_ok: Bool, ciphertext_ok: Bool) -> Result<&2, &2, Error, List<&2, U32>>:
    match aad_ok ciphertext_ok:
        case False{} _: Fail{InvalidBytes{}}
        case True{} False{}: Fail{InvalidBytes{}}
        case True{} True{}: decrypt_authenticated(key, aad, envelope)

def decrypt_impl(key: SecretKey, +aad: List<&2, U32>, +envelope: Envelope) -> Result<&2, &2, Error, List<&2, U32>>:
    decrypt_checked(key, aad, envelope, aad_valid(aad), plaintext_valid(ciphertext(envelope)))

def parse_decoded(+nonce_bytes: List<&2, U32>, +tag_bytes: List<&2, U32>, +ciphertext: List<&2, U32>,
    nonce_size: Maybe<&0, {List.length(&2, U32, nonce_bytes) == 12n : Nat}>,
    tag_size: Maybe<&0, {List.length(&2, U32, tag_bytes) == 16n : Nat}>,
    nonce_valid: Maybe<&0, {bytes_valid(nonce_bytes) == True{} : Bool}>,
    tag_valid: Maybe<&0, {bytes_valid(tag_bytes) == True{} : Bool}>,
    ciphertext_valid: Maybe<&0, {bytes_valid(ciphertext) == True{} : Bool}>) -> Result<&2, &2, Error, Envelope>:
    match nonce_size tag_size nonce_valid tag_valid ciphertext_valid:
        case Some{ns} Some{ts} Some{nv} Some{tv} Some{cv}:
            Done{Envelope{Nonce{nonce_bytes, ns, nv}, ciphertext, Tag{tag_bytes, ts, tv}, cv}}
        case _ _ _ _ _: Fail{InvalidEnvelope{}}

def parse_decoded_hex(nonce: Maybe<&2, List<&2, U32>>, tag: Maybe<&2, List<&2, U32>>,
    ciphertext: Maybe<&2, List<&2, U32>>) -> Result<&2, &2, Error, Envelope>:
    match nonce tag ciphertext:
        case Some{+n} Some{+t} Some{+c}:
            parse_decoded(n, t, c, aes_nat_eq_proof(List.length(&2, U32, n), 12n),
                aes_nat_eq_proof(List.length(&2, U32, t), 16n), aes_bytes_valid_proof(n),
                aes_bytes_valid_proof(t), aes_bytes_valid_proof(c))
        case _ _ _: Fail{InvalidEnvelope{}}

def parse_version_fields(fields: List<&2, String>) -> Result<&2, &2, Error, Envelope>:
    match fields:
        case version <> nonce_text <> tag_text <> ciphertext_text <> Nil{}:
            parse_decoded_hex(decode_hex(nonce_text), decode_hex(tag_text), decode_hex(ciphertext_text))
        case _: Fail{InvalidEnvelope{}}

def parse_version(fields: List<&2, String>, valid_version: Bool) -> Result<&2, &2, Error, Envelope>:
    match valid_version:
        case False{}: Fail{InvalidEnvelope{}}
        case True{}: parse_version_fields(fields)

def parse_string_cmp_is_eq(result: ((String & String) & Cmp)) -> Bool:
    match result:
        case ((_, _), EQ{}): True{}
        case ((_, _), _): False{}

def parse_fields(fields: List<&2, String>) -> Result<&2, &2, Error, Envelope>:
    match fields:
        case +version <> rest:
            parse_version(fields, parse_string_cmp_is_eq(String.cmp(version, "v1")))
        case Nil{}: Fail{InvalidEnvelope{}}

def parse_canonical_decision(text: String, envelope: Envelope,
    canonical: Bool) -> Result<&2, &2, Error, Envelope>:
    match canonical:
        case True{}: Done{envelope}
        case False{}: Fail{InvalidEnvelope{}}

def parse_canonical(+text: String,
    result: Result<&2, &2, Error, Envelope>) ->
    Result<&2, &2, Error, Envelope>:
    match result:
        case Fail{error}: Fail{error}
        case Done{+envelope}:
            parse_canonical_decision(text, envelope,
                String.eq(encode_impl(envelope), text))

def parse_impl(+text: String) -> Result<&2, &2, Error, Envelope>:
    parse_canonical(text, parse_fields(String.split(text, '.')))

def key(bytes):
    key_impl(bytes)

def nonce(bytes):
    nonce_impl(bytes)

def encrypt(key, nonce, aad, plaintext):
    encrypt_impl(key, nonce, aad, plaintext)

def decrypt(key, aad, envelope):
    decrypt_impl(key, aad, envelope)

def encode(envelope):
    encode_impl(envelope)

def parse(text):
    parse_impl(text)
