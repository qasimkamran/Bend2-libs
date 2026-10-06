import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key
import ./AES_NistCtr2BlockProof.bend as B2
import ./AES_NistCtr2ComposeProof.bend as P2
import ./AES_NistCtr3BlockProof.bend as B3
import ./AES_NistCtr3ComposeProof.bend as P3
import ./AES_NistCtr4BlockProof.bend as B4
import ./AES_NistCtr4ComposeProof.bend as P4
import ./AES_NistCtr5BlockProof.bend as B5
import ./AES_NistCtr5ComposeProof.bend as P5

def stream_step(+remaining: Nat, +fuel: Nat, +words: List<&2, U32>, +counter: List<&2, U32>, +block: List<&2, U32>,
    count: {remaining == 1n+fuel : Nat}, same: {Core.aes256_encrypt_expanded(words, counter) == block : List<&2, U32>}) ->
    {Core.gcm_ctr_stream_exact.go(remaining, words, counter, Nil{}) ==
     Core.aes_byte_at(block, 0n) <> Core.gcm_ctr_stream_exact.go(fuel, words, Core.gcm_inc32(counter), List.tail(&2, U32, block)) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(remaining, words, counter, Nil{}),
        Core.gcm_ctr_stream_exact.go(1n+fuel, words, counter, Nil{}),
        Core.aes_byte_at(block, 0n) <> Core.gcm_ctr_stream_exact.go(fuel, words, Core.gcm_inc32(counter), List.tail(&2, U32, block)),
        Equal.cong(Nat, List<&2, U32>, n => Core.gcm_ctr_stream_exact.go(n, words, counter, Nil{}), remaining, 1n+fuel, count),
        Equal.cong(List<&2, U32>, List<&2, U32>, value =>
            Core.aes_byte_at(value, 0n) <> Core.gcm_ctr_stream_exact.go(fuel, words, Core.gcm_inc32(counter), List.tail(&2, U32, value)),
            Core.aes256_encrypt_expanded(words, counter), block, same))

def checkpoint_ctr2_stream(+remaining: Nat, +fuel: Nat, +next_counter: List<&2, U32>,
    count: {remaining == 16n+fuel : Nat},
    counter: {Core.gcm_inc32(B2.block()) == next_counter : List<&2, U32>}) ->
    {Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B2.block(), Nil{}) == List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B2.block(), Nil{}), Core.aes_byte_at(B2.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B2.block()), List.tail(&2, U32, B2.result())), List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})),
        stream_step(remaining, 15n+fuel, Key.words_60(), B2.block(), B2.result(), count, P2.expanded_block_matches()),
        Equal.trans(List<&2, U32>, Core.aes_byte_at(B2.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B2.block()), List.tail(&2, U32, B2.result())), List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), Core.gcm_inc32(B2.block()), Nil{})), List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})), {==},
            Equal.cong(List<&2, U32>, List<&2, U32>, next => List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next, Nil{})),
                Core.gcm_inc32(B2.block()), next_counter, counter)))

def checkpoint_ctr3_stream(+remaining: Nat, +fuel: Nat, +next_counter: List<&2, U32>,
    count: {remaining == 16n+fuel : Nat},
    counter: {Core.gcm_inc32(B3.block()) == next_counter : List<&2, U32>}) ->
    {Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B3.block(), Nil{}) == List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B3.block(), Nil{}), Core.aes_byte_at(B3.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B3.block()), List.tail(&2, U32, B3.result())), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})),
        stream_step(remaining, 15n+fuel, Key.words_60(), B3.block(), B3.result(), count, P3.expanded_block_matches()),
        Equal.trans(List<&2, U32>, Core.aes_byte_at(B3.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B3.block()), List.tail(&2, U32, B3.result())), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), Core.gcm_inc32(B3.block()), Nil{})), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})), {==},
            Equal.cong(List<&2, U32>, List<&2, U32>, next => List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next, Nil{})),
                Core.gcm_inc32(B3.block()), next_counter, counter)))

def checkpoint_ctr4_stream(+remaining: Nat, +fuel: Nat, +next_counter: List<&2, U32>,
    count: {remaining == 16n+fuel : Nat},
    counter: {Core.gcm_inc32(B4.block()) == next_counter : List<&2, U32>}) ->
    {Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B4.block(), Nil{}) == List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B4.block(), Nil{}), Core.aes_byte_at(B4.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B4.block()), List.tail(&2, U32, B4.result())), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})),
        stream_step(remaining, 15n+fuel, Key.words_60(), B4.block(), B4.result(), count, P4.expanded_block_matches()),
        Equal.trans(List<&2, U32>, Core.aes_byte_at(B4.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B4.block()), List.tail(&2, U32, B4.result())), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), Core.gcm_inc32(B4.block()), Nil{})), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})), {==},
            Equal.cong(List<&2, U32>, List<&2, U32>, next => List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next, Nil{})),
                Core.gcm_inc32(B4.block()), next_counter, counter)))

def checkpoint_ctr5_stream(+remaining: Nat, +fuel: Nat, +next_counter: List<&2, U32>,
    count: {remaining == 16n+fuel : Nat},
    counter: {Core.gcm_inc32(B5.block()) == next_counter : List<&2, U32>}) ->
    {Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B5.block(), Nil{}) == List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(remaining, Key.words_60(), B5.block(), Nil{}), Core.aes_byte_at(B5.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B5.block()), List.tail(&2, U32, B5.result())), List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})),
        stream_step(remaining, 15n+fuel, Key.words_60(), B5.block(), B5.result(), count, P5.expanded_block_matches()),
        Equal.trans(List<&2, U32>, Core.aes_byte_at(B5.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B5.block()), List.tail(&2, U32, B5.result())), List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), Core.gcm_inc32(B5.block()), Nil{})), List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next_counter, Nil{})), {==},
            Equal.cong(List<&2, U32>, List<&2, U32>, next => List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(fuel, Key.words_60(), next, Nil{})),
                Core.gcm_inc32(B5.block()), next_counter, counter)))

def counter_6() -> List<&2, U32>:
    [202,254,186,190,250,206,219,173,222,202,248,136,0,0,0,6]

def stream_64() -> List<&2, U32>:
    List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), B5.result())))

def stream_60() -> List<&2, U32>:
    List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), List.take(&2, U32, B5.result(), 12n))))

def checkpoint_stream_64() ->
    {Core.gcm_ctr_stream_exact.go(64n, Key.words_60(), B2.block(), Nil{}) == stream_64() : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(64n, Key.words_60(), B2.block(), Nil{}), List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(48n, Key.words_60(), B3.block(), Nil{})), stream_64(), checkpoint_ctr2_stream(64n, 48n, B3.block(), {==}, {==}), Equal.trans(List<&2, U32>, List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(48n, Key.words_60(), B3.block(), Nil{})), List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(32n, Key.words_60(), B4.block(), Nil{}))), stream_64(), Equal.cong(List<&2, U32>, List<&2, U32>, value => List.append(&2, U32, B2.result(), value), Core.gcm_ctr_stream_exact.go(48n, Key.words_60(), B3.block(), Nil{}), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(32n, Key.words_60(), B4.block(), Nil{})), checkpoint_ctr3_stream(48n, 32n, B4.block(), {==}, {==})), Equal.trans(List<&2, U32>, List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(32n, Key.words_60(), B4.block(), Nil{}))), List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(16n, Key.words_60(), B5.block(), Nil{})))), stream_64(), Equal.cong(List<&2, U32>, List<&2, U32>, value => List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), value)), Core.gcm_ctr_stream_exact.go(32n, Key.words_60(), B4.block(), Nil{}), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(16n, Key.words_60(), B5.block(), Nil{})), checkpoint_ctr4_stream(32n, 16n, B5.block(), {==}, {==})), Equal.trans(List<&2, U32>, List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(16n, Key.words_60(), B5.block(), Nil{})))), List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(0n, Key.words_60(), counter_6(), Nil{}))))), stream_64(), Equal.cong(List<&2, U32>, List<&2, U32>, value => List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), value))), Core.gcm_ctr_stream_exact.go(16n, Key.words_60(), B5.block(), Nil{}), List.append(&2, U32, B5.result(), Core.gcm_ctr_stream_exact.go(0n, Key.words_60(), counter_6(), Nil{})), checkpoint_ctr5_stream(16n, 0n, counter_6(), {==}, {==})), {==}))))

def checkpoint_ctr5_partial() ->
    {Core.gcm_ctr_stream_exact.go(12n, Key.words_60(), B5.block(), Nil{}) == List.take(&2, U32, B5.result(), 12n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(12n, Key.words_60(), B5.block(), Nil{}),
        Core.aes_byte_at(B5.result(), 0n) <> Core.gcm_ctr_stream_exact.go(11n, Key.words_60(), Core.gcm_inc32(B5.block()), List.tail(&2, U32, B5.result())),
        List.take(&2, U32, B5.result(), 12n), stream_step(12n, 11n, Key.words_60(), B5.block(), B5.result(), {==}, P5.expanded_block_matches()), {==})

def checkpoint_stream_60() ->
    {Core.gcm_ctr_stream_exact.go(60n, Key.words_60(), B2.block(), Nil{}) == stream_60() : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(60n, Key.words_60(), B2.block(), Nil{}), List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(44n, Key.words_60(), B3.block(), Nil{})), stream_60(), checkpoint_ctr2_stream(60n, 44n, B3.block(), {==}, {==}), Equal.trans(List<&2, U32>, List.append(&2, U32, B2.result(), Core.gcm_ctr_stream_exact.go(44n, Key.words_60(), B3.block(), Nil{})), List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(28n, Key.words_60(), B4.block(), Nil{}))), stream_60(), Equal.cong(List<&2, U32>, List<&2, U32>, value => List.append(&2, U32, B2.result(), value), Core.gcm_ctr_stream_exact.go(44n, Key.words_60(), B3.block(), Nil{}), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(28n, Key.words_60(), B4.block(), Nil{})), checkpoint_ctr3_stream(44n, 28n, B4.block(), {==}, {==})), Equal.trans(List<&2, U32>, List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), Core.gcm_ctr_stream_exact.go(28n, Key.words_60(), B4.block(), Nil{}))), List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(12n, Key.words_60(), B5.block(), Nil{})))), stream_60(), Equal.cong(List<&2, U32>, List<&2, U32>, value => List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), value)), Core.gcm_ctr_stream_exact.go(28n, Key.words_60(), B4.block(), Nil{}), List.append(&2, U32, B4.result(), Core.gcm_ctr_stream_exact.go(12n, Key.words_60(), B5.block(), Nil{})), checkpoint_ctr4_stream(28n, 12n, B5.block(), {==}, {==})), Equal.cong(List<&2, U32>, List<&2, U32>, value => List.append(&2, U32, B2.result(), List.append(&2, U32, B3.result(), List.append(&2, U32, B4.result(), value))), Core.gcm_ctr_stream_exact.go(12n, Key.words_60(), B5.block(), Nil{}), List.take(&2, U32, B5.result(), 12n), checkpoint_ctr5_partial()))))
