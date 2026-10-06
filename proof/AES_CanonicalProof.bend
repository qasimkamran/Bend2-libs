import Base
import ../libs/AES256GCM.bend as AES
import ./AES_StringEqProof.bend as StringEq

def encoding_or(text: String,
    result: Result<&2, &2, AES.Error, AES.Envelope>) -> String:
    match result:
        case Fail{error}: text
        case Done{envelope}: AES.encode(envelope)

def canonical_sound_done(+text: String, +found: AES.Envelope,
    +envelope: AES.Envelope, canonical: Bool,
    link: {canonical == String.eq(AES.encode(found), text) : Bool},
    accepted: {AES.parse_canonical_decision(text, found, canonical) ==
        Done{envelope} : Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.encode(envelope) == text : String}:
    match canonical:
        case False{}:
            status = Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>,
                Bool,
                r => Result.is_done(&2, &2, AES.Error, AES.Envelope, r),
                AES.parse_canonical_decision(text, found, False{}),
                Done{envelope}, accepted)
            Empty.absurd({AES.encode(envelope) == text : String},
                StringEq.false_true(status))
        case True{}:
            encoded = Equal.cong(
                Result<&2, &2, AES.Error, AES.Envelope>, String,
                r => encoding_or(text, r),
                AES.parse_canonical_decision(text, found, True{}),
                Done{envelope}, accepted)
            Equal.trans(String,
                AES.encode(envelope), AES.encode(found), text,
                Equal.sym(String,
                    AES.encode(found), AES.encode(envelope), encoded),
                StringEq.string_eq_sound(AES.encode(found), text,
                    Equal.sym(Bool, True{},
                        String.eq(AES.encode(found), text), link)))

def canonical_sound(+text: String,
    result: Result<&2, &2, AES.Error, AES.Envelope>,
    +envelope: AES.Envelope,
    accepted: {AES.parse_canonical(text, result) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {AES.encode(envelope) == text : String}:
    match result:
        case Fail{error}:
            status = Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>, Bool,
                r => Result.is_done(&2, &2, AES.Error, AES.Envelope, r),
                AES.parse_canonical(text, Fail{error}), Done{envelope},
                accepted)
            Empty.absurd({AES.encode(envelope) == text : String},
                StringEq.false_true(status))
        case Done{+found}:
            canonical_sound_done(text, found, envelope,
                String.eq(AES.encode(found), text), {==}, accepted)

def canonical_law(+text: String, +envelope: AES.Envelope,
    +parsed: {AES.parse(text) == Done{envelope} :
        Result<&2, &2, AES.Error, AES.Envelope>}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
        AES.parse(text)) == Done{text} :
        Result<&2, &2, AES.Error, String>}:
    encoded = canonical_sound(text,
        AES.parse_fields(String.split(text, Chr{46})), envelope, parsed)
    Equal.trans(Result<&2, &2, AES.Error, String>,
        Result.map(&2, &2, AES.Error, AES.Envelope, String, AES.encode,
            AES.parse(text)),
        Done{AES.encode(envelope)}, Done{text},
        Equal.cong(Result<&2, &2, AES.Error, AES.Envelope>,
            Result<&2, &2, AES.Error, String>,
            result => Result.map(&2, &2, AES.Error, AES.Envelope, String,
                AES.encode, result),
            AES.parse(text), Done{envelope}, parsed),
        Equal.cong(String, Result<&2, &2, AES.Error, String>,
            value => Done{value}, AES.encode(envelope), text, encoded))

def map_done_text(+text: String,
    result: Result<&2, &2, AES.Error, String>) -> String:
    match result:
        case Fail{error}: text
        case Done{value}: value

def canonical_map_from_encoded(+text: String,
    result: Result<&2, &2, AES.Error, AES.Envelope>,
    encoded: {Result.map(&2, &2, AES.Error, AES.Envelope, String,
        AES.encode, result) == Done{text} :
        Result<&2, &2, AES.Error, String>}) ->
    {Result.map(&2, &2, AES.Error, AES.Envelope, String,
        AES.encode, AES.parse_canonical(text, result)) == Done{text} :
        Result<&2, &2, AES.Error, String>}:
    match result:
        case Fail{error}:
            status = Equal.cong(Result<&2, &2, AES.Error, String>, Bool,
                r => Result.is_done(&2, &2, AES.Error, String, r),
                Fail{error}, Done{text}, encoded)
            Empty.absurd(
                {Result.map(&2, &2, AES.Error, AES.Envelope, String,
                    AES.encode, AES.parse_canonical(text, Fail{error})) ==
                    Done{text} : Result<&2, &2, AES.Error, String>},
                StringEq.false_true(status))
        case Done{+found}:
            found_text = Equal.cong(Result<&2, &2, AES.Error, String>,
                String, r => map_done_text(text, r),
                Done{AES.encode(found)}, Done{text}, encoded)
            %found_text :
                {Result.map(&2, &2, AES.Error, AES.Envelope, String,
                    AES.encode, AES.parse_canonical(_, Done{found})) ==
                 Done{_} : Result<&2, &2, AES.Error, String>}
            Equal.cong(Bool,
                Result<&2, &2, AES.Error, String>,
                b => Result.map(&2, &2, AES.Error, AES.Envelope,
                    String, AES.encode,
                    AES.parse_canonical_decision(AES.encode(found), found, b)),
                String.eq(AES.encode(found), AES.encode(found)), True{},
                StringEq.string_eq_self(AES.encode(found)))
