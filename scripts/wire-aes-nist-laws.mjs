import fs from "node:fs";

const laws = fs.readFileSync("LAWS.bend", "utf8");
let proof = fs.readFileSync("PROOF.bend", "utf8");
const importLine = "import ./proof/AES_NistInputProof.bend as AESNistInputProof";
if (!proof.includes(importLine)) proof = proof.replace("import Base", `import Base\n${importLine}`);
const qualify = text => text.replace(/(?<![\w.])(aes256gcm_nist_\w+)\(/g, "L.$1(");
function argumentsOf(text, name) {
  let start = text.indexOf(`AES.${name}(`) + name.length + 5;
  if (start < name.length + 5) throw new Error(`Missing ${name} call`);
  const args = [];
  let depth = 0, from = start;
  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if ("([{<".includes(ch)) depth++;
    if (")]} >".replaceAll(" ", "").includes(ch)) {
      if (ch === ")" && depth === 0) { args.push(qualify(text.slice(from, i).trim())); return args; }
      depth--;
    }
    if (ch === "," && depth === 0) { args.push(qualify(text.slice(from, i).trim())); from = i + 1; }
  }
  throw new Error(`Unclosed ${name} call`);
}
function body(name, lines) {
  const pattern = new RegExp(`def L\\.${name}\\(\\):\\r?\\n(?:    [^\\r\\n]*\\r?\\n)+`);
  if (!pattern.test(proof)) throw new Error(`Missing proof definition: ${name}`);
  proof = proof.replace(pattern, `def L.${name}():\n${lines.map(line => `    ${line}`).join("\n")}\n`);
}
for (const vector of ["empty", "multiblock", "aad_only", "aad_and_multiblock", "partial_block"]) {
  for (const operation of ["encrypt", "decrypt"]) {
    const name = `aes256gcm_nist_${vector}_${operation}`;
    const statement = laws.split(`law ${name}:`)[1]?.split(/\n(?:law|def) /)[0];
    if (!statement) throw new Error(`Missing law: ${name}`);
    const args = argumentsOf(statement, operation);
    if (operation === "encrypt") {
      const [key, nonce, aad, plaintext] = args;
      body(name, [
        `AESNistInputProof.encrypt_inputs(${key}, ${nonce},`,
        `    ${aad}, AESNistVectorProof.${vector}_aad(),`,
        `    ${plaintext}, AESNistVectorProof.${vector}_plaintext(),`,
        `    L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_${vector}()}),`,
        `    {==}, {==}, AESNistVectorProof.${vector}_encrypt())`,
      ]);
    } else {
      const [key, aad, envelope] = args;
      body(name, [
        `AESNistInputProof.decrypt_inputs(${key}, ${key},`,
        `    ${aad}, AESNistVectorProof.${vector}_aad(),`,
        `    ${envelope}, ${envelope}, Done{AESNistVectorProof.${vector}_plaintext()},`,
        `    {==}, {==}, {==}, AESNistVectorProof.${vector}_decrypt())`,
      ]);
    }
  }
}
for (const changed of ["aad", "key", "nonce", "ciphertext"]) {
  const name = `aes256gcm_nist_rejects_changed_${changed}`;
  const statement = laws.split(`law ${name}:`)[1]?.split(/\n(?:law|def) /)[0];
  const [key, aad, envelope] = argumentsOf(statement, "decrypt");
  body(name, [
    `AESNistInputProof.decrypt_inputs(${key}, ${changed === "key" ? "AESNistTamperVectorProof.zero_key()" : "L.aes256gcm_nist_key()"},`,
    `    ${aad}, AESNistTamperVectorProof.changed_${changed}_aad(),`,
    `    ${envelope}, AESNistTamperVectorProof.changed_${changed}_envelope(),`,
    `    Fail{AES.AuthenticationFailed{}}, {==}, {==}, {==},`,
    `    AESNistTamperVectorProof.rejects_changed_${changed}())`,
  ]);
}
fs.writeFileSync("PROOF.bend", proof);
console.log("Wired 14 NIST laws through explicit fixture-input equality transports.");
