import assert from "node:assert/strict";
import { createCipheriv, createDecipheriv, createHash } from "node:crypto";
import { pathToFileURL } from "node:url";

// Run against the actual JavaScript emitted by Bend, not a second AES port.
const modulePath = process.argv[2];
assert(modulePath, "Pass the compiled AES256GCM.mjs path");
const { default: AES } = await import(pathToFileURL(modulePath).href);

function list(bytes) {
  let result = { $: "Nil" };
  for (let i = bytes.length - 1; i >= 0; i--) {
    result = { $: "Con", head: bytes[i], tail: result };
  }
  return result;
}

function bytes(value) {
  const result = [];
  for (; value.$ === "Con"; value = value.tail) result.push(value.head);
  assert.equal(value.$, "Nil");
  return Buffer.from(result);
}

function done(result) {
  assert.equal(result.$, "Done", JSON.stringify(result));
  return result.value;
}

function fails(result, error) {
  assert.equal(result.$, "Fail");
  assert.equal(result.error.$, error);
}

function deterministicBytes(label, length) {
  const blocks = [];
  for (let i = 0; blocks.length * 32 < length; i++) {
    blocks.push(createHash("sha256").update(`${label}/${i}`).digest());
  }
  return Buffer.concat(blocks).subarray(0, length);
}

let cases = 0;
function checkCase(label, keyBytes, nonceBytes, aad, plaintext) {
  const key = done(AES.key(list(keyBytes)));
  const nonce = done(AES.nonce(list(nonceBytes)));
  const envelope = done(AES.encrypt(key, nonce, list(aad), list(plaintext)));
  const cipher = createCipheriv("aes-256-gcm", keyBytes, nonceBytes);
  cipher.setAAD(aad);
  const expectedCiphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const expectedTag = cipher.getAuthTag();
  const ciphertext = bytes(AES.ciphertext(envelope));
  const tag = bytes(AES.tag_bytes(AES.envelope_tag(envelope)));
  assert.deepEqual(ciphertext, expectedCiphertext, `${label}: ciphertext`);
  assert.deepEqual(tag, expectedTag, `${label}: tag`);
  assert.deepEqual(bytes(done(AES.decrypt(key, list(aad), envelope))), plaintext,
    `${label}: decrypt`);

  const encoded = AES.encode(envelope);
  assert.equal(encoded, `v1.${nonceBytes.toString("hex")}.${expectedTag.toString("hex")}.${expectedCiphertext.toString("hex")}`);
  const parsed = done(AES.parse(encoded));
  assert.equal(AES.encode(parsed), encoded);
  assert.deepEqual(bytes(done(AES.decrypt(key, list(aad), parsed))), plaintext);

  const decipher = createDecipheriv("aes-256-gcm", keyBytes, nonceBytes);
  decipher.setAAD(aad);
  decipher.setAuthTag(tag);
  assert.deepEqual(Buffer.concat([decipher.update(ciphertext), decipher.final()]), plaintext);

  const changedTag = Buffer.from(tag);
  changedTag[0] ^= 1;
  const changed = done(AES.parse(`v1.${nonceBytes.toString("hex")}.${changedTag.toString("hex")}.${ciphertext.toString("hex")}`));
  fails(AES.decrypt(key, list(aad), changed), "AuthenticationFailed");
  fails(AES.decrypt(key, list(Buffer.concat([aad, Buffer.from([1])])), parsed),
    "AuthenticationFailed");
  const changedKey = Buffer.from(keyBytes);
  changedKey[0] ^= 1;
  fails(AES.decrypt(done(AES.key(list(changedKey))), list(aad), parsed),
    "AuthenticationFailed");
  const changedNonce = Buffer.from(nonceBytes);
  changedNonce[0] ^= 1;
  const nonceChanged = done(AES.parse(`v1.${changedNonce.toString("hex")}.${tag.toString("hex")}.${ciphertext.toString("hex")}`));
  fails(AES.decrypt(key, list(aad), nonceChanged), "AuthenticationFailed");
  const changedCiphertext = ciphertext.length === 0 ? Buffer.from([1]) : Buffer.from(ciphertext);
  changedCiphertext[0] ^= 1;
  const ciphertextChanged = done(AES.parse(`v1.${nonceBytes.toString("hex")}.${tag.toString("hex")}.${changedCiphertext.toString("hex")}`));
  fails(AES.decrypt(key, list(aad), ciphertextChanged), "AuthenticationFailed");
  const lastByteChanged = Buffer.from(tag);
  lastByteChanged[15] ^= 1;
  const lastTagByteChanged = done(AES.parse(`v1.${nonceBytes.toString("hex")}.${lastByteChanged.toString("hex")}.${ciphertext.toString("hex")}`));
  fails(AES.decrypt(key, list(aad), lastTagByteChanged), "AuthenticationFailed");
  fails(AES.encrypt(key, nonce, list([256]), list(plaintext)), "InvalidBytes");
  fails(AES.encrypt(key, nonce, list(aad), list([256])), "InvalidBytes");
  fails(AES.decrypt(key, list([256]), parsed), "InvalidBytes");
  cases++;
}

const lengths = [0, 1, 15, 16, 17, 31, 32, 33, 60, 64, 65, 255, 1024];
const aadLengths = [0, 1, 15, 16, 17, 31, 32, 65];
for (const length of lengths) {
  for (const aadLength of aadLengths) {
    const label = `plaintext=${length},aad=${aadLength}`;
    checkCase(label, deterministicBytes(`${label}/key`, 32),
      deterministicBytes(`${label}/nonce`, 12),
      deterministicBytes(`${label}/aad`, aadLength),
      deterministicBytes(`${label}/plaintext`, length));
  }
}

fails(AES.key(list(new Uint8Array(31))), "InvalidKey");
fails(AES.key(list([...new Uint8Array(31), 256])), "InvalidKey");
fails(AES.nonce(list(new Uint8Array(11))), "InvalidNonce");
fails(AES.nonce(list([...new Uint8Array(11), 256])), "InvalidNonce");
for (const text of ["", "v2." + "00".repeat(12) + "." + "00".repeat(16) + ".",
  "v1." + "AA".repeat(12) + "." + "00".repeat(16) + ".",
  "v1." + "00".repeat(12) + "." + "00".repeat(16) + ".0",
  "v1." + "00".repeat(12) + "." + "00".repeat(16) + ".gg"]) {
  fails(AES.parse(text), "InvalidEnvelope");
}
console.log(`AES interoperability passed: ${cases} cases against Node/OpenSSL`);
