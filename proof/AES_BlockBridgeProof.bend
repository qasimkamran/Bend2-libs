import Base
import ../libs/AES256GCMCore.bend as Core

# Keep fuel symbolic while substituting the certified initial state.
def rounds_input_matches(+fuel: Nat, +words: List<&2, U32>,
    +block: List<&2, U32>, +initial: List<&2, U32>, +expected: List<&2, U32>,
    initial_match: {Core.aes_add_key(block, words, 0n) == initial : List<&2, U32>},
    rounds_match: {Core.aes_rounds.go(fuel, initial, words, 1n) == expected : List<&2, U32>}) ->
    {Core.aes_rounds.go(fuel, Core.aes_add_key(block, words, 0n), words, 1n) == expected : List<&2, U32>}:
    Equal.trans(List<&2, U32>,
        Core.aes_rounds.go(fuel, Core.aes_add_key(block, words, 0n), words, 1n),
        Core.aes_rounds.go(fuel, initial, words, 1n), expected,
        Equal.cong(List<&2, U32>, List<&2, U32>,
            value => Core.aes_rounds.go(fuel, value, words, 1n),
            Core.aes_add_key(block, words, 0n), initial, initial_match), rounds_match)

