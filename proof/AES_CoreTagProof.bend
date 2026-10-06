import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core

def output_ciphertext(output: Core.GcmOutput) -> List<&2, U32>:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            ciphertext

def output_tag(output: Core.GcmOutput) -> List<&2, U32>:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            tag_bytes

def output_tag_words(output: Core.GcmOutput) -> List<&2, U32>:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_words

def output_tag_nonce(output: Core.GcmOutput) -> List<&2, U32>:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_nonce

def output_tag_aad(output: Core.GcmOutput) -> List<&2, U32>:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_aad

def output_tag_ciphertext(output: Core.GcmOutput) -> List<&2, U32>:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            ciphertext

def output_from_ciphertext_matches(+words: List<&2, U32>,
    +nonce: List<&2, U32>, +aad: List<&2, U32>,
    +cipher_output: Core.GcmCiphertext) ->
    {output_ciphertext(Core.gcm_output_from_ciphertext(words, nonce, aad,
        cipher_output)) == Core.gcm_ciphertext_bytes(cipher_output) :
        List<&2, U32>}:
    match cipher_output:
        case Core.GcmCiphertext{bytes, valid}: {==}



def output_ciphertext_valid(+output: Core.GcmOutput) ->
    {Core.gcm_bytes_valid(output_ciphertext(output)) == True{} : Bool}:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            ciphertext_valid

def output_tag_valid(+output: Core.GcmOutput) ->
    {Core.gcm_bytes_valid(output_tag(output)) == True{} : Bool}:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            tag_valid

def envelope_gcm_ciphertext(nonce: AES.Nonce,
    output: Core.GcmOutput) ->
    {AES.ciphertext(AES.envelope_from_gcm_checked(nonce, output)) ==
     output_ciphertext(output) : List<&2, U32>}:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}: {==}

def envelope_gcm_tag(nonce: AES.Nonce,
    output: Core.GcmOutput) ->
    {AES.tag_bytes(AES.envelope_tag(
        AES.envelope_from_gcm_checked(nonce, output))) ==
     output_tag(output) : List<&2, U32>}:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}: {==}

def envelope_gcm_nonce(nonce: AES.Nonce,
    output: Core.GcmOutput) ->
    {AES.raw_nonce_bytes(AES.envelope_nonce(
        AES.envelope_from_gcm_checked(nonce, output))) ==
     AES.raw_nonce_bytes(nonce) : List<&2, U32>}:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}: {==}

def raw_encrypt_output_ciphertext(+key: List<&2, U32>,
    +nonce: List<&2, U32>, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>) ->
    {output_ciphertext(Core.gcm_encrypt_raw(key, nonce, aad, plaintext)) ==
     Core.gcm_zip_xor(plaintext,
        Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
            Core.aes256_expand(key),
            Core.gcm_inc32(Core.gcm_j0(nonce)))) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        output_ciphertext(Core.gcm_encrypt_raw(key, nonce, aad, plaintext)),
        Core.gcm_ciphertext_bytes(Core.gcm_ctr_encrypt(
            Core.aes256_expand(key), nonce, plaintext)),
        Core.gcm_zip_xor(plaintext,
            Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
                Core.aes256_expand(key),
                Core.gcm_inc32(Core.gcm_j0(nonce)))),
        output_from_ciphertext_matches(Core.aes256_expand(key), nonce, aad,
            Core.gcm_ctr_encrypt(Core.aes256_expand(key), nonce, plaintext)),
        {==})
