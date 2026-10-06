import Base
import ../LAWS.bend as L
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core

def ciphertext(output: Core.GcmCiphertext) -> List<&2, U32>:
    match output:
        case Core.GcmCiphertext{bytes, valid}: bytes

def schedule_input_matches(+key: AES.SecretKey, +bytes: List<&2, U32>, +words: List<&2, U32>,
    input_matches: {AES.secret_key_bytes(key) == bytes : List<&2, U32>},
    computed: {Core.aes256_expand(bytes) == words : List<&2, U32>}) ->
    {Core.aes256_expand(AES.secret_key_bytes(key)) == words : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.aes256_expand(AES.secret_key_bytes(key)), Core.aes256_expand(bytes), words,
        Equal.cong(List<&2, U32>, List<&2, U32>, value => Core.aes256_expand(value),
            AES.secret_key_bytes(key), bytes, input_matches), computed)

def stream_parameters(+size: Nat, +words: List<&2, U32>, +start: List<&2, U32>,
    +known_size: Nat, +known_start: List<&2, U32>, +stream: List<&2, U32>,
    count: {size == known_size : Nat}, counter: {start == known_start : List<&2, U32>},
    computed: {Core.gcm_ctr_stream_exact.go(known_size, words, known_start, Nil{}) == stream : List<&2, U32>}) ->
    {Core.gcm_ctr_stream_exact(size, words, start) == stream : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact(size, words, start),
        Core.gcm_ctr_stream_exact.go(known_size, words, start, Nil{}), stream,
        Equal.cong(Nat, List<&2, U32>, n => Core.gcm_ctr_stream_exact.go(n, words, start, Nil{}), size, known_size, count),
        Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(known_size, words, start, Nil{}),
            Core.gcm_ctr_stream_exact.go(known_size, words, known_start, Nil{}), stream,
            Equal.cong(List<&2, U32>, List<&2, U32>, value => Core.gcm_ctr_stream_exact.go(known_size, words, value, Nil{}),
                start, known_start, counter), computed))

def ciphertext_shape(+words: List<&2, U32>, +nonce: List<&2, U32>, +input: List<&2, U32>) ->
    {ciphertext(Core.gcm_ctr_encrypt(words, nonce, input)) == Core.gcm_decrypt_expanded(words, nonce, input) : List<&2, U32>}:
    {==}

def xor_from_stream(+words: List<&2, U32>, +nonce: List<&2, U32>, +input: List<&2, U32>, +stream: List<&2, U32>,
    computed: {Core.gcm_ctr_stream_exact(List.length(&2, U32, input), words, Core.gcm_inc32(Core.gcm_j0(nonce))) == stream : List<&2, U32>}) ->
    {Core.gcm_decrypt_expanded(words, nonce, input) == Core.gcm_zip_xor(input, stream) : List<&2, U32>}:
    Equal.cong(List<&2, U32>, List<&2, U32>, value => Core.gcm_zip_xor(input, value),
        Core.gcm_ctr_stream_exact(List.length(&2, U32, input), words, Core.gcm_inc32(Core.gcm_j0(nonce))), stream, computed)

def finish_cipher(+words: List<&2, U32>, +nonce: List<&2, U32>, +input: List<&2, U32>, +stream: List<&2, U32>, +output: List<&2, U32>,
    computed: {Core.gcm_ctr_stream_exact(List.length(&2, U32, input), words, Core.gcm_inc32(Core.gcm_j0(nonce))) == stream : List<&2, U32>},
    xor_matches: {Core.gcm_zip_xor(input, stream) == output : List<&2, U32>}) ->
    {ciphertext(Core.gcm_ctr_encrypt(words, nonce, input)) == output : List<&2, U32>}:
    Equal.trans(List<&2, U32>, ciphertext(Core.gcm_ctr_encrypt(words, nonce, input)),
        Core.gcm_decrypt_expanded(words, nonce, input), output, ciphertext_shape(words, nonce, input),
        Equal.trans(List<&2, U32>, Core.gcm_decrypt_expanded(words, nonce, input),
            Core.gcm_zip_xor(input, stream), output, xor_from_stream(words, nonce, input, stream, computed), xor_matches))

def parts(+words: List<&2, U32>, +nonce: AES.Nonce,
          +aad: List<&2, U32>, +bytes: List<&2, U32>) -> List<&2, U32>:
    List.append(&2, U32, AES.raw_nonce_bytes(nonce),
        List.append(&2, U32, bytes,
            Core.gcm_tag_bytes(Core.gcm_tag_output(words,
                AES.raw_nonce_bytes(nonce), aad, bytes))))

def expanded(+words: List<&2, U32>, +nonce: AES.Nonce,
             +aad: List<&2, U32>, +plaintext: List<&2, U32>) -> List<&2, U32>:
    parts(words, nonce, aad,
        ciphertext(Core.gcm_ctr_encrypt(words, AES.raw_nonce_bytes(nonce), plaintext)))

def from_ciphertext(+words: List<&2, U32>, +nonce: AES.Nonce,
                    +aad: List<&2, U32>, +output: Core.GcmCiphertext) ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt_output_from_gcm(nonce,
        Core.gcm_output_from_ciphertext(words, AES.raw_nonce_bytes(nonce), aad, output))) ==
     parts(words, nonce, aad, ciphertext(output)) : List<&2, U32>}:
    match nonce output:
        case AES.Nonce{nonce_bytes, nonce_size, nonce_valid} Core.GcmCiphertext{bytes, valid}: {==}

def valid_encrypt(+key: AES.SecretKey, +nonce: AES.Nonce,
                  +aad: List<&2, U32>, +plaintext: List<&2, U32>) ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt_valid(key, nonce, aad, plaintext)) ==
     expanded(Core.aes256_expand(AES.secret_key_bytes(key)), nonce, aad, plaintext) : List<&2, U32>}:
    from_ciphertext(Core.aes256_expand(AES.secret_key_bytes(key)), nonce, aad,
        Core.gcm_ctr_encrypt(Core.aes256_expand(AES.secret_key_bytes(key)),
            AES.raw_nonce_bytes(nonce), plaintext))

def checked_encrypt(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool}) ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, aad, plaintext)) ==
     expanded(Core.aes256_expand(AES.secret_key_bytes(key)), nonce, aad, plaintext) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, aad, plaintext)),
        L.aes256gcm_nist_encrypt_observation(AES.encrypt_valid(key, nonce, aad, plaintext)),
        expanded(Core.aes256_expand(AES.secret_key_bytes(key)), nonce, aad, plaintext),
        Equal.trans(List<&2, U32>,
            L.aes256gcm_nist_encrypt_observation(AES.encrypt_checked(key, nonce, aad, plaintext,
                AES.aad_valid(aad), AES.plaintext_valid(plaintext))),
            L.aes256gcm_nist_encrypt_observation(AES.encrypt_checked(key, nonce, aad, plaintext,
                True{}, AES.plaintext_valid(plaintext))),
            L.aes256gcm_nist_encrypt_observation(AES.encrypt_checked(key, nonce, aad, plaintext,
                True{}, True{})),
            Equal.cong(Bool, List<&2, U32>, flag =>
                L.aes256gcm_nist_encrypt_observation(AES.encrypt_checked(key, nonce, aad, plaintext,
                    flag, AES.plaintext_valid(plaintext))),
                AES.aad_valid(aad), True{}, aad_ok),
            Equal.cong(Bool, List<&2, U32>, flag =>
                L.aes256gcm_nist_encrypt_observation(AES.encrypt_checked(key, nonce, aad, plaintext,
                    True{}, flag)),
                AES.plaintext_valid(plaintext), True{}, plaintext_ok)),
        valid_encrypt(key, nonce, aad, plaintext))

def finish_encrypt(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +words: List<&2, U32>, +bytes: List<&2, U32>, +tag: List<&2, U32>,
    aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_ok: {AES.plaintext_valid(plaintext) == True{} : Bool},
    key_matches: {Core.aes256_expand(AES.secret_key_bytes(key)) == words : List<&2, U32>},
    ciphertext_matches: {ciphertext(Core.gcm_ctr_encrypt(words, AES.raw_nonce_bytes(nonce), plaintext)) == bytes : List<&2, U32>},
    tag_matches: {Core.gcm_tag_bytes(Core.gcm_tag_output(words, AES.raw_nonce_bytes(nonce), aad, bytes)) == tag : List<&2, U32>}) ->
    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, aad, plaintext)) ==
     List.append(&2, U32, AES.raw_nonce_bytes(nonce), List.append(&2, U32, bytes, tag)) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        L.aes256gcm_nist_encrypt_observation(AES.encrypt(key, nonce, aad, plaintext)),
        expanded(Core.aes256_expand(AES.secret_key_bytes(key)), nonce, aad, plaintext),
        List.append(&2, U32, AES.raw_nonce_bytes(nonce), List.append(&2, U32, bytes, tag)),
        checked_encrypt(key, nonce, aad, plaintext, aad_ok, plaintext_ok),
        Equal.trans(List<&2, U32>,
            expanded(Core.aes256_expand(AES.secret_key_bytes(key)), nonce, aad, plaintext),
            expanded(words, nonce, aad, plaintext),
            List.append(&2, U32, AES.raw_nonce_bytes(nonce), List.append(&2, U32, bytes, tag)),
            Equal.cong(List<&2, U32>, List<&2, U32>, expanded_words =>
                expanded(expanded_words, nonce, aad, plaintext),
                Core.aes256_expand(AES.secret_key_bytes(key)), words, key_matches),
            Equal.trans(List<&2, U32>, expanded(words, nonce, aad, plaintext),
                parts(words, nonce, aad, bytes),
                List.append(&2, U32, AES.raw_nonce_bytes(nonce), List.append(&2, U32, bytes, tag)),
                Equal.cong(List<&2, U32>, List<&2, U32>, encrypted => parts(words, nonce, aad, encrypted),
                    ciphertext(Core.gcm_ctr_encrypt(words, AES.raw_nonce_bytes(nonce), plaintext)), bytes,
                    ciphertext_matches),
                Equal.cong(List<&2, U32>, List<&2, U32>, tag_bytes =>
                    List.append(&2, U32, AES.raw_nonce_bytes(nonce), List.append(&2, U32, bytes, tag_bytes)),
                    Core.gcm_tag_bytes(Core.gcm_tag_output(words, AES.raw_nonce_bytes(nonce), aad, bytes)),
                    tag, tag_matches))))

def decrypt_expanded(+words: List<&2, U32>, +aad: List<&2, U32>,
                     +envelope: AES.Envelope) -> Result<&2, &2, AES.Error, List<&2, U32>>:
    match envelope:
        case AES.Envelope{nonce, bytes, tag, valid}:
            AES.decrypt_authenticated_tag(words, AES.raw_nonce_bytes(nonce), aad, bytes, envelope, tag)

def decrypt_key_shape(+key: AES.SecretKey, +aad: List<&2, U32>, +envelope: AES.Envelope) ->
    {AES.decrypt_authenticated(key, aad, envelope) ==
     decrypt_expanded(Core.aes256_expand(AES.secret_key_bytes(key)), aad, envelope) : Result<&2, &2, AES.Error, List<&2, U32>>}:
    match key envelope:
        case AES.SecretKey{key_bytes, key_size, key_valid} AES.Envelope{nonce, bytes, tag, valid}: {==}

def payload_shape(+words: List<&2, U32>, +envelope: AES.Envelope) ->
    {AES.decrypt_auth_result(words, envelope, True{}) ==
     Done{Core.gcm_decrypt_expanded(words, AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), AES.ciphertext(envelope))} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    match envelope:
        case AES.Envelope{nonce, bytes, tag, valid}: {==}

def payload_parameters(+words: List<&2, U32>, +envelope: AES.Envelope,
    +nonce: List<&2, U32>, +bytes: List<&2, U32>, +plaintext: List<&2, U32>,
    nonce_matches: {AES.raw_nonce_bytes(AES.envelope_nonce(envelope)) == nonce : List<&2, U32>},
    ciphertext_matches: {AES.ciphertext(envelope) == bytes : List<&2, U32>},
    computed: {Core.gcm_decrypt_expanded(words, nonce, bytes) == plaintext : List<&2, U32>}) ->
    {AES.decrypt_auth_result(words, envelope, True{}) == Done{plaintext} : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>, AES.decrypt_auth_result(words, envelope, True{}),
        Done{Core.gcm_decrypt_expanded(words, AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), AES.ciphertext(envelope))},
        Done{plaintext}, payload_shape(words, envelope),
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            Done{Core.gcm_decrypt_expanded(words, AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), AES.ciphertext(envelope))},
            Done{Core.gcm_decrypt_expanded(words, nonce, AES.ciphertext(envelope))}, Done{plaintext},
            Equal.cong(List<&2, U32>, Result<&2, &2, AES.Error, List<&2, U32>>, value => Done{Core.gcm_decrypt_expanded(words, value, AES.ciphertext(envelope))},
                AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), nonce, nonce_matches),
            Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>, Done{Core.gcm_decrypt_expanded(words, nonce, AES.ciphertext(envelope))},
                Done{Core.gcm_decrypt_expanded(words, nonce, bytes)}, Done{plaintext},
                Equal.cong(List<&2, U32>, Result<&2, &2, AES.Error, List<&2, U32>>, value => Done{Core.gcm_decrypt_expanded(words, nonce, value)},
                    AES.ciphertext(envelope), bytes, ciphertext_matches),
                Equal.cong(List<&2, U32>, Result<&2, &2, AES.Error, List<&2, U32>>, value => Done{value},
                    Core.gcm_decrypt_expanded(words, nonce, bytes), plaintext, computed))))

def envelope_tag_computed(+words: List<&2, U32>, +aad: List<&2, U32>, +envelope: AES.Envelope) -> List<&2, U32>:
    Core.gcm_tag_bytes(Core.gcm_tag_output(words, AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), aad, AES.ciphertext(envelope)))

def tag_parameters(+words: List<&2, U32>, +aad: List<&2, U32>, +envelope: AES.Envelope,
    +nonce: List<&2, U32>, +bytes: List<&2, U32>, +tag: List<&2, U32>,
    nonce_matches: {AES.raw_nonce_bytes(AES.envelope_nonce(envelope)) == nonce : List<&2, U32>},
    ciphertext_matches: {AES.ciphertext(envelope) == bytes : List<&2, U32>},
    computed: {Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, bytes)) == tag : List<&2, U32>}) ->
    {envelope_tag_computed(words, aad, envelope) == tag : List<&2, U32>}:
    Equal.trans(List<&2, U32>, envelope_tag_computed(words, aad, envelope),
        Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, AES.ciphertext(envelope))), tag,
        Equal.cong(List<&2, U32>, List<&2, U32>, value =>
            Core.gcm_tag_bytes(Core.gcm_tag_output(words, value, aad, AES.ciphertext(envelope))),
            AES.raw_nonce_bytes(AES.envelope_nonce(envelope)), nonce, nonce_matches),
        Equal.trans(List<&2, U32>, Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, AES.ciphertext(envelope))),
            Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, bytes)), tag,
            Equal.cong(List<&2, U32>, List<&2, U32>, value =>
                Core.gcm_tag_bytes(Core.gcm_tag_output(words, nonce, aad, value)),
                AES.ciphertext(envelope), bytes, ciphertext_matches), computed))

def auth_for_tag(+envelope: AES.Envelope, tag: List<&2, U32>) -> Bool:
    AES.bytes_equal_full_scan(AES.tag_bytes(AES.envelope_tag(envelope)), tag)

def decrypt_auth_shape(+words: List<&2, U32>, +aad: List<&2, U32>, +envelope: AES.Envelope) ->
    {decrypt_expanded(words, aad, envelope) == AES.decrypt_auth_result(words, envelope,
        auth_for_tag(envelope, envelope_tag_computed(words, aad, envelope))) : Result<&2, &2, AES.Error, List<&2, U32>>}:
    match envelope:
        case AES.Envelope{nonce, bytes, tag, valid}:
            match tag:
                case AES.Tag{tag_bytes, tag_size, tag_valid}: {==}

def finish_auth(+words: List<&2, U32>, +aad: List<&2, U32>, +envelope: AES.Envelope,
    +tag: List<&2, U32>, +flag: Bool, +result: Result<&2, &2, AES.Error, List<&2, U32>>,
    tag_matches: {envelope_tag_computed(words, aad, envelope) == tag : List<&2, U32>},
    compare_matches: {auth_for_tag(envelope, tag) == flag : Bool},
    branch_matches: {AES.decrypt_auth_result(words, envelope, flag) == result : Result<&2, &2, AES.Error, List<&2, U32>>}) ->
    {decrypt_expanded(words, aad, envelope) == result : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
        decrypt_expanded(words, aad, envelope),
        AES.decrypt_auth_result(words, envelope, auth_for_tag(envelope, envelope_tag_computed(words, aad, envelope))),
        result, decrypt_auth_shape(words, aad, envelope),
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            AES.decrypt_auth_result(words, envelope, auth_for_tag(envelope, envelope_tag_computed(words, aad, envelope))),
            AES.decrypt_auth_result(words, envelope, auth_for_tag(envelope, tag)), result,
            Equal.cong(List<&2, U32>, Result<&2, &2, AES.Error, List<&2, U32>>, actual_tag =>
                AES.decrypt_auth_result(words, envelope, auth_for_tag(envelope, actual_tag)),
                envelope_tag_computed(words, aad, envelope), tag, tag_matches),
            Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
                AES.decrypt_auth_result(words, envelope, auth_for_tag(envelope, tag)),
                AES.decrypt_auth_result(words, envelope, flag), result,
                Equal.cong(Bool, Result<&2, &2, AES.Error, List<&2, U32>>, accepted => AES.decrypt_auth_result(words, envelope, accepted),
                    auth_for_tag(envelope, tag), flag, compare_matches), branch_matches)))

def finish_decrypt(+key: AES.SecretKey, +aad: List<&2, U32>, +envelope: AES.Envelope,
    +words: List<&2, U32>, +result: Result<&2, &2, AES.Error, List<&2, U32>>,
    aad_ok: {AES.aad_valid(aad) == True{} : Bool},
    ciphertext_ok: {AES.plaintext_valid(AES.ciphertext(envelope)) == True{} : Bool},
    key_matches: {Core.aes256_expand(AES.secret_key_bytes(key)) == words : List<&2, U32>},
    expanded_matches: {decrypt_expanded(words, aad, envelope) == result : Result<&2, &2, AES.Error, List<&2, U32>>}) ->
    {AES.decrypt(key, aad, envelope) == result : Result<&2, &2, AES.Error, List<&2, U32>>}:
    Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
        AES.decrypt(key, aad, envelope), AES.decrypt_authenticated(key, aad, envelope), result,
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            AES.decrypt_checked(key, aad, envelope, AES.aad_valid(aad), AES.plaintext_valid(AES.ciphertext(envelope))),
            AES.decrypt_checked(key, aad, envelope, True{}, AES.plaintext_valid(AES.ciphertext(envelope))),
            AES.decrypt_checked(key, aad, envelope, True{}, True{}),
            Equal.cong(Bool, Result<&2, &2, AES.Error, List<&2, U32>>, flag =>
                AES.decrypt_checked(key, aad, envelope, flag, AES.plaintext_valid(AES.ciphertext(envelope))),
                AES.aad_valid(aad), True{}, aad_ok),
            Equal.cong(Bool, Result<&2, &2, AES.Error, List<&2, U32>>, flag =>
                AES.decrypt_checked(key, aad, envelope, True{}, flag),
                AES.plaintext_valid(AES.ciphertext(envelope)), True{}, ciphertext_ok)),
        Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
            AES.decrypt_authenticated(key, aad, envelope),
            decrypt_expanded(Core.aes256_expand(AES.secret_key_bytes(key)), aad, envelope), result,
            decrypt_key_shape(key, aad, envelope),
            Equal.trans(Result<&2, &2, AES.Error, List<&2, U32>>,
                decrypt_expanded(Core.aes256_expand(AES.secret_key_bytes(key)), aad, envelope),
                decrypt_expanded(words, aad, envelope), result,
                Equal.cong(List<&2, U32>, Result<&2, &2, AES.Error, List<&2, U32>>, expanded_words =>
                    decrypt_expanded(expanded_words, aad, envelope),
                    Core.aes256_expand(AES.secret_key_bytes(key)), words, key_matches), expanded_matches)))
