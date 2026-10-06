import Base
import ../LAWS.bend as L
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key
import ./AES_NistObservationProof.bend as Obs
import ./AES_NistTagProof.bend as TagProof
import ./AES_NistHashBlockProof.bend as Hash
import ./AES_NistCtrProof.bend as Ctr
import ./AES_NistCtr2BlockProof.bend as Ctr2

def checkpoint_nist_schedule() ->
    {Core.aes256_expand(AES.secret_key_bytes(L.aes256gcm_nist_key())) == Key.words_60() : List<&2, U32>}:
    Obs.schedule_input_matches(L.aes256gcm_nist_key(), Key.key_bytes(), Key.words_60(), {==}, Key.key_schedule_matches())

def empty_aad() -> List<&2, U32>:
    []

def empty_plaintext() -> List<&2, U32>:
    []

def empty_ciphertext() -> List<&2, U32>:
    []

def empty_tag() -> List<&2, U32>:
    [253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126]

def empty_auth() -> List<&2, U32>:
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

def checkpoint_empty_ciphertext() ->
    {Obs.ciphertext(Core.gcm_ctr_encrypt(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), empty_plaintext())) == empty_ciphertext() : List<&2, U32>}:
    {==}

def checkpoint_empty_ghash() ->
    {TagProof.auth_from_hash(Hash.result(), empty_aad(), empty_ciphertext()) == empty_auth() : List<&2, U32>}:
    {==}

def checkpoint_empty_tag() ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), empty_aad(), empty_ciphertext())) == empty_tag() : List<&2, U32>}:
    TagProof.nist_tag(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), empty_aad(), empty_ciphertext(),
        empty_auth(), empty_tag(), {==}, checkpoint_empty_ghash(), {==})

def empty_encrypt() ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(), empty_aad(), empty_plaintext())) ==
     L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_empty()}) : List<&2, U32>}:
    Obs.finish_encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        empty_aad(), empty_plaintext(), Key.words_60(), empty_ciphertext(), empty_tag(),
        {==}, {==}, checkpoint_nist_schedule(), checkpoint_empty_ciphertext(), checkpoint_empty_tag())

def checkpoint_empty_plaintext() ->
    {Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), empty_ciphertext()) == empty_plaintext() : List<&2, U32>}:
    {==}

def checkpoint_empty_authenticated() ->
    {Obs.decrypt_expanded(Key.words_60(), empty_aad(), L.aes256gcm_nist_empty()) == Done{empty_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), empty_aad(), L.aes256gcm_nist_empty(),
        empty_tag(), True{}, Done{empty_plaintext()},
        Obs.tag_parameters(Key.words_60(), empty_aad(), L.aes256gcm_nist_empty(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), empty_ciphertext(), empty_tag(),
            {==}, {==}, checkpoint_empty_tag()), {==},
        Obs.payload_parameters(Key.words_60(), L.aes256gcm_nist_empty(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), empty_ciphertext(), empty_plaintext(),
            {==}, {==}, checkpoint_empty_plaintext()))

def empty_decrypt() ->
    {AES.decrypt(L.aes256gcm_nist_key(), empty_aad(), L.aes256gcm_nist_empty()) == Done{empty_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), empty_aad(), L.aes256gcm_nist_empty(),
        Key.words_60(), Done{empty_plaintext()}, {==}, {==}, checkpoint_nist_schedule(),
        checkpoint_empty_authenticated())

def multiblock_aad() -> List<&2, U32>:
    []

def multiblock_plaintext() -> List<&2, U32>:
    [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85]

def multiblock_ciphertext() -> List<&2, U32>:
    [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132, 66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162, 189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167, 176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122, 10, 188, 201, 246, 98, 137, 128, 21, 173]

def multiblock_tag() -> List<&2, U32>:
    [176, 148, 218, 197, 217, 52, 113, 189, 236, 26, 80, 34, 112, 227, 204, 108]

def multiblock_auth() -> List<&2, U32>:
    [77,184,112,211,124,183,95,203,70,9,124,54,35,13,22,18]

def checkpoint_multiblock_plaintext_stream() ->
    {Core.gcm_ctr_stream_exact(List.length(&2, U32, multiblock_plaintext()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_64() : List<&2, U32>}:
    Obs.stream_parameters(List.length(&2, U32, multiblock_plaintext()), Key.words_60(),
        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), 64n, Ctr2.block(), Ctr.stream_64(),
        {==}, {==}, Ctr.checkpoint_stream_64())

def checkpoint_multiblock_ciphertext_stream() ->
    {Core.gcm_ctr_stream_exact(List.length(&2, U32, multiblock_ciphertext()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_64() : List<&2, U32>}:
    Obs.stream_parameters(List.length(&2, U32, multiblock_ciphertext()), Key.words_60(),
        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), 64n, Ctr2.block(), Ctr.stream_64(),
        {==}, {==}, Ctr.checkpoint_stream_64())

def checkpoint_multiblock_ciphertext() ->
    {Obs.ciphertext(Core.gcm_ctr_encrypt(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_plaintext())) == multiblock_ciphertext() : List<&2, U32>}:
    Obs.finish_cipher(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_plaintext(), Ctr.stream_64(), multiblock_ciphertext(), checkpoint_multiblock_plaintext_stream(), {==})

def checkpoint_multiblock_ghash() ->
    {TagProof.auth_from_hash(Hash.result(), multiblock_aad(), multiblock_ciphertext()) == multiblock_auth() : List<&2, U32>}:
    {==}

def checkpoint_multiblock_tag() ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_aad(), multiblock_ciphertext())) == multiblock_tag() : List<&2, U32>}:
    TagProof.nist_tag(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_aad(), multiblock_ciphertext(),
        multiblock_auth(), multiblock_tag(), {==}, checkpoint_multiblock_ghash(), {==})

def multiblock_encrypt() ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(), multiblock_aad(), multiblock_plaintext())) ==
     L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_multiblock()}) : List<&2, U32>}:
    Obs.finish_encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        multiblock_aad(), multiblock_plaintext(), Key.words_60(), multiblock_ciphertext(), multiblock_tag(),
        {==}, {==}, checkpoint_nist_schedule(), checkpoint_multiblock_ciphertext(), checkpoint_multiblock_tag())

def checkpoint_multiblock_plaintext() ->
    {Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_ciphertext()) == multiblock_plaintext() : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_ciphertext()), Core.gcm_zip_xor(multiblock_ciphertext(), Ctr.stream_64()), multiblock_plaintext(), Obs.xor_from_stream(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_ciphertext(), Ctr.stream_64(), checkpoint_multiblock_ciphertext_stream()), {==})

def checkpoint_multiblock_authenticated() ->
    {Obs.decrypt_expanded(Key.words_60(), multiblock_aad(), L.aes256gcm_nist_multiblock()) == Done{multiblock_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), multiblock_aad(), L.aes256gcm_nist_multiblock(),
        multiblock_tag(), True{}, Done{multiblock_plaintext()},
        Obs.tag_parameters(Key.words_60(), multiblock_aad(), L.aes256gcm_nist_multiblock(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_ciphertext(), multiblock_tag(),
            {==}, {==}, checkpoint_multiblock_tag()), {==},
        Obs.payload_parameters(Key.words_60(), L.aes256gcm_nist_multiblock(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), multiblock_ciphertext(), multiblock_plaintext(),
            {==}, {==}, checkpoint_multiblock_plaintext()))

def multiblock_decrypt() ->
    {AES.decrypt(L.aes256gcm_nist_key(), multiblock_aad(), L.aes256gcm_nist_multiblock()) == Done{multiblock_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), multiblock_aad(), L.aes256gcm_nist_multiblock(),
        Key.words_60(), Done{multiblock_plaintext()}, {==}, {==}, checkpoint_nist_schedule(),
        checkpoint_multiblock_authenticated())

def aad_only_aad() -> List<&2, U32>:
    [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212]

def aad_only_plaintext() -> List<&2, U32>:
    []

def aad_only_ciphertext() -> List<&2, U32>:
    []

def aad_only_tag() -> List<&2, U32>:
    [222, 52, 182, 220, 212, 206, 226, 253, 190, 195, 206, 160, 26, 241, 238, 68]

def aad_only_auth() -> List<&2, U32>:
    [35,24,28,202,113,77,204,139,20,208,226,180,73,31,52,58]

def checkpoint_aad_only_ciphertext() ->
    {Obs.ciphertext(Core.gcm_ctr_encrypt(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_only_plaintext())) == aad_only_ciphertext() : List<&2, U32>}:
    {==}

def checkpoint_aad_only_ghash() ->
    {TagProof.auth_from_hash(Hash.result(), aad_only_aad(), aad_only_ciphertext()) == aad_only_auth() : List<&2, U32>}:
    {==}

def checkpoint_aad_only_tag() ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_only_aad(), aad_only_ciphertext())) == aad_only_tag() : List<&2, U32>}:
    TagProof.nist_tag(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_only_aad(), aad_only_ciphertext(),
        aad_only_auth(), aad_only_tag(), {==}, checkpoint_aad_only_ghash(), {==})

def aad_only_encrypt() ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(), aad_only_aad(), aad_only_plaintext())) ==
     L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_aad_only()}) : List<&2, U32>}:
    Obs.finish_encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        aad_only_aad(), aad_only_plaintext(), Key.words_60(), aad_only_ciphertext(), aad_only_tag(),
        {==}, {==}, checkpoint_nist_schedule(), checkpoint_aad_only_ciphertext(), checkpoint_aad_only_tag())

def checkpoint_aad_only_plaintext() ->
    {Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_only_ciphertext()) == aad_only_plaintext() : List<&2, U32>}:
    {==}

def checkpoint_aad_only_authenticated() ->
    {Obs.decrypt_expanded(Key.words_60(), aad_only_aad(), L.aes256gcm_nist_aad_only()) == Done{aad_only_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), aad_only_aad(), L.aes256gcm_nist_aad_only(),
        aad_only_tag(), True{}, Done{aad_only_plaintext()},
        Obs.tag_parameters(Key.words_60(), aad_only_aad(), L.aes256gcm_nist_aad_only(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_only_ciphertext(), aad_only_tag(),
            {==}, {==}, checkpoint_aad_only_tag()), {==},
        Obs.payload_parameters(Key.words_60(), L.aes256gcm_nist_aad_only(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_only_ciphertext(), aad_only_plaintext(),
            {==}, {==}, checkpoint_aad_only_plaintext()))

def aad_only_decrypt() ->
    {AES.decrypt(L.aes256gcm_nist_key(), aad_only_aad(), L.aes256gcm_nist_aad_only()) == Done{aad_only_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), aad_only_aad(), L.aes256gcm_nist_aad_only(),
        Key.words_60(), Done{aad_only_plaintext()}, {==}, {==}, checkpoint_nist_schedule(),
        checkpoint_aad_only_authenticated())

def aad_and_multiblock_aad() -> List<&2, U32>:
    [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105, 157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127, 89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120, 94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212]

def aad_and_multiblock_plaintext() -> List<&2, U32>:
    [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57, 26, 175, 210, 85]

def aad_and_multiblock_ciphertext() -> List<&2, U32>:
    [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132, 66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162, 189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167, 176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122, 10, 188, 201, 246, 98, 137, 128, 21, 173]

def aad_and_multiblock_tag() -> List<&2, U32>:
    [192, 109, 118, 243, 25, 48, 254, 243, 122, 202, 226, 62, 212, 101, 174, 98]

def aad_and_multiblock_auth() -> List<&2, U32>:
    [61,65,220,229,188,179,208,133,208,217,206,42,135,139,116,28]

def checkpoint_aad_and_multiblock_plaintext_stream() ->
    {Core.gcm_ctr_stream_exact(List.length(&2, U32, aad_and_multiblock_plaintext()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_64() : List<&2, U32>}:
    Obs.stream_parameters(List.length(&2, U32, aad_and_multiblock_plaintext()), Key.words_60(),
        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), 64n, Ctr2.block(), Ctr.stream_64(),
        {==}, {==}, Ctr.checkpoint_stream_64())

def checkpoint_aad_and_multiblock_ciphertext_stream() ->
    {Core.gcm_ctr_stream_exact(List.length(&2, U32, aad_and_multiblock_ciphertext()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_64() : List<&2, U32>}:
    Obs.stream_parameters(List.length(&2, U32, aad_and_multiblock_ciphertext()), Key.words_60(),
        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), 64n, Ctr2.block(), Ctr.stream_64(),
        {==}, {==}, Ctr.checkpoint_stream_64())

def checkpoint_aad_and_multiblock_ciphertext() ->
    {Obs.ciphertext(Core.gcm_ctr_encrypt(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_plaintext())) == aad_and_multiblock_ciphertext() : List<&2, U32>}:
    Obs.finish_cipher(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_plaintext(), Ctr.stream_64(), aad_and_multiblock_ciphertext(), checkpoint_aad_and_multiblock_plaintext_stream(), {==})

def checkpoint_aad_and_multiblock_ghash() ->
    {TagProof.auth_from_hash(Hash.result(), aad_and_multiblock_aad(), aad_and_multiblock_ciphertext()) == aad_and_multiblock_auth() : List<&2, U32>}:
    {==}

def checkpoint_aad_and_multiblock_tag() ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_aad(), aad_and_multiblock_ciphertext())) == aad_and_multiblock_tag() : List<&2, U32>}:
    TagProof.nist_tag(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_aad(), aad_and_multiblock_ciphertext(),
        aad_and_multiblock_auth(), aad_and_multiblock_tag(), {==}, checkpoint_aad_and_multiblock_ghash(), {==})

def aad_and_multiblock_encrypt() ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(), aad_and_multiblock_aad(), aad_and_multiblock_plaintext())) ==
     L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_aad_and_multiblock()}) : List<&2, U32>}:
    Obs.finish_encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        aad_and_multiblock_aad(), aad_and_multiblock_plaintext(), Key.words_60(), aad_and_multiblock_ciphertext(), aad_and_multiblock_tag(),
        {==}, {==}, checkpoint_nist_schedule(), checkpoint_aad_and_multiblock_ciphertext(), checkpoint_aad_and_multiblock_tag())

def checkpoint_aad_and_multiblock_plaintext() ->
    {Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_ciphertext()) == aad_and_multiblock_plaintext() : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_ciphertext()), Core.gcm_zip_xor(aad_and_multiblock_ciphertext(), Ctr.stream_64()), aad_and_multiblock_plaintext(), Obs.xor_from_stream(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_ciphertext(), Ctr.stream_64(), checkpoint_aad_and_multiblock_ciphertext_stream()), {==})

def checkpoint_aad_and_multiblock_authenticated() ->
    {Obs.decrypt_expanded(Key.words_60(), aad_and_multiblock_aad(), L.aes256gcm_nist_aad_and_multiblock()) == Done{aad_and_multiblock_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), aad_and_multiblock_aad(), L.aes256gcm_nist_aad_and_multiblock(),
        aad_and_multiblock_tag(), True{}, Done{aad_and_multiblock_plaintext()},
        Obs.tag_parameters(Key.words_60(), aad_and_multiblock_aad(), L.aes256gcm_nist_aad_and_multiblock(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_ciphertext(), aad_and_multiblock_tag(),
            {==}, {==}, checkpoint_aad_and_multiblock_tag()), {==},
        Obs.payload_parameters(Key.words_60(), L.aes256gcm_nist_aad_and_multiblock(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), aad_and_multiblock_ciphertext(), aad_and_multiblock_plaintext(),
            {==}, {==}, checkpoint_aad_and_multiblock_plaintext()))

def aad_and_multiblock_decrypt() ->
    {AES.decrypt(L.aes256gcm_nist_key(), aad_and_multiblock_aad(), L.aes256gcm_nist_aad_and_multiblock()) == Done{aad_and_multiblock_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), aad_and_multiblock_aad(), L.aes256gcm_nist_aad_and_multiblock(),
        Key.words_60(), Done{aad_and_multiblock_plaintext()}, {==}, {==}, checkpoint_nist_schedule(),
        checkpoint_aad_and_multiblock_authenticated())

def partial_block_aad() -> List<&2, U32>:
    [58, 215, 123, 180, 13, 122, 54, 96, 168, 158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133]

def partial_block_plaintext() -> List<&2, U32>:
    [217, 49, 50, 37, 248, 132, 6, 229, 165, 89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247, 218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149, 104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237, 245, 170, 13, 230, 87, 186, 99, 123, 57]

def partial_block_ciphertext() -> List<&2, U32>:
    [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132, 66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162, 189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167, 176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122, 10, 188, 201, 246, 98]

def partial_block_tag() -> List<&2, U32>:
    [224, 151, 25, 95, 69, 50, 218, 137, 95, 185, 23, 165, 165, 92, 106, 160]

def partial_block_auth() -> List<&2, U32>:
    [29,187,179,73,224,177,244,255,245,170,59,177,246,178,176,222]

def checkpoint_partial_block_plaintext_stream() ->
    {Core.gcm_ctr_stream_exact(List.length(&2, U32, partial_block_plaintext()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_60() : List<&2, U32>}:
    Obs.stream_parameters(List.length(&2, U32, partial_block_plaintext()), Key.words_60(),
        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), 60n, Ctr2.block(), Ctr.stream_60(),
        {==}, {==}, Ctr.checkpoint_stream_60())

def checkpoint_partial_block_ciphertext_stream() ->
    {Core.gcm_ctr_stream_exact(List.length(&2, U32, partial_block_ciphertext()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_60() : List<&2, U32>}:
    Obs.stream_parameters(List.length(&2, U32, partial_block_ciphertext()), Key.words_60(),
        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), 60n, Ctr2.block(), Ctr.stream_60(),
        {==}, {==}, Ctr.checkpoint_stream_60())

def checkpoint_partial_block_ciphertext() ->
    {Obs.ciphertext(Core.gcm_ctr_encrypt(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_plaintext())) == partial_block_ciphertext() : List<&2, U32>}:
    Obs.finish_cipher(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_plaintext(), Ctr.stream_60(), partial_block_ciphertext(), checkpoint_partial_block_plaintext_stream(), {==})

def checkpoint_partial_block_ghash() ->
    {TagProof.auth_from_hash(Hash.result(), partial_block_aad(), partial_block_ciphertext()) == partial_block_auth() : List<&2, U32>}:
    {==}

def checkpoint_partial_block_tag() ->
    {Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_aad(), partial_block_ciphertext())) == partial_block_tag() : List<&2, U32>}:
    TagProof.nist_tag(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_aad(), partial_block_ciphertext(),
        partial_block_auth(), partial_block_tag(), {==}, checkpoint_partial_block_ghash(), {==})

def partial_block_encrypt() ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(), partial_block_aad(), partial_block_plaintext())) ==
     L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_partial_block()}) : List<&2, U32>}:
    Obs.finish_encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),
        partial_block_aad(), partial_block_plaintext(), Key.words_60(), partial_block_ciphertext(), partial_block_tag(),
        {==}, {==}, checkpoint_nist_schedule(), checkpoint_partial_block_ciphertext(), checkpoint_partial_block_tag())

def checkpoint_partial_block_plaintext() ->
    {Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_ciphertext()) == partial_block_plaintext() : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_ciphertext()), Core.gcm_zip_xor(partial_block_ciphertext(), Ctr.stream_60()), partial_block_plaintext(), Obs.xor_from_stream(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_ciphertext(), Ctr.stream_60(), checkpoint_partial_block_ciphertext_stream()), {==})

def checkpoint_partial_block_authenticated() ->
    {Obs.decrypt_expanded(Key.words_60(), partial_block_aad(), L.aes256gcm_nist_partial_block()) == Done{partial_block_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), partial_block_aad(), L.aes256gcm_nist_partial_block(),
        partial_block_tag(), True{}, Done{partial_block_plaintext()},
        Obs.tag_parameters(Key.words_60(), partial_block_aad(), L.aes256gcm_nist_partial_block(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_ciphertext(), partial_block_tag(),
            {==}, {==}, checkpoint_partial_block_tag()), {==},
        Obs.payload_parameters(Key.words_60(), L.aes256gcm_nist_partial_block(),
            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), partial_block_ciphertext(), partial_block_plaintext(),
            {==}, {==}, checkpoint_partial_block_plaintext()))

def partial_block_decrypt() ->
    {AES.decrypt(L.aes256gcm_nist_key(), partial_block_aad(), L.aes256gcm_nist_partial_block()) == Done{partial_block_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), partial_block_aad(), L.aes256gcm_nist_partial_block(),
        Key.words_60(), Done{partial_block_plaintext()}, {==}, {==}, checkpoint_nist_schedule(),
        checkpoint_partial_block_authenticated())
