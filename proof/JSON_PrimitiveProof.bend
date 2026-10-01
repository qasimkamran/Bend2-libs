import Base
import ../libs/JSON.bend as J

def R() -> Type:
    Result<&1, &1, J.Error, J.Value>

def absurd(-A: Type, empty: Empty) -> A:
    match empty:

def false_type(b: Bool) -> Data:
    match b:
        case False{}: Unit
        case True{}: Empty

def false_true(e: {False{} == True{} : Bool}) -> Empty:
    %e : false_type(_)
    Unit{}

def proof_valid(+valid: Bool, witness: J.NumberProofFrom(valid)) -> {valid == True{} : Bool}:
    match valid:
        case True{}: {==}
        case False{}:
            match witness:

def cert_valid(+text: String,
               certificate: J.NumberCert<text>) -> {J.number_valid(text) == True{} : Bool}:
    match certificate:
        case J.Certified{witness}: proof_valid(J.number_valid(text), witness)

def proof_unique(+valid: Bool,
                 +a: J.NumberProofFrom(valid),
                 +b: J.NumberProofFrom(valid)) -> {a == b : J.NumberProofFrom(valid)}:
    match valid:
        case True{}:
            match a b:
                case Unit{} Unit{}: {==}
        case False{}:
            match a:

def cert_unique(+text: String,
                +a: J.NumberCert<text>,
                +b: J.NumberCert<text>) -> {a == b : J.NumberCert<text>}:
    match a b:
        case J.Certified{x} J.Certified{y}:
            Equal.cong(J.NumberProof(text), J.NumberCert<text>, w => J.Certified{w}, x, y, proof_unique(J.number_valid(text), x, y))

def number_route(+text: String,
                 +valid: Bool,
                 +certificate: J.NumberCert<text>,
                 evidence: {J.number_valid(text) == valid : Bool}) -> {J.payload_number(text, valid, evidence) == Done{J.Number{text, certificate}} : R()}:
    match valid:
        case True{}:
            Equal.cong(J.NumberCert<text>, R(), c => Done{J.Number{text, c}},
                J.Certified{J.number_proof(text, evidence)}, certificate,
                cert_unique(text, J.Certified{J.number_proof(text, evidence)}, certificate))
        case False{}:
            absurd({J.payload_number(text, False{}, evidence) == Done{J.Number{text, certificate}} : R()},
                false_true(Equal.trans(Bool, False{}, J.number_valid(text), True{},
                    Equal.sym(Bool, J.number_valid(text), False{}, evidence), cert_valid(text, certificate))))

def number_roundtrip(+text: String,
                     +certificate: J.NumberCert<text>) -> {J.decode_payload(text) == Done{J.Number{text, certificate}} : R()}:
    number_route(text, J.number_valid(text), certificate, {==})

def invalid_step(+text: String) -> {J.number_valid_step(text, J.NumberInvalid{}) == J.NumberInvalid{} : J.NumberState}:
    match text:
        case SNil{}: {==}
        case SCon{head, tail}: {==}

def route_false(+text: String,
                +valid: Bool,
                evidence: {J.number_valid(text) == valid : Bool},
                no: {valid == False{} : Bool}) -> {J.payload_number(text, valid, evidence) == J.payload_other(text) : R()}:
    match valid:
        case False{}: {==}
        case True{}:
            absurd({J.payload_number(text, True{}, evidence) == J.payload_other(text) : R()}, false_true(Equal.sym(Bool, True{}, False{}, no)))

def decode_false(+text: String,
                 no: {J.number_valid(text) == False{} : Bool}) -> {J.decode_payload(text) == J.payload_other(text) : R()}:
    route_false(text, J.number_valid(text), {==}, no)

def invalid_end(+text: String) -> {J.number_valid_end(J.number_valid_step(text, J.NumberInvalid{})) == False{} : Bool}:
    Equal.cong(J.NumberState, Bool, J.number_valid_end, J.number_valid_step(text, J.NumberInvalid{}), J.NumberInvalid{}, invalid_step(text))
