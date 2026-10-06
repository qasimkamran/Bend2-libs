import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key
import ./AES_NistBlockProof.bend as Block
import ./AES_TraceProof.bend as Trace
import ./AES_BlockBridgeProof.bend as Bridge

# Symbolic remaining fuel prevents every suffix from recomputing the rounds after it.

def suffix_1(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(fuel, Block.state_12(), Key.words_60(), 13n,
            Block.state_13(), 14n, Block.round_13_matches(), {==}), {==})

def suffix_2(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_11(), Key.words_60(), 12n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_11(), Key.words_60(), 12n),
        Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(fuel), Block.state_11(), Key.words_60(), 12n,
            Block.state_12(), 13n, Block.round_12_matches(), {==}),
        suffix_1(fuel))

def suffix_3(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_10(), Key.words_60(), 11n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_10(), Key.words_60(), 11n),
        Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_11(), Key.words_60(), 12n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(fuel)), Block.state_10(), Key.words_60(), 11n,
            Block.state_11(), 12n, Block.round_11_matches(), {==}),
        suffix_2(fuel))

def suffix_4(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(fuel)))), Block.state_9(), Key.words_60(), 10n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(fuel)))), Block.state_9(), Key.words_60(), 10n),
        Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_10(), Key.words_60(), 11n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(fuel))), Block.state_9(), Key.words_60(), 10n,
            Block.state_10(), 11n, Block.round_10_matches(), {==}),
        suffix_3(fuel))

def suffix_5(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(fuel))))), Block.state_8(), Key.words_60(), 9n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(fuel))))), Block.state_8(), Key.words_60(), 9n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(fuel)))), Block.state_9(), Key.words_60(), 10n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(fuel)))), Block.state_8(), Key.words_60(), 9n,
            Block.state_9(), 10n, Block.round_9_matches(), {==}),
        suffix_4(fuel))

def suffix_6(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))), Block.state_7(), Key.words_60(), 8n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))), Block.state_7(), Key.words_60(), 8n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(fuel))))), Block.state_8(), Key.words_60(), 9n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(fuel))))), Block.state_7(), Key.words_60(), 8n,
            Block.state_8(), 9n, Block.round_8_matches(), {==}),
        suffix_5(fuel))

def suffix_7(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))), Block.state_7(), Key.words_60(), 8n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))), Block.state_6(), Key.words_60(), 7n,
            Block.state_7(), 8n, Block.round_7_matches(), {==}),
        suffix_6(fuel))

def suffix_8(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))), Block.state_5(), Key.words_60(), 6n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))), Block.state_5(), Key.words_60(), 6n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_5(), Key.words_60(), 6n,
            Block.state_6(), 7n, Block.round_6_matches(), {==}),
        suffix_7(fuel))

def suffix_9(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))), Block.state_4(), Key.words_60(), 5n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))), Block.state_4(), Key.words_60(), 5n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))), Block.state_5(), Key.words_60(), 6n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))), Block.state_4(), Key.words_60(), 5n,
            Block.state_5(), 6n, Block.round_5_matches(), {==}),
        suffix_8(fuel))

def suffix_10(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))), Block.state_3(), Key.words_60(), 4n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))), Block.state_3(), Key.words_60(), 4n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))), Block.state_4(), Key.words_60(), 5n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))), Block.state_3(), Key.words_60(), 4n,
            Block.state_4(), 5n, Block.round_4_matches(), {==}),
        suffix_9(fuel))

def suffix_11(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))), Block.state_2(), Key.words_60(), 3n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))), Block.state_2(), Key.words_60(), 3n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))), Block.state_3(), Key.words_60(), 4n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))), Block.state_2(), Key.words_60(), 3n,
            Block.state_3(), 4n, Block.round_3_matches(), {==}),
        suffix_10(fuel))

def suffix_12(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))))), Block.state_1(), Key.words_60(), 2n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))))), Block.state_1(), Key.words_60(), 2n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))), Block.state_2(), Key.words_60(), 3n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))), Block.state_1(), Key.words_60(), 2n,
            Block.state_2(), 3n, Block.round_2_matches(), {==}),
        suffix_11(fuel))

def suffix_13(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n) ==
     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))))), Block.state_1(), Key.words_60(), 2n),
        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_step_at(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))))), Block.state_0(), Key.words_60(), 1n,
            Block.state_1(), 2n, Block.round_1_matches(), {==}),
        suffix_12(fuel))

def chunk_0(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_0(), Key.words_60(), 1n) ==
     Core.aes_rounds.go(fuel, Block.state_3(), Key.words_60(), 4n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_0(), Key.words_60(), 1n),
        Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_1(), Key.words_60(), 2n),
        Core.aes_rounds.go(fuel, Block.state_3(), Key.words_60(), 4n),
        Trace.rounds_step_at(1n+(1n+(fuel)), Block.state_0(), Key.words_60(), 1n,
            Block.state_1(), 2n, Block.round_1_matches(), {==}),
        Equal.trans(List<&2, U32>,
            Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_1(), Key.words_60(), 2n),
            Core.aes_rounds.go(1n+(fuel), Block.state_2(), Key.words_60(), 3n),
            Core.aes_rounds.go(fuel, Block.state_3(), Key.words_60(), 4n),
            Trace.rounds_step_at(1n+(fuel), Block.state_1(), Key.words_60(), 2n,
                Block.state_2(), 3n, Block.round_2_matches(), {==}),
            Trace.rounds_step_at(fuel, Block.state_2(), Key.words_60(), 3n,
                Block.state_3(), 4n, Block.round_3_matches(), {==})))

def chunk_3(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_3(), Key.words_60(), 4n) ==
     Core.aes_rounds.go(fuel, Block.state_6(), Key.words_60(), 7n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_3(), Key.words_60(), 4n),
        Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_4(), Key.words_60(), 5n),
        Core.aes_rounds.go(fuel, Block.state_6(), Key.words_60(), 7n),
        Trace.rounds_step_at(1n+(1n+(fuel)), Block.state_3(), Key.words_60(), 4n,
            Block.state_4(), 5n, Block.round_4_matches(), {==}),
        Equal.trans(List<&2, U32>,
            Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_4(), Key.words_60(), 5n),
            Core.aes_rounds.go(1n+(fuel), Block.state_5(), Key.words_60(), 6n),
            Core.aes_rounds.go(fuel, Block.state_6(), Key.words_60(), 7n),
            Trace.rounds_step_at(1n+(fuel), Block.state_4(), Key.words_60(), 5n,
                Block.state_5(), 6n, Block.round_5_matches(), {==}),
            Trace.rounds_step_at(fuel, Block.state_5(), Key.words_60(), 6n,
                Block.state_6(), 7n, Block.round_6_matches(), {==})))

def chunk_6(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_6(), Key.words_60(), 7n) ==
     Core.aes_rounds.go(fuel, Block.state_9(), Key.words_60(), 10n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_6(), Key.words_60(), 7n),
        Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_7(), Key.words_60(), 8n),
        Core.aes_rounds.go(fuel, Block.state_9(), Key.words_60(), 10n),
        Trace.rounds_step_at(1n+(1n+(fuel)), Block.state_6(), Key.words_60(), 7n,
            Block.state_7(), 8n, Block.round_7_matches(), {==}),
        Equal.trans(List<&2, U32>,
            Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_7(), Key.words_60(), 8n),
            Core.aes_rounds.go(1n+(fuel), Block.state_8(), Key.words_60(), 9n),
            Core.aes_rounds.go(fuel, Block.state_9(), Key.words_60(), 10n),
            Trace.rounds_step_at(1n+(fuel), Block.state_7(), Key.words_60(), 8n,
                Block.state_8(), 9n, Block.round_8_matches(), {==}),
            Trace.rounds_step_at(fuel, Block.state_8(), Key.words_60(), 9n,
                Block.state_9(), 10n, Block.round_9_matches(), {==})))

def chunk_9(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_9(), Key.words_60(), 10n) ==
     Core.aes_rounds.go(fuel, Block.state_12(), Key.words_60(), 13n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(fuel))), Block.state_9(), Key.words_60(), 10n),
        Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_10(), Key.words_60(), 11n),
        Core.aes_rounds.go(fuel, Block.state_12(), Key.words_60(), 13n),
        Trace.rounds_step_at(1n+(1n+(fuel)), Block.state_9(), Key.words_60(), 10n,
            Block.state_10(), 11n, Block.round_10_matches(), {==}),
        Equal.trans(List<&2, U32>,
            Core.aes_rounds.go(1n+(1n+(fuel)), Block.state_10(), Key.words_60(), 11n),
            Core.aes_rounds.go(1n+(fuel), Block.state_11(), Key.words_60(), 12n),
            Core.aes_rounds.go(fuel, Block.state_12(), Key.words_60(), 13n),
            Trace.rounds_step_at(1n+(fuel), Block.state_10(), Key.words_60(), 11n,
                Block.state_11(), 12n, Block.round_11_matches(), {==}),
            Trace.rounds_step_at(fuel, Block.state_11(), Key.words_60(), 12n,
                Block.state_12(), 13n, Block.round_12_matches(), {==})))

def rounds_0_to_6(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n) == Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n), Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))), Block.state_3(), Key.words_60(), 4n), Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n),
        chunk_0(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))),
        chunk_3(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel)))))))))

def rounds_6_to_12(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n) == Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n), Core.aes_rounds.go(1n+(1n+(1n+(1n+(fuel)))), Block.state_9(), Key.words_60(), 10n), Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n),
        chunk_6(1n+(1n+(1n+(1n+(fuel))))),
        chunk_9(1n+(fuel)))

def full_rounds_match(+fuel: Nat) ->
    {Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n) == Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n), Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n), Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),
        Equal.trans(List<&2, U32>,
            Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))))))))), Block.state_0(), Key.words_60(), 1n), Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(fuel))))))), Block.state_6(), Key.words_60(), 7n), Core.aes_rounds.go(1n+(fuel), Block.state_12(), Key.words_60(), 13n), rounds_0_to_6(fuel), rounds_6_to_12(fuel)),
        suffix_1(fuel))

def full_nist_rounds_match() ->
    {Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n) == Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n),
        Core.aes_rounds.go(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(0n))))))))))))), Block.state_0(), Key.words_60(), 1n),
        Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n),
        Trace.rounds_fuel_matches(13n, 1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(1n+(0n))))))))))))), Block.state_0(), Key.words_60(), 1n, {==}), full_rounds_match(0n))

def final_nist_block_match() ->
    {Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n) == Block.result() : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n),
        Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n),
        Block.result(), full_nist_rounds_match(), Block.final_matches())

def expanded_block_matches() ->
    {Core.aes256_encrypt_expanded(Key.words_60(), Block.block()) == Block.result() : List<&2, U32>}:
    Bridge.expanded_block_from_initial(Key.words_60(), Block.block(), Block.state_0(),
        Block.result(), Block.initial_matches(), final_nist_block_match())
