import Base
import ../libs/AES256GCM.bend as AES
import ./AES_CertificateProof.bend as Certificate
import ./AES_StringEqProof.bend as Logic

def key_certificates(+bytes: List<&2, U32>,
    +first_size: {List.length(&2, U32, bytes) == 32n : Nat},
    +first_valid: {AES.bytes_valid(bytes) == True{} : Bool},
    +second_size: {List.length(&2, U32, bytes) == 32n : Nat},
    +second_valid: {AES.bytes_valid(bytes) == True{} : Bool}) ->
    {AES.SecretKey{bytes, first_size, first_valid} ==
     AES.SecretKey{bytes, second_size, second_valid} : AES.SecretKey}:
    Equal.trans(AES.SecretKey,
        AES.SecretKey{bytes, first_size, first_valid},
        AES.SecretKey{bytes, second_size, first_valid},
        AES.SecretKey{bytes, second_size, second_valid},
        Equal.cong({List.length(&2, U32, bytes) == 32n : Nat}, AES.SecretKey,
            proof => AES.SecretKey{bytes, proof, first_valid},
            first_size, second_size,
            Certificate.nat_unique(List.length(&2, U32, bytes), 32n,
                first_size, second_size)),
        Equal.cong({AES.bytes_valid(bytes) == True{} : Bool}, AES.SecretKey,
            proof => AES.SecretKey{bytes, second_size, proof},
            first_valid, second_valid,
            Certificate.bool_unique(AES.bytes_valid(bytes), True{},
                first_valid, second_valid)))

def key_accepts(+bytes: List<&2, U32>,
    +expected_size: {List.length(&2, U32, bytes) == 32n : Nat},
    +expected_valid: {AES.bytes_valid(bytes) == True{} : Bool},
    size: Maybe<&0, {List.length(&2, U32, bytes) == 32n : Nat}>,
    valid: Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>,
    size_present: {Maybe.is_some(&0,
        {List.length(&2, U32, bytes) == 32n : Nat}, size) == True{} : Bool},
    valid_present: {Maybe.is_some(&0,
        {AES.bytes_valid(bytes) == True{} : Bool}, valid) == True{} : Bool}) ->
    {AES.key_from_proofs(bytes, size, valid) ==
     Done{AES.SecretKey{bytes, expected_size, expected_valid}} :
        Result<&2, &2, AES.Error, AES.SecretKey>}:
    match size valid:
        case None{} _:
            Empty.absurd({AES.key_from_proofs(bytes, size, valid) ==
                Done{AES.SecretKey{bytes, expected_size, expected_valid}} :
                Result<&2, &2, AES.Error, AES.SecretKey>},
                Logic.false_true(size_present))
        case _ None{}:
            Empty.absurd({AES.key_from_proofs(bytes, size, valid) ==
                Done{AES.SecretKey{bytes, expected_size, expected_valid}} :
                Result<&2, &2, AES.Error, AES.SecretKey>},
                Logic.false_true(valid_present))
        case Some{size_proof} Some{valid_proof}:
            Equal.cong(AES.SecretKey,
                Result<&2, &2, AES.Error, AES.SecretKey>, value => Done{value},
                AES.SecretKey{bytes, size_proof, valid_proof},
                AES.SecretKey{bytes, expected_size, expected_valid},
                key_certificates(bytes, size_proof, valid_proof,
                    expected_size, expected_valid))
def nonce_certificates(+bytes: List<&2, U32>,
    +first_size: {List.length(&2, U32, bytes) == 12n : Nat},
    +first_valid: {AES.bytes_valid(bytes) == True{} : Bool},
    +second_size: {List.length(&2, U32, bytes) == 12n : Nat},
    +second_valid: {AES.bytes_valid(bytes) == True{} : Bool}) ->
    {AES.Nonce{bytes, first_size, first_valid} ==
     AES.Nonce{bytes, second_size, second_valid} : AES.Nonce}:
    Equal.trans(AES.Nonce,
        AES.Nonce{bytes, first_size, first_valid},
        AES.Nonce{bytes, second_size, first_valid},
        AES.Nonce{bytes, second_size, second_valid},
        Equal.cong({List.length(&2, U32, bytes) == 12n : Nat}, AES.Nonce,
            proof => AES.Nonce{bytes, proof, first_valid},
            first_size, second_size,
            Certificate.nat_unique(List.length(&2, U32, bytes), 12n,
                first_size, second_size)),
        Equal.cong({AES.bytes_valid(bytes) == True{} : Bool}, AES.Nonce,
            proof => AES.Nonce{bytes, second_size, proof},
            first_valid, second_valid,
            Certificate.bool_unique(AES.bytes_valid(bytes), True{},
                first_valid, second_valid)))

def nonce_accepts(+bytes: List<&2, U32>,
    +expected_size: {List.length(&2, U32, bytes) == 12n : Nat},
    +expected_valid: {AES.bytes_valid(bytes) == True{} : Bool},
    size: Maybe<&0, {List.length(&2, U32, bytes) == 12n : Nat}>,
    valid: Maybe<&0, {AES.bytes_valid(bytes) == True{} : Bool}>,
    size_present: {Maybe.is_some(&0,
        {List.length(&2, U32, bytes) == 12n : Nat}, size) == True{} : Bool},
    valid_present: {Maybe.is_some(&0,
        {AES.bytes_valid(bytes) == True{} : Bool}, valid) == True{} : Bool}) ->
    {AES.nonce_from_proofs(bytes, size, valid) ==
     Done{AES.Nonce{bytes, expected_size, expected_valid}} :
        Result<&2, &2, AES.Error, AES.Nonce>}:
    match size valid:
        case None{} _:
            Empty.absurd({AES.nonce_from_proofs(bytes, size, valid) ==
                Done{AES.Nonce{bytes, expected_size, expected_valid}} :
                Result<&2, &2, AES.Error, AES.Nonce>},
                Logic.false_true(size_present))
        case _ None{}:
            Empty.absurd({AES.nonce_from_proofs(bytes, size, valid) ==
                Done{AES.Nonce{bytes, expected_size, expected_valid}} :
                Result<&2, &2, AES.Error, AES.Nonce>},
                Logic.false_true(valid_present))
        case Some{size_proof} Some{valid_proof}:
            Equal.cong(AES.Nonce,
                Result<&2, &2, AES.Error, AES.Nonce>, value => Done{value},
                AES.Nonce{bytes, size_proof, valid_proof},
                AES.Nonce{bytes, expected_size, expected_valid},
                nonce_certificates(bytes, size_proof, valid_proof,
                    expected_size, expected_valid))

def nonce_equal(+bytes: List<&2, U32>,
    +size: {List.length(&2, U32, bytes) == 12n : Nat},
    +valid: {AES.bytes_valid(bytes) == True{} : Bool},
    +expected: List<&2, U32>, same: {bytes == expected : List<&2, U32>}) ->
    @+expected_size: {List.length(&2, U32, expected) == 12n : Nat} ->
    @+expected_valid: {AES.bytes_valid(expected) == True{} : Bool} ->
    {AES.Nonce{bytes, size, valid} ==
     AES.Nonce{expected, expected_size, expected_valid} : AES.Nonce}:
    %same :
        @+expected_size: {List.length(&2, U32, _) == 12n : Nat} ->
        @+expected_valid: {AES.bytes_valid(_) == True{} : Bool} ->
        {AES.Nonce{bytes, size, valid} ==
         AES.Nonce{_, expected_size, expected_valid} : AES.Nonce}
    expected_size => expected_valid =>
        Equal.trans(AES.Nonce, AES.Nonce{bytes, size, valid},
            AES.Nonce{bytes, expected_size, valid},
            AES.Nonce{bytes, expected_size, expected_valid},
            Equal.cong({List.length(&2, U32, bytes) == 12n : Nat}, AES.Nonce,
                proof => AES.Nonce{bytes, proof, valid}, size, expected_size,
                Certificate.nat_unique(List.length(&2, U32, bytes), 12n,
                    size, expected_size)),
            Equal.cong({AES.bytes_valid(bytes) == True{} : Bool}, AES.Nonce,
                proof => AES.Nonce{bytes, expected_size, proof}, valid,
                expected_valid, Certificate.bool_unique(AES.bytes_valid(bytes),
                    True{}, valid, expected_valid)))
