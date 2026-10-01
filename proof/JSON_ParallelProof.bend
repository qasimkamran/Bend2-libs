import Base
import ../libs/JSON.bend as J

# Semantic token sequence for a forest, independent of its scheduling shape.
def forest(trees: List<&2, J.LexTree>, tail: List<J.Token>) -> List<J.Token>:
    match trees:
        case Nil{}: tail
        case head <> rest: J.token_list(J.decode_tree(head), forest(rest, tail))

def flat(items: List<&2, J.Lexeme>, tail: List<J.Token>) -> List<J.Token>:
    match items:
        case Nil{}: tail
        case head <> rest: J.decode_lexeme(head) <> flat(rest, tail)

def join(+trees: List<&2, J.LexTree>,
         -tail: List<J.Token>) -> {J.token_list(J.decode_tree(J.lex_join(trees)), tail) == forest(trees, tail) : List<J.Token>}:
    match trees:
        case Nil{}: {==}
        case head <> rest:
            Equal.cong(List<J.Token>, List<J.Token>, xs => J.token_list(J.decode_tree(head), xs),
                J.token_list(J.decode_tree(J.lex_join(rest)), tail), forest(rest, tail), join(rest, tail))

def pairs(+trees: List<&2, J.LexTree>,
          -tail: List<J.Token>) -> {forest(J.lex_pairs(trees), tail) == forest(trees, tail) : List<J.Token>}:
    match trees:
        case Nil{}: {==}
        case head <> Nil{}: {==}
        case left <> right <> rest:
            Equal.cong(List<J.Token>, List<J.Token>, xs => J.token_list(J.decode_tree(left), J.token_list(J.decode_tree(right), xs)),
                forest(J.lex_pairs(rest), tail), forest(rest, tail), pairs(rest, tail))

def balance(+fuel: Nat,
            +trees: List<&2, J.LexTree>,
            -tail: List<J.Token>) -> {J.token_list(J.decode_tree(J.lex_balance(fuel, trees)), tail) == forest(trees, tail) : List<J.Token>}:
    match fuel:
        case 0n: join(trees, tail)
        case 1n+p:
            match trees:
                case Nil{}: {==}
                case head <> Nil{}: {==}
                case left <> right <> rest:
                    Equal.trans(List<J.Token>, J.token_list(J.decode_tree(J.lex_balance(p, J.lex_pairs(left <> right <> rest))), tail),
                        forest(J.lex_pairs(left <> right <> rest), tail), forest(left <> right <> rest, tail),
                        balance(p, J.lex_pairs(left <> right <> rest), tail), pairs(left <> right <> rest, tail))

def leaves(+items: List<&2, J.Lexeme>,
           -tail: List<J.Token>) -> {forest(J.lex_leaves(items), tail) == flat(items, tail) : List<J.Token>}:
    match items:
        case Nil{}: {==}
        case head <> rest:
            Equal.cong(List<J.Token>, List<J.Token>, xs => J.decode_lexeme(head) <> xs,
                forest(J.lex_leaves(rest), tail), flat(rest, tail), leaves(rest, tail))

def decode(+items: List<&2, J.Lexeme>,
           -tail: List<J.Token>) -> {J.token_list(J.decode_tree(J.lex_tree(items)), tail) == flat(items, tail) : List<J.Token>}:
    Equal.trans(List<J.Token>, J.token_list(J.decode_tree(J.lex_tree(items)), tail), forest(J.lex_leaves(items), tail), flat(items, tail),
        balance(1n+List.length(&2, J.Lexeme, items), J.lex_leaves(items), tail), leaves(items, tail))
