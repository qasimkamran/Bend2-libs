import Base
import ../libs/AES256GCMCore.bend as Core
import ./AES_NistKeyScheduleProof.bend as Key

# Concrete stages of the NIST J0 block, checked by the independent kernel.
def block() -> List<&2, U32>:
    [202, 254, 186, 190, 250, 206, 219, 173, 222, 202, 248, 136, 0, 0, 0, 1]

def state_0() -> List<&2, U32>:
    [52, 1, 83, 44, 124, 171, 168, 177, 179, 160, 119, 28, 103, 48, 131, 9]

def state_1() -> List<&2, U32>:
    [156, 38, 97, 47, 0, 240, 211, 194, 158, 235, 100, 65, 172, 140, 90, 1]

def state_2() -> List<&2, U32>:
    [236, 119, 137, 89, 48, 16, 120, 211, 96, 208, 224, 67, 169, 97, 146, 179]

def state_3() -> List<&2, U32>:
    [69, 154, 167, 162, 145, 21, 18, 184, 176, 0, 241, 125, 152, 86, 217, 137]

def state_4() -> List<&2, U32>:
    [0, 167, 253, 31, 255, 112, 13, 177, 113, 88, 180, 147, 66, 240, 37, 93]

def state_5() -> List<&2, U32>:
    [14, 37, 120, 128, 26, 140, 120, 147, 217, 218, 212, 88, 167, 213, 24, 51]

def state_6() -> List<&2, U32>:
    [73, 102, 200, 157, 169, 97, 250, 71, 60, 50, 198, 22, 55, 247, 26, 229]

def state_7() -> List<&2, U32>:
    [102, 20, 1, 111, 4, 13, 186, 228, 138, 205, 84, 191, 183, 70, 127, 8]

def state_8() -> List<&2, U32>:
    [65, 166, 229, 84, 99, 106, 0, 126, 14, 25, 152, 116, 177, 23, 227, 170]

def state_9() -> List<&2, U32>:
    [36, 77, 13, 105, 78, 204, 117, 212, 46, 49, 3, 55, 243, 223, 61, 19]

def state_10() -> List<&2, U32>:
    [183, 212, 41, 223, 232, 146, 128, 96, 119, 186, 11, 144, 1, 46, 232, 8]

def state_11() -> List<&2, U32>:
    [197, 183, 64, 59, 156, 26, 67, 102, 38, 11, 185, 182, 153, 16, 232, 116]

def state_12() -> List<&2, U32>:
    [62, 65, 245, 143, 201, 180, 35, 187, 211, 190, 117, 16, 8, 241, 60, 255]

def state_13() -> List<&2, U32>:
    [31, 209, 218, 183, 4, 93, 109, 1, 29, 206, 52, 97, 35, 119, 70, 140]

def result() -> List<&2, U32>:
    [253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20, 83, 238, 218, 126]

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
