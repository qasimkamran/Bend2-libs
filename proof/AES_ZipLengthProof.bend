import Base
import ../libs/AES256GCMCore.bend as Core

def false_type(b: Bool) -> Data:
    match b:
        case False{}: Unit
        case True{}: Empty

def false_true(e: {False{} == True{} : Bool}) -> Empty:
    %e : false_type(_)
    Unit{}

def predecessor(n: Nat) -> Nat:
    match n:
        case 0n: 0n
        case 1n+p: p

def zip_length_equal(+bytes: List<&2, U32>, +stream: List<&2, U32>,
    same_length: {List.length(&2, U32, bytes) ==
        List.length(&2, U32, stream) : Nat}) ->
    {List.length(&2, U32, Core.gcm_zip_xor(bytes, stream)) ==
        List.length(&2, U32, bytes) : Nat}:
    match bytes stream:
        case Nil{} _:
            Equal.cong(List<&2, U32>, Nat,
                xs => List.length(&2, U32, xs),
                Core.gcm_zip_xor(Nil{}, stream), Nil{},
                Core.gcm_zip_xor_nil_left(stream))
        case byte <> tail Nil{}:
            impossible = Equal.cong(Nat, Bool,
                n => Nat.is_eq(n, 0n),
                1n+List.length(&2, U32, tail), 0n, same_length)
            Empty.absurd(
                {List.length(&2, U32,
                    Core.gcm_zip_xor(byte <> tail, Nil{})) ==
                 List.length(&2, U32, byte <> tail) : Nat},
                false_true(impossible))
        case byte <> tail stream_byte <> stream_tail:
            tail_length = Equal.cong(Nat, Nat, predecessor,
                1n+List.length(&2, U32, tail),
                1n+List.length(&2, U32, stream_tail), same_length)
            Equal.cong(Nat, Nat, n => 1n+n,
                List.length(&2, U32, Core.gcm_zip_xor(tail, stream_tail)),
                List.length(&2, U32, tail),
                zip_length_equal(tail, stream_tail, tail_length))

def encrypt_block_length(+words: List<&2, U32>, +counter: List<&2, U32>) ->
    {List.length(&2, U32, Core.aes256_encrypt_expanded(words, counter)) ==
     16n : Nat}:
    {==}

def nat_add_succ_right(+a: Nat, +b: Nat) ->
    {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}:
    match a:
        case 0n: {==}
        case 1n+p:
            Equal.cong(Nat, Nat, n => 1n+n,
                Nat.add(p, 1n+b), 1n+Nat.add(p, b),
                nat_add_succ_right(p, b))

def nat_add_zero_right(+a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
    match a:
        case 0n: {==}
        case 1n+p:
            Equal.cong(Nat, Nat, n => 1n+n,
                Nat.add(p, 0n), p, nat_add_zero_right(p))

def nat_add_comm(+a: Nat, +b: Nat) ->
    {Nat.add(a, b) == Nat.add(b, a) : Nat}:
    match a:
        case 0n:
            Equal.sym(Nat, Nat.add(b, 0n), b,
                nat_add_zero_right(b))
        case 1n+p:
            Equal.trans(Nat,
                Nat.add(1n+p, b), 1n+Nat.add(b, p),
                Nat.add(b, 1n+p),
                Equal.cong(Nat, Nat, n => 1n+n,
                    Nat.add(p, b), Nat.add(b, p), nat_add_comm(p, b)),
                Equal.sym(Nat,
                    Nat.add(b, 1n+p), 1n+Nat.add(b, p),
                    nat_add_succ_right(b, p)))

def reverse_go_length(+xs: List<&2, U32>, +acc: List<&2, U32>) ->
    {List.length(&2, U32, List.reverse.go(&2, U32, xs, acc)) ==
     (List.length(&2, U32, acc) + List.length(&2, U32, xs) : Nat) : Nat}:
    match xs:
        case Nil{}:
            Equal.sym(Nat, Nat.add(List.length(&2, U32, acc), 0n),
                List.length(&2, U32, acc),
                nat_add_zero_right(List.length(&2, U32, acc)))
        case x <> tail:
            Equal.trans(Nat,
                List.length(&2, U32,
                    List.reverse.go(&2, U32, x <> tail, acc)),
                (List.length(&2, U32, x <> acc) +
                    List.length(&2, U32, tail) : Nat),
                (List.length(&2, U32, acc) +
                    List.length(&2, U32, x <> tail) : Nat),
                reverse_go_length(tail, x <> acc),
                Equal.sym(Nat,
                    (List.length(&2, U32, acc) +
                        List.length(&2, U32, x <> tail) : Nat),
                    (List.length(&2, U32, x <> acc) +
                        List.length(&2, U32, tail) : Nat),
                    nat_add_succ_right(List.length(&2, U32, acc),
                        List.length(&2, U32, tail))))

def reverse_length(+xs: List<&2, U32>) ->
    {List.length(&2, U32, List.reverse(&2, U32, xs)) ==
     List.length(&2, U32, xs) : Nat}:
    reverse_go_length(xs, Nil{})

def append_length(+xs: List<&2, U32>, +ys: List<&2, U32>) ->
    {List.length(&2, U32, List.append(&2, U32, xs, ys)) ==
     Nat.add(List.length(&2, U32, xs), List.length(&2, U32, ys)) : Nat}:
    match xs:
        case Nil{}: {==}
        case x <> tail:
            Equal.cong(Nat, Nat, n => 1n+n,
                List.length(&2, U32, List.append(&2, U32, tail, ys)),
                Nat.add(List.length(&2, U32, tail),
                    List.length(&2, U32, ys)),
                append_length(tail, ys))

def stream_step_length(+words: List<&2, U32>,
    +counter: List<&2, U32>, +acc: List<&2, U32>) ->
    {List.length(&2, U32, List.append(&2, U32,
        List.reverse(&2, U32,
            Core.aes256_encrypt_expanded(words, counter)), acc)) ==
     Nat.add(16n, List.length(&2, U32, acc)) : Nat}:
    +block = Core.aes256_encrypt_expanded(words, counter)
    Equal.trans(Nat,
        List.length(&2, U32,
            List.append(&2, U32, List.reverse(&2, U32, block), acc)),
        Nat.add(List.length(&2, U32,
            List.reverse(&2, U32, block)),
            List.length(&2, U32, acc)),
        Nat.add(16n, List.length(&2, U32, acc)),
        append_length(List.reverse(&2, U32, block), acc),
        Equal.cong(Nat, Nat,
            n => Nat.add(n, List.length(&2, U32, acc)),
            List.length(&2, U32, List.reverse(&2, U32, block)),
            16n,
            Equal.trans(Nat,
                List.length(&2, U32, List.reverse(&2, U32, block)),
                List.length(&2, U32, block), 16n,
                reverse_length(block),
                encrypt_block_length(words, counter))))

def ctr_stream_exact_go_length(+fuel: Nat, +words: List<&2, U32>,
    +counter: List<&2, U32>, +block: List<&2, U32>) ->
    {List.length(&2, U32,
        Core.gcm_ctr_stream_exact.go(fuel, words, counter, block)) ==
     fuel : Nat}:
    match fuel:
        case 0n: {==}
        case 1n+p:
            +step = Core.gcm_ctr_step(words, counter, block)
            Equal.cong(Nat, Nat, n => 1n+n,
                List.length(&2, U32,
                    Core.gcm_ctr_stream_exact.go(p, words,
                        Core.gcm_ctr_step_counter(step),
                        Core.gcm_ctr_step_rest(step))),
                p,
                ctr_stream_exact_go_length(p, words,
                    Core.gcm_ctr_step_counter(step),
                    Core.gcm_ctr_step_rest(step)))

def ctr_stream_exact_length(+fuel: Nat, +words: List<&2, U32>,
    +start: List<&2, U32>) ->
    {List.length(&2, U32,
        Core.gcm_ctr_stream_exact(fuel, words, start)) == fuel : Nat}:
    ctr_stream_exact_go_length(fuel, words, start, Nil{})

def ctr_encrypt_ciphertext_length(+words: List<&2, U32>,
    +nonce: List<&2, U32>, +plaintext: List<&2, U32>) ->
    {List.length(&2, U32,
        Core.gcm_ciphertext_bytes(
            Core.gcm_ctr_encrypt(words, nonce, plaintext))) ==
     List.length(&2, U32, plaintext) : Nat}:
    +start = Core.gcm_inc32(Core.gcm_j0(nonce))
    +stream = Core.gcm_ctr_stream_exact(
        List.length(&2, U32, plaintext), words, start)
    zip_length_equal(plaintext, stream,
        Equal.sym(Nat,
            List.length(&2, U32, stream),
            List.length(&2, U32, plaintext),
            ctr_stream_exact_length(List.length(&2, U32, plaintext),
                words, start)))



