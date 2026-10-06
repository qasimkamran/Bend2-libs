import Base
import ../libs/AES256GCM.bend as AES
import 0xa7e654f9780078ca65bf9e187da99d3e/proofs/crypto/subtle/word.bend as SW
import 0xa7e654f9780078ca65bf9e187da99d3e/proofs/lib/logic.bend as Logic

def diff_same(+a: List<&2, U32>, +acc: U32,
    acc_zero: {U32.is_eq(acc, 0) == True{} : Bool}) ->
    {U32.is_eq(AES.bytes_difference.go(a, a, acc), 0) == True{} : Bool}:
    match a:
        case Nil{}: acc_zero
        case x <> xs:
            xor_zero = Equal.trans(Bool,
                U32.is_eq(U32.xor(x, x), 0), U32.is_eq(x, x), True{},
                SW.u32_xor_zero(x, x), SW.u32_refl(x))
            both = Logic.and_intro(U32.is_eq(acc, 0),
                U32.is_eq(U32.xor(x, x), 0), acc_zero, xor_zero)
            next_zero = Equal.trans(Bool,
                U32.is_eq(U32.or(acc, U32.xor(x, x)), 0),
                Bool.and(U32.is_eq(acc, 0), U32.is_eq(U32.xor(x, x), 0)),
                True{}, SW.u32_or_zero(acc, U32.xor(x, x)), both)
            diff_same(xs, U32.or(acc, U32.xor(x, x)), next_zero)

def equal_same(+a: List<&2, U32>) ->
    {AES.bytes_equal_full_scan(a, a) == True{} : Bool}:
    diff_same(a, 0, {==})

def equal_of_equal(+a: List<&2, U32>, +b: List<&2, U32>,
    same: {a == b : List<&2, U32>}) ->
    {AES.bytes_equal_full_scan(a, b) == True{} : Bool}:
    Equal.trans(Bool, AES.bytes_equal_full_scan(a, b),
        AES.bytes_equal_full_scan(b, b), True{},
        Equal.cong(List<&2, U32>, Bool,
            left => AES.bytes_equal_full_scan(left, b), a, b, same),
        equal_same(b))

def diff_acc_zero(+a: List<&2, U32>, +b: List<&2, U32>, +acc: U32,
    zero: {U32.is_eq(AES.bytes_difference.go(a, b, acc), 0) == True{} : Bool}) ->
    {U32.is_eq(acc, 0) == True{} : Bool}:
    match a b:
        case Nil{} Nil{}: zero
        case Nil{} y <> ys:
            Empty.absurd({U32.is_eq(acc, 0) == True{} : Bool},
                Logic.false_true(zero))
        case x <> xs Nil{}:
            Empty.absurd({U32.is_eq(acc, 0) == True{} : Bool},
                Logic.false_true(zero))
        case x <> xs y <> ys:
            acc2 = U32.or(acc, U32.xor(x, y))
            step_zero = diff_acc_zero(xs, ys, acc2, zero)
            both = Equal.trans(Bool,
                Bool.and(U32.is_eq(acc, 0), U32.is_eq(U32.xor(x, y), 0)),
                U32.is_eq(acc2, 0), True{},
                Equal.sym(Bool, U32.is_eq(acc2, 0),
                    Bool.and(U32.is_eq(acc, 0),
                        U32.is_eq(U32.xor(x, y), 0)),
                    SW.u32_or_zero(acc, U32.xor(x, y))),
                step_zero)
            Logic.and_left(U32.is_eq(acc, 0),
                U32.is_eq(U32.xor(x, y), 0), both)

def diff_list_sound(+a: List<&2, U32>, +b: List<&2, U32>, +acc: U32,
    +zero: {U32.is_eq(AES.bytes_difference.go(a, b, acc), 0) == True{} : Bool}) ->
    {a == b : List<&2, U32>}:
    match a b:
        case Nil{} Nil{}: {==}
        case Nil{} y <> ys:
            Empty.absurd({Nil{} == y <> ys : List<&2, U32>},
                Logic.false_true(zero))
        case x <> xs Nil{}:
            Empty.absurd({x <> xs == Nil{} : List<&2, U32>},
                Logic.false_true(zero))
        case x <> xs y <> ys:
            +acc2 = U32.or(acc, U32.xor(x, y))
            acc2_zero = diff_acc_zero(xs, ys, acc2, zero)
            both = Equal.trans(Bool,
                Bool.and(U32.is_eq(acc, 0), U32.is_eq(U32.xor(x, y), 0)),
                U32.is_eq(acc2, 0), True{},
                Equal.sym(Bool, U32.is_eq(acc2, 0),
                    Bool.and(U32.is_eq(acc, 0),
                        U32.is_eq(U32.xor(x, y), 0)),
                    SW.u32_or_zero(acc, U32.xor(x, y))),
                acc2_zero)
            xor_zero = Logic.and_right(U32.is_eq(acc, 0),
                U32.is_eq(U32.xor(x, y), 0), both)
            byte_equal = SW.u32_sound(x, y,
                Equal.trans(Bool, U32.is_eq(x, y),
                    U32.is_eq(U32.xor(x, y), 0), True{},
                    Equal.sym(Bool, U32.is_eq(U32.xor(x, y), 0),
                        U32.is_eq(x, y), SW.u32_xor_zero(x, y)),
                    xor_zero))
            tail_equal = diff_list_sound(xs, ys, acc2, zero)
            Equal.trans(List<&2, U32>, x <> xs, y <> xs, y <> ys,
                Equal.cong(U32, List<&2, U32>, h => h <> xs,
                    x, y, byte_equal),
                Equal.cong(List<&2, U32>, List<&2, U32>,
                    t => y <> t, xs, ys, tail_equal))

def equal_sound(+a: List<&2, U32>, +b: List<&2, U32>,
    accepted: {AES.bytes_equal_full_scan(a, b) == True{} : Bool}) ->
    {a == b : List<&2, U32>}:
    diff_list_sound(a, b, 0, accepted)

def unequal_from_bool(+a: List<&2, U32>, +b: List<&2, U32>,
    compared: Bool,
    link: {compared == AES.bytes_equal_full_scan(a, b) : Bool},
    unequal: {a != b : List<&2, U32>}) ->
    {AES.bytes_equal_full_scan(a, b) == False{} : Bool}:
    match compared:
        case False{}:
            Equal.sym(Bool, False{}, AES.bytes_equal_full_scan(a, b), link)
        case True{}:
            accepted = Equal.sym(Bool, True{},
                AES.bytes_equal_full_scan(a, b), link)
            Empty.absurd(
                {AES.bytes_equal_full_scan(a, b) == False{} : Bool},
                unequal(equal_sound(a, b, accepted)))

def unequal_is_false(+a: List<&2, U32>, +b: List<&2, U32>,
    unequal: {a != b : List<&2, U32>}) ->
    {AES.bytes_equal_full_scan(a, b) == False{} : Bool}:
    unequal_from_bool(a, b, AES.bytes_equal_full_scan(a, b), {==}, unequal)
