import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_TagCompareProof.bend as Compare

def rejects_comparison(+words: List<&2, U32>,
    +envelope: AES.Envelope, +supplied: List<&2, U32>,
    +expected: List<&2, U32>,
    changed: {supplied != expected : List<&2, U32>}) ->
    {AES.decrypt_auth_result(words, envelope,
        AES.bytes_equal_full_scan(supplied, expected)) ==
     Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    Equal.cong(Bool, Result<&2, &2, AES.Error, List<&2, U32>>,
        authenticated => AES.decrypt_auth_result(words, envelope,
            authenticated),
        AES.bytes_equal_full_scan(supplied, expected), False{},
        Compare.unequal_is_false(supplied, expected, changed))

def rejects_tag(+words: List<&2, U32>, +nonce: List<&2, U32>,
    +aad: List<&2, U32>, +ciphertext: List<&2, U32>,
    +envelope: AES.Envelope, +tag: AES.Tag,
    +original: List<&2, U32>,
    canonical: {original == Core.gcm_tag_bytes(Core.gcm_tag_output(
        words, nonce, aad, ciphertext)) : List<&2, U32>},
    changed: {AES.tag_bytes(tag) != original : List<&2, U32>}) ->
    {AES.decrypt_authenticated_tag(words, nonce, aad, ciphertext, envelope,
        tag) == Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    match tag:
        case AES.Tag{bytes, size, valid}:
            rejects_comparison(words, envelope, bytes,
                Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad,
                    ciphertext)),
                same => changed(Equal.trans(List<&2, U32>, bytes,
                    Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce,
                        aad, ciphertext)), original, same,
                    Equal.sym(List<&2, U32>, original,
                        Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce,
                            aad, ciphertext)), canonical))))
