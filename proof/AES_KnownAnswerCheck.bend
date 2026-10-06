import Base
import ../libs/AES256GCM.bend as AES
import ./AES_KnownAnswerProof.bend as Known

def key() -> AES.SecretKey:
    AES.SecretKey{[254, 255, 233, 146, 134, 101, 115, 28, 109, 106, 143,
        148, 103, 48, 131, 8, 254, 255, 233, 146, 134, 101, 115, 28, 109,
        106, 143, 148, 103, 48, 131, 8], {==}, {==}}

def nonce() -> AES.Nonce:
    AES.Nonce{[202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248,
        136], {==}, {==}}

def empty() -> AES.Envelope:
    AES.Envelope{nonce(), [], AES.Tag{[253, 44, 170, 22, 165, 131, 46,
        118, 170, 19, 44, 20, 83, 238, 218, 126], {==}, {==}}, {==}}

def empty_encrypt() ->
    {AES.encrypt(key(), nonce(), [], []) == Done{empty()} :
        Result<&2, &2, AES.Error, AES.Envelope>}:
    Known.encrypt_matches(key(), nonce(), [], [], [],
        [253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238,
            218, 126], {==}, {==}, {==}, {==}, {==}, {==}, {==})
