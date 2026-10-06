import Base
import ../LAWS.bend as L
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key
import ./AES_NistObservationProof.bend as Obs
import ./AES_NistVectorProof.bend as V

def zero_words() -> List<&2, U32>:
    [0, 0, 0, 0, 0, 0, 0, 0, 1650680675, 1650680675, 1650680675, 1650680675, 2868640763, 2868640763, 2868640763, 2868640763, 1869376719, 219090860, 1869376719, 219090860, 2106428778, 3614865041, 2106428778, 3614865041, 1398074817, 1583080045, 825724578, 1010336014, 2525659585, 1107097424, 1014069818, 3943107755, 2661977896, 3237047621, 4056343527, 3456000745, 724642783, 1791876239, 1455204021, 3183192606, 1678179666, 2767687703, 1429304304, 2563707161, 1841015051, 125203844, 1372246833, 3966859567, 3887130780, 1128757387, 376834939, 2394495586, 1961692065, 1939570213, 575778068, 3458257979, 284690967, 1405055644, 1170831847, 3413140357]

def zero_key() -> AES.SecretKey:
    AES.SecretKey{[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], {==}, {==}}

def checkpoint_zero_key() ->
    {Core.aes256_expand(AES.secret_key_bytes(zero_key())) == zero_words() : List<&2, U32>}:
    {==}

def changed_aad_aad() -> List<&2, U32>:
    [1]

def changed_aad_computed_tag() -> List<&2, U32>:
    [234, 201, 142, 11, 241, 133, 165, 69, 86, 235, 98, 228, 188, 36, 2, 6]

def changed_aad_envelope() -> AES.Envelope:
    AES.Envelope{AES.Nonce{[202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136], {==}, {==}}, [],
        AES.Tag{V.empty_tag(), {==}, {==}}, {==}}

def checkpoint_changed_aad_tag() ->
    {Obs.envelope_tag_computed(Key.words_60(), changed_aad_aad(), changed_aad_envelope()) == changed_aad_computed_tag() : List<&2, U32>}:
    {==}

def checkpoint_changed_aad_rejected() ->
    {Obs.decrypt_expanded(Key.words_60(), changed_aad_aad(), changed_aad_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), changed_aad_aad(), changed_aad_envelope(),
        changed_aad_computed_tag(), False{}, Fail{AES.AuthenticationFailed{}},
        checkpoint_changed_aad_tag(), {==}, {==})

def rejects_changed_aad() ->
    {AES.decrypt(L.aes256gcm_nist_key(), changed_aad_aad(), changed_aad_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), changed_aad_aad(), changed_aad_envelope(),
        Key.words_60(), Fail{AES.AuthenticationFailed{}}, {==}, {==}, V.checkpoint_nist_schedule(), checkpoint_changed_aad_rejected())

def changed_key_aad() -> List<&2, U32>:
    []

def changed_key_computed_tag() -> List<&2, U32>:
    [239, 143, 216, 178, 152, 53, 97, 46, 103, 163, 19, 50, 155, 145, 168, 216]

def changed_key_envelope() -> AES.Envelope:
    AES.Envelope{AES.Nonce{[202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136], {==}, {==}}, [],
        AES.Tag{V.empty_tag(), {==}, {==}}, {==}}

def checkpoint_changed_key_tag() ->
    {Obs.envelope_tag_computed(zero_words(), changed_key_aad(), changed_key_envelope()) == changed_key_computed_tag() : List<&2, U32>}:
    {==}

def checkpoint_changed_key_rejected() ->
    {Obs.decrypt_expanded(zero_words(), changed_key_aad(), changed_key_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(zero_words(), changed_key_aad(), changed_key_envelope(),
        changed_key_computed_tag(), False{}, Fail{AES.AuthenticationFailed{}},
        checkpoint_changed_key_tag(), {==}, {==})

def rejects_changed_key() ->
    {AES.decrypt(zero_key(), changed_key_aad(), changed_key_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(zero_key(), changed_key_aad(), changed_key_envelope(),
        zero_words(), Fail{AES.AuthenticationFailed{}}, {==}, {==}, checkpoint_zero_key(), checkpoint_changed_key_rejected())

def changed_nonce_aad() -> List<&2, U32>:
    []

def changed_nonce_computed_tag() -> List<&2, U32>:
    [233, 144, 99, 34, 140, 197, 191, 38, 223, 98, 138, 58, 82, 20, 52, 245]

def changed_nonce_envelope() -> AES.Envelope:
    AES.Envelope{AES.Nonce{[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], {==}, {==}}, [],
        AES.Tag{V.empty_tag(), {==}, {==}}, {==}}

def checkpoint_changed_nonce_tag() ->
    {Obs.envelope_tag_computed(Key.words_60(), changed_nonce_aad(), changed_nonce_envelope()) == changed_nonce_computed_tag() : List<&2, U32>}:
    {==}

def checkpoint_changed_nonce_rejected() ->
    {Obs.decrypt_expanded(Key.words_60(), changed_nonce_aad(), changed_nonce_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), changed_nonce_aad(), changed_nonce_envelope(),
        changed_nonce_computed_tag(), False{}, Fail{AES.AuthenticationFailed{}},
        checkpoint_changed_nonce_tag(), {==}, {==})

def rejects_changed_nonce() ->
    {AES.decrypt(L.aes256gcm_nist_key(), changed_nonce_aad(), changed_nonce_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), changed_nonce_aad(), changed_nonce_envelope(),
        Key.words_60(), Fail{AES.AuthenticationFailed{}}, {==}, {==}, V.checkpoint_nist_schedule(), checkpoint_changed_nonce_rejected())

def changed_ciphertext_aad() -> List<&2, U32>:
    []

def changed_ciphertext_computed_tag() -> List<&2, U32>:
    [121, 67, 50, 73, 40, 25, 211, 209, 162, 58, 88, 216, 225, 249, 199, 126]

def changed_ciphertext_envelope() -> AES.Envelope:
    AES.Envelope{AES.Nonce{[202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136], {==}, {==}}, [1],
        AES.Tag{V.empty_tag(), {==}, {==}}, {==}}

def checkpoint_changed_ciphertext_tag() ->
    {Obs.envelope_tag_computed(Key.words_60(), changed_ciphertext_aad(), changed_ciphertext_envelope()) == changed_ciphertext_computed_tag() : List<&2, U32>}:
    {==}

def checkpoint_changed_ciphertext_rejected() ->
    {Obs.decrypt_expanded(Key.words_60(), changed_ciphertext_aad(), changed_ciphertext_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_auth(Key.words_60(), changed_ciphertext_aad(), changed_ciphertext_envelope(),
        changed_ciphertext_computed_tag(), False{}, Fail{AES.AuthenticationFailed{}},
        checkpoint_changed_ciphertext_tag(), {==}, {==})

def rejects_changed_ciphertext() ->
    {AES.decrypt(L.aes256gcm_nist_key(), changed_ciphertext_aad(), changed_ciphertext_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Obs.finish_decrypt(L.aes256gcm_nist_key(), changed_ciphertext_aad(), changed_ciphertext_envelope(),
        Key.words_60(), Fail{AES.AuthenticationFailed{}}, {==}, {==}, V.checkpoint_nist_schedule(), checkpoint_changed_ciphertext_rejected())
