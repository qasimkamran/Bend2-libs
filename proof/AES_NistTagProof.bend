import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key
import ./AES_NistBlockProof.bend as J0
import ./AES_NistBlockComposeProof.bend as J0Proof
import ./AES_NistHashBlockProof.bend as Hash
import ./AES_NistHashBlockComposeProof.bend as HashProof

def zero() -> List<&2, U32>:
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

def auth_from_hash(+h: List<&2, U32>, +aad: List<&2, U32>, +bytes: List<&2, U32>) -> List<&2, U32>:
    Core.ghash_auth_with_hash(h, aad, bytes)

def tag_from_parts(auth: List<&2, U32>, mask: List<&2, U32>) -> List<&2, U32>:
    Core.gcm_mask_bytes(Core.gcm_tag_parts(auth, mask))

def tag_shape(+words: List<&2, U32>, +nonce: List<&2, U32>, +aad: List<&2, U32>, +bytes: List<&2, U32>) ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, bytes)) ==
     tag_from_parts(Core.ghash_auth_expanded(words, aad, bytes), Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce))) : List<&2, U32>}:
    match nonce:
        case Nil{}: {==}
        case head <> tail: {==}

def auth_from_checked_hash(+words: List<&2, U32>, +h: List<&2, U32>,
    +aad: List<&2, U32>, +bytes: List<&2, U32>, +auth: List<&2, U32>,
    hash_matches: {Core.aes256_encrypt_expanded(words, [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) == h : List<&2, U32>},
    computed: {auth_from_hash(h, aad, bytes) == auth : List<&2, U32>}) ->
    {Core.ghash_auth_expanded(words, aad, bytes) == auth : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.ghash_auth_expanded(words, aad, bytes),
        auth_from_hash(h, aad, bytes), auth,
        Equal.cong(List<&2, U32>, List<&2, U32>, h => auth_from_hash(h, aad, bytes),
            Core.aes256_encrypt_expanded(words, [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]), h, hash_matches),
        computed)

def aes_block_input_matches(+words: List<&2, U32>, +input: List<&2, U32>, +block: List<&2, U32>, +result: List<&2, U32>,
    input_matches: {input == block : List<&2, U32>},
    block_matches: {Core.aes256_encrypt_expanded(words, block) == result : List<&2, U32>}) ->
    {Core.aes256_encrypt_expanded(words, input) == result : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.aes256_encrypt_expanded(words, input),
        Core.aes256_encrypt_expanded(words, block), result,
        Equal.cong(List<&2, U32>, List<&2, U32>, value => Core.aes256_encrypt_expanded(words, value),
            input, block, input_matches), block_matches)

def finish_tag(+words: List<&2, U32>, +nonce: List<&2, U32>, +aad: List<&2, U32>, +bytes: List<&2, U32>,
    +auth: List<&2, U32>, +mask: List<&2, U32>, +tag: List<&2, U32>,
    auth_matches: {Core.ghash_auth_expanded(words, aad, bytes) == auth : List<&2, U32>},
    mask_matches: {Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce)) == mask : List<&2, U32>},
    xor_matches: {tag_from_parts(auth, mask) == tag : List<&2, U32>}) ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, bytes)) == tag : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, bytes)),
        tag_from_parts(Core.ghash_auth_expanded(words, aad, bytes), Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce))), tag,
        tag_shape(words, nonce, aad, bytes),
        Equal.trans(List<&2, U32>,
            tag_from_parts(Core.ghash_auth_expanded(words, aad, bytes), Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce))),
            tag_from_parts(auth, Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce))), tag,
            Equal.cong(List<&2, U32>, List<&2, U32>, value => tag_from_parts(value, Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce))),
                Core.ghash_auth_expanded(words, aad, bytes), auth, auth_matches),
            Equal.trans(List<&2, U32>, tag_from_parts(auth, Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce))),
                tag_from_parts(auth, mask), tag,
                Equal.cong(List<&2, U32>, List<&2, U32>, value => tag_from_parts(auth, value),
                    Core.aes256_encrypt_expanded(words, Core.gcm_j0(nonce)), mask, mask_matches), xor_matches)))

def nist_tag(+nonce: List<&2, U32>, +aad: List<&2, U32>, +bytes: List<&2, U32>,
    +auth: List<&2, U32>, +tag: List<&2, U32>,
    j0_matches: {Core.gcm_j0(nonce) == J0.block() : List<&2, U32>},
    auth_matches: {auth_from_hash(Hash.result(), aad, bytes) == auth : List<&2, U32>},
    xor_matches: {tag_from_parts(auth, J0.result()) == tag : List<&2, U32>}) ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), nonce, aad, bytes)) == tag : List<&2, U32>}:
    finish_tag(Key.words_60(), nonce, aad, bytes, auth, J0.result(), tag,
        auth_from_checked_hash(Key.words_60(), Hash.result(), aad, bytes, auth,
            aes_block_input_matches(Key.words_60(), [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], Hash.block(), Hash.result(),
                {==}, HashProof.expanded_block_matches()), auth_matches),
        aes_block_input_matches(Key.words_60(), Core.gcm_j0(nonce), J0.block(), J0.result(),
            j0_matches, J0Proof.expanded_block_matches()), xor_matches)
