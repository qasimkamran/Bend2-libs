import Base
import ../libs/AES256GCMCore.bend as Core

def compare_sbox(fuel: Nat, +value: U32) -> Bool:
    match fuel:
        case 0n: True{}
        case 1n+rest:
            Bool.and(U32.is_eq(Core.aes_sbox_algebraic(value), Core.aes_sbox(value)),
                compare_sbox(rest, U32.add(value, 1)))

def main() -> Bool:
    compare_sbox(256n, 0)
