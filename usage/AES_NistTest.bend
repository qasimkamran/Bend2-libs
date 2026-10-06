import Base
import ../libs/AES256GCM.bend as AES

def result_matches(result: Result<&2, &2, AES.Error, AES.Envelope>,
    expected: AES.Envelope) -> Bool:
    match result:
        case Fail{error}: False{}
        case Done{envelope}: String.eq(AES.encode(envelope), AES.encode(expected))

def plaintext_matches(result: Result<&2, &2, AES.Error, List<&2, U32>>,
    expected: List<&2, U32>) -> Bool:
    match result:
        case Fail{error}: False{}
        case Done{plaintext}:
            String.eq(AES.hex_bytes(plaintext), AES.hex_bytes(expected))

def check_vector(+key: AES.SecretKey, +nonce: AES.Nonce,
    +aad: List<&2, U32>, +plaintext: List<&2, U32>,
    +expected: AES.Envelope) -> Bool:
    encryption_ok = result_matches(AES.encrypt(key, nonce, aad, plaintext),
        expected)
    decryption_ok = plaintext_matches(AES.decrypt(key, aad, expected),
        plaintext)
    parsing_ok = result_matches(AES.parse(AES.encode(expected)), expected)
    Bool.and(encryption_ok, Bool.and(decryption_ok, parsing_ok))

def main() -> Bool:
    +key: AES.SecretKey = AES.SecretKey{[254, 255, 233, 146, 134, 101, 115, 28,
        109, 106, 143, 148, 103, 48, 131, 8, 254, 255, 233, 146,
        134, 101, 115, 28, 109, 106, 143, 148, 103, 48, 131, 8],
        {==}, {==}}
    +nonce: AES.Nonce = AES.Nonce{[202, 254, 186, 190, 250, 206, 219, 173,
        222, 202, 248, 136], {==}, {==}}
    +aad: List<&2, U32> = [58, 215, 123, 180, 13, 122, 54, 96, 168, 158,
        202, 243, 36, 102, 239, 151, 245, 211, 213, 133]
    +plaintext: List<&2, U32> = [217, 49, 50, 37, 248, 132, 6, 229, 165,
        89, 9, 197, 175, 245, 38, 154, 134, 167, 169, 83, 21, 52, 247,
        218, 46, 76, 48, 61, 138, 49, 138, 114, 28, 60, 12, 149, 149,
        104, 9, 83, 47, 207, 14, 36, 73, 166, 181, 37, 177, 106, 237,
        245, 170, 13, 230, 87, 186, 99, 123, 57]
    +expected: AES.Envelope = AES.Envelope{nonce,
        [82, 45, 193, 240, 153, 86, 125, 7, 244, 127, 55, 163, 42, 132,
         66, 125, 100, 58, 140, 220, 191, 229, 192, 201, 117, 152, 162,
         189, 37, 85, 209, 170, 140, 176, 142, 72, 89, 13, 187, 61, 167,
         176, 139, 16, 86, 130, 136, 56, 197, 246, 30, 99, 147, 186, 122,
         10, 188, 201, 246, 98],
        AES.Tag{[224, 151, 25, 95, 69, 50, 218, 137, 95, 185, 23, 165,
            165, 92, 106, 160], {==}, {==}}, {==}}
    empty_expected: AES.Envelope = AES.Envelope{nonce, [],
        AES.Tag{[253, 44, 170, 22, 165, 131, 46, 118, 170, 19, 44, 20,
            83, 238, 218, 126], {==}, {==}}, {==}}
    +multiblock_plaintext = List.append(&2, U32, plaintext,
        [26, 175, 210, 85])
    +multiblock_ciphertext = List.append(&2, U32, AES.ciphertext(expected),
        [137, 128, 21, 173])
    +full_aad: List<&2, U32> = [58, 215, 123, 180, 13, 122, 54, 96, 168,
        158, 202, 243, 36, 102, 239, 151, 245, 211, 213, 133, 3, 185, 105,
        157, 231, 133, 137, 90, 150, 253, 186, 175, 67, 177, 205, 127,
        89, 142, 206, 35, 136, 27, 0, 227, 237, 3, 6, 136, 123, 12, 120,
        94, 39, 232, 173, 63, 130, 35, 32, 113, 4, 114, 93, 212]
    multiblock_expected: AES.Envelope = AES.Envelope{nonce,
        multiblock_ciphertext,
        AES.Tag{[176, 148, 218, 197, 217, 52, 113, 189, 236, 26, 80, 34,
            112, 227, 204, 108], {==}, {==}}, {==}}
    aad_only_expected: AES.Envelope = AES.Envelope{nonce, [],
        AES.Tag{[222, 52, 182, 220, 212, 206, 226, 253, 190, 195, 206,
            160, 26, 241, 238, 68], {==}, {==}}, {==}}
    aad_multiblock_expected: AES.Envelope = AES.Envelope{nonce,
        multiblock_ciphertext,
        AES.Tag{[192, 109, 118, 243, 25, 48, 254, 243, 122, 202, 226, 62,
            212, 101, 174, 98], {==}, {==}}, {==}}
    empty_ok = check_vector(key, nonce, [], [], empty_expected)
    multiblock_ok = check_vector(key, nonce, [], multiblock_plaintext,
        multiblock_expected)
    aad_only_ok = check_vector(key, nonce, full_aad, [], aad_only_expected)
    aad_multiblock_ok = check_vector(key, nonce, full_aad,
        multiblock_plaintext, aad_multiblock_expected)
    partial_ok = check_vector(key, nonce, aad, plaintext, expected)
    Bool.and(empty_ok, Bool.and(multiblock_ok, Bool.and(aad_only_ok,
        Bool.and(aad_multiblock_ok, partial_ok))))
