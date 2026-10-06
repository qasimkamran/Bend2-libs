import Base
import ../libs/AES256GCMCore.bend as Core

# Substitute a certified initial word list with a symbolic fuel parameter.
# The public bridge below compares function aliases before applying the key,
# avoiding normalization of all 52 rounds merely to compare the aliases.
def expand_input_matches(+fuel: Nat, +key: List<&2, U32>,
    +initial_words: List<&2, U32>, +expected: List<&2, U32>,
    initial_match: {Core.aes_words(key) == initial_words : List<&2, U32>},
    expanded_match: {Core.aes_expand.go(fuel, 8, 1, initial_words) == expected : List<&2, U32>}) ->
    {Core.aes_expand.go(fuel, 8, 1, Core.aes_words(key)) == expected : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.aes_expand.go(fuel, 8, 1, Core.aes_words(key)),
        Core.aes_expand.go(fuel, 8, 1, initial_words), expected,
        Equal.cong(List<&2, U32>, List<&2, U32>, values => Core.aes_expand.go(fuel, 8, 1, values),
            Core.aes_words(key), initial_words, initial_match), expanded_match)

def expand_key_matches(+fuel: Nat, +key: List<&2, U32>,
    +initial_words: List<&2, U32>, +expected: List<&2, U32>,
    +initial_match: {Core.aes_words(key) == initial_words : List<&2, U32>},
    +expanded_match: {Core.aes_expand.go(fuel, 8, 1, initial_words) == expected : List<&2, U32>}) ->
    {Core.aes_expand_key(fuel, key) == expected : List<&2, U32>}:
    match key:
        case Nil{}: expand_input_matches(fuel, key, initial_words, expected, initial_match, expanded_match)
        case head <> tail: expand_input_matches(fuel, key, initial_words, expected, initial_match, expanded_match)

def expansion_alias() ->
    {Core.aes256_expand == (+key => Core.aes_expand_key(52n, key)) :
        @+key: List<&2, U32> -> List<&2, U32>}:
    {==}

def public_expansion_matches(+key: List<&2, U32>, +expected: List<&2, U32>,
    same: {Core.aes_expand_key(52n, key) == expected : List<&2, U32>}) ->
    {Core.aes256_expand(key) == expected : List<&2, U32>}:
    Equal.trans(List<&2, U32>, Core.aes256_expand(key), Core.aes_expand_key(52n, key), expected,
        Equal.cong((@+input: List<&2, U32> -> List<&2, U32>), List<&2, U32>,
            function => function(key), Core.aes256_expand,
            +input => Core.aes_expand_key(52n, input), expansion_alias()), same)
