import Base
import ../libs/AES256GCM.bend as AES
import ./AES_ZipLengthProof.bend as ZipLengthProof

def bool_and_true_right(+a: Bool, +b: Bool,
    both: {Bool.and(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
    match a b:
        case False{} False{}:
            Empty.absurd({False{} == True{} : Bool},
                ZipLengthProof.false_true(both))
        case False{} True{}: {==}
        case True{} False{}:
            Empty.absurd({False{} == True{} : Bool},
                ZipLengthProof.false_true(both))
        case True{} True{}: {==}

def predecessor(n: Nat) -> Nat:
    match n:
        case 0n: 0n
        case 1n+p: p

def length_limit_go_same(+a: List<&2, U32>, +b: List<&2, U32>,
    +low: U32, +high: U32, +max_low: U32, +max_high: U32,
    +within: Bool,
    same_length: {List.length(&2, U32, a) ==
        List.length(&2, U32, b) : Nat}) ->
    {AES.bytes_length_limit.go(List.length(&2, U32, a), a,
        low, high, max_low, max_high, within) ==
     AES.bytes_length_limit.go(List.length(&2, U32, b), b,
        low, high, max_low, max_high, within) : Bool}:
    match a b within:
        case Nil{} Nil{} _: {==}
        case Nil{} y <> ys _:
            mismatch = Equal.cong(Nat, Bool,
                n => Nat.is_eq(0n, n),
                List.length(&2, U32, Nil{}),
                List.length(&2, U32, y <> ys), same_length)
            Empty.absurd(
                {AES.bytes_length_limit.go(0n, Nil{}, low, high,
                    max_low, max_high, within) ==
                 AES.bytes_length_limit.go(
                    List.length(&2, U32, y <> ys), y <> ys,
                    low, high, max_low, max_high, within) : Bool},
                ZipLengthProof.false_true(Equal.sym(Bool,
                    True{}, False{}, mismatch)))
        case x <> xs Nil{} _:
            mismatch = Equal.cong(Nat, Bool,
                n => Nat.is_eq(n, 0n),
                List.length(&2, U32, x <> xs),
                List.length(&2, U32, Nil{}), same_length)
            Empty.absurd(
                {AES.bytes_length_limit.go(
                    List.length(&2, U32, x <> xs), x <> xs,
                    low, high, max_low, max_high, within) ==
                 AES.bytes_length_limit.go(0n, Nil{}, low, high,
                    max_low, max_high, within) : Bool},
                ZipLengthProof.false_true(mismatch))
        case x <> xs y <> ys False{}: {==}
        case x <> xs y <> ys True{}:
            tail_length = Equal.cong(Nat, Nat, predecessor,
                List.length(&2, U32, x <> xs),
                List.length(&2, U32, y <> ys), same_length)
            +next_low = U32.add(low, 1)
            +next_high = Bool.pick(U32, U32.is_eq(next_low, 0),
                U32.add(high, 1), high)
            next_within = AES.length_pair_within(next_low, next_high,
                max_low, max_high)
            length_limit_go_same(xs, ys, next_low, next_high,
                max_low, max_high, next_within, tail_length)

def bytes_length_limit_same(+a: List<&2, U32>, +b: List<&2, U32>,
    +max_low: U32, +max_high: U32,
    same_length: {List.length(&2, U32, a) ==
        List.length(&2, U32, b) : Nat}) ->
    {AES.bytes_length_limit(a, max_low, max_high) ==
     AES.bytes_length_limit(b, max_low, max_high) : Bool}:
    length_limit_go_same(a, b, 0, 0, max_low, max_high, True{},
        same_length)

def plaintext_valid_same_length(+ciphertext: List<&2, U32>,
    +plaintext: List<&2, U32>,
    ciphertext_bytes_valid: {AES.bytes_valid(ciphertext) == True{} : Bool},
    plaintext_is_valid: {AES.plaintext_valid(plaintext) == True{} : Bool},
    same_length: {List.length(&2, U32, ciphertext) ==
        List.length(&2, U32, plaintext) : Nat}) ->
    {AES.plaintext_valid(ciphertext) == True{} : Bool}:
    length_limit_eq = bytes_length_limit_same(ciphertext, plaintext,
        4294967264, 15, same_length)
    plaintext_limit = bool_and_true_right(AES.bytes_valid(plaintext),
        AES.bytes_length_limit(plaintext, 4294967264, 15),
        plaintext_is_valid)
    ciphertext_limit = Equal.trans(Bool,
        AES.bytes_length_limit(ciphertext, 4294967264, 15),
        AES.bytes_length_limit(plaintext, 4294967264, 15), True{},
        length_limit_eq, plaintext_limit)
    Equal.trans(Bool, AES.plaintext_valid(ciphertext),
        Bool.and(True{}, True{}), True{},
        Equal.trans(Bool,
            Bool.and(AES.bytes_valid(ciphertext),
                AES.bytes_length_limit(ciphertext, 4294967264, 15)),
            Bool.and(True{},
                AES.bytes_length_limit(ciphertext, 4294967264, 15)),
            Bool.and(True{}, True{}),
            Equal.cong(Bool, Bool, valid => Bool.and(valid,
                AES.bytes_length_limit(ciphertext, 4294967264, 15)),
                AES.bytes_valid(ciphertext), True{}, ciphertext_bytes_valid),
            Equal.cong(Bool, Bool, within => Bool.and(True{}, within),
                AES.bytes_length_limit(ciphertext, 4294967264, 15), True{},
                ciphertext_limit)),
        {==})
