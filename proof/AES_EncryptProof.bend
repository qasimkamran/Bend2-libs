import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_ZipLengthProof.bend as ZipLengthProof
import ./AES_CoreTagProof.bend as CoreTagProof
import ./AES_MaskedXorProof.bend as MaskedXorProof
import ./AES_LengthLimitProof.bend as LengthLimitProof
import ./AES_TagCompareProof.bend as TagCompareProof

type TagContext is Data:
    TagContext{
        words: List<&2, U32>,
        nonce: List<&2, U32>,
        aad: List<&2, U32>,
        ciphertext: List<&2, U32>
    }

def result_ciphertext(fallback: List<&2, U32>,
    result: Result<&2, &2, AES.Error, AES.Envelope>) -> List<&2, U32>:
    match result:
        case Fail{error}: fallback
        case Done{envelope}: AES.ciphertext(envelope)

def output_tag_context(output: Core.GcmOutput) -> TagContext:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            TagContext{tag_words, tag_nonce, tag_aad, ciphertext}

def tag_for_context(context: TagContext) -> List<&2, U32>:
    match context:
        case TagContext{words, nonce, aad, ciphertext}:
            Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad,
                ciphertext))

def output_tag_matches_context(+output: Core.GcmOutput) ->
    {CoreTagProof.output_tag(output) ==
     tag_for_context(output_tag_context(output)) : List<&2, U32>}:
    match output:
        case Core.GcmOutput{ciphertext, ciphertext_valid, tag_bytes,
            tag_valid, tag_size, tag_words, tag_nonce, tag_aad, tag_matches}:
            tag_matches

def raw_output_tag_canonical(+key: List<&2, U32>,
    +nonce: List<&2, U32>, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>) ->
    {CoreTagProof.output_tag(Core.gcm_encrypt_raw(key, nonce, aad,
        plaintext)) == Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(key), nonce, aad,
            CoreTagProof.output_ciphertext(Core.gcm_encrypt_raw(key, nonce,
                aad, plaintext)))) : List<&2, U32>}:
    +output = Core.gcm_encrypt_raw(key, nonce, aad, plaintext)
    +context = output_tag_context(output)
    +expected_context = {TagContext{Core.aes256_expand(key), nonce, aad,
        CoreTagProof.output_ciphertext(output)} : TagContext}
    context_eq: {context == expected_context : TagContext} = {==}
    Equal.trans(List<&2, U32>, CoreTagProof.output_tag(output),
        tag_for_context(context), tag_for_context(expected_context),
        output_tag_matches_context(output),
        Equal.cong(TagContext, List<&2, U32>, tag_for_context,
            context, expected_context, context_eq))

def result_tag_bytes(fallback: List<&2, U32>,
    result: Result<&2, &2, AES.Error, AES.Envelope>) -> List<&2, U32>:
    match result:
        case Fail{error}: fallback
        case Done{envelope}: AES.tag_bytes(AES.envelope_tag(envelope))

def valid_output_ciphertext_length(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>) ->
    {List.length(&2, U32,
        AES.ciphertext(AES.envelope_from_gcm_checked(nonce,
            AES.encrypt_valid_output(key, nonce, aad, plaintext)))) ==
     List.length(&2, U32, plaintext) : Nat}:
    ZipLengthProof.ctr_encrypt_ciphertext_length(
        Core.aes256_expand(AES.secret_key_bytes(key)),
        AES.raw_nonce_bytes(nonce), plaintext)

def encrypt_checked_with_flags(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +aad_flag: Bool, +plaintext_flag: Bool,
    aad_ok: {AES.aad_valid(aad) == aad_flag : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == plaintext_flag : Bool},
    +envelope: AES.Envelope,
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.encrypt_checked(key, nonce, aad, plaintext, aad_flag,
        plaintext_flag) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}:
    changed_flags = Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
            AES.encrypt(key, nonce, aad, plaintext),
            AES.encrypt_checked(key, nonce, aad, plaintext,
                AES.aad_valid(aad), AES.plaintext_valid(plaintext)),
            AES.encrypt_checked(key, nonce, aad, plaintext, aad_flag,
                plaintext_flag), {==},
            Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
                AES.encrypt_checked(key, nonce, aad, plaintext,
                    AES.aad_valid(aad), AES.plaintext_valid(plaintext)),
                AES.encrypt_checked(key, nonce, aad, plaintext, aad_flag,
                    AES.plaintext_valid(plaintext)),
                AES.encrypt_checked(key, nonce, aad, plaintext, aad_flag,
                    plaintext_flag),
                Equal.cong(Bool, Result<&2, &2, AES.Error, AES.Envelope>,
                    flag => AES.encrypt_checked(key, nonce, aad, plaintext,
                        flag, AES.plaintext_valid(plaintext)),
                    AES.aad_valid(aad), aad_flag, aad_ok),
                Equal.cong(Bool, Result<&2, &2, AES.Error, AES.Envelope>,
                    flag => AES.encrypt_checked(key, nonce, aad, plaintext,
                        aad_flag, flag),
                    AES.plaintext_valid(plaintext), plaintext_flag,
                    plaintext_ok)))
    Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
        AES.encrypt_checked(key, nonce, aad, plaintext, aad_flag,
            plaintext_flag),
        AES.encrypt(key, nonce, aad, plaintext),
        Done{envelope},
        Equal.sym(Result<&2, &2, AES.Error, AES.Envelope>,
            AES.encrypt(key, nonce, aad, plaintext),
            AES.encrypt_checked(key, nonce, aad, plaintext, aad_flag,
                plaintext_flag), changed_flags),
        encrypted)

def successful_encrypt_aad_valid(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +aad_flag: Bool, +plaintext_flag: Bool,
    aad_ok: {AES.aad_valid(aad) == aad_flag : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == plaintext_flag : Bool},
    +envelope: AES.Envelope,
    encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {aad_flag == True{} : Bool}:
    match aad_flag:
        case True{}: {==}
        case False{}:
            checked = encrypt_checked_with_flags(key, nonce, aad, plaintext,
                aad_flag, plaintext_flag, aad_ok, plaintext_ok, envelope,
                encrypted)
            Equal.trans(Bool, False{},
                Result.is_done(&2, &2, AES.Error, AES.Envelope,
                    AES.encrypt_checked(key, nonce, aad, plaintext,
                        aad_flag, plaintext_flag)),
                True{}, {==},
                Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>, Bool,
                    result => Result.is_done(&2, &2, AES.Error, AES.Envelope,
                        result),
                    AES.encrypt_checked(key, nonce, aad, plaintext,
                        aad_flag, plaintext_flag), Done{envelope}, checked))

def successful_encrypt_plaintext_valid(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +aad_flag: Bool, +plaintext_flag: Bool,
    aad_ok: {AES.aad_valid(aad) == aad_flag : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == plaintext_flag : Bool},
    +envelope: AES.Envelope,
    encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {plaintext_flag == True{} : Bool}:
    match aad_flag plaintext_flag:
        case True{} True{}: {==}
        case True{} False{}:
            checked = encrypt_checked_with_flags(key, nonce, aad, plaintext,
                aad_flag, plaintext_flag, aad_ok, plaintext_ok, envelope,
                encrypted)
            Equal.trans(Bool, False{},
                Result.is_done(&2, &2, AES.Error, AES.Envelope,
                    AES.encrypt_checked(key, nonce, aad, plaintext,
                        aad_flag, plaintext_flag)),
                True{}, {==},
                Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>, Bool,
                    result => Result.is_done(&2, &2, AES.Error, AES.Envelope,
                        result),
                    AES.encrypt_checked(key, nonce, aad, plaintext,
                        aad_flag, plaintext_flag), Done{envelope}, checked))
        case False{} _:
            checked = encrypt_checked_with_flags(key, nonce, aad, plaintext,
                aad_flag, plaintext_flag, aad_ok, plaintext_ok, envelope,
                encrypted)
            Empty.absurd({plaintext_flag == True{} : Bool},
                ZipLengthProof.false_true(Equal.trans(Bool, False{},
                    Result.is_done(&2, &2, AES.Error, AES.Envelope,
                        AES.encrypt_checked(key, nonce, aad, plaintext,
                            aad_flag, plaintext_flag)),
                    True{}, {==},
                    Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>, Bool,
                        result => Result.is_done(&2, &2, AES.Error, AES.Envelope,
                            result),
                        AES.encrypt_checked(key, nonce, aad, plaintext,
                            aad_flag, plaintext_flag), Done{envelope}, checked))))

def result_ciphertext_length(
    result: Result<&2, &2, AES.Error, AES.Envelope>) -> Nat:
    match result:
        case Fail{error}: 0n
        case Done{envelope}:
            List.length(&2, U32, AES.ciphertext(envelope))

def successful_encrypt_preserves_length(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope,
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {List.length(&2, U32, AES.ciphertext(envelope)) ==
     List.length(&2, U32, plaintext) : Nat}:
    +aad_flag = AES.aad_valid(aad)
    +plaintext_flag = AES.plaintext_valid(plaintext)
    aad_is_true = successful_encrypt_aad_valid(key, nonce, aad, plaintext,
        aad_flag, plaintext_flag, {==}, {==}, envelope, encrypted)
    plaintext_is_true = successful_encrypt_plaintext_valid(key, nonce,
        aad, plaintext, aad_flag, plaintext_flag, {==}, {==},
        envelope, encrypted)
    checked = encrypt_checked_with_flags(key, nonce, aad, plaintext,
        True{}, True{}, aad_is_true, plaintext_is_true, envelope, encrypted)
    output_length = valid_output_ciphertext_length(key, nonce, aad, plaintext)
    Equal.trans(Nat,
        List.length(&2, U32, AES.ciphertext(envelope)),
        result_ciphertext_length(
            AES.encrypt_checked(key, nonce, aad, plaintext, True{}, True{})),
        List.length(&2, U32, plaintext),
        Equal.sym(Nat,
            result_ciphertext_length(
                AES.encrypt_checked(key, nonce, aad, plaintext, True{}, True{})),
            result_ciphertext_length(Done{envelope}),
            Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>, Nat,
                result => result_ciphertext_length(result),
                AES.encrypt_checked(key, nonce, aad, plaintext, True{}, True{}),
                Done{envelope}, checked)),
        output_length)

def successful_encrypt_ciphertext_matches_gcm(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>, +envelope: AES.Envelope,
    aad_valid: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_valid: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.ciphertext(envelope) ==
     CoreTagProof.output_ciphertext(AES.encrypt_valid_output(key, nonce,
        aad, plaintext)) : List<&2, U32>}:
    checked = encrypt_checked_with_flags(key, nonce, aad, plaintext,
        True{}, True{}, aad_valid, plaintext_valid, envelope, encrypted)
    +output = AES.encrypt_valid_output(key, nonce, aad, plaintext)
    constructed_matches = Equal.cong(
        Result<&2, &2, AES.Error, AES.Envelope>, List<&2, U32>,
        result => result_ciphertext(AES.ciphertext(envelope), result),
        AES.encrypt_checked(key, nonce, aad, plaintext, True{}, True{}),
        Done{envelope}, checked)
    Equal.trans(List<&2, U32>,
        AES.ciphertext(envelope),
        AES.ciphertext(AES.envelope_from_gcm_checked(nonce, output)),
        CoreTagProof.output_ciphertext(output),
        Equal.sym(List<&2, U32>,
            AES.ciphertext(AES.envelope_from_gcm_checked(nonce, output)),
            AES.ciphertext(envelope), constructed_matches),
        CoreTagProof.envelope_gcm_ciphertext(nonce, output))

def successful_encrypt_tag_matches_gcm(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope,
    aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool},
    encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.tag_bytes(AES.envelope_tag(envelope)) ==
     CoreTagProof.output_tag(AES.encrypt_valid_output(key, nonce, aad,
        plaintext)) : List<&2, U32>}:
    checked = encrypt_checked_with_flags(key, nonce, aad, plaintext,
        True{}, True{}, aad_ok, plaintext_ok, envelope, encrypted)
    +output = AES.encrypt_valid_output(key, nonce, aad, plaintext)
    constructed_matches = Equal.cong(
        Result<&2, &2, AES.Error, AES.Envelope>, List<&2, U32>,
        result => result_tag_bytes([], result),
        AES.encrypt_checked(key, nonce, aad, plaintext, True{}, True{}),
        Done{envelope}, checked)
    Equal.trans(List<&2, U32>, AES.tag_bytes(AES.envelope_tag(envelope)),
        AES.tag_bytes(AES.envelope_tag(AES.envelope_from_gcm_checked(nonce,
            output))), CoreTagProof.output_tag(output),
        Equal.sym(List<&2, U32>,
            AES.tag_bytes(AES.envelope_tag(AES.envelope_from_gcm_checked(
                nonce, output))), AES.tag_bytes(AES.envelope_tag(envelope)),
            constructed_matches), CoreTagProof.envelope_gcm_tag(nonce, output))

def successful_encrypt_tag_canonical(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope,
    +aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    +plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.tag_bytes(AES.envelope_tag(envelope)) == Core.gcm_tag_bytes(
        Core.gcm_tag_output(Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(nonce), aad, AES.ciphertext(envelope))) :
        List<&2, U32>}:
    +output = AES.encrypt_valid_output(key, nonce, aad, plaintext)
    tag_matches = successful_encrypt_tag_matches_gcm(key, nonce, aad,
        plaintext, envelope, aad_ok, plaintext_ok, encrypted)
    ciphertext_matches = successful_encrypt_ciphertext_matches_gcm(key,
        nonce, aad, plaintext, envelope, aad_ok, plaintext_ok, encrypted)
    raw_canonical = raw_output_tag_canonical(AES.secret_key_bytes(key),
        AES.raw_nonce_bytes(nonce), aad, plaintext)
    current_ciphertext = Equal.cong(List<&2, U32>, List<&2, U32>,
        value => Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(nonce), aad, value)),
        CoreTagProof.output_ciphertext(output), AES.ciphertext(envelope),
        Equal.sym(List<&2, U32>, AES.ciphertext(envelope),
            CoreTagProof.output_ciphertext(output), ciphertext_matches))
    Equal.trans(List<&2, U32>, AES.tag_bytes(AES.envelope_tag(envelope)),
        CoreTagProof.output_tag(output),
        Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(nonce), aad, AES.ciphertext(envelope))),
        tag_matches,
        Equal.trans(List<&2, U32>, CoreTagProof.output_tag(output),
            Core.gcm_tag_bytes(Core.gcm_tag_output(
                Core.aes256_expand(AES.secret_key_bytes(key)),
                AES.raw_nonce_bytes(nonce), aad,
                CoreTagProof.output_ciphertext(output))),
            Core.gcm_tag_bytes(Core.gcm_tag_output(
                Core.aes256_expand(AES.secret_key_bytes(key)),
                AES.raw_nonce_bytes(nonce), aad, AES.ciphertext(envelope))),
            raw_canonical, current_ciphertext))

def successful_encrypt_ciphertext_matches_ctr(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>, +envelope: AES.Envelope,
    aad_valid: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_valid: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.ciphertext(envelope) ==
     Core.gcm_zip_xor(plaintext,
        Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
            Core.aes256_expand(AES.secret_key_bytes(key)),
            Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(nonce))))) :
        List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        AES.ciphertext(envelope),
        CoreTagProof.output_ciphertext(AES.encrypt_valid_output(key, nonce,
            aad, plaintext)),
        Core.gcm_zip_xor(plaintext,
            Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
                Core.aes256_expand(AES.secret_key_bytes(key)),
                Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(nonce))))),
        successful_encrypt_ciphertext_matches_gcm(key, nonce, aad,
            plaintext, envelope, aad_valid, plaintext_valid, encrypted),
        CoreTagProof.raw_encrypt_output_ciphertext(
            AES.secret_key_bytes(key), AES.raw_nonce_bytes(nonce), aad,
            plaintext))

def successful_encrypt_ciphertext_valid(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>, +envelope: AES.Envelope,
    aad_valid: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_valid: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.plaintext_valid(AES.ciphertext(envelope)) == True{} : Bool}:
    length_eq = successful_encrypt_preserves_length(key, nonce, aad,
        plaintext, envelope, encrypted)
    LengthLimitProof.plaintext_valid_same_length(
        AES.ciphertext(envelope), plaintext,
        AES.envelope_ciphertext_valid(envelope), plaintext_valid, length_eq)

def successful_encrypt_ctr_decrypts(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>, +envelope: AES.Envelope,
    aad_valid: {AES.aad_valid(aad) == True{} : Bool},
    +plaintext_valid: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {Core.gcm_decrypt_raw(AES.secret_key_bytes(key),
        AES.raw_nonce_bytes(nonce), AES.ciphertext(envelope)) ==
     plaintext : List<&2, U32>}:
    +words = Core.aes256_expand(AES.secret_key_bytes(key))
    aes_bytes_valid = MaskedXorProof.bool_and_true_left(
        AES.bytes_valid(plaintext),
        AES.bytes_length_limit(plaintext, 4294967264, 15), plaintext_valid)
    core_bytes_valid = Equal.trans(Bool,
        Core.gcm_bytes_valid(plaintext), AES.bytes_valid(plaintext), True{},
        Equal.sym(Bool, AES.bytes_valid(plaintext),
            Core.gcm_bytes_valid(plaintext),
            AES.core_bytes_valid_eq(plaintext)), aes_bytes_valid)
    cipher = successful_encrypt_ciphertext_matches_ctr(key, nonce, aad,
        plaintext, envelope, aad_valid, plaintext_valid, encrypted)
    Equal.trans(List<&2, U32>,
        Core.gcm_decrypt_raw(AES.secret_key_bytes(key),
            AES.raw_nonce_bytes(nonce), AES.ciphertext(envelope)),
        Core.gcm_decrypt_raw(AES.secret_key_bytes(key),
            AES.raw_nonce_bytes(nonce),
            Core.gcm_zip_xor(plaintext,
                Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
                    words, Core.gcm_inc32(Core.gcm_j0(
                        AES.raw_nonce_bytes(nonce)))))),
        plaintext,
        Equal.cong(List<&2, U32>, List<&2, U32>,
            ciphertext => Core.gcm_decrypt_raw(AES.secret_key_bytes(key),
                AES.raw_nonce_bytes(nonce), ciphertext),
            AES.ciphertext(envelope),
            Core.gcm_zip_xor(plaintext,
                Core.gcm_ctr_stream_exact(List.length(&2, U32, plaintext),
                    words, Core.gcm_inc32(Core.gcm_j0(
                        AES.raw_nonce_bytes(nonce))))), cipher),
        MaskedXorProof.ctr_decrypt_ciphertext_roundtrip(words,
            AES.raw_nonce_bytes(nonce), plaintext, core_bytes_valid))

def result_nonce(fallback: AES.Nonce,
    result: Result<&2, &2, AES.Error, AES.Envelope>) -> AES.Nonce:
    match result:
        case Fail{error}: fallback
        case Done{envelope}: AES.envelope_nonce(envelope)

def output_nonce(+nonce: AES.Nonce, +output: Core.GcmOutput) ->
    {result_nonce(nonce, AES.encrypt_output_from_gcm(nonce, output)) ==
     nonce : AES.Nonce}:
    match output:
        case Core.GcmOutput{+ciphertext, ciphertext_valid,
            tag_bytes, tag_valid, tag_size, tag_words, tag_nonce, tag_aad,
            tag_matches}:
            {==}

def valid_nonce(key: AES.SecretKey, +nonce: AES.Nonce,
    aad: List<&2, U32>, plaintext: List<&2, U32>) ->
    {result_nonce(nonce, AES.encrypt_valid(key, nonce, aad, plaintext)) ==
     nonce : AES.Nonce}:
    output_nonce(nonce,
        AES.encrypt_valid_output(key, nonce, aad, plaintext))

def checked_nonce(key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    aad_ok: Bool, plaintext_ok: Bool) ->
    {result_nonce(nonce, AES.encrypt_checked(key, nonce, aad, plaintext,
        aad_ok, plaintext_ok)) == nonce : AES.Nonce}:
    match aad_ok plaintext_ok:
        case True{} True{}: valid_nonce(key, nonce, aad, plaintext)
        case False{} _: {==}
        case True{} False{}: {==}

def encrypt_nonce(key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>) ->
    {result_nonce(nonce, AES.encrypt(key, nonce, aad, plaintext)) ==
     nonce : AES.Nonce}:
    checked_nonce(key, nonce, aad, plaintext,
        AES.aad_valid(aad), AES.plaintext_valid(plaintext))

def preserves_nonce(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope,
    encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.envelope_nonce(envelope) == nonce : AES.Nonce}:
    Equal.trans(AES.Nonce,
        result_nonce(nonce, Done{envelope}),
        result_nonce(nonce, AES.encrypt(key, nonce, aad, plaintext)),
        nonce,
        Equal.sym(AES.Nonce,
            result_nonce(nonce, AES.encrypt(key, nonce, aad, plaintext)),
            result_nonce(nonce, Done{envelope}),
            Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>, AES.Nonce,
                result => result_nonce(nonce, result),
                AES.encrypt(key, nonce, aad, plaintext), Done{envelope},
                encrypted)),
        encrypt_nonce(key, nonce, aad, plaintext))

def successful_encrypt_envelope_tag_canonical(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope,
    aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.tag_bytes(AES.envelope_tag(envelope)) == Core.gcm_tag_bytes(
        Core.gcm_tag_output(Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), aad,
            AES.ciphertext(envelope))) : List<&2, U32>}:
    canonical = successful_encrypt_tag_canonical(key, nonce, aad, plaintext,
        envelope, aad_ok, plaintext_ok, encrypted)
    nonce_matches = Equal.cong(AES.Nonce, List<&2, U32>,
        AES.raw_nonce_bytes, AES.envelope_nonce(envelope), nonce,
        preserves_nonce(key, nonce, aad, plaintext, envelope, encrypted))
    nonce_rewrite = Equal.cong(List<&2, U32>, List<&2, U32>,
        value => Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(AES.secret_key_bytes(key)), value, aad,
            AES.ciphertext(envelope))), AES.raw_nonce_bytes(nonce),
        AES.raw_nonce_bytes(AES.envelope_nonce(envelope)),
        Equal.sym(List<&2, U32>,
            AES.raw_nonce_bytes(AES.envelope_nonce(envelope)),
            AES.raw_nonce_bytes(nonce), nonce_matches))
    Equal.trans(List<&2, U32>, AES.tag_bytes(AES.envelope_tag(envelope)),
        Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(nonce), aad, AES.ciphertext(envelope))),
        Core.gcm_tag_bytes(Core.gcm_tag_output(
            Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), aad,
            AES.ciphertext(envelope))), canonical, nonce_rewrite)

def decrypt_auth_tag_canonical(+words: List<&2, U32>,
    +nonce: List<&2, U32>, +aad: List<&2, U32>,
    +ciphertext: List<&2, U32>, +envelope: AES.Envelope, +tag: AES.Tag,
    canonical: {AES.tag_bytes(tag) == Core.gcm_tag_bytes(
        Core.gcm_tag_output(words, nonce, aad, ciphertext)) : List<&2, U32>}) ->
    {AES.decrypt_authenticated_tag(words, nonce, aad, ciphertext, envelope,
        tag) == AES.decrypt_auth_result(words, envelope, True{}) :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    match tag:
        case AES.Tag{bytes, size, valid}:
            Equal.cong(Bool, Result<&2, &2, AES.Error, List<&2, U32>>,
                ok => AES.decrypt_auth_result(words, envelope, ok),
                AES.bytes_equal_full_scan(bytes, Core.gcm_tag_bytes(
                    Core.gcm_tag_output(words, nonce, aad, ciphertext))),
                True{}, TagCompareProof.equal_of_equal(bytes,
                    Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce,
                        aad, ciphertext)), canonical))

def successful_encrypt_decrypt_authenticated(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +envelope: AES.Envelope,
    +aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    +plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool},
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.decrypt_authenticated(key, aad, envelope) == Done{plaintext} :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    match key envelope:
        case AES.SecretKey{+key_bytes, _, _}
             AES.Envelope{envelope_nonce, ciphertext, tag, _}:
            +words = Core.aes256_expand(key_bytes)
            +nonce_bytes = AES.raw_nonce_bytes(envelope_nonce)
            canonical = successful_encrypt_envelope_tag_canonical(key,
                nonce, aad, plaintext, envelope, aad_ok, plaintext_ok,
                encrypted)
            authenticated = decrypt_auth_tag_canonical(words, nonce_bytes,
                aad, ciphertext, envelope, tag, canonical)
            nonce_matches = Equal.cong(AES.Nonce, List<&2, U32>,
                AES.raw_nonce_bytes, envelope_nonce, nonce,
                preserves_nonce(key, nonce, aad, plaintext, envelope,
                    encrypted))
            ctr_roundtrip = successful_encrypt_ctr_decrypts(key, nonce, aad,
                plaintext, envelope, aad_ok, plaintext_ok, encrypted)
            expanded_nonce = Equal.cong(List<&2, U32>, List<&2, U32>,
                value => Core.gcm_decrypt_expanded(words, value, ciphertext),
                nonce_bytes, AES.raw_nonce_bytes(nonce), nonce_matches)
            expanded_to_raw = Equal.trans(List<&2, U32>,
                Core.gcm_decrypt_expanded(words, nonce_bytes, ciphertext),
                Core.gcm_decrypt_expanded(words, AES.raw_nonce_bytes(nonce),
                    ciphertext),
                Core.gcm_decrypt_raw(AES.secret_key_bytes(key),
                    AES.raw_nonce_bytes(nonce), ciphertext),
                expanded_nonce, {==})
            expanded_roundtrip = Equal.trans(List<&2, U32>,
                Core.gcm_decrypt_expanded(words, nonce_bytes, ciphertext),
                Core.gcm_decrypt_raw(AES.secret_key_bytes(key),
                    AES.raw_nonce_bytes(nonce), ciphertext), plaintext,
                expanded_to_raw, ctr_roundtrip)
            payload = Equal.cong(List<&2, U32>,
                Result<&2, &2, AES.Error, List<&2, U32>>,
                value => Done{value},
                Core.gcm_decrypt_expanded(words, nonce_bytes, ciphertext),
                plaintext, expanded_roundtrip)
            Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
                AES.decrypt_authenticated(key, aad, envelope),
                AES.decrypt_auth_result(words, envelope, True{}),
                Done{plaintext}, authenticated, payload)

def successful_encrypt_decrypt_roundtrip(+key: AES.SecretKey,
    +nonce: AES.Nonce, +aad: List<&2, U32>,
    +plaintext: List<&2, U32>, +envelope: AES.Envelope,
    +encrypted: {AES.encrypt(key, nonce, aad, plaintext) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.decrypt(key, aad, envelope) == Done{plaintext} :
        Result<&2, &2, AES.Error, List<&2, U32>>}:
    +aad_ok = successful_encrypt_aad_valid(key, nonce, aad, plaintext,
        AES.aad_valid(aad), AES.plaintext_valid(plaintext), {==}, {==},
        envelope, encrypted)
    +plaintext_ok = successful_encrypt_plaintext_valid(key, nonce, aad,
        plaintext, AES.aad_valid(aad), AES.plaintext_valid(plaintext),
        {==}, {==}, envelope, encrypted)
    ciphertext_ok = successful_encrypt_ciphertext_valid(key, nonce, aad,
        plaintext, envelope, aad_ok, plaintext_ok, encrypted)
    authenticated = successful_encrypt_decrypt_authenticated(key, nonce,
        aad, plaintext, envelope, aad_ok, plaintext_ok, encrypted)
    aad_checked = Equal.cong(Bool,
        Result<&2, &2, AES.Error, List<&2, U32>>,
        flag => AES.decrypt_checked(key, aad, envelope, flag,
            AES.plaintext_valid(AES.ciphertext(envelope))),
        AES.aad_valid(aad), True{}, aad_ok)
    ciphertext_checked = Equal.cong(Bool,
        Result<&2, &2, AES.Error, List<&2, U32>>,
        flag => AES.decrypt_checked(key, aad, envelope, True{}, flag),
        AES.plaintext_valid(AES.ciphertext(envelope)), True{}, ciphertext_ok)
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
        AES.decrypt(key, aad, envelope),
        AES.decrypt_checked(key, aad, envelope, True{}, True{}),
        Done{plaintext},
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            AES.decrypt(key, aad, envelope),
            AES.decrypt_checked(key, aad, envelope,
                AES.aad_valid(aad),
                AES.plaintext_valid(AES.ciphertext(envelope))),
            AES.decrypt_checked(key, aad, envelope, True{}, True{}),
            {==},
            Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
                AES.decrypt_checked(key, aad, envelope,
                    AES.aad_valid(aad),
                    AES.plaintext_valid(AES.ciphertext(envelope))),
                AES.decrypt_checked(key, aad, envelope, True{},
                    AES.plaintext_valid(AES.ciphertext(envelope))),
                AES.decrypt_checked(key, aad, envelope, True{}, True{}),
                aad_checked, ciphertext_checked)),
        authenticated)

def output_is_done(+nonce: AES.Nonce, +output: Core.GcmOutput) ->
    {Result.is_done(&2, &2, AES.Error, AES.Envelope,
        AES.encrypt_output_from_gcm(nonce, output)) == True{} : Bool}:
    {==}

def valid_is_done(key: AES.SecretKey, +nonce: AES.Nonce,
    aad: List<&2, U32>, plaintext: List<&2, U32>) ->
    {Result.is_done(&2, &2, AES.Error, AES.Envelope,
        AES.encrypt_valid(key, nonce, aad, plaintext)) == True{} : Bool}:
    output_is_done(nonce,
        AES.encrypt_valid_output(key, nonce, aad, plaintext))

def valid_input_is_done(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool}) ->
    {Result.is_done(&2, &2, AES.Error, AES.Envelope,
        AES.encrypt(key, nonce, aad, plaintext)) == True{} : Bool}:
    Equal.trans(Bool,
        Result.is_done(&2, &2, AES.Error, AES.Envelope,
            AES.encrypt(key, nonce, aad, plaintext)),
        Result.is_done(&2, &2, AES.Error, AES.Envelope,
            AES.encrypt_checked(key, nonce, aad, plaintext,
                True{}, AES.plaintext_valid(plaintext))),
        True{},
        Equal.cong(Bool, Bool,
            b => Result.is_done(&2, &2, AES.Error, AES.Envelope,
                AES.encrypt_checked(key, nonce, aad, plaintext,
                    b, AES.plaintext_valid(plaintext))),
            AES.aad_valid(aad), True{}, aad_ok),
        Equal.trans(Bool,
            Result.is_done(&2, &2, AES.Error, AES.Envelope,
                AES.encrypt_checked(key, nonce, aad, plaintext,
                    True{}, AES.plaintext_valid(plaintext))),
            Result.is_done(&2, &2, AES.Error, AES.Envelope,
                AES.encrypt_valid(key, nonce, aad, plaintext)),
            True{},
            Equal.cong(Bool, Bool,
                b => Result.is_done(&2, &2, AES.Error, AES.Envelope,
                    AES.encrypt_checked(key, nonce, aad, plaintext,
                        True{}, b)),
                AES.plaintext_valid(plaintext), True{}, plaintext_ok),
            valid_is_done(key, nonce, aad, plaintext)))
