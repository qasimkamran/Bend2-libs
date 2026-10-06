import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key

# Candidate NIST ctr2 block stages. Only kernel acceptance certifies them.

def block() -> List<&2, U32>:
    [202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136, 0, 0, 0, 2]

def state_0() -> List<&2, U32>:
    [52, 1, 83, 44, 124, 171, 168, 177, 179, 160, 119, 28, 103, 48, 131, 10]

def state_1() -> List<&2, U32>:
    [250, 64, 203, 227, 0, 240, 211, 194, 158, 235, 100, 65, 172, 140, 90, 1]

def state_2() -> List<&2, U32>:
    [17, 132, 122, 87, 52, 20, 116, 219, 144, 219, 27, 179, 176, 134, 108, 77]

def state_3() -> List<&2, U32>:
    [77, 234, 206, 15, 102, 49, 82, 113, 143, 165, 106, 197, 76, 40, 130, 191]

def state_4() -> List<&2, U32>:
    [180, 92, 89, 235, 69, 46, 66, 167, 206, 112, 90, 227, 77, 248, 23, 168]

def state_5() -> List<&2, U32>:
    [212, 208, 25, 253, 65, 225, 197, 189, 206, 93, 179, 65, 46, 237, 96, 21]

def state_6() -> List<&2, U32>:
    [148, 83, 72, 53, 34, 104, 138, 107, 111, 62, 15, 166, 207, 195, 44, 206]

def state_7() -> List<&2, U32>:
    [33, 77, 219, 136, 55, 210, 149, 237, 163, 8, 68, 35, 222, 103, 178, 115]

def state_8() -> List<&2, U32>:
    [228, 94, 229, 33, 182, 91, 128, 118, 101, 160, 230, 138, 25, 198, 155, 246]

def state_9() -> List<&2, U32>:
    [128, 124, 126, 120, 187, 195, 130, 128, 254, 148, 231, 207, 13, 62, 53, 38]

def state_10() -> List<&2, U32>:
    [144, 69, 247, 76, 185, 11, 22, 234, 173, 129, 113, 12, 62, 144, 246, 32]

def state_11() -> List<&2, U32>:
    [239, 178, 116, 130, 96, 251, 29, 126, 143, 210, 240, 36, 96, 137, 182, 182]

def state_12() -> List<&2, U32>:
    [38, 208, 241, 208, 72, 8, 10, 27, 44, 150, 234, 234, 11, 73, 115, 109]

def state_13() -> List<&2, U32>:
    [121, 241, 104, 139, 36, 1, 17, 215, 132, 122, 248, 15, 23, 31, 251, 137]

def result() -> List<&2, U32>:
    [139, 28, 243, 213, 97, 210, 123, 226, 81, 38, 62, 102, 133, 113, 100, 231]

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
