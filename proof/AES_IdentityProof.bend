import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_EnvelopeProof.bend as Encoding
import ./AES_ConstructorProof.bend as Constructor
import ./AES_KnownAnswerProof.bend as Known
import ./AES_MaskedXorProof.bend as Masked
import ./AES_StringEqProof.bend as Logic

def mask_word_same(+value: U32) ->
    {AES.hex_mask(value, 255) == Core.gcm_hex_mask(value, 255) : U32}:
    match value:
        case U32{WCon{b0, WCon{b1, WCon{b2, WCon{b3, WCon{b4, WCon{b5, WCon{b6, WCon{b7, WCon{b8, WCon{b9, WCon{b10, WCon{b11, WCon{b12, WCon{b13, WCon{b14, WCon{b15, WCon{b16, WCon{b17, WCon{b18, WCon{b19, WCon{b20, WCon{b21, WCon{b22, WCon{b23, WCon{b24, WCon{b25, WCon{b26, WCon{b27, WCon{b28, WCon{b29, WCon{b30, WCon{b31, WNil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}: {==}

def mask_same(+bytes: List<&2, U32>) ->
    {Encoding.aes_hex_mask_bytes(bytes) == Core.gcm_mask_bytes(bytes) : List<&2, U32>}:
    match bytes:
        case Nil{}: {==}
        case byte <> tail:
            Equal.trans(List<&2, U32>, Encoding.aes_hex_mask_bytes(byte <> tail),
                Core.gcm_hex_mask(byte, 255) <> Encoding.aes_hex_mask_bytes(tail), Core.gcm_mask_bytes(byte <> tail),
                Equal.cong(U32, List<&2, U32>, value => value <> Encoding.aes_hex_mask_bytes(tail),
                    AES.hex_mask(byte, 255), Core.gcm_hex_mask(byte, 255), mask_word_same(byte)),
                Equal.cong(List<&2, U32>, List<&2, U32>, xs => Core.gcm_hex_mask(byte, 255) <> xs,
                    Encoding.aes_hex_mask_bytes(tail), Core.gcm_mask_bytes(tail), mask_same(tail)))

def mask_identity(+bytes: List<&2, U32>, valid: {AES.bytes_valid(bytes) == True{} : Bool}) ->
    {Encoding.aes_hex_mask_bytes(bytes) == bytes : List<&2, U32>}:
    core_valid = Equal.trans(Bool, Core.gcm_bytes_valid(bytes), AES.bytes_valid(bytes), True{},
        Equal.sym(Bool, AES.bytes_valid(bytes), Core.gcm_bytes_valid(bytes), AES.core_bytes_valid_eq(bytes)), valid)
    Equal.trans(List<&2, U32>, Encoding.aes_hex_mask_bytes(bytes), Core.gcm_mask_bytes(bytes), bytes,
        mask_same(bytes), Masked.mask_bytes_identity(bytes, core_valid))

def decoded_or_empty(value: Maybe<&2, List<&2, U32>>) -> List<&2, U32>:
    match value:
        case None{}: Nil{}
        case Some{bytes}: bytes

def hex_injective(+first: List<&2, U32>, +second: List<&2, U32>,
    first_valid: {AES.bytes_valid(first) == True{} : Bool},
    second_valid: {AES.bytes_valid(second) == True{} : Bool},
    same: {AES.hex_bytes(first) == AES.hex_bytes(second) : String}) ->
    {first == second : List<&2, U32>}:
    decoded = Equal.trans(Maybe<&2, List<&2, U32>>,
        Some{Encoding.aes_hex_mask_bytes(first)}, AES.decode_hex(AES.hex_bytes(first)),
        Some{Encoding.aes_hex_mask_bytes(second)},
        Equal.sym(Maybe<&2, List<&2, U32>>, AES.decode_hex(AES.hex_bytes(first)),
            Some{Encoding.aes_hex_mask_bytes(first)}, Encoding.aes_decode_hex_bytes(first)),
        Equal.trans(Maybe<&2, List<&2, U32>>, AES.decode_hex(AES.hex_bytes(first)),
            AES.decode_hex(AES.hex_bytes(second)), Some{Encoding.aes_hex_mask_bytes(second)},
            Equal.cong(String, Maybe<&2, List<&2, U32>>, AES.decode_hex,
                AES.hex_bytes(first), AES.hex_bytes(second), same), Encoding.aes_decode_hex_bytes(second)))
    masks_equal = Equal.cong(Maybe<&2, List<&2, U32>>, List<&2, U32>, decoded_or_empty,
        Some{Encoding.aes_hex_mask_bytes(first)}, Some{Encoding.aes_hex_mask_bytes(second)}, decoded)
    Equal.trans(List<&2, U32>, first, Encoding.aes_hex_mask_bytes(first), second,
        Equal.sym(List<&2, U32>, Encoding.aes_hex_mask_bytes(first), first, mask_identity(first, first_valid)),
        Equal.trans(List<&2, U32>, Encoding.aes_hex_mask_bytes(first), Encoding.aes_hex_mask_bytes(second),
            second, masks_equal, mask_identity(second, second_valid)))

def fields(+envelope: AES.Envelope) -> List<&2, String>:
    ["v1", AES.hex_bytes(AES.fixed_bytes(12n, AES.nonce_bytes(AES.envelope_nonce(envelope)))),
        AES.hex_bytes(AES.fixed_bytes(16n, AES.tag_bytes(AES.envelope_tag(envelope)))),
        AES.hex_bytes(AES.ciphertext(envelope))]

def optional_text(value: Maybe<&2, String>) -> String:
    match value:
        case None{}: ""
        case Some{text}: text

def field_text(index: Nat, parts: List<&2, String>) -> String:
    optional_text(List.get(&2, String, parts, index))

def result_text(value: Result<&2, &2, AES.Error, String>) -> String:
    match value:
        case Fail{error}: ""
        case Done{text}: text

def fields_equal(+first: AES.Envelope, +second: AES.Envelope,
    same: {AES.encode(first) == AES.encode(second) : String}) ->
    {fields(first) == fields(second) : List<&2, String>}:
    Equal.trans(List<&2, String>, fields(first), String.split(AES.encode(first), Chr{46}), fields(second),
        Equal.sym(List<&2, String>, String.split(AES.encode(first), Chr{46}), fields(first),
            Encoding.aes_encode_fields_split(first)),
        Equal.trans(List<&2, String>, String.split(AES.encode(first), Chr{46}),
            String.split(AES.encode(second), Chr{46}), fields(second),
            Equal.cong(String, List<&2, String>, text => String.split(text, Chr{46}),
                AES.encode(first), AES.encode(second), same), Encoding.aes_encode_fields_split(second)))

def fixed_hex_equal(+n: Nat, +first: List<&2, U32>, +second: List<&2, U32>,
    first_size: {List.length(&2, U32, first) == n : Nat},
    second_size: {List.length(&2, U32, second) == n : Nat},
    same: {AES.hex_bytes(AES.fixed_bytes(n, first)) == AES.hex_bytes(AES.fixed_bytes(n, second)) : String}) ->
    {AES.hex_bytes(first) == AES.hex_bytes(second) : String}:
    first_path = Equal.cong(List<&2, U32>, String, bytes => AES.hex_bytes(bytes),
        AES.fixed_bytes(n, first), first, Encoding.aes_fixed_bytes_identity(n, first, first_size))
    second_path = Equal.cong(List<&2, U32>, String, bytes => AES.hex_bytes(bytes),
        AES.fixed_bytes(n, second), second, Encoding.aes_fixed_bytes_identity(n, second, second_size))
    Equal.trans(String, AES.hex_bytes(first), AES.hex_bytes(AES.fixed_bytes(n, first)), AES.hex_bytes(second),
        Equal.sym(String, AES.hex_bytes(AES.fixed_bytes(n, first)), AES.hex_bytes(first), first_path),
        Equal.trans(String, AES.hex_bytes(AES.fixed_bytes(n, first)), AES.hex_bytes(AES.fixed_bytes(n, second)),
            AES.hex_bytes(second), same, second_path))

def encode_injective(+first: AES.Envelope, +second: AES.Envelope,
    same: {AES.encode(first) == AES.encode(second) : String}) -> {first == second : AES.Envelope}:
    match first second:
        case AES.Envelope{AES.Nonce{+bytes_a, +size_a, +nonce_valid_a},
                 +cipher_a, AES.Tag{+tag_bytes_a, +tag_size_a, +tag_valid_a}, +valid_a}
             AES.Envelope{AES.Nonce{+bytes_b, +size_b, +nonce_valid_b},
                 +cipher_b, AES.Tag{+tag_bytes_b, +tag_size_b, +tag_valid_b}, +valid_b}:
            +size_a_copy = size_a
            +size_b_copy = size_b
            +nonce_valid_a_copy = nonce_valid_a
            +nonce_valid_b_copy = nonce_valid_b
            +nonce_a = {AES.Nonce{bytes_a, size_a_copy, nonce_valid_a_copy} : AES.Nonce}
            +nonce_b = {AES.Nonce{bytes_b, size_b_copy, nonce_valid_b_copy} : AES.Nonce}
            +tag_a = {AES.Tag{tag_bytes_a, tag_size_a, tag_valid_a} : AES.Tag}
            +tag_b = {AES.Tag{tag_bytes_b, tag_size_b, tag_valid_b} : AES.Tag}
            +parts_same = fields_equal(first, second, same)
            nonce_hex = Equal.cong(List<&2, String>, String, parts => field_text(1n, parts),
                fields(first), fields(second), parts_same)
            tag_hex = Equal.cong(List<&2, String>, String, parts => field_text(2n, parts),
                fields(first), fields(second), parts_same)
            cipher_hex = Equal.cong(List<&2, String>, String, parts => field_text(3n, parts),
                fields(first), fields(second), parts_same)
            nonce_bytes_same = hex_injective(bytes_a, bytes_b, nonce_valid_a_copy, nonce_valid_b_copy,
                fixed_hex_equal(12n, bytes_a, bytes_b, size_a_copy, size_b_copy, nonce_hex))
            tag_bytes_same = hex_injective(tag_bytes_a, tag_bytes_b, tag_valid_a, tag_valid_b,
                fixed_hex_equal(16n, tag_bytes_a, tag_bytes_b, tag_size_a, tag_size_b, tag_hex))
            cipher_same = hex_injective(cipher_a, cipher_b, valid_a, valid_b, cipher_hex)
            nonce_same = Constructor.nonce_equal(bytes_a, size_a_copy, nonce_valid_a_copy, bytes_b,
                nonce_bytes_same, size_b_copy, nonce_valid_b_copy)
            tag_same = Known.tag_equal(tag_bytes_a, tag_size_a, tag_valid_a, tag_bytes_b,
                tag_bytes_same, tag_size_b, tag_valid_b)
            fields_same = Known.envelope_equal(nonce_a, cipher_a, tag_a, valid_a,
                cipher_b, tag_b, cipher_same, tag_same, valid_b)
            Equal.trans(AES.Envelope, first, AES.Envelope{nonce_a, cipher_b, tag_b, valid_b}, second,
                fields_same, Equal.cong(AES.Nonce, AES.Envelope,
                    nonce => AES.Envelope{nonce, cipher_b, tag_b, valid_b}, nonce_a, nonce_b, nonce_same))

def exact_roundtrip_result(+envelope: AES.Envelope,
    result: Result<&2, &2, AES.Error, AES.Envelope>,
    encoded: {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode, result) ==
        Done{AES.encode(envelope)} : Result<&2, &2, AES.Error, String>}) ->
    {result == Done{envelope} : Result<&2, &2, AES.Error, AES.Envelope>}:
    match result:
        case Fail{error}:
            status = Equal.cong(Result<&2, &2, AES.Error, String>, Bool,
                value => Result.is_done(&2, &2, AES.Error, String, value),
                Fail{error}, Done{AES.encode(envelope)}, encoded)
            Empty.absurd({Fail{error} == Done{envelope} : Result<&2, &2, AES.Error, AES.Envelope>},
                Logic.false_true(status))
        case Done{+found}:
            text_same = Equal.cong(Result<&2, &2, AES.Error, String>, String,
                result_text,
                Done{AES.encode(found)}, Done{AES.encode(envelope)}, encoded)
            Equal.cong(AES.Envelope, Result<&2, &2, AES.Error, AES.Envelope>, value => Done{value},
                found, envelope, encode_injective(found, envelope, text_same))

def exact_roundtrip(+envelope: AES.Envelope) ->
    {AES.parse(AES.encode(envelope)) == Done{envelope} : Result<&2, &2, AES.Error, AES.Envelope>}:
    exact_roundtrip_result(envelope, AES.parse(AES.encode(envelope)), Encoding.aes_envelope_roundtrip(envelope))
