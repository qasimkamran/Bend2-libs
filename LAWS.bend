# Library correctness laws and integration obligations.

import Base

# JSON contract: libs/JSON.bend.
#
# Expected API:
#   Json.parse(text: String) -> Result<&1, &1, Json.Error, Json.Value>
#   Json.stringify(value: Json.Value) -> String

import ./libs/JSON.bend as Json
import ./libs/URL.bend as URL
import ./libs/AES256GCM.bend as AES

# ============================================================
# JSON: Core correctness
# ============================================================

law stringify_parse_roundtrip:
    for value: Json.Value {
        Json.parse(Json.stringify(value))
        ==
        Done{value}
        :
        Result<&1, &1, Json.Error, Json.Value>
    }

# ============================================================
# JSON: Literals
# ============================================================

law parses_null:
    { Json.parse("null") == Done{Json.Null{}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_true:
    { Json.parse("true") == Done{Json.Bool{True{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_false:
    { Json.parse("false") == Done{Json.Bool{False{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

# ============================================================
# JSON: Whitespace
# ============================================================

law accepts_leading_space:
    for value: Json.Value {
        Json.parse(" " ++ Json.stringify(value)) == Done{value} :
        Result<&1, &1, Json.Error, Json.Value>
    }

law accepts_trailing_space:
    for value: Json.Value {
        Json.parse(Json.stringify(value) ++ " ") == Done{value} :
        Result<&1, &1, Json.Error, Json.Value>
    }

law accepts_surrounding_space:
    for value: Json.Value {
        Json.parse(" \n\t\r" ++ Json.stringify(value) ++ "\r\t\n ") == Done{value} :
        Result<&1, &1, Json.Error, Json.Value>
    }

# ============================================================
# JSON: Invalid and incomplete input
# ============================================================

law rejects_trailing_garbage:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("nullx"))
        == True{} : Bool }

law rejects_second_value:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("null true"))
        == True{} : Bool }

law rejects_invalid_null:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("nul"))
        == True{} : Bool }

law rejects_invalid_true:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("tru"))
        == True{} : Bool }

law rejects_invalid_false:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("fals"))
        == True{} : Bool }

law rejects_empty_input:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse(""))
        == True{} : Bool }

law rejects_whitespace_only:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse(" \t\r\n "))
        == True{} : Bool }

# ============================================================
# JSON: Strings
# ============================================================

law parses_empty_string:
    { Json.parse("\"\"") == Done{Json.Str{""}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_simple_string:
    { Json.parse("\"hello\"") == Done{Json.Str{"hello"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_newline_escape:
    { Json.parse("\"a\\nb\"") == Done{Json.Str{"a\nb"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_quote_escape:
    { Json.parse("\"a\\\"b\"") == Done{Json.Str{"a\"b"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_backslash_escape:
    { Json.parse("\"a\\\\b\"") == Done{Json.Str{"a\\b"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law rejects_unterminated_string:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("\"hello"))
        == True{} : Bool }

# ============================================================
# JSON: Arrays
# ============================================================

law parses_empty_array:
    { Json.parse("[]") == Done{Json.Arr{Nil{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_literal_array:
    {
        Json.parse("[null,true,false]")
        ==
        Done{Json.Arr{
            Json.Null{} <>
            Json.Bool{True{}} <>
            Json.Bool{False{}} <>
            Nil{}
        }}
        :
        Result<&1, &1, Json.Error, Json.Value>
    }

law rejects_array_trailing_comma:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("[null,]"))
        == True{} : Bool }

# ============================================================
# JSON: Objects
# ============================================================

law parses_empty_object:
    { Json.parse("{}") == Done{Json.Obj{Nil{}}} :
        Result<&1, &1, Json.Error, Json.Value> }

law rejects_unquoted_object_key:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("{foo:null}"))
        == True{} : Bool }

law rejects_object_trailing_comma:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("{\"x\":null,}"))
        == True{} : Bool }

# ============================================================
# JSON: Nesting
# ============================================================

law parses_nested_containers:
    {
        Json.parse("[{\"x\":[true,null]}]")
        ==
        Done{Json.Arr{
            Json.Obj{
                ("x", Json.Arr{
                    Json.Bool{True{}} <>
                    Json.Null{} <>
                    Nil{}
                }) <>
                Nil{}
            } <>
            Nil{}
        }}
        :
        Result<&1, &1, Json.Error, Json.Value>
    }

# ============================================================
# JSON: Additional semantics
# ============================================================

# JSON permits only space, tab, carriage return and line feed as whitespace.
law rejects_non_json_whitespace:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("\u{000b}null"))
        == True{} : Bool }

# A raw control character is forbidden inside a JSON string.
law rejects_raw_string_control:
    { Result.is_fail(&1, &1, Json.Error, Json.Value,
            Json.parse("\"" ++ "\u{0001}" ++ "\""))
        == True{} : Bool }

# Unicode escapes decode to their scalar value, including a surrogate pair.
law parses_unicode_escape:
    { Json.parse("\"\\u263A\"") == Done{Json.Str{"\u{263a}"}} :
        Result<&1, &1, Json.Error, Json.Value> }

law parses_unicode_surrogate_pair:
    { Json.parse("\"\\uD83D\\uDE00\"") == Done{Json.Str{"\u{1f600}"}} :
        Result<&1, &1, Json.Error, Json.Value> }

# This representative decimal/exponent form is accepted. A separate law below
# checks that the smart number constructor preserves the original lexeme.
law parses_fraction_and_exponent:
    { Result.is_done(&1, &1, Json.Error, Json.Value, Json.parse("-12.50e+3"))
        == True{} : Bool }

law rejects_malformed_number_forms:
    { Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("01"))
        && Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("1."))
        && Result.is_fail(&1, &1, Json.Error, Json.Value, Json.parse("1e+"))
        == True{} : Bool }

# Arrays retain source order. Objects retain source order and duplicate keys;
# consumers that need map semantics must choose their own duplicate-key policy.
law preserves_array_order:
    { Json.parse("[3,1,2]") == Done{Json.Arr{
            Json.Number{"3", Json.Certified{Json.number_proof("3", {==})}} <>
            Json.Number{"1", Json.Certified{Json.number_proof("1", {==})}} <>
            Json.Number{"2", Json.Certified{Json.number_proof("2", {==})}} <>
            Nil{}
        }} : Result<&1, &1, Json.Error, Json.Value> }

law preserves_object_order_and_duplicates:
    { Json.parse("{\"x\":1,\"x\":2}") == Done{Json.Obj{
            ("x", Json.Number{"1", Json.Certified{Json.number_proof("1", {==})}}) <>
            ("x", Json.Number{"2", Json.Certified{Json.number_proof("2", {==})}}) <>
            Nil{}
        }} : Result<&1, &1, Json.Error, Json.Value> }

# GPU entry points have the same specified results as their CPU counterparts.
law gpu_single_matches_cpu:
    for text: String {
        Json.parse_gpu(text) == Json.parse(text) :
        Result<&1, &1, Json.Error, Json.Value>
    }

law preserves_number_lexeme:
    { Json.number("-12.50e+3") == Done{Json.Number{
            "-12.50e+3",
            Json.Certified{Json.number_proof("-12.50e+3", {==})}
        }} : Result<&1, &1, Json.Error, Json.Value> }

law gpu_batch_matches_cpu:
    for batch: Json.Batch {
        Json.parse_batch_gpu(batch) == Json.parse_batch(batch) : Json.BatchResult
    }

# ============================================================
# URL component encoding
# ============================================================

# Encode each UTF-8 byte with an uppercase percent escape.
law url_component_ascii:
    { URL.percent_component("A") == "%41" : String }

law url_component_reserved:
    { URL.percent_component("/") == "%2F" : String }

law url_component_utf8:
    { URL.percent_component(SCon{Chr{233}, SNil{}}) == "%C3%A9" : String }


# ============================================================
# AES-256-GCM: validated keys and nonces
# ============================================================

law aes256gcm_accepts_32_byte_key:
    for +bytes: List<&2, U32>
    for size: {List.length(&2, U32, bytes) == 32n : Nat}
    for valid: {AES.bytes_valid(bytes) == True{} : Bool}
    {AES.key(bytes) == Done{AES.SecretKey{bytes, size, valid}} :
        Result<&2, &2, AES.Error, AES.SecretKey>}

law aes256gcm_rejects_wrong_key_length:
    for +bytes: List<&2, U32>
    for size: {List.length(&2, U32, bytes) != 32n : Nat}
    {AES.key(bytes) == Fail{AES.InvalidKey{}} :
        Result<&2, &2, AES.Error, AES.SecretKey>}

law aes256gcm_rejects_non_byte_key:
    for +bytes: List<&2, U32>
    for valid: {AES.bytes_valid(bytes) == False{} : Bool}
    {AES.key(bytes) == Fail{AES.InvalidKey{}} :
        Result<&2, &2, AES.Error, AES.SecretKey>}

law aes256gcm_accepts_12_byte_nonce:
    for +bytes: List<&2, U32>
    for size: {List.length(&2, U32, bytes) == 12n : Nat}
    for valid: {AES.bytes_valid(bytes) == True{} : Bool}
    {AES.nonce(bytes) == Done{AES.Nonce{bytes, size, valid}} :
        Result<&2, &2, AES.Error, AES.Nonce>}

law aes256gcm_rejects_wrong_nonce_length:
    for +bytes: List<&2, U32>
    for size: {List.length(&2, U32, bytes) != 12n : Nat}
    {AES.nonce(bytes) == Fail{AES.InvalidNonce{}} :
        Result<&2, &2, AES.Error, AES.Nonce>}

law aes256gcm_rejects_non_byte_nonce:
    for +bytes: List<&2, U32>
    for valid: {AES.bytes_valid(bytes) == False{} : Bool}
    {AES.nonce(bytes) == Fail{AES.InvalidNonce{}} :
        Result<&2, &2, AES.Error, AES.Nonce>}

# ============================================================
# AES-256-GCM: encryption and authenticated decryption
# ============================================================

# This prevents satisfying the conditional roundtrip by always failing.
law aes256gcm_encrypts_valid_input:
    for key: AES.SecretKey
    for nonce: AES.Nonce
    for aad: List<&2, U32>
    for plaintext: List<&2, U32>
    for aad_ok: {AES.aad_valid(aad) == True{} : Bool}
    for plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool}
    {Result.is_done(&2, &2, AES.Error, AES.Envelope,
        AES.encrypt(key, nonce, aad, plaintext)) == True{} : Bool}

law aes256gcm_rejects_invalid_plaintext:
    for +key: AES.SecretKey
    for +nonce: AES.Nonce
    for +aad: List<&2, U32>
    for +plaintext: List<&2, U32>
    for valid: {AES.plaintext_valid(plaintext) == False{} : Bool}
    {AES.encrypt(key, nonce, aad, plaintext) == Fail{AES.InvalidBytes{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_invalid_aad:
    for +key: AES.SecretKey
    for +nonce: AES.Nonce
    for +aad: List<&2, U32>
    for +plaintext: List<&2, U32>
    for valid: {AES.aad_valid(aad) == False{} : Bool}
    {AES.encrypt(key, nonce, aad, plaintext) == Fail{AES.InvalidBytes{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_decrypt_rejects_invalid_aad:
    for +key: AES.SecretKey
    for +aad: List<&2, U32>
    for +envelope: AES.Envelope
    for valid: {AES.aad_valid(aad) == False{} : Bool}
    {AES.decrypt(key, aad, envelope) == Fail{AES.InvalidBytes{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

law aes256gcm_roundtrip:
    for +key: AES.SecretKey
    for +nonce: AES.Nonce
    for +aad: List<&2, U32>
    for +plaintext: List<&2, U32>
    for +envelope: AES.Envelope
    for encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}
    {AES.decrypt(key, aad, envelope) == Done{plaintext} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

law aes256gcm_preserves_nonce:
    for +key: AES.SecretKey
    for +nonce: AES.Nonce
    for +aad: List<&2, U32>
    for +plaintext: List<&2, U32>
    for +envelope: AES.Envelope
    for encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}
    {AES.envelope_nonce(envelope) == nonce : AES.Nonce}

law aes256gcm_preserves_plaintext_length:
    for +key: AES.SecretKey
    for +nonce: AES.Nonce
    for +aad: List<&2, U32>
    for +plaintext: List<&2, U32>
    for +envelope: AES.Envelope
    for encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}
    {List.length(&2, U32, AES.ciphertext(envelope)) ==
        List.length(&2, U32, plaintext) : Nat}

# For fixed key, nonce, AAD, and ciphertext there is exactly one valid tag.
# Different ciphertext/AAD/key/nonce can collide in a finite tag space; do not
# claim that every possible change to those fields is mathematically rejected.
law aes256gcm_rejects_changed_tag:
    for +key: AES.SecretKey
    for +nonce: AES.Nonce
    for +aad: List<&2, U32>
    for +plaintext: List<&2, U32>
    for +envelope: AES.Envelope
    for +tampered: AES.Envelope
    for encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}
    for same_nonce: {AES.envelope_nonce(tampered) ==
        AES.envelope_nonce(envelope) : AES.Nonce}
    for same_ciphertext: {AES.ciphertext(tampered) ==
        AES.ciphertext(envelope) : List<&2, U32>}
    for changed_tag: {AES.tag_bytes(AES.envelope_tag(tampered)) !=
        AES.tag_bytes(AES.envelope_tag(envelope)) : List<&2, U32>}
    {AES.decrypt(key, aad, tampered) == Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

# ============================================================
# AES-256-GCM: strict, canonical versioned envelope
# ============================================================

law aes256gcm_envelope_roundtrip:
    for +envelope: AES.Envelope
    {AES.parse(AES.encode(envelope)) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_envelope_is_canonical:
    for +text: String
    for +envelope: AES.Envelope
    for parsed: {AES.parse(text) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}
    {AES.encode(envelope) == text : String}

law aes256gcm_rejects_empty_envelope:
    {AES.parse("") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_unknown_version:
    {AES.parse("v2.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_missing_version:
    {AES.parse("cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_short_nonce:
    {AES.parse("v1.cafebabefacedbaddecaf8.fd2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_long_nonce:
    {AES.parse("v1.cafebabefacedbaddecaf88800.fd2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_short_tag:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_long_tag:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e00.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_odd_ciphertext_hex:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.0") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_non_hex_ciphertext:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.gg") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_non_hex_nonce:
    {AES.parse("v1.zzfebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_non_hex_tag:
    {AES.parse("v1.cafebabefacedbaddecaf888.zz2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_uppercase_hex:
    {AES.parse("v1.CAFEBABEFACEDBADDECAF888.fd2caa16a5832e76aa132c1453eeda7e.") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_extra_field:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e..") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_missing_ciphertext_field:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_trailing_garbage:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.00!") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

law aes256gcm_rejects_surrounding_whitespace:
    {AES.parse(" v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e. ") == Fail{AES.InvalidEnvelope{}} :
        Result<&2, &2, AES.Error, AES.Envelope>}

# ============================================================
# AES-256-GCM: NIST known-answer laws (not roundtrip-only tests)
# ============================================================
# Source: NIST AES_GCM.pdf, GCM-AES256 examples 1-5 (pages 21-28).
# https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_GCM.pdf
# These are public test fixtures, never production keys/nonces.

def aes256gcm_nist_key() -> AES.SecretKey:
    AES.SecretKey{[254, 255, 233, 146, 134, 101, 115, 28, 109, 106, 143, 148, 103, 48, 131, 8, 254, 255, 233, 146, 134, 101, 115, 28, 109, 106, 143, 148, 103, 48, 131, 8], {==}, {==}}

def aes256gcm_nist_nonce() -> AES.Nonce:
    AES.Nonce{[202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136], {==}, {==}}

def aes256gcm_nist_empty() -> AES.Envelope:
    AES.Envelope{aes256gcm_nist_nonce(), [],
        AES.Tag{[253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126], {==}, {==}}, {==}}

# Compare the protocol-visible result while leaving internal certificate terms
# out of the NIST contract: success, nonce bytes, ciphertext, and tag bytes.
def aes256gcm_nist_encrypt_observation(result: Result<&2, &2, AES.Error, AES.Envelope>) -> List<&2, U32>:
    match result:
        case Fail{error}: []
        case Done{envelope}:
            match envelope:
                case AES.Envelope{nonce, ciphertext, tag, valid}:
                    match nonce tag:
                        case AES.Nonce{nonce_bytes, nonce_size, nonce_valid}
                             AES.Tag{tag_bytes, tag_size, tag_valid}:
                            List.append(&2, U32, nonce_bytes,
                                List.append(&2, U32, ciphertext, tag_bytes))

law aes256gcm_nist_empty_encrypt:
    {aes256gcm_nist_encrypt_observation(AES.encrypt(aes256gcm_nist_key(), aes256gcm_nist_nonce(),
        [], [])) == aes256gcm_nist_encrypt_observation(Done{aes256gcm_nist_empty()}) :
        List<&2, U32>}

law aes256gcm_nist_empty_decrypt:
    {AES.decrypt(aes256gcm_nist_key(), [],
        aes256gcm_nist_empty()) == Done{[]} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

def aes256gcm_nist_multiblock() -> AES.Envelope:
    AES.Envelope{aes256gcm_nist_nonce(), [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132, 66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162, 189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167, 176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122, 10, 188, 201, 246, 98, 137, 128, 21, 173],
        AES.Tag{[176, 148, 218, 197, 217, 52, 113, 189, 236, 26, 80, 34, 112, 227, 204, 108], {==}, {==}}, {==}}

law aes256gcm_nist_multiblock_encrypt:
    {aes256gcm_nist_encrypt_observation(AES.encrypt(aes256gcm_nist_key(), aes256gcm_nist_nonce(),
        [], [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85])) == aes256gcm_nist_encrypt_observation(Done{aes256gcm_nist_multiblock()}) :
        List<&2, U32>}

law aes256gcm_nist_multiblock_decrypt:
    {AES.decrypt(aes256gcm_nist_key(), [],
        aes256gcm_nist_multiblock()) == Done{[217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85]} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

def aes256gcm_nist_aad_only() -> AES.Envelope:
    AES.Envelope{aes256gcm_nist_nonce(), [],
        AES.Tag{[222, 52, 182, 220, 212, 206, 226, 253, 190, 195, 206, 160, 26, 241, 238, 68], {==}, {==}}, {==}}

law aes256gcm_nist_aad_only_encrypt:
    {aes256gcm_nist_encrypt_observation(AES.encrypt(aes256gcm_nist_key(), aes256gcm_nist_nonce(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212], [])) == aes256gcm_nist_encrypt_observation(Done{aes256gcm_nist_aad_only()}) :
        List<&2, U32>}

law aes256gcm_nist_aad_only_decrypt:
    {AES.decrypt(aes256gcm_nist_key(), [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212],
        aes256gcm_nist_aad_only()) == Done{[]} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

def aes256gcm_nist_aad_and_multiblock() -> AES.Envelope:
    AES.Envelope{aes256gcm_nist_nonce(), [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132, 66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162, 189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167, 176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122, 10, 188, 201, 246, 98, 137, 128, 21, 173],
        AES.Tag{[192, 109, 118, 243, 25, 48, 254, 243, 122, 202, 226, 62, 212, 101, 174, 98], {==}, {==}}, {==}}

law aes256gcm_nist_aad_and_multiblock_encrypt:
    {aes256gcm_nist_encrypt_observation(AES.encrypt(aes256gcm_nist_key(), aes256gcm_nist_nonce(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212], [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85])) == aes256gcm_nist_encrypt_observation(Done{aes256gcm_nist_aad_and_multiblock()}) :
        List<&2, U32>}

law aes256gcm_nist_aad_and_multiblock_decrypt:
    {AES.decrypt(aes256gcm_nist_key(), [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212],
        aes256gcm_nist_aad_and_multiblock()) == Done{[217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85]} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

def aes256gcm_nist_partial_block() -> AES.Envelope:
    AES.Envelope{aes256gcm_nist_nonce(), [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132, 66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162, 189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167, 176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122, 10, 188, 201, 246, 98],
        AES.Tag{[224, 151, 25, 95, 69, 50, 218, 137, 95, 185, 23, 165, 165, 92, 106, 160], {==}, {==}}, {==}}

law aes256gcm_nist_partial_block_encrypt:
    {aes256gcm_nist_encrypt_observation(AES.encrypt(aes256gcm_nist_key(), aes256gcm_nist_nonce(),
        [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133], [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57])) == aes256gcm_nist_encrypt_observation(Done{aes256gcm_nist_partial_block()}) :
        List<&2, U32>}

law aes256gcm_nist_partial_block_decrypt:
    {AES.decrypt(aes256gcm_nist_key(), [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133],
        aes256gcm_nist_partial_block()) == Done{[217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57]} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

law aes256gcm_nist_canonical_encoding:
    {AES.encode(aes256gcm_nist_empty()) == "v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e." : String}

law aes256gcm_nist_canonical_parsing:
    {AES.parse("v1.cafebabefacedbaddecaf888.fd2caa16a5832e76aa132c1453eeda7e.") == Done{aes256gcm_nist_empty()} :
        Result<&2, &2, AES.Error, AES.Envelope>}

# Concrete tamper checks supplement tag uniqueness without claiming collision-
# free authentication for all distinct AAD, nonce, key, or ciphertext inputs.
law aes256gcm_nist_rejects_changed_aad:
    {AES.decrypt(aes256gcm_nist_key(), [1], aes256gcm_nist_empty()) ==
        Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

law aes256gcm_nist_rejects_changed_key:
    {AES.decrypt(AES.SecretKey{List.replicate(U32, 32n, 0), {==}, {==}},
        [], aes256gcm_nist_empty()) == Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

law aes256gcm_nist_rejects_changed_nonce:
    {AES.decrypt(aes256gcm_nist_key(), [],
        AES.Envelope{AES.Nonce{List.replicate(U32, 12n, 0), {==}, {==}},
            [], AES.Tag{[253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126], {==}, {==}}, {==}}) ==
        Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

law aes256gcm_nist_rejects_changed_ciphertext:
    {AES.decrypt(aes256gcm_nist_key(), [],
        AES.Envelope{aes256gcm_nist_nonce(), [1],
            AES.Tag{[253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126], {==}, {==}}, {==}}) ==
        Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}

# DirectH1 integration obligations (effectful behavior, not formal proofs):
# - HTTP/1.1 only; never negotiate HTTP/2 or bypass TLS chain/hostname checks.
# - Reuse pinned upstream codecs, framing and redirect credential stripping.
# - Active requests/pools own their sockets; failures, expiry, eviction and
#   explicit pool.close release them. Never drop a pool without closing it.
# - Pool keys include origin and client identity; idle count is globally bounded.
# - Only self-delimited HTTP/1.1 responses can return a socket to the pool.
# - Do not reuse close-delimited/HTTP1.0/upgrade/trailing-byte/Connection:close
#   responses. Connection tokens are normalized across all repeated fields.
# - Stale reuse retries at most once, only for idempotent methods with no
#   response bytes. Never retry POST/PATCH or reset the shared deadline.
# - Clamp reads/writes/dial/TLS to finite phase and remaining total budgets.
# - Never interpret exhausted total budget as socket timeout zero (unlimited).
# - Bound header/wire reads, reject oversized Content-Length before retention,
#   and count fresh body fragments before retaining/concatenating them.
# - DNS/decompression run in a deadline-bound Bend child. Timeout terminates
#   and reaps the child; never replace this with an uncancelled IO.within race.
# - Parent parsing/serialization/cleanup are not preemptible: do not claim
#   strict real-time return latency for total_ms.
# - Decoded allocation retains upstream's 16 MiB cap; smaller body caps are
#   post-decode checks. Do not advertise them as decoder allocation limits.
# - Concurrent batches own separate sockets and preserve result input order.
