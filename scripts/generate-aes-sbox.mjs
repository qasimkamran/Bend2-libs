import fs from "node:fs";

const xtime = value => ((value << 1) ^ ((value & 0x80) ? 0x11b : 0)) & 0xff;
const multiply = (left, right) => {
  let product = 0;
  for (let i = 0; i < 8; i++) {
    if (right & 1) product ^= left;
    left = xtime(left);
    right >>>= 1;
  }
  return product;
};
const power = (value, exponent) => {
  let result = 1;
  while (exponent > 0) {
    if (exponent & 1) result = multiply(result, value);
    value = multiply(value, value);
    exponent >>>= 1;
  }
  return result;
};
const rotate = (value, amount) => ((value << amount) | (value >>> (8 - amount))) & 0xff;
const sbox = value => {
  const inverse = value === 0 ? 0 : power(value, 254);
  return (inverse ^ rotate(inverse, 1) ^ rotate(inverse, 2) ^ rotate(inverse, 3) ^ rotate(inverse, 4) ^ 0x63) & 0xff;
};
const lines = [
  "import Base",
  "",
  "# The AES byte substitution table, generated from the field inverse and affine map.",
  "# A byte selects one literal branch so formal NIST checkpoints avoid expanding",
  "# the exponentiation network for every substituted byte.",
  "def lookup(value: U32) -> U32:",
  "    byte = U32.and(255, value)",
  "    index = U32.to_nat(byte)",
  "    match index:",
];
for (let row = 0; row < 16; row++) {
  for (let col = 0; col < 16; col++) {
    const input = row * 16 + col;
    lines.push(`        case ${input}n: ${sbox(input)}`);
  }
}
lines.push("        case _: 0", "");
const out = process.argv[2] ?? "libs/AES256SBox.bend";
fs.writeFileSync(out, lines.join("\n"));
if (sbox(0) !== 0x63 || sbox(1) !== 0x7c || sbox(0x53) !== 0xed) {
  throw new Error("Generated AES S-box failed the FIPS sample values");
}
console.log(`Generated 256 standard AES S-box entries in ${out}.`);
