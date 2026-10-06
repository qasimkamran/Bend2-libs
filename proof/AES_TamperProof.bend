import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_EncryptProof.bend as Encrypt
import ./AES_TagRejectProof.bend as Reject

def canonical_for_equal_envelope(+words: List<&2, U32>,
    +nonce: List<&2, U32>, +tampered_nonce: List<&2, U32>,
    +aad: List<&2, U32>, +ciphertext: List<&2, U32>,
    +tampered_ciphertext: List<&2, U32>, +original: List<&2, U32>,
    canonical: {original == Core.gcm_tag_bytes(Core.gcm_tag_output(words,
        nonce, aad, ciphertext)) : List<&2, U32>},
    same_nonce: {tampered_nonce == nonce : List<&2, U32>},
    same_ciphertext: {tampered_ciphertext == ciphertext : List<&2, U32>}) ->
    {original == Core.gcm_tag_bytes(Core.gcm_tag_output(words,
        tampered_nonce, aad, tampered_ciphertext)) : List<&2, U32>}:
    nonce_rewrite = Equal.cong(List<&2, U32>, List<&2, U32>,
        value => Core.gcm_tag_bytes(Core.gcm_tag_output(words, value, aad,
            ciphertext)), nonce, tampered_nonce,
        Equal.sym(List<&2, U32>, tampered_nonce, nonce, same_nonce))
    ciphertext_rewrite = Equal.cong(List<&2, U32>, List<&2, U32>,
        value => Core.gcm_tag_bytes(Core.gcm_tag_output(words,
            tampered_nonce, aad, value)), ciphertext, tampered_ciphertext,
        Equal.sym(List<&2, U32>, tampered_ciphertext, ciphertext,
            same_ciphertext))
    Equal.trans(List<&2, U32>, original,
        Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, ciphertext)),
        Core.gcm_tag_bytes(Core.gcm_tag_output(words, tampered_nonce, aad,
            tampered_ciphertext)), canonical,
        Equal.trans(List<&2, U32>,
            Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad,
                ciphertext)),
            Core.gcm_tag_bytes(Core.gcm_tag_output(words, tampered_nonce,
                aad, ciphertext)),
            Core.gcm_tag_bytes(Core.gcm_tag_output(words, tampered_nonce,
                aad, tampered_ciphertext)), nonce_rewrite, ciphertext_rewrite))

def reject_authenticated(+key: AES.SecretKey, +aad: List<&2, U32>,
    +envelope: AES.Envelope, +tampered: AES.Envelope,
    canonical: {AES.tag_bytes(AES.envelope_tag(envelope)) ==
        Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), aad,
            AES.ciphertext(envelope))) : List<&2, U32>},
    same_nonce: {AES.raw_nonce_bytes(AES.envelope_nonce(tampered)) ==
        AES.raw_nonce_bytes(AES.envelope_nonce(envelope)) : List<&2, U32>},
    same_ciphertext: {AES.ciphertext(tampered) == AES.ciphertext(envelope) :
        List<&2, U32>},
    changed_tag: {AES.tag_bytes(AES.envelope_tag(tampered)) !=
        AES.tag_bytes(AES.envelope_tag(envelope)) : List<&2, U32>}) ->
    {AES.decrypt_authenticated(key, aad, tampered) ==
     Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    match key envelope tampered:
        case AES.SecretKey{+key_bytes, _, _}
             AES.Envelope{nonce, ciphertext, tag, _}
             AES.Envelope{tampered_nonce, tampered_ciphertext, tampered_tag, _}:
            +words = Core.aes256_expand(key_bytes)
            +tampered_nonce_bytes = AES.raw_nonce_bytes(tampered_nonce)
            +original = AES.tag_bytes(tag)
            canonical_tampered = canonical_for_equal_envelope(words,
                AES.raw_nonce_bytes(nonce), tampered_nonce_bytes, aad,
                ciphertext, tampered_ciphertext, original, canonical,
                same_nonce, same_ciphertext)
            Reject.rejects_tag(words, tampered_nonce_bytes, aad,
                tampered_ciphertext, tampered, tampered_tag, original,
                canonical_tampered, changed_tag)

def rejects_changed_tag(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope, +tampered: AES.Envelope,
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>},
    same_nonce: {AES.raw_nonce_bytes(AES.envelope_nonce(tampered)) ==
        AES.raw_nonce_bytes(AES.envelope_nonce(envelope)) : List<&2, U32>},
    +same_ciphertext: {AES.ciphertext(tampered) == AES.ciphertext(envelope) :
        List<&2, U32>},
    changed_tag: {AES.tag_bytes(AES.envelope_tag(tampered)) !=
        AES.tag_bytes(AES.envelope_tag(envelope)) : List<&2, U32>}) ->
    {AES.decrypt(key, aad, tampered) == Fail{AES.AuthenticationFailed{}} :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    +aad_ok = Encrypt.successful_encrypt_aad_valid(key, nonce, aad,
        plaintext, AES.aad_valid(aad), AES.plaintext_valid(plaintext),
        {==}, {==}, envelope, encrypted)
    +plaintext_ok = Encrypt.successful_encrypt_plaintext_valid(key, nonce,
        aad, plaintext, AES.aad_valid(aad), AES.plaintext_valid(plaintext),
        {==}, {==}, envelope, encrypted)
    ciphertext_ok = Encrypt.successful_encrypt_ciphertext_valid(key, nonce,
        aad, plaintext, envelope, aad_ok, plaintext_ok, encrypted)
    tampered_ciphertext_ok = Equal.trans(Bool,
        AES.plaintext_valid(AES.ciphertext(tampered)),
        AES.plaintext_valid(AES.ciphertext(envelope)), True{},
        Equal.cong(List<&2, U32>, Bool, value => AES.plaintext_valid(value),
            AES.ciphertext(tampered), AES.ciphertext(envelope),
            same_ciphertext), ciphertext_ok)
    canonical = Encrypt.successful_encrypt_envelope_tag_canonical(key,
        nonce, aad, plaintext, envelope, aad_ok, plaintext_ok, encrypted)
    rejected = reject_authenticated(key, aad, envelope, tampered,
        canonical, same_nonce, same_ciphertext, changed_tag)
    aad_checked = Equal.cong(Bool,
        Result<&2, &2, AES.Error, List<&2, U32>>,
        flag => AES.decrypt_checked(key, aad, tampered, flag,
            AES.plaintext_valid(AES.ciphertext(tampered))),
        AES.aad_valid(aad), True{}, aad_ok)
    ciphertext_checked = Equal.cong(Bool,
        Result<&2, &2, AES.Error, List<&2, U32>>,
        flag => AES.decrypt_checked(key, aad, tampered, True{}, flag),
        AES.plaintext_valid(AES.ciphertext(tampered)), True{},
        tampered_ciphertext_ok)
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
        AES.decrypt(key, aad, tampered),
        AES.decrypt_checked(key, aad, tampered, True{}, True{}),
        Fail{AES.AuthenticationFailed{}},
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            AES.decrypt(key, aad, tampered),
            AES.decrypt_checked(key, aad, tampered, True{},
                AES.plaintext_valid(AES.ciphertext(tampered))),
            AES.decrypt_checked(key, aad, tampered, True{}, True{}),
            aad_checked, ciphertext_checked), rejected)
