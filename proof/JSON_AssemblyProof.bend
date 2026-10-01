import Base
import ../libs/JSON.bend as J
import ./JSON_ListProof.bend as L
import ./JSON_PrimitiveProof.bend as P
import ./JSON_StringProof.bend as S

def R() -> Type:
    Result<&1, &1, J.Error, J.Value>

type Mode is Data:
    Whole{}
    Members{}

def tokens(value: J.Value, mode: Mode, tail: List<J.Token>) -> List<J.Token>:
    match value:
        case J.Arr{Nil{}}:
            match mode:
                case Whole{}: J.Delimiter{'['} <> J.Delimiter{']'} <> tail
                case Members{}: J.Delimiter{']'} <> tail
        case J.Arr{head <> rest}:
            match mode:
                case Whole{}: J.Delimiter{'['} <> tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail))
                case Members{}: J.Delimiter{','} <> tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail))
        case J.Obj{Nil{}}:
            match mode:
                case Whole{}: J.Delimiter{'{'} <> J.Delimiter{'}'} <> tail
                case Members{}: J.Delimiter{'}'} <> tail
        case J.Obj{(key, value) <> rest}:
            match mode:
                case Whole{}: J.Delimiter{'{'} <> J.Atom{Done{J.Str{key}}} <> J.Delimiter{':'} <> tokens(value, Whole{}, tokens(J.Obj{rest}, Members{}, tail))
                case Members{}: J.Delimiter{','} <> J.Atom{Done{J.Str{key}}} <> J.Delimiter{':'} <> tokens(value, Whole{}, tokens(J.Obj{rest}, Members{}, tail))
        case J.Null{}: J.Atom{J.decode_payload("null")} <> tail
        case J.Bool{truth}:
            match truth:
                case True{}: J.Atom{J.decode_payload("true")} <> tail
                case False{}: J.Atom{J.decode_payload("false")} <> tail
        case J.Number{lexeme, certificate}: J.Atom{J.decode_payload(lexeme)} <> tail
        case J.Str{text}: J.Atom{J.decode_payload("\"" ++ J.escape_string(text) ++ "\"")} <> tail

def start_members(value: J.Value,
                  acc: List<&2, J.Value>,
                  fields: List<&2, Sigma<&2, &2, String, key => J.Value>>, kont: J.ParserKont) -> J.Assembly:
    match value:
        case J.Arr{_}: J.ArrayComma{acc, kont}
        case J.Obj{_}: J.ObjectComma{fields, kont}
        case _: J.NeedValue{kont}

def start(value: J.Value,
          mode: Mode,
          acc: List<&2, J.Value>,
          fields: List<&2, Sigma<&2, &2, String, key => J.Value>>, kont: J.ParserKont) -> J.Assembly:
    match mode:
        case Whole{}: J.NeedValue{kont}
        case Members{}: start_members(value, acc, fields, kont)

def completed_members(value: J.Value,
                      acc: List<&2, J.Value>,
                      fields: List<&2, Sigma<&2, &2, String, key => J.Value>>) -> J.Value:
    match value:
        case J.Arr{xs}: J.Arr{List.reverse(&2, J.Value, List.reverse.go(&2, J.Value, xs, acc))}
        case J.Obj{xs}: J.Obj{List.reverse(&2, Sigma<&2, &2, String, key => J.Value>, List.reverse.go(&2, Sigma<&2, &2, String, key => J.Value>, xs, fields))}
        case _: value

def completed(value: J.Value,
              mode: Mode,
              acc: List<&2, J.Value>,
              fields: List<&2, Sigma<&2, &2, String, key => J.Value>>) -> J.Value:
    match mode:
        case Whole{}: value
        case Members{}: completed_members(value, acc, fields)

def atom_roundtrip(+value: J.Value,
                   +mode: Mode,
                   -tail: List<J.Token>,
                   +acc: List<&2, J.Value>,
                   +fields: List<&2, Sigma<&2, &2, String, key => J.Value>>, +kont: J.ParserKont, +text: String, started: {start(value, mode, acc, fields, kont) == J.NeedValue{kont} : J.Assembly}, completed_value: {completed(value, mode, acc, fields) == value : J.Value}, tokenized: {tokens(value, mode, tail) == J.Atom{J.decode_payload(text)} <> tail : List<J.Token>}, decoded: {J.decode_payload(text) == Done{value} : Result<&1, &1, J.Error, J.Value>}) -> {J.assemble(tokens(value, mode, tail), start(value, mode, acc, fields, kont)) == J.assemble(tail, J.assembly_resume(kont, completed(value, mode, acc, fields))) : R()}:
    Equal.trans(R(),
        J.assemble(tokens(value, mode, tail), start(value, mode, acc, fields, kont)),
        J.assemble(J.Atom{Done{value}} <> tail, J.NeedValue{kont}),
        J.assemble(tail, J.assembly_resume(kont, completed(value, mode, acc, fields))),
        Equal.trans(R(),
            J.assemble(tokens(value, mode, tail), start(value, mode, acc, fields, kont)),
            J.assemble(tokens(value, mode, tail), J.NeedValue{kont}),
            J.assemble(J.Atom{Done{value}} <> tail, J.NeedValue{kont}),
            Equal.cong(J.Assembly, R(), state => J.assemble(tokens(value, mode, tail), state),
                start(value, mode, acc, fields, kont), J.NeedValue{kont}, started),
            Equal.cong(List<J.Token>, R(), stream => J.assemble(stream, J.NeedValue{kont}),
                tokens(value, mode, tail), J.Atom{Done{value}} <> tail,
                Equal.trans(List<J.Token>, tokens(value, mode, tail), J.Atom{J.decode_payload(text)} <> tail,
                    J.Atom{Done{value}} <> tail, tokenized,
                    Equal.cong(Result<&1, &1, J.Error, J.Value>, List<J.Token>, result => J.Atom{result} <> tail,
                        J.decode_payload(text), Done{value}, decoded)))),
        Equal.cong(J.Value, R(), item => J.assemble(tail, J.assembly_resume(kont, item)),
            value, completed(value, mode, acc, fields), Equal.sym(J.Value, completed(value, mode, acc, fields), value, completed_value)))

def array_first_atom(result: Result<&1, &1, J.Error, J.Value>,
                     -tail: List<J.Token>,
                     +kont: J.ParserKont) -> {J.assemble(J.Atom{result} <> tail, J.ArrayFirst{kont}) == J.assemble(J.Atom{result} <> tail, J.NeedValue{J.InArray{Nil{}, kont}}) : R()}:
    {==}

def array_next_atom(result: Result<&1, &1, J.Error, J.Value>,
                    -tail: List<J.Token>,
                    +acc: List<&2, J.Value>,
                    +kont: J.ParserKont) -> {J.assemble(J.Atom{result} <> tail, J.ArrayNext{acc, kont}) == J.assemble(J.Atom{result} <> tail, J.NeedValue{J.InArray{acc, kont}}) : R()}:
    {==}

def array_first(+value: J.Value,
                -tail: List<J.Token>,
                +acc: List<&2, J.Value>,
                +kont: J.ParserKont) -> {J.assemble(tokens(value, Whole{}, tail), J.ArrayFirst{kont}) == J.assemble(tokens(value, Whole{}, tail), J.NeedValue{J.InArray{Nil{}, kont}}) : R()}:
    match value:
        case J.Arr{Nil{}}: {==}
        case J.Arr{head <> rest}: {==}
        case J.Obj{Nil{}}: {==}
        case J.Obj{(key, head) <> rest}: {==}
        case J.Null{}: array_first_atom(J.decode_payload("null"), tail, kont)
        case J.Bool{True{}}: array_first_atom(J.decode_payload("true"), tail, kont)
        case J.Bool{False{}}: array_first_atom(J.decode_payload("false"), tail, kont)
        case J.Number{s, cert}: array_first_atom(J.decode_payload(s), tail, kont)
        case J.Str{s}: array_first_atom(J.decode_payload("\"" ++ J.escape_string(s) ++ "\""), tail, kont)

def array_next(+value: J.Value,
               -tail: List<J.Token>,
               +acc: List<&2, J.Value>,
               +kont: J.ParserKont) -> {J.assemble(tokens(value, Whole{}, tail), J.ArrayNext{acc, kont}) == J.assemble(tokens(value, Whole{}, tail), J.NeedValue{J.InArray{acc, kont}}) : R()}:
    match value:
        case J.Arr{Nil{}}: {==}
        case J.Arr{head <> rest}: {==}
        case J.Obj{Nil{}}: {==}
        case J.Obj{(key, head) <> rest}: {==}
        case J.Null{}: array_next_atom(J.decode_payload("null"), tail, acc, kont)
        case J.Bool{True{}}: array_next_atom(J.decode_payload("true"), tail, acc, kont)
        case J.Bool{False{}}: array_next_atom(J.decode_payload("false"), tail, acc, kont)
        case J.Number{s, cert}: array_next_atom(J.decode_payload(s), tail, acc, kont)
        case J.Str{s}: array_next_atom(J.decode_payload("\"" ++ J.escape_string(s) ++ "\""), tail, acc, kont)

def roundtrip(+value: J.Value,
              +mode: Mode,
              -tail: List<J.Token>,
              +acc: List<&2, J.Value>,
              +fields: List<&2, Sigma<&2, &2, String, key => J.Value>>, +kont: J.ParserKont) -> {J.assemble(tokens(value, mode, tail), start(value, mode, acc, fields, kont)) == J.assemble(tail, J.assembly_resume(kont, completed(value, mode, acc, fields))) : R()}:
    match value:
        case J.Arr{Nil{}}:
            match mode:
                case Whole{}: {==}
                case Members{}: {==}
        case J.Arr{head <> rest}:
            match mode:
                case Whole{}:
                    %Equal.sym(R(), J.assemble(tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail)), J.ArrayFirst{kont}), J.assemble(tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail)), J.NeedValue{J.InArray{Nil{}, kont}}), array_first(head, tokens(J.Arr{rest}, Members{}, tail), Nil{}, kont)) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Arr{head <> rest}, Whole{}, acc, fields))) : R()}
                    %Equal.sym(R(), J.assemble(tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail)), J.NeedValue{J.InArray{Nil{}, kont}}), J.assemble(tokens(J.Arr{rest}, Members{}, tail), J.ArrayComma{head <> Nil{}, kont}), roundtrip(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail), Nil{}, Nil{}, J.InArray{Nil{}, kont})) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Arr{head <> rest}, Whole{}, acc, fields))) : R()}
                    %Equal.sym(R(), J.assemble(tokens(J.Arr{rest}, Members{}, tail), J.ArrayComma{head <> Nil{}, kont}), J.assemble(tail, J.assembly_resume(kont, completed(J.Arr{rest}, Members{}, head <> Nil{}, Nil{}))), roundtrip(J.Arr{rest}, Members{}, tail, head <> Nil{}, Nil{}, kont)) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Arr{head <> rest}, Whole{}, acc, fields))) : R()}
                    Equal.cong(List<&2, J.Value>, R(), xs => J.assemble(tail, J.assembly_resume(kont, J.Arr{xs})), List.reverse(&2, J.Value, List.reverse(&2, J.Value, head <> rest)), head <> rest, L.reverse_twice(J.Value, head <> rest))
                case Members{}:
                    %Equal.sym(R(), J.assemble(tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail)), J.ArrayNext{acc, kont}), J.assemble(tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail)), J.NeedValue{J.InArray{acc, kont}}), array_next(head, tokens(J.Arr{rest}, Members{}, tail), acc, kont)) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Arr{head <> rest}, Members{}, acc, fields))) : R()}
                    %Equal.sym(R(), J.assemble(tokens(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail)), J.NeedValue{J.InArray{acc, kont}}), J.assemble(tokens(J.Arr{rest}, Members{}, tail), J.ArrayComma{head <> acc, kont}), roundtrip(head, Whole{}, tokens(J.Arr{rest}, Members{}, tail), Nil{}, Nil{}, J.InArray{acc, kont})) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Arr{head <> rest}, Members{}, acc, fields))) : R()}
                    roundtrip(J.Arr{rest}, Members{}, tail, head <> acc, Nil{}, kont)
        case J.Obj{Nil{}}:
            match mode:
                case Whole{}: {==}
                case Members{}: {==}
        case J.Obj{(key, head) <> rest}:
            match mode:
                case Whole{}:
                    %Equal.sym(R(), J.assemble(tokens(head, Whole{}, tokens(J.Obj{rest}, Members{}, tail)), J.NeedValue{J.InObject{key, Nil{}, kont}}), J.assemble(tokens(J.Obj{rest}, Members{}, tail), J.ObjectComma{(key, head) <> Nil{}, kont}), roundtrip(head, Whole{}, tokens(J.Obj{rest}, Members{}, tail), Nil{}, Nil{}, J.InObject{key, Nil{}, kont})) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Obj{(key, head) <> rest}, Whole{}, acc, fields))) : R()}
                    %Equal.sym(R(), J.assemble(tokens(J.Obj{rest}, Members{}, tail), J.ObjectComma{(key, head) <> Nil{}, kont}), J.assemble(tail, J.assembly_resume(kont, completed(J.Obj{rest}, Members{}, Nil{}, (key, head) <> Nil{}))), roundtrip(J.Obj{rest}, Members{}, tail, Nil{}, (key, head) <> Nil{}, kont)) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Obj{(key, head) <> rest}, Whole{}, acc, fields))) : R()}
                    Equal.cong(List<&2, Sigma<&2, &2, String, key => J.Value>>, R(), xs => J.assemble(tail, J.assembly_resume(kont, J.Obj{xs})), List.reverse(&2, Sigma<&2, &2, String, key => J.Value>, List.reverse(&2, Sigma<&2, &2, String, key => J.Value>, (key, head) <> rest)), (key, head) <> rest, L.reverse_twice(Sigma<&2, &2, String, key => J.Value>, (key, head) <> rest))
                case Members{}:
                    %Equal.sym(R(), J.assemble(tokens(head, Whole{}, tokens(J.Obj{rest}, Members{}, tail)), J.NeedValue{J.InObject{key, fields, kont}}), J.assemble(tokens(J.Obj{rest}, Members{}, tail), J.ObjectComma{(key, head) <> fields, kont}), roundtrip(head, Whole{}, tokens(J.Obj{rest}, Members{}, tail), Nil{}, Nil{}, J.InObject{key, fields, kont})) : {_ == J.assemble(tail, J.assembly_resume(kont, completed(J.Obj{(key, head) <> rest}, Members{}, acc, fields))) : R()}
                    roundtrip(J.Obj{rest}, Members{}, tail, Nil{}, (key, head) <> fields, kont)
        case J.Null{}:
            match mode:
                case Whole{}: atom_roundtrip(J.Null{}, mode, tail, acc, fields, kont, "null", {==}, {==}, {==}, {==})
                case Members{}: atom_roundtrip(J.Null{}, mode, tail, acc, fields, kont, "null", {==}, {==}, {==}, {==})
        case J.Bool{True{}}:
            match mode:
                case Whole{}: atom_roundtrip(J.Bool{True{}}, mode, tail, acc, fields, kont, "true", {==}, {==}, {==}, {==})
                case Members{}: atom_roundtrip(J.Bool{True{}}, mode, tail, acc, fields, kont, "true", {==}, {==}, {==}, {==})
        case J.Bool{False{}}:
            match mode:
                case Whole{}: atom_roundtrip(J.Bool{False{}}, mode, tail, acc, fields, kont, "false", {==}, {==}, {==}, {==})
                case Members{}: atom_roundtrip(J.Bool{False{}}, mode, tail, acc, fields, kont, "false", {==}, {==}, {==}, {==})
        case J.Number{s, cert}:
            match mode:
                case Whole{}: atom_roundtrip(J.Number{s, cert}, mode, tail, acc, fields, kont, s, {==}, {==}, {==}, P.number_roundtrip(s, cert))
                case Members{}: atom_roundtrip(J.Number{s, cert}, mode, tail, acc, fields, kont, s, {==}, {==}, {==}, P.number_roundtrip(s, cert))
        case J.Str{s}:
            match mode:
                case Whole{}: atom_roundtrip(J.Str{s}, mode, tail, acc, fields, kont, "\"" ++ J.escape_string(s) ++ "\"", {==}, {==}, {==}, S.string_payload(s))
                case Members{}: atom_roundtrip(J.Str{s}, mode, tail, acc, fields, kont, "\"" ++ J.escape_string(s) ++ "\"", {==}, {==}, {==}, S.string_payload(s))
