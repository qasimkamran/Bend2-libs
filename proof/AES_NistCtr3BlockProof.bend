import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key

# Candidate NIST ctr3 block stages. Only kernel acceptance certifies them.

def block() -> List<&2, U32>:
    [202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136, 0, 0, 0, 3]

def state_0() -> List<&2, U32>:
    [52, 1, 83, 44, 124, 171, 168, 177, 179, 160, 119, 28, 103, 48, 131, 11]

def state_1() -> List<&2, U32>:
    [182, 12, 31, 123, 0, 240, 211, 194, 158, 235, 100, 65, 172, 140, 90, 1]

def state_2() -> List<&2, U32>:
    [215, 231, 25, 242, 4, 36, 36, 187, 79, 161, 190, 108, 178, 115, 155, 186]

def state_3() -> List<&2, U32>:
    [23, 241, 181, 99, 185, 200, 214, 36, 71, 141, 172, 145, 40, 191, 141, 193]

def state_4() -> List<&2, U32>:
    [0, 207, 200, 130, 161, 162, 108, 28, 252, 172, 173, 222, 204, 143, 178, 17]

def state_5() -> List<&2, U32>:
    [101, 21, 106, 116, 159, 142, 217, 177, 13, 167, 167, 134, 78, 86, 228, 82]

def state_6() -> List<&2, U32>:
    [206, 133, 37, 88, 221, 6, 250, 189, 132, 98, 205, 15, 220, 230, 116, 195]

def state_7() -> List<&2, U32>:
    [120, 83, 33, 216, 164, 114, 29, 3, 197, 22, 198, 230, 73, 56, 148, 234]

def state_8() -> List<&2, U32>:
    [197, 12, 12, 168, 34, 252, 250, 43, 209, 241, 50, 255, 97, 221, 87, 87]

def state_9() -> List<&2, U32>:
    [49, 79, 82, 36, 169, 114, 193, 140, 105, 173, 239, 129, 2, 1, 203, 253]

def state_10() -> List<&2, U32>:
    [222, 237, 251, 42, 10, 77, 20, 144, 58, 227, 224, 190, 47, 56, 133, 51]

def state_11() -> List<&2, U32>:
    [96, 246, 217, 103, 60, 88, 207, 102, 140, 71, 126, 206, 149, 212, 187, 98]

def state_12() -> List<&2, U32>:
    [12, 112, 82, 8, 51, 120, 214, 208, 79, 118, 28, 0, 232, 150, 124, 66]

def state_13() -> List<&2, U32>:
    [239, 198, 235, 39, 33, 33, 205, 200, 237, 229, 133, 164, 122, 161, 100, 33]

def result() -> List<&2, U32>:
    [226, 157, 37, 143, 170, 209, 55, 19, 91, 212, 146, 128, 175, 100, 91, 216]

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
