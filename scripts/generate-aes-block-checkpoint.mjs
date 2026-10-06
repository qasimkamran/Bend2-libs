import fs from "node:fs";
import { pathToFileURL } from "node:url";

// Runtime output supplies candidate intermediate values only. Every generated
// equality must pass the independent proof kernel before it is evidence.
const [modulePath, outputPath, kind = "h"] = process.argv.slice(2);
if (!modulePath || !outputPath || !/^(h|j0|ctr[2-5])$/.test(kind)) {
  throw new Error("Usage: node scripts/generate-aes-block-checkpoint.mjs <core.mjs> <proof-file> [h|j0|ctr2..ctr5]");
}
const { default: C } = await import(pathToFileURL(modulePath).href);
const list = xs => xs.reduceRight((tail, head) => ({ $: "Con", head, tail }), { $: "Nil" });
const flat = xs => xs.$ === "Nil" ? [] : [xs.head, ...flat(xs.tail)];
const key = [254,255,233,146,134,101,115,28,109,106,143,148,103,48,131,8,254,255,233,146,134,101,115,28,109,106,143,148,103,48,131,8];
const nonce = [202,254,186,190,250,206,219,173,222,202,248,136];
const block = kind === "h" ? Array(16).fill(0) : [...nonce, 0, 0, 0, kind === "j0" ? 1 : Number(kind.slice(3))];
const words = C.aes256_expand(list(key));
let state = C.aes_add_key(list(block), words, 0n);
const states = [flat(state)];
for (let round = 1; round <= 13; round++) {
  state = C.aes_middle_round(state, words, BigInt(round));
  states.push(flat(state));
}
const result = flat(C.aes_final_round(state, words));
let text = "import Base\nimport ../libs/AES256GCMCore.bend as Core\nimport ./AES_NistKeyScheduleProof.bend as Key\n\n";
text += `# Candidate NIST ${kind} block stages. Only kernel acceptance certifies them.\n`;
const constant = (name, bytes) => `\ndef ${name}() -> List<&2, U32>:\n    [${bytes.join(", ")}]\n`;
text += constant("block", block);
states.forEach((bytes, round) => { text += constant(`state_${round}`, bytes); });
text += constant("result", result);
const lemma = (name, expression, expected) => `\ndef ${name}() ->\n    {${expression} == ${expected} : List<&2, U32>}:\n    {==}\n`;
text += lemma("initial_matches", "Core.aes_add_key(block(), Key.words_60(), 0n)", "state_0()");
for (let round = 1; round <= 13; round++) {
  text += lemma(`round_${round}_matches`, `Core.aes_middle_round(state_${round - 1}(), Key.words_60(), ${round}n)`, `state_${round}()`);
}
text += lemma("final_matches", "Core.aes_final_round(state_13(), Key.words_60())", "result()");
fs.writeFileSync(outputPath, text);
console.log(`Generated candidate ${kind} stages in ${outputPath}; independent verification required.`);
