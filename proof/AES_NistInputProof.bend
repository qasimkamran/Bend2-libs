import Base
import ../LAWS.bend as L
import ../libs/AES256GCM.bend as AES

# Transport fixture aliases before entering the encryption or decryption code.
# Equal fixtures must not force a fresh evaluation of the entire cipher.
def encrypt_inputs(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +fixture_aad: List<&2, U32>,
    +plaintext: List<&2, U32>, +fixture_plaintext: List<&2, U32>,
    +expected: List<&2, U32>,
    aad_matches: {aad == fixture_aad : List<&2, U32>},
    plaintext_matches: {plaintext == fixture_plaintext : List<&2, U32>},
    computed: {L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, fixture_aad, fixture_plaintext)) == expected : List<&2, U32>}) ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, aad, plaintext)) == expected : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, aad, plaintext)),
        L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, fixture_aad, plaintext)), expected,
        Equal.cong(List<&2, U32>, List<&2, U32>, value =>
            L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, value, plaintext)),
            aad, fixture_aad, aad_matches),
        Equal.trans(List<&2, U32>,
            L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, fixture_aad, plaintext)),
            L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, fixture_aad, fixture_plaintext)), expected,
            Equal.cong(List<&2, U32>, List<&2, U32>, value =>
                L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, fixture_aad, value)),
                plaintext, fixture_plaintext, plaintext_matches), computed))

def decrypt_inputs(+key: AES.SecretKey, +fixture_key: AES.SecretKey,
    +aad: List<&2, U32>, +fixture_aad: List<&2, U32>,
    +envelope: AES.Envelope, +fixture_envelope: AES.Envelope,
    +expected: Result<&2, &2, AES.Error, List<&2, U32>>,
    key_matches: {key == fixture_key : AES.SecretKey},
    aad_matches: {aad == fixture_aad : List<&2, U32>},
    envelope_matches: {envelope == fixture_envelope : AES.Envelope},
    computed: {AES.decrypt(fixture_key, fixture_aad, fixture_envelope) == expected : Result<&2, &2, AES.Error, List<&2, U32>>}) ->
    {AES.decrypt(key, aad, envelope) == expected : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
        AES.decrypt(key, aad, envelope), AES.decrypt(fixture_key, aad, envelope), expected,
        Equal.cong(AES.SecretKey, Result<&2, &2, AES.Error, List<&2, U32>>,
            value => AES.decrypt(value, aad, envelope), key, fixture_key, key_matches),
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            AES.decrypt(fixture_key, aad, envelope), AES.decrypt(fixture_key, fixture_aad, envelope), expected,
            Equal.cong(List<&2, U32>, Result<&2, &2, AES.Error, List<&2, U32>>,
                value => AES.decrypt(fixture_key, value, envelope), aad, fixture_aad, aad_matches),
            Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
                AES.decrypt(fixture_key, fixture_aad, envelope), AES.decrypt(fixture_key, fixture_aad, fixture_envelope), expected,
                Equal.cong(AES.Envelope, Result<&2, &2, AES.Error, List<&2, U32>>,
                    value => AES.decrypt(fixture_key, fixture_aad, value), envelope, fixture_envelope, envelope_matches), computed)))
