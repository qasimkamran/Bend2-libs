import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key

# Candidate NIST ctr4 block stages. Only kernel acceptance certifies them.

def block() -> List<&2, U32>:
    [202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136, 0, 0, 0, 4]

def state_0() -> List<&2, U32>:
    [52, 1, 83, 44, 124, 171, 168, 177, 179, 160, 119, 28, 103, 48, 131, 12]

def state_1() -> List<&2, U32>:
    [99, 217, 123, 202, 0, 240, 211, 194, 158, 235, 100, 65, 172, 140, 90, 1]

def state_2() -> List<&2, U32>:
    [166, 82, 172, 54, 81, 113, 219, 17, 174, 153, 103, 141, 244, 254, 80, 113]

def state_3() -> List<&2, U32>:
    [155, 192, 165, 13, 75, 13, 40, 217, 246, 34, 202, 144, 6, 131, 131, 67]

def state_4() -> List<&2, U32>:
    [21, 3, 100, 171, 164, 36, 74, 15, 196, 240, 19, 210, 116, 94, 85, 252]

def state_5() -> List<&2, U32>:
    [223, 38, 193, 186, 244, 248, 161, 8, 114, 81, 72, 38, 193, 79, 56, 30]

def state_6() -> List<&2, U32>:
    [231, 134, 36, 132, 145, 183, 101, 62, 108, 233, 136, 9, 47, 76, 77, 238]

def state_7() -> List<&2, U32>:
    [104, 86, 0, 74, 167, 231, 84, 108, 232, 159, 63, 210, 13, 193, 141, 25]

def state_8() -> List<&2, U32>:
    [217, 77, 77, 11, 127, 252, 79, 130, 159, 160, 42, 15, 249, 37, 185, 214]

def state_9() -> List<&2, U32>:
    [103, 32, 186, 13, 12, 79, 251, 202, 94, 106, 243, 137, 0, 205, 73, 19]

def state_10() -> List<&2, U32>:
    [246, 120, 185, 168, 55, 216, 222, 141, 223, 204, 67, 83, 142, 120, 170, 6]

def state_11() -> List<&2, U32>:
    [20, 12, 6, 188, 47, 123, 119, 85, 2, 226, 46, 116, 9, 96, 78, 254]

def state_12() -> List<&2, U32>:
    [86, 128, 159, 221, 185, 66, 186, 239, 79, 111, 105, 114, 7, 70, 62, 206]

def state_13() -> List<&2, U32>:
    [24, 186, 12, 86, 232, 131, 159, 167, 220, 179, 8, 240, 88, 249, 199, 27]

def result() -> List<&2, U32>:
    [144, 140, 130, 221, 204, 101, 178, 110, 136, 127, 133, 52, 31, 36, 61, 29]

def initial_matches() ->
    {Core.aes_add_key(block(), Key.words_60(), 0n) == state_0() : List<&2, U32>}:
    {==}

def round_1_matches() ->
    {Core.aes_middle_round(state_0(), Key.words_60(), 1n) == state_1() : List<&2, U32>}:
    {==}

def round_2_matches() ->
    {Core.aes_middle_round(state_1(), Key.words_60(), 2n) == state_2() : List<&2, U32>}:
    {==}

def round_3_matches() ->
    {Core.aes_middle_round(state_2(), Key.words_60(), 3n) == state_3() : List<&2, U32>}:
    {==}

def round_4_matches() ->
    {Core.aes_middle_round(state_3(), Key.words_60(), 4n) == state_4() : List<&2, U32>}:
    {==}

def round_5_matches() ->
    {Core.aes_middle_round(state_4(), Key.words_60(), 5n) == state_5() : List<&2, U32>}:
    {==}

def round_6_matches() ->
    {Core.aes_middle_round(state_5(), Key.words_60(), 6n) == state_6() : List<&2, U32>}:
    {==}

def round_7_matches() ->
    {Core.aes_middle_round(state_6(), Key.words_60(), 7n) == state_7() : List<&2, U32>}:
    {==}

def round_8_matches() ->
    {Core.aes_middle_round(state_7(), Key.words_60(), 8n) == state_8() : List<&2, U32>}:
    {==}

def round_9_matches() ->
    {Core.aes_middle_round(state_8(), Key.words_60(), 9n) == state_9() : List<&2, U32>}:
    {==}

def round_10_matches() ->
    {Core.aes_middle_round(state_9(), Key.words_60(), 10n) == state_10() : List<&2, U32>}:
    {==}

def round_11_matches() ->
    {Core.aes_middle_round(state_10(), Key.words_60(), 11n) == state_11() : List<&2, U32>}:
    {==}

def round_12_matches() ->
    {Core.aes_middle_round(state_11(), Key.words_60(), 12n) == state_12() : List<&2, U32>}:
    {==}

def round_13_matches() ->
    {Core.aes_middle_round(state_12(), Key.words_60(), 13n) == state_13() : List<&2, U32>}:
    {==}

def final_matches() ->
    {Core.aes_final_round(state_13(), Key.words_60()) == result() : List<&2, U32>}:
    {==}
