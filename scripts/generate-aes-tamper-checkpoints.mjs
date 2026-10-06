import fs from "node:fs";
import { pathToFileURL } from "node:url";

const [corePath] = process.argv.slice(2);
if (!corePath) throw new Error("Usage: node scripts/generate-aes-tamper-checkpoints.mjs <core.mjs>");
const { default: C } = await import(pathToFileURL(corePath).href);
const list = xs => xs.reduceRight((tail, head) => ({ $: "Con", head, tail }), { $: "Nil" });
const flat = xs => xs.$ === "Nil" ? [] : [xs.head, ...flat(xs.tail)];
const key = [254,255,233,146,134,101,115,28,109,106,143,148,103,48,131,8,254,255,233,146,134,101,115,28,109,106,143,148,103,48,131,8];
const nonce = [202,254,186,190,250,206,219,173,222,202,248,136];
const zeroKey = Array(32).fill(0);
const zeroWords = flat(C.aes256_expand(list(zeroKey)));
const rows = ["import Base", "import ../LAWS.bend as L", "import ../libs/AES256GCM.bend as AES",
  "import ../libs/AES256GCMCore.bend as Core", "import ./AES_NistKeyScheduleProof.bend as Key",
  "import ./AES_NistObservationProof.bend as Obs", "import ./AES_NistVectorProof.bend as V", ""];
const constant = (name, bytes) => rows.push(`def ${name}() -> List<&2, U32>:`, `    [${bytes.join(", ")}]`, "");
constant("zero_words", zeroWords);
rows.push("def zero_key() -> AES.SecretKey:", `    AES.SecretKey{[${zeroKey.join(", ")}], {==}, {==}}`, "",
  "def checkpoint_zero_key() ->", "    {Core.aes256_expand(AES.secret_key_bytes(zero_key())) == zero_words() : List<&2, U32>}:", "    {==}", "");
for (const name of ["aad", "key", "nonce", "ciphertext"]) {
  const aad = name === "aad" ? [1] : [];
  const actualNonce = name === "nonce" ? Array(12).fill(0) : nonce;
  const bytes = name === "ciphertext" ? [1] : [];
  const actualKey = name === "key" ? zeroKey : key;
  const expanded = name === "key" ? "zero_words()" : "Key.words_60()";
  const publicKey = name === "key" ? "zero_key()" : "L.aes256gcm_nist_key()";
  const keyProof = name === "key" ? "checkpoint_zero_key()" : "V.checkpoint_nist_schedule()";
  const tag = flat(C.gcm_tag_expanded(C.aes256_expand(list(actualKey)), list(actualNonce), list(aad), list(bytes)));
  constant(`changed_${name}_aad`, aad);
  constant(`changed_${name}_computed_tag`, tag);
  rows.push(`def changed_${name}_envelope() -> AES.Envelope:`,
    `    AES.Envelope{AES.Nonce{[${actualNonce.join(", ")}], {==}, {==}}, [${bytes.join(", ")}],`,
    "        AES.Tag{V.empty_tag(), {==}, {==}}, {==}}", "",
    `def checkpoint_changed_${name}_tag() ->`,
    `    {Obs.envelope_tag_computed(${expanded}, changed_${name}_aad(), changed_${name}_envelope()) == changed_${name}_computed_tag() : List<&2, U32>}:`,
    "    {==}", "",
    `def checkpoint_changed_${name}_rejected() ->`,
    `    {Obs.decrypt_expanded(${expanded}, changed_${name}_aad(), changed_${name}_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:`,
    `    Obs.finish_auth(${expanded}, changed_${name}_aad(), changed_${name}_envelope(),`,
    `        changed_${name}_computed_tag(), False{}, Fail{AES.AuthenticationFailed{}},`,
    `        checkpoint_changed_${name}_tag(), {==}, {==})`, "",
    `def rejects_changed_${name}() ->`,
    `    {AES.decrypt(${publicKey}, changed_${name}_aad(), changed_${name}_envelope()) == Fail{AES.AuthenticationFailed{}} : Result<&2, &2, AES.Error, List<&2, U32>>}:`,
    `    Obs.finish_decrypt(${publicKey}, changed_${name}_aad(), changed_${name}_envelope(),`,
    `        ${expanded}, Fail{AES.AuthenticationFailed{}}, {==}, {==}, ${keyProof}, checkpoint_changed_${name}_rejected())`, "");
}
fs.writeFileSync("proof/AES_NistTamperVectorProof.bend", rows.join("\n"));
console.log("Generated four candidate NIST rejection checkpoint compositions; independent verification required.");
