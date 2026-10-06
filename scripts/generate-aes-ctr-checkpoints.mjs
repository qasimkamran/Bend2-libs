import fs from "node:fs";
import { execFileSync } from "node:child_process";
const [corePath] = process.argv.slice(2);
if (!corePath) throw new Error("Usage: node scripts/generate-aes-ctr-checkpoints.mjs <core.mjs>");
for (let counter = 2; counter <= 5; counter++) {
  const block = `AES_NistCtr${counter}BlockProof.bend`;
  execFileSync(process.execPath, ["scripts/generate-aes-block-checkpoint.mjs", corePath, `proof/${block}`, `ctr${counter}`]);
  execFileSync(process.execPath, ["scripts/generate-aes-round-composition.mjs", `proof/AES_NistCtr${counter}ComposeProof.bend`, block]);
}
const rows = ["import Base", "import ../libs/AES256GCMCore.bend as Core", "import ./AES_NistKeyScheduleProof.bend as Key"];
for (let c = 2; c <= 5; c++) rows.push(`import ./AES_NistCtr${c}BlockProof.bend as B${c}`, `import ./AES_NistCtr${c}ComposeProof.bend as P${c}`);
rows.push("", "def stream_step(+remaining: Nat, +fuel: Nat, +words: List<&2, U32>, +counter: List<&2, U32>, +block: List<&2, U32>,",
  "    count: {remaining == 1n+fuel : Nat}, same: {Core.aes256_encrypt_expanded(words, counter) == block : List<&2, U32>}) ->",
  "    {Core.gcm_ctr_stream_exact.go(remaining, words, counter, Nil{}) ==",
  "     Core.aes_byte_at(block, 0n) <> Core.gcm_ctr_stream_exact.go(fuel, words, Core.gcm_inc32(counter), List.tail(&2, U32, block)) : List<&2, U32>}:",
  "    Equal.trans(List<&2, U32>, Core.gcm_ctr_stream_exact.go(remaining, words, counter, Nil{}),",
  "        Core.gcm_ctr_stream_exact.go(1n+fuel, words, counter, Nil{}),",
  "        Core.aes_byte_at(block, 0n) <> Core.gcm_ctr_stream_exact.go(fuel, words, Core.gcm_inc32(counter), List.tail(&2, U32, block)),",
  "        Equal.cong(Nat, List<&2, U32>, n => Core.gcm_ctr_stream_exact.go(n, words, counter, Nil{}), remaining, 1n+fuel, count),",
  "        Equal.cong(List<&2, U32>, List<&2, U32>, value =>",
  "            Core.aes_byte_at(value, 0n) <> Core.gcm_ctr_stream_exact.go(fuel, words, Core.gcm_inc32(counter), List.tail(&2, U32, value)),",
  "            Core.aes256_encrypt_expanded(words, counter), block, same))", "");
const go = (n,c) => `Core.gcm_ctr_stream_exact.go(${n}, Key.words_60(), ${c}, Nil{})`;
const append = (a,b) => `List.append(&2, U32, ${a}, ${b})`;
for (let c = 2; c <= 5; c++) {
  const left = go("remaining", `B${c}.block()`);
  const middle = `Core.aes_byte_at(B${c}.result(), 0n) <> Core.gcm_ctr_stream_exact.go(15n+fuel, Key.words_60(), Core.gcm_inc32(B${c}.block()), List.tail(&2, U32, B${c}.result()))`;
  const after = append(`B${c}.result()`, go("fuel", `Core.gcm_inc32(B${c}.block())`));
  const right = append(`B${c}.result()`, go("fuel", "next_counter"));
  rows.push(`def checkpoint_ctr${c}_stream(+remaining: Nat, +fuel: Nat, +next_counter: List<&2, U32>,`,
    "    count: {remaining == 16n+fuel : Nat},", `    counter: {Core.gcm_inc32(B${c}.block()) == next_counter : List<&2, U32>}) ->`,
    `    {${left} == ${right} : List<&2, U32>}:`,
    `    Equal.trans(List<&2, U32>, ${left}, ${middle}, ${right},`,
    `        stream_step(remaining, 15n+fuel, Key.words_60(), B${c}.block(), B${c}.result(), count, P${c}.expanded_block_matches()),`,
    `        Equal.trans(List<&2, U32>, ${middle}, ${after}, ${right}, {==},`,
    `            Equal.cong(List<&2, U32>, List<&2, U32>, next => ${append(`B${c}.result()`,go("fuel", "next"))},`,
    `                Core.gcm_inc32(B${c}.block()), next_counter, counter)))`, "");
}
rows.push("def counter_6() -> List<&2, U32>:", "    [202,254,186,190,250,206,219,173,222,202,248,136,0,0,0,6]", "",
  "def stream_64() -> List<&2, U32>:", `    ${append("B2.result()",append("B3.result()",append("B4.result()","B5.result()")))}`, "",
  "def stream_60() -> List<&2, U32>:", `    ${append("B2.result()",append("B3.result()",append("B4.result()","List.take(&2, U32, B5.result(), 12n)")))}`, "");
const stages = [go("64n","B2.block()")];
for (let count = 1; count <= 4; count++) {
  let term = go(`${64-count*16}n`, count === 4 ? "counter_6()" : `B${2+count}.block()`);
  for (let c = count+1; c >= 2; c--) term = append(`B${c}.result()`,term);
  stages.push(term);
}
function chain(terms, proofs) {
  if (proofs.length === 1) return proofs[0];
  return `Equal.trans(List<&2, U32>, ${terms[0]}, ${terms[1]}, ${terms.at(-1)}, ${proofs[0]}, ${chain(terms.slice(1),proofs.slice(1))})`;
}
const proofs = [];
for (let c=2;c<=5;c++) {
  let context = "value";
  for (let prefix=c-1;prefix>=2;prefix--) context=append(`B${prefix}.result()`,context);
  const next=c===5?"counter_6()":`B${c+1}.block()`;
  const leaf=`checkpoint_ctr${c}_stream(${64-(c-2)*16}n, ${64-(c-1)*16}n, ${next}, {==}, {==})`;
  proofs.push(c===2?leaf:`Equal.cong(List<&2, U32>, List<&2, U32>, value => ${context}, ${go(`${64-(c-2)*16}n`,`B${c}.block()`)}, ${append(`B${c}.result()`,go(`${64-(c-1)*16}n`,next))}, ${leaf})`);
}
stages.push("stream_64()"); proofs.push("{==}");
rows.push("def checkpoint_stream_64() ->", `    {${stages[0]} == stream_64() : List<&2, U32>}:`, `    ${chain(stages,proofs)}`, "",
  "def checkpoint_ctr5_partial() ->", `    {${go("12n","B5.block()")} == List.take(&2, U32, B5.result(), 12n) : List<&2, U32>}:`,
  `    Equal.trans(List<&2, U32>, ${go("12n","B5.block()")},`,
  "        Core.aes_byte_at(B5.result(), 0n) <> Core.gcm_ctr_stream_exact.go(11n, Key.words_60(), Core.gcm_inc32(B5.block()), List.tail(&2, U32, B5.result())),",
  "        List.take(&2, U32, B5.result(), 12n), stream_step(12n, 11n, Key.words_60(), B5.block(), B5.result(), {==}, P5.expanded_block_matches()), {==})", "");
const stages60=[go("60n","B2.block()")], proofs60=[];
for(let c=2;c<=4;c++) {
  const remaining=60-(c-2)*16, fuel=remaining-16;
  let nextStage=go(`${fuel}n`,`B${c+1}.block()`);
  for(let prefix=c;prefix>=2;prefix--) nextStage=append(`B${prefix}.result()`,nextStage);
  stages60.push(nextStage);
  const leaf=`checkpoint_ctr${c}_stream(${remaining}n, ${fuel}n, B${c+1}.block(), {==}, {==})`;
  let context="value"; for(let prefix=c-1;prefix>=2;prefix--)context=append(`B${prefix}.result()`,context);
  proofs60.push(c===2?leaf:`Equal.cong(List<&2, U32>, List<&2, U32>, value => ${context}, ${go(`${remaining}n`,`B${c}.block()`)}, ${append(`B${c}.result()`,go(`${fuel}n`,`B${c+1}.block()`))}, ${leaf})`);
}
stages60.push("stream_60()");
const context=append("B2.result()",append("B3.result()",append("B4.result()","value")));
proofs60.push(`Equal.cong(List<&2, U32>, List<&2, U32>, value => ${context}, ${go("12n","B5.block()")}, List.take(&2, U32, B5.result(), 12n), checkpoint_ctr5_partial())`);
rows.push("def checkpoint_stream_60() ->", `    {${stages60[0]} == stream_60() : List<&2, U32>}:`, `    ${chain(stages60,proofs60)}`, "");
fs.writeFileSync("proof/AES_NistCtrProof.bend", rows.join("\n"));
console.log("Generated four composed AES counter blocks and 60/64-byte stream proofs; independent verification required.");
