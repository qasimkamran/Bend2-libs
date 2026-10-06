import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key
import ./AES_NistBlockProof.bend as Block
import ./AES_TraceProof.bend as Trace
import ./AES_BlockBridgeProof.bend as Bridge

# Each suffix uses an independently certified round rather than recomputing
# all remaining rounds during one equality check.
def suffix_14() ->
    {Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n) == Block.result() : List<&2, U32>}:
    Block.final_matches()

def suffix_13() ->
    {Core.aes_rounds.go(1n, Block.state_12(), Key.words_60(), 13n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n, Block.state_12(), Key.words_60(), 13n),
        Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n), Block.result(),
        Trace.rounds_step_at(0n, Block.state_12(), Key.words_60(), 13n,
            Block.state_13(), 14n, Block.round_13_matches(), {==}), suffix_14())

def suffix_12() ->
    {Core.aes_rounds.go(2n, Block.state_11(), Key.words_60(), 12n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(2n, Block.state_11(), Key.words_60(), 12n),
        Core.aes_rounds.go(1n, Block.state_12(), Key.words_60(), 13n), Block.result(),
        Trace.rounds_step_at(1n, Block.state_11(), Key.words_60(), 12n,
            Block.state_12(), 13n, Block.round_12_matches(), {==}), suffix_13())

def suffix_11() ->
    {Core.aes_rounds.go(3n, Block.state_10(), Key.words_60(), 11n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(3n, Block.state_10(), Key.words_60(), 11n),
        Core.aes_rounds.go(2n, Block.state_11(), Key.words_60(), 12n), Block.result(),
        Trace.rounds_step_at(2n, Block.state_10(), Key.words_60(), 11n,
            Block.state_11(), 12n, Block.round_11_matches(), {==}), suffix_12())

def suffix_10() ->
    {Core.aes_rounds.go(4n, Block.state_9(), Key.words_60(), 10n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(4n, Block.state_9(), Key.words_60(), 10n),
        Core.aes_rounds.go(3n, Block.state_10(), Key.words_60(), 11n), Block.result(),
        Trace.rounds_step_at(3n, Block.state_9(), Key.words_60(), 10n,
            Block.state_10(), 11n, Block.round_10_matches(), {==}), suffix_11())

def suffix_9() ->
    {Core.aes_rounds.go(5n, Block.state_8(), Key.words_60(), 9n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(5n, Block.state_8(), Key.words_60(), 9n),
        Core.aes_rounds.go(4n, Block.state_9(), Key.words_60(), 10n), Block.result(),
        Trace.rounds_step_at(4n, Block.state_8(), Key.words_60(), 9n,
            Block.state_9(), 10n, Block.round_9_matches(), {==}), suffix_10())

def suffix_8() ->
    {Core.aes_rounds.go(6n, Block.state_7(), Key.words_60(), 8n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(6n, Block.state_7(), Key.words_60(), 8n),
        Core.aes_rounds.go(5n, Block.state_8(), Key.words_60(), 9n), Block.result(),
        Trace.rounds_step_at(5n, Block.state_7(), Key.words_60(), 8n,
            Block.state_8(), 9n, Block.round_8_matches(), {==}), suffix_9())

def suffix_7() ->
    {Core.aes_rounds.go(7n, Block.state_6(), Key.words_60(), 7n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(7n, Block.state_6(), Key.words_60(), 7n),
        Core.aes_rounds.go(6n, Block.state_7(), Key.words_60(), 8n), Block.result(),
        Trace.rounds_step_at(6n, Block.state_6(), Key.words_60(), 7n,
            Block.state_7(), 8n, Block.round_7_matches(), {==}), suffix_8())

def suffix_6() ->
    {Core.aes_rounds.go(8n, Block.state_5(), Key.words_60(), 6n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(8n, Block.state_5(), Key.words_60(), 6n),
        Core.aes_rounds.go(7n, Block.state_6(), Key.words_60(), 7n), Block.result(),
        Trace.rounds_step_at(7n, Block.state_5(), Key.words_60(), 6n,
            Block.state_6(), 7n, Block.round_6_matches(), {==}), suffix_7())

def suffix_5() ->
    {Core.aes_rounds.go(9n, Block.state_4(), Key.words_60(), 5n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(9n, Block.state_4(), Key.words_60(), 5n),
        Core.aes_rounds.go(8n, Block.state_5(), Key.words_60(), 6n), Block.result(),
        Trace.rounds_step_at(8n, Block.state_4(), Key.words_60(), 5n,
            Block.state_5(), 6n, Block.round_5_matches(), {==}), suffix_6())

def suffix_4() ->
    {Core.aes_rounds.go(10n, Block.state_3(), Key.words_60(), 4n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(10n, Block.state_3(), Key.words_60(), 4n),
        Core.aes_rounds.go(9n, Block.state_4(), Key.words_60(), 5n), Block.result(),
        Trace.rounds_step_at(9n, Block.state_3(), Key.words_60(), 4n,
            Block.state_4(), 5n, Block.round_4_matches(), {==}), suffix_5())

def suffix_3() ->
    {Core.aes_rounds.go(11n, Block.state_2(), Key.words_60(), 3n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(11n, Block.state_2(), Key.words_60(), 3n),
        Core.aes_rounds.go(10n, Block.state_3(), Key.words_60(), 4n), Block.result(),
        Trace.rounds_step_at(10n, Block.state_2(), Key.words_60(), 3n,
            Block.state_3(), 4n, Block.round_3_matches(), {==}), suffix_4())

def suffix_2() ->
    {Core.aes_rounds.go(12n, Block.state_1(), Key.words_60(), 2n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(12n, Block.state_1(), Key.words_60(), 2n),
        Core.aes_rounds.go(11n, Block.state_2(), Key.words_60(), 3n), Block.result(),
        Trace.rounds_step_at(11n, Block.state_1(), Key.words_60(), 2n,
            Block.state_2(), 3n, Block.round_2_matches(), {==}), suffix_3())

def suffix_1() ->
    {Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n),
        Core.aes_rounds.go(12n, Block.state_1(), Key.words_60(), 2n), Block.result(),
        Trace.rounds_step_at(12n, Block.state_0(), Key.words_60(), 1n,
            Block.state_1(), 2n, Block.round_1_matches(), {==}), suffix_2())

def expanded_block_matches() ->
    {Core.aes256_encrypt_expanded(Key.words_60(), Block.block()) == Block.result() : List<&2, U32>}:
    Bridge.rounds_input_matches(13n, Key.words_60(), Block.block(), Block.state_0(),
        Block.result(), Block.initial_matches(), suffix_1())
