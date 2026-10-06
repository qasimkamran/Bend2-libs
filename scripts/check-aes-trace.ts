import assert from "node:assert/strict";
import path from "node:path";
import fs from "node:fs";
import os from "node:os";
import crypto from "node:crypto";
import childProcess from "node:child_process";
import { pathToFileURL } from "node:url";

// Check one composition prefix with the unmodified Bend checker and kernel.
// Excluded proofs are not assumed: safe_emit includes referenced dependencies.
const [sourceDir, depthText = "0", proofFile = "proof/AES_NistBlockTraceProof.bend"] = process.argv.slice(2);
assert(sourceDir, "Usage: bun scripts/check-aes-trace.ts <bend2-source> [0..13] [proof-module]");
const depth = Number(depthText);
const composed = proofFile.includes("Compose");
assert(Number.isInteger(depth) && depth >= 0 && depth <= (composed ? 13 : 14));
const B = await import(pathToFileURL(path.resolve(sourceDir, "bend.ts")).href);
const S = await import(pathToFileURL(path.resolve(sourceDir, "safe.ts")).href);
const hash = crypto.createHash("sha256").update(fs.readFileSync(path.resolve(sourceDir, "bendtt.lean"))).digest("hex");
const cachedKernel = path.join(os.homedir(), ".bend", "bendtt", hash.slice(0, 16), "bendtt.exe");
if (process.platform === "win32" && !process.env.BENDTT && fs.existsSync(cachedKernel)) {
  process.env.BENDTT = cachedKernel;
}
const book = B.book_nil();
await B.book_load(book, proofFile, "", new Map());
const name = (key: string) => B.name_key?.(key) ?? key;
book.order = book.order.filter((key: string) => {
  const full = name(key);
  const leaf = full.slice(full.lastIndexOf(".") + 1);
  if (full.startsWith("libs/AES256GCM.") || full.startsWith("LAWS.")) {
    return false;
  }
  if (full.includes("AES_NistKeyScheduleProof.")) {
    return leaf === "words_60";
  }
  if (full.includes("AES_NistBlockProof.")) {
    const round = /^round_(\d+)_matches$/.exec(leaf);
    if (round) return composed ? Number(round[1]) <= depth : Number(round[1]) >= 14 - depth;
    if (leaf === "initial_matches") return composed ? depth === 13 : depth === 14;
  }
  if (full.includes("AES_NistBlockTraceProof.") || full.includes("AES_NistBlockComposeProof.") || !full.includes(".")) {
    const suffix = /^suffix_(\d+)$/.exec(leaf);
    if (suffix) return composed ? Number(suffix[1]) <= depth : Number(suffix[1]) >= 14 - depth;
    if (leaf === "expanded_block_matches") return composed ? depth === 13 : depth === 14;
    if (leaf === "full_rounds_match") return composed && depth === 13;
  }
  return true;
});
console.log(`Selected ${book.order.length} definitions for Bend validation.`);
const rawOrder = book.order;
const coreStart = rawOrder.findIndex((key: string) => name(key).includes("AES256GCMCore.aes_add_key"));
assert(coreStart > 0, "Expected the core AES import to follow Base definitions");
console.log(`Treating ${coreStart} standard Base definitions as the imported prelude.`);
let progressBucket = 0;
let lastOrderIndex = -1;
book.order = new Proxy(rawOrder, {
  get(target, property, receiver) {
    if (typeof property === "string" && /^\d+$/.test(property)) {
      const current = Number(property);
      if (lastOrderIndex > rawOrder.length - 10 && current === 0) {
        progressBucket = 0;
        console.log("Starting definition typechecks.");
      }
      lastOrderIndex = current;
      const bucket = Math.floor(current / 100);
      if (bucket > progressBucket) {
        progressBucket = bucket;
        console.log(`Bend validation reached definition ${bucket * 100}/${rawOrder.length}.`);
      }
    }
    return Reflect.get(target, property, receiver);
  },
});
console.log(`Checking NIST block composition depth ${depth}.`);
B.book_valid(book);
assert(book.hols === 0, "Checkpoint must contain no proof holes");
console.log("Bend typecheck passed; checking independent kernel.");
const output = path.resolve("C:/Users/qasim/AppData/Local/Temp/aes-compose-check.bendtt");
const scopeErrors = S.safe_emit(book, output);
assert.equal(scopeErrors.length, 0, scopeErrors.join("\n"));
if (composed) {
  // Check each checkpoint body once, then make the verified boundary opaque
  // to downstream proof checks, as BendTT's serialized proof format permits.
  const serialized = fs.readFileSync(output, "utf8");
  const checkpointNames = /^(chunk_\d+|checkpoint_\d+|rounds_0_to_6|rounds_6_to_12|rounds_6_to_13|full_rounds_match|full_nist_rounds_match|final_nist_block_match|expanded_block_matches) :/gm;
  fs.writeFileSync(output, serialized.replace(checkpointNames, "opaque $1 :"));
}
if (composed || !S.safe_check(book)) {
  const result = childProcess.spawnSync(process.env.BENDTT!, [output], { encoding: "utf8" });
  console.error(result.stdout || result.stderr || "Independent kernel returned no diagnostic.");
  process.exitCode = 1;
} else {
  fs.rmSync(output, { force: true });
  console.log(`NIST block composition depth ${depth} passed independent kernel.`);
}
