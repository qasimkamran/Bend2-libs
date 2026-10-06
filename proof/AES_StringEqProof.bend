import Base
import 0xa7e654f9780078ca65bf9e187da99d3e/proofs/lib/lemmas/proofs/string_compare.bend as Compare

def false_type(b: Bool) -> Data:
    match b:
        case False{}: Unit
        case True{}: Empty

def false_true(e: {False{} == True{} : Bool}) -> Empty:
    %e : false_type(_)
    Unit{}

def cmp_eq_of_true(c: Cmp,
    accepted: {Cmp.is_eq(c) == True{} : Bool}) -> {c == EQ{} : Cmp}:
    match c:
        case EQ{}: {==}
        case LT{}: Empty.absurd({LT{} == EQ{} : Cmp}, false_true(accepted))
        case GT{}: Empty.absurd({GT{} == EQ{} : Cmp}, false_true(accepted))

def tag_is_snd(r: (String & String) & Cmp) ->
    {Compare.comparison_tag(String, r) ==
     Pair.snd(String & String, Cmp, r) : Cmp}:
    match r:
        case ((a, b), c): {==}

def string_eq_sound(+a: String, +b: String,
    accepted: {String.eq(a, b) == True{} : Bool}) -> {a == b : String}:
    Compare.string_equal_from_comparison(a, b,
        Equal.trans(Cmp,
            Compare.comparison_tag(String, String.cmp(a, b)),
            String.order(a, b), EQ{},
            tag_is_snd(String.cmp(a, b)),
            cmp_eq_of_true(String.order(a, b), accepted)))

def string_eq_self(+s: String) ->
    {String.eq(s, s) == True{} : Bool}:
    Equal.cong((String & String) & Cmp, Bool,
        result => Cmp.is_eq(Pair.snd(String & String, Cmp, result)),
        String.cmp(s, s), ((s, s), EQ{}),
        Compare.string_compare_self(s))
