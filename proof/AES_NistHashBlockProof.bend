import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key

# Candidate NIST h block stages. Only kernel acceptance certifies them.

def block() -> List<&2, U32>:
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

def state_0() -> List<&2, U32>:
    [254, 255, 233, 146, 134, 101, 115, 28, 109, 106, 143, 148, 103, 48, 131, 8]

def state_1() -> List<&2, U32>:
    [7, 123, 169, 26, 171, 69, 39, 160, 155, 224, 52, 233, 225, 49, 115, 65]

def state_2() -> List<&2, U32>:
    [67, 161, 220, 40, 172, 229, 209, 156, 89, 19, 112, 108, 45, 199, 222, 85]

def state_3() -> List<&2, U32>:
    [226, 50, 179, 95, 26, 147, 52, 166, 100, 146, 82, 51, 20, 31, 212, 69]

def state_4() -> List<&2, U32>:
    [11, 113, 151, 179, 69, 121, 252, 116, 200, 5, 219, 180, 122, 53, 255, 176]

def state_5() -> List<&2, U32>:
    [51, 79, 89, 198, 109, 32, 191, 114, 231, 128, 200, 247, 124, 62, 44, 8]

def state_6() -> List<&2, U32>:
    [164, 187, 38, 171, 158, 214, 214, 74, 70, 239, 135, 11, 207, 19, 152, 58]

def state_7() -> List<&2, U32>:
    [83, 243, 220, 241, 104, 61, 9, 247, 165, 1, 84, 145, 80, 229, 175, 226]

def state_8() -> List<&2, U32>:
    [69, 43, 40, 150, 236, 171, 32, 196, 155, 104, 143, 135, 32, 149, 159, 180]

def state_9() -> List<&2, U32>:
    [81, 30, 137, 82, 246, 53, 149, 171, 60, 226, 141, 31, 56, 243, 176, 130]

def state_10() -> List<&2, U32>:
    [86, 150, 237, 202, 234, 227, 57, 161, 44, 231, 220, 82, 80, 133, 232, 132]

def state_11() -> List<&2, U32>:
    [213, 144, 246, 62, 238, 44, 26, 237, 214, 49, 93, 168, 11, 142, 26, 194]

def state_12() -> List<&2, U32>:
    [172, 192, 117, 199, 120, 154, 187, 207, 146, 185, 155, 71, 237, 226, 212, 217]

def state_13() -> List<&2, U32>:
    [172, 59, 160, 40, 195, 156, 109, 136, 31, 120, 114, 152, 4, 69, 39, 2]

def result() -> List<&2, U32>:
    [172, 190, 242, 5, 121, 180, 184, 235, 206, 136, 155, 172, 135, 50, 218, 215]

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
