import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key

# Candidate NIST ctr5 block stages. Only kernel acceptance certifies them.

def block() -> List<&2, U32>:
    [202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136, 0, 0, 0, 5]

def state_0() -> List<&2, U32>:
    [52, 1, 83, 44, 124, 171, 168, 177, 179, 160, 119, 28, 103, 48, 131, 13]

def state_1() -> List<&2, U32>:
    [74, 240, 0, 152, 0, 240, 211, 194, 158, 235, 100, 65, 172, 140, 90, 1]

def state_2() -> List<&2, U32>:
    [252, 127, 129, 65, 99, 67, 141, 117, 236, 95, 227, 207, 36, 151, 233, 200]

def state_3() -> List<&2, U32>:
    [167, 209, 102, 17, 183, 52, 40, 220, 117, 205, 211, 126, 81, 85, 105, 64]

def state_4() -> List<&2, U32>:
    [206, 235, 242, 136, 162, 8, 171, 176, 215, 227, 120, 240, 23, 96, 193, 156]

def state_5() -> List<&2, U32>:
    [197, 206, 62, 204, 140, 155, 173, 211, 142, 156, 245, 107, 37, 236, 240, 236]

def state_6() -> List<&2, U32>:
    [96, 111, 229, 78, 25, 75, 102, 169, 156, 55, 238, 206, 10, 137, 160, 247]

def state_7() -> List<&2, U32>:
    [98, 73, 93, 240, 233, 212, 19, 244, 232, 93, 89, 248, 50, 120, 106, 18]

def state_8() -> List<&2, U32>:
    [192, 197, 62, 121, 92, 48, 202, 56, 8, 173, 154, 33, 38, 205, 122, 245]

def state_9() -> List<&2, U32>:
    [232, 43, 11, 78, 169, 47, 169, 161, 75, 121, 4, 84, 104, 169, 31, 25]

def state_10() -> List<&2, U32>:
    [52, 236, 51, 173, 169, 104, 185, 94, 57, 199, 169, 72, 83, 42, 251, 227]

def state_11() -> List<&2, U32>:
    [123, 32, 115, 67, 197, 154, 23, 14, 122, 125, 197, 61, 152, 18, 132, 165]

def state_12() -> List<&2, U32>:
    [97, 109, 52, 196, 98, 208, 15, 200, 146, 156, 255, 201, 226, 41, 254, 58]

def state_13() -> List<&2, U32>:
    [164, 125, 214, 17, 69, 85, 123, 102, 191, 244, 248, 228, 245, 93, 200, 174]

def result() -> List<&2, U32>:
    [116, 156, 243, 150, 57, 183, 156, 93, 6, 170, 141, 91, 147, 47, 199, 248]

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
