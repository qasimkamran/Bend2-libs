import Base
import ../libs/AES256GCMCore.bend as Core

# Compose short, independently checked computation steps. Concrete AES vectors
# can reuse these equalities without normalizing every round in one kernel call.

def next_word(+i: U32, rcon: U32, +words: List<&2, U32>) -> U32:
    previous = Core.aes_word_at(words, U32.to_nat(U32.sub(i, 1)))
    back8 = Core.aes_word_at(words, U32.to_nat(U32.sub(i, 8)))
    part = Core.aes_key_word_kind(previous, rcon, U32.is_eq(U32.mod(i, 8), 0), U32.is_eq(U32.mod(i, 8), 4))
    U32.xor(back8, part)

def expand_step(+fuel: Nat, +i: U32, +rcon: U32, +words: List<&2, U32>,
    +next_words: List<&2, U32>, +next_rcon: U32,
    words_match: {List.append(&2, U32, words, [next_word(i, rcon, words)]) == next_words : List<&2, U32>},
    rcon_match: {Core.aes_rcon_kind(rcon, U32.is_eq(U32.mod(i, 8), 0)) == next_rcon : U32}) ->
    {Core.aes_expand.go(1n+fuel, i, rcon, words) ==
     Core.aes_expand.go(fuel, U32.add(i, 1), next_rcon, next_words) : List<&2, U32>}:
    +actual_rcon = Core.aes_rcon_kind(rcon, U32.is_eq(U32.mod(i, 8), 0))
    Equal.trans(List<&2, U32>, Core.aes_expand.go(1n+fuel, i, rcon, words),
        Core.aes_expand.go(fuel, U32.add(i, 1), actual_rcon, next_words),
        Core.aes_expand.go(fuel, U32.add(i, 1), next_rcon, next_words),
        Equal.cong(List<&2, U32>, List<&2, U32>,
            value => Core.aes_expand.go(fuel, U32.add(i, 1), actual_rcon, value),
            List.append(&2, U32, words, [next_word(i, rcon, words)]), next_words, words_match),
        Equal.cong(U32, List<&2, U32>, value => Core.aes_expand.go(fuel, U32.add(i, 1), value, next_words),
            actual_rcon, next_rcon, rcon_match))

def rounds_step(+fuel: Nat, +state: List<&2, U32>, +words: List<&2, U32>,
    +round: Nat, +next_state: List<&2, U32>,
    same: {Core.aes_middle_round(state, words, round) == next_state : List<&2, U32>}) ->
    {Core.aes_rounds.go(1n+fuel, state, words, round) ==
     Core.aes_rounds.go(fuel, next_state, words, (round + 1n : Nat)) : List<&2, U32>}:
    Equal.cong(List<&2, U32>, List<&2, U32>,
        value => Core.aes_rounds.go(fuel, value, words, (round + 1n : Nat)),
        Core.aes_middle_round(state, words, round), next_state, same)

def expand_step_at(+fuel: Nat, +i: U32, +rcon: U32, +words: List<&2, U32>,
    +next_words: List<&2, U32>, +next_rcon: U32, +next_i: U32,
    words_match: {List.append(&2, U32, words, [next_word(i, rcon, words)]) == next_words : List<&2, U32>},
    rcon_match: {Core.aes_rcon_kind(rcon, U32.is_eq(U32.mod(i, 8), 0)) == next_rcon : U32},
    index_match: {U32.add(i, 1) == next_i : U32}) ->
    {Core.aes_expand.go(1n+fuel, i, rcon, words) ==
     Core.aes_expand.go(fuel, next_i, next_rcon, next_words) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.aes_expand.go(1n+fuel, i, rcon, words),
        Core.aes_expand.go(fuel, U32.add(i, 1), next_rcon, next_words),
        Core.aes_expand.go(fuel, next_i, next_rcon, next_words),
        expand_step(fuel, i, rcon, words, next_words, next_rcon, words_match, rcon_match),
        Equal.cong(U32, List<&2, U32>, value => Core.aes_expand.go(fuel, value, next_rcon, next_words),
            U32.add(i, 1), next_i, index_match))

def rounds_step_at(+fuel: Nat, +state: List<&2, U32>, +words: List<&2, U32>,
    +round: Nat, +next_state: List<&2, U32>, +next_round: Nat,
    same: {Core.aes_middle_round(state, words, round) == next_state : List<&2, U32>},
    round_match: {(round + 1n : Nat) == next_round : Nat}) ->
    {Core.aes_rounds.go(1n+fuel, state, words, round) ==
     Core.aes_rounds.go(fuel, next_state, words, next_round) : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.aes_rounds.go(1n+fuel, state, words, round),
        Core.aes_rounds.go(fuel, next_state, words, (round + 1n : Nat)),
        Core.aes_rounds.go(fuel, next_state, words, next_round),
        rounds_step(fuel, state, words, round, next_state, same),
        Equal.cong(Nat, List<&2, U32>,
            value => Core.aes_rounds.go(fuel, next_state, words, value),
            (round + 1n : Nat), next_round, round_match))
