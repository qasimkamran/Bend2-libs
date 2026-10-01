import Base

def append_nil(-A: Data, +xs: List<&2, A>) -> {List.append(&2, A, xs, Nil{}) == xs : List<&2, A>}:
    match xs:
        case Nil{}: {==}
        case h <> t:
            Equal.cong(List<&2, A>, List<&2, A>, ys => h <> ys, List.append(&2, A, t, Nil{}), t, append_nil(A, t))

def append_assoc(-A: Data,
                 +xs: List<&2, A>,
                 +ys: List<&2, A>,
                 +zs: List<&2, A>) -> {List.append(&2, A, List.append(&2, A, xs, ys), zs) == List.append(&2, A, xs, List.append(&2, A, ys, zs)) : List<&2, A>}:
    match xs:
        case Nil{}: {==}
        case h <> t:
            Equal.cong(List<&2, A>, List<&2, A>, q => h <> q,
                List.append(&2, A, List.append(&2, A, t, ys), zs), List.append(&2, A, t, List.append(&2, A, ys, zs)), append_assoc(A, t, ys, zs))

def reverse_shift(-A: Data,
                  +xs: List<&2, A>,
                  +acc: List<&2, A>,
                  +tail: List<&2, A>) -> {List.reverse.go(&2, A, List.reverse.go(&2, A, xs, acc), tail) == List.reverse.go(&2, A, acc, List.append(&2, A, xs, tail)) : List<&2, A>}:
    match xs:
        case Nil{}: {==}
        case h <> t: reverse_shift(A, t, h <> acc, tail)

def reverse_go_append(-A: Data,
                      +xs: List<&2, A>,
                      +acc: List<&2, A>,
                      +tail: List<&2, A>) -> {List.reverse.go(&2, A, xs, List.append(&2, A, acc, tail)) == List.append(&2, A, List.reverse.go(&2, A, xs, acc), tail) : List<&2, A>}:
    match xs:
        case Nil{}: {==}
        case h <> t:
            reverse_go_append(A, t, h <> acc, tail)

def reverse_cons(-A: Data,
                 +head: A,
                 +tail: List<&2, A>) -> {List.reverse(&2, A, head <> tail) == List.append(&2, A, List.reverse(&2, A, tail), head <> Nil{}) : List<&2, A>}:
    reverse_go_append(A, tail, Nil{}, head <> Nil{})

def reverse_append(-A: Data,
                   +xs: List<&2, A>,
                   +ys: List<&2, A>) -> {List.reverse(&2, A, List.append(&2, A, xs, ys)) == List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, xs)) : List<&2, A>}:
    match xs:
        case Nil{}:
            Equal.sym(List<&2, A>, List.append(&2, A, List.reverse(&2, A, ys), Nil{}),
                List.reverse(&2, A, ys),
                append_nil(A, List.reverse(&2, A, ys)))
        case h <> t:
            Equal.trans(List<&2, A>,
                List.reverse(&2, A, List.append(&2, A, h <> t, ys)),
                List.append(&2, A, List.reverse(&2, A, List.append(&2, A, t, ys)), h <> Nil{}),
                List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, h <> t)),
                reverse_go_append(A, List.append(&2, A, t, ys), Nil{}, h <> Nil{}),
                Equal.trans(List<&2, A>,
                    List.append(&2, A, List.reverse(&2, A, List.append(&2, A, t, ys)), h <> Nil{}),
                    List.append(&2, A, List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, t)), h <> Nil{}),
                    List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, h <> t)),
                    Equal.cong(List<&2, A>, List<&2, A>, xs => List.append(&2, A, xs, h <> Nil{}),
                        List.reverse(&2, A, List.append(&2, A, t, ys)),
                        List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, t)),
                        reverse_append(A, t, ys)),
                    Equal.trans(List<&2, A>,
                        List.append(&2, A, List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, t)), h <> Nil{}),
                        List.append(&2, A, List.reverse(&2, A, ys), List.append(&2, A, List.reverse(&2, A, t), h <> Nil{})),
                        List.append(&2, A, List.reverse(&2, A, ys), List.reverse(&2, A, h <> t)),
                        append_assoc(A, List.reverse(&2, A, ys), List.reverse(&2, A, t), h <> Nil{}),
                        Equal.cong(List<&2, A>, List<&2, A>, xs => List.append(&2, A, List.reverse(&2, A, ys), xs),
                            List.append(&2, A, List.reverse(&2, A, t), h <> Nil{}),
                            List.reverse(&2, A, h <> t),
                            Equal.sym(List<&2, A>,
                                List.reverse(&2, A, h <> t),
                                List.append(&2, A, List.reverse(&2, A, t), h <> Nil{}),
                                reverse_go_append(A, t, Nil{}, h <> Nil{}))))))

def reverse_twice(-A: Data,
                  +xs: List<&2, A>) -> {List.reverse(&2, A, List.reverse(&2, A, xs)) == xs : List<&2, A>}:
    Equal.trans(List<&2, A>, List.reverse(&2, A, List.reverse(&2, A, xs)), List.append(&2, A, xs, Nil{}), xs,
        reverse_shift(A, xs, Nil{}, Nil{}), append_nil(A, xs))
