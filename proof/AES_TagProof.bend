import Base
import ../libs/AES256GCMCore.bend as Core

def tag_length(+words: List<&2, U32>, +nonce: List<&2, U32>,
    +aad: List<&2, U32>, +ciphertext: List<&2, U32>) ->
    {List.length(&2, U32,
        Core.gcm_tag_expanded(words, nonce, aad, ciphertext)) == 16n : Nat}:
    Core.gcm_tag_size(Core.gcm_tag_output(words, nonce, aad, ciphertext))

def auth_length(+words: List<&2, U32>, +aad: List<&2, U32>,
    +ciphertext: List<&2, U32>) ->
    {List.length(&2, U32,
        Core.ghash_auth_expanded(words, aad, ciphertext)) == 16n : Nat}:
    {==}
