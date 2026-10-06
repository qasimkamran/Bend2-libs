import Base
import ../libs/AES256GCM.bend as AES
import ../libs/AES256GCMCore.bend as Core
import ./AES_CoreTagProof.bend as Fields
import ./AES_CertificateProof.bend as Certificate

def tag_equal(+bytes: List<&2, U32>,
    +size: {List.length(&2, U32, bytes) == 16n : Nat},
    +valid: {AES.bytes_valid(bytes) == True{} : Bool},
    +expected: List<&2, U32>, same: {bytes == expected : List<&2, U32>}) ->
    @+expected_size: {List.length(&2, U32, expected) == 16n : Nat} ->
    @+expected_valid: {AES.bytes_valid(expected) == True{} : Bool} ->
    {AES.Tag{bytes, size, valid} ==
     AES.Tag{expected, expected_size, expected_valid} : AES.Tag}:
    %same :
        @+expected_size: {List.length(&2, U32, _) == 16n : Nat} ->
        @+expected_valid: {AES.bytes_valid(_) == True{} : Bool} ->
        {AES.Tag{bytes, size, valid} ==
         AES.Tag{_, expected_size, expected_valid} : AES.Tag}
    expected_size => expected_valid =>
        Equal.trans(AES.Tag, AES.Tag{bytes, size, valid},
            AES.Tag{bytes, expected_size, valid},
            AES.Tag{bytes, expected_size, expected_valid},
            Equal.cong({List.length(&2, U32, bytes) == 16n : Nat}, AES.Tag,
                proof => AES.Tag{bytes, proof, valid}, size, expected_size,
                Certificate.nat_unique(List.length(&2, U32, bytes), 16n,
                    size, expected_size)),
            Equal.cong({AES.bytes_valid(bytes) == True{} : Bool}, AES.Tag,
                proof => AES.Tag{bytes, expected_size, proof}, valid,
                expected_valid, Certificate.bool_unique(AES.bytes_valid(bytes),
                    True{}, valid, expected_valid)))

def envelope_equal(+nonce: AES.Nonce, +ciphertext: List<&2, U32>,
    +tag: AES.Tag, +valid: {AES.bytes_valid(ciphertext) == True{} : Bool},
    +expected_ciphertext: List<&2, U32>, +expected_tag: AES.Tag,
    same_ciphertext: {ciphertext == expected_ciphertext : List<&2, U32>},
    same_tag: {tag == expected_tag : AES.Tag}) ->
    @+expected_valid: {AES.bytes_valid(expected_ciphertext) == True{} : Bool} ->
    {AES.Envelope{nonce, ciphertext, tag, valid} ==
     AES.Envelope{nonce, expected_ciphertext, expected_tag, expected_valid} :
        AES.Envelope}:
    %same_ciphertext :
        @+expected_valid: {AES.bytes_valid(_) == True{} : Bool} ->
        {AES.Envelope{nonce, ciphertext, tag, valid} ==
         AES.Envelope{nonce, _, expected_tag, expected_valid} : AES.Envelope}
    expected_valid =>
        Equal.trans(AES.Envelope,
            AES.Envelope{nonce, ciphertext, tag, valid},
            AES.Envelope{nonce, ciphertext, expected_tag, valid},
            AES.Envelope{nonce, ciphertext, expected_tag, expected_valid},
            Equal.cong(AES.Tag, AES.Envelope,
                value => AES.Envelope{nonce, ciphertext, value, valid},
                tag, expected_tag, same_tag),
            Equal.cong({AES.bytes_valid(ciphertext) == True{} : Bool},
                AES.Envelope,
                proof => AES.Envelope{nonce, ciphertext, expected_tag, proof},
                valid, expected_valid,
                Certificate.bool_unique(AES.bytes_valid(ciphertext), True{},
                    valid, expected_valid)))

def output_matches(+nonce: AES.Nonce, +output: Core.GcmOutput,
    +ciphertext: List<&2, U32>, +tag_bytes: List<&2, U32>,
    ciphertext_matches: {Fields.output_ciphertext(output) == ciphertext :
        List<&2, U32>},
    tag_matches: {Fields.output_tag(output) == tag_bytes : List<&2, U32>}) ->
    @+tag_size: {List.length(&2, U32, tag_bytes) == 16n : Nat} ->
    @+tag_valid: {AES.bytes_valid(tag_bytes) == True{} : Bool} ->
    @+ciphertext_valid: {AES.bytes_valid(ciphertext) == True{} : Bool} ->
    {AES.encrypt_output_from_gcm(nonce, output) ==
     Done{AES.Envelope{nonce, ciphertext,
        AES.Tag{tag_bytes, tag_size, tag_valid}, ciphertext_valid}} :
        Result<&2, &2, AES.Error, AES.Envelope>}:
    match output:
        case Core.GcmOutput{+actual_ciphertext, actual_ciphertext_valid,
            +actual_tag, actual_tag_valid, actual_tag_size, _, _, _, _}:
            tag_size => tag_valid => ciphertext_valid =>
                +actual_valid = AES.core_bytes_valid_proof(actual_ciphertext,
                    actual_ciphertext_valid)
                +actual_tag_value = {AES.Tag{actual_tag, actual_tag_size,
                    AES.core_bytes_valid_proof(actual_tag, actual_tag_valid)} :
                    AES.Tag}
                +expected_tag_value = {AES.Tag{tag_bytes, tag_size, tag_valid} :
                    AES.Tag}
                tag_eq = tag_equal(actual_tag, actual_tag_size,
                    AES.core_bytes_valid_proof(actual_tag, actual_tag_valid),
                    tag_bytes, tag_matches, tag_size, tag_valid)
                envelope_eq = envelope_equal(nonce, actual_ciphertext,
                    actual_tag_value, actual_valid, ciphertext,
                    expected_tag_value, ciphertext_matches, tag_eq,
                    ciphertext_valid)
                Equal.cong(AES.Envelope,
                    Result<&2, &2, AES.Error, AES.Envelope>, value => Done{value},
                    AES.envelope_from_gcm_checked(nonce, output),
                    AES.Envelope{nonce, ciphertext, expected_tag_value,
                        ciphertext_valid}, envelope_eq)

def encrypt_matches(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +ciphertext: List<&2, U32>, +tag_bytes: List<&2, U32>,
    aad_valid: {AES.aad_valid(aad) == True{} : Bool},
    plaintext_valid: {AES.plaintext_valid(plaintext) == True{} : Bool},
    ciphertext_matches: {Fields.output_ciphertext(AES.encrypt_valid_output(
        key, nonce, aad, plaintext)) == ciphertext : List<&2, U32>},
    tag_matches: {Fields.output_tag(AES.encrypt_valid_output(key, nonce, aad,
        plaintext)) == tag_bytes : List<&2, U32>},
    +tag_size: {List.length(&2, U32, tag_bytes) == 16n : Nat},
    +tag_valid: {AES.bytes_valid(tag_bytes) == True{} : Bool},
    +ciphertext_valid: {AES.bytes_valid(ciphertext) == True{} : Bool}) ->
    {AES.encrypt(key, nonce, aad, plaintext) ==
     Done{AES.Envelope{nonce, ciphertext,
        AES.Tag{tag_bytes, tag_size, tag_valid}, ciphertext_valid}} :
        Result<&2, &2, AES.Error, AES.Envelope>}:
    aad_checked = Equal.cong(Bool,
        Result<&2, &2, AES.Error, AES.Envelope>,
        flag => AES.encrypt_checked(key, nonce, aad, plaintext, flag,
            AES.plaintext_valid(plaintext)), AES.aad_valid(aad), True{},
        aad_valid)
    plaintext_checked = Equal.cong(Bool,
        Result<&2, &2, AES.Error, AES.Envelope>,
        flag => AES.encrypt_checked(key, nonce, aad, plaintext, True{}, flag),
        AES.plaintext_valid(plaintext), True{}, plaintext_valid)
    output_eq = output_matches(nonce,
        AES.encrypt_valid_output(key, nonce, aad, plaintext), ciphertext,
        tag_bytes, ciphertext_matches, tag_matches, tag_size, tag_valid,
        ciphertext_valid)
    Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
        AES.encrypt(key, nonce, aad, plaintext),
        AES.encrypt_valid(key, nonce, aad, plaintext),
        Done{AES.Envelope{nonce, ciphertext,
            AES.Tag{tag_bytes, tag_size, tag_valid}, ciphertext_valid}},
        Equal.trans(Result<&2, &2, AES.Error, AES.Envelope>,
            AES.encrypt(key, nonce, aad, plaintext),
            AES.encrypt_checked(key, nonce, aad, plaintext, True{},
                AES.plaintext_valid(plaintext)),
            AES.encrypt_valid(key, nonce, aad, plaintext),
            aad_checked, plaintext_checked), output_eq)
