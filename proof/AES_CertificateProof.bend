import Base

# Decidable equality makes certificates for Bool and Nat unique. These lemmas
# compare proofs without evaluating the computation that produced each proof.
def bool_code(a: Bool, b: Bool) -> Data:
    match a b:
        case False{} False{}: Unit
        case True{} True{}: Unit
        case _ _: Empty

def bool_code_refl(a: Bool) -> bool_code(a, a):
    match a:
        case False{}: Unit{}
        case True{}: Unit{}

def bool_encode(+a: Bool, +b: Bool, proof: {a == b : Bool}) -> bool_code(a, b):
    %proof : bool_code(a, _)
    bool_code_refl(a)

def bool_decode(+a: Bool, +b: Bool, code: bool_code(a, b)) -> {a == b : Bool}:
    match a b:
        case False{} False{}: {==}
        case True{} True{}: {==}
        case False{} True{}: Empty.absurd({a == b : Bool}, code)
        case True{} False{}: Empty.absurd({a == b : Bool}, code)

def bool_decode_refl(+a: Bool) ->
    {bool_decode(a, a, bool_code_refl(a)) == {==} : {a == a : Bool}}:
    match a:
        case False{}: {==}
        case True{}: {==}

def bool_decode_encode(+a: Bool, +b: Bool, +proof: {a == b : Bool}) ->
    {bool_decode(a, b, bool_encode(a, b, proof)) == proof : {a == b : Bool}}:
    %path@proof : {bool_decode(a, _, bool_encode(a, _, path)) == path :
        {a == _ : Bool}}
    bool_decode_refl(a)

def bool_code_unique(+a: Bool, +b: Bool,
    +first: bool_code(a, b), second: bool_code(a, b)) ->
    {first == second : bool_code(a, b)}:
    match a b:
        case False{} False{}:
            match first second:
                case Unit{} Unit{}: {==}
        case True{} True{}:
            match first second:
                case Unit{} Unit{}: {==}
        case False{} True{}:
            Empty.absurd({first == second : bool_code(a, b)}, first)
        case True{} False{}:
            Empty.absurd({first == second : bool_code(a, b)}, first)

def bool_unique(+a: Bool, +b: Bool,
    +first: {a == b : Bool}, +second: {a == b : Bool}) ->
    {first == second : {a == b : Bool}}:
    +first_code = bool_encode(a, b, first)
    +second_code = bool_encode(a, b, second)
    codes_same = bool_code_unique(a, b, first_code, second_code)
    decoded_same = Equal.cong(bool_code(a, b), {a == b : Bool},
        code => bool_decode(a, b, code), first_code, second_code, codes_same)
    Equal.trans({a == b : Bool}, first, bool_decode(a, b, first_code), second,
        Equal.sym({a == b : Bool}, bool_decode(a, b, first_code), first,
            bool_decode_encode(a, b, first)),
        Equal.trans({a == b : Bool}, bool_decode(a, b, first_code),
            bool_decode(a, b, second_code), second, decoded_same,
            bool_decode_encode(a, b, second)))

def nat_code(a: Nat, b: Nat) -> Data:
    match a b:
        case 0n 0n: Unit
        case 1n+p 1n+q: nat_code(p, q)
        case _ _: Empty

def nat_code_refl(a: Nat) -> nat_code(a, a):
    match a:
        case 0n: Unit{}
        case 1n+p: nat_code_refl(p)

def nat_encode(+a: Nat, +b: Nat, proof: {a == b : Nat}) -> nat_code(a, b):
    %proof : nat_code(a, _)
    nat_code_refl(a)

def nat_decode(+a: Nat, +b: Nat, code: nat_code(a, b)) -> {a == b : Nat}:
    match a b:
        case 0n 0n: {==}
        case 0n 1n+q: Empty.absurd({a == b : Nat}, code)
        case 1n+p 0n: Empty.absurd({a == b : Nat}, code)
        case 1n+p 1n+q:
            Equal.cong(Nat, Nat, value => 1n+value, p, q,
                nat_decode(p, q, code))

def nat_decode_refl(+a: Nat) ->
    {nat_decode(a, a, nat_code_refl(a)) == {==} : {a == a : Nat}}:
    match a:
        case 0n: {==}
        case 1n+p:
            %Equal.sym({p == p : Nat},
                nat_decode(p, p, nat_code_refl(p)), {==},
                nat_decode_refl(p)) :
                {Equal.cong(Nat, Nat, value => 1n+value, p, p, _) == {==} :
                    {1n+p == 1n+p : Nat}}
            {==}

def nat_decode_encode(+a: Nat, +b: Nat, +proof: {a == b : Nat}) ->
    {nat_decode(a, b, nat_encode(a, b, proof)) == proof : {a == b : Nat}}:
    %path@proof : {nat_decode(a, _, nat_encode(a, _, path)) == path :
        {a == _ : Nat}}
    nat_decode_refl(a)

def nat_code_unique(+a: Nat, +b: Nat,
    +first: nat_code(a, b), second: nat_code(a, b)) ->
    {first == second : nat_code(a, b)}:
    match a b:
        case 0n 0n:
            match first second:
                case Unit{} Unit{}: {==}
        case 0n 1n+q:
            Empty.absurd({first == second : nat_code(a, b)}, first)
        case 1n+p 0n:
            Empty.absurd({first == second : nat_code(a, b)}, first)
        case 1n+p 1n+q: nat_code_unique(p, q, first, second)

def nat_unique(+a: Nat, +b: Nat,
    +first: {a == b : Nat}, +second: {a == b : Nat}) ->
    {first == second : {a == b : Nat}}:
    +first_code = nat_encode(a, b, first)
    +second_code = nat_encode(a, b, second)
    codes_same = nat_code_unique(a, b, first_code, second_code)
    decoded_same = Equal.cong(nat_code(a, b), {a == b : Nat},
        code => nat_decode(a, b, code), first_code, second_code, codes_same)
    Equal.trans({a == b : Nat}, first, nat_decode(a, b, first_code), second,
        Equal.sym({a == b : Nat}, nat_decode(a, b, first_code), first,
            nat_decode_encode(a, b, first)),
        Equal.trans({a == b : Nat}, nat_decode(a, b, first_code),
            nat_decode(a, b, second_code), second, decoded_same,
            nat_decode_encode(a, b, second)))
