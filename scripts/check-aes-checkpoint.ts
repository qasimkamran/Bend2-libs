import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import { pathToFileURL } from "node:url";
import { proofScope, checkWithProgress } from "./aes-proof-scope.ts";

const [sourceDir, ...requested] = process.argv.slice(2);
const roots = requested.length === 1 && requested[0] === "all"
  ? [...fs.readFileSync("LAWS.bend", "utf8").matchAll(/^law (aes256gcm_nist_\w+):/gm)].map(match => `LAWS.${match[1]}`)
  : requested;
if (requested.length === 1 && requested[0] === "all" && roots.length !== 16) throw new Error(`Expected 16 NIST laws, found ${roots.length}`);
if (!sourceDir || !roots.length || !process.env.BENDTT) throw new Error("Usage: BENDTT=<kernel> bun scripts/check-aes-checkpoint.ts <bend2-source> <proof-root>...");
const started = Date.now();
const digest = (file: string) => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
const kernel = process.env.BENDTT!;
const kernelSource = path.join(path.dirname(kernel), "bendtt.lean");
const fuel = fs.existsSync(kernelSource) ? fs.readFileSync(kernelSource, "utf8").match(/def FUEL : Nat := (\d+)/)?.[1] : "unknown";
console.log(`Kernel FUEL=${fuel}; executable SHA256=${digest(kernel)}`);
const B = await import(pathToFileURL(path.resolve(sourceDir, "bend.ts")).href);
const S = await import(pathToFileURL(path.resolve(sourceDir, "safe.ts")).href);
const book = B.book_nil();
try {
  await B.book_load(book, "PROOF.bend", "", new Map());
  proofScope(B, book, roots);
  console.log("Starting Bend typecheck.");
  checkWithProgress(B, book);
  if (book.hols) throw new Error(`${book.hols} open proof holes`);
  for (const root of roots) {
    const key = book.order.find((key: string) => B.name_key(key) === root);
    if (!key || book.tlds[key].e === undefined) throw new Error(`Unchecked proof root: ${root}`);
  }
} catch (error) {
  console.error((error as any).$ === "Err" ? B.err_show(error) : String(error));
  process.exit(1);
}
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "aes-checkpoint-"));
const input = path.join(dir, "proof.bendtt");
const errors = S.safe_emit(book, input);
if (errors.length) throw new Error(errors.join("\n"));
// BendTT checks every opaque body before permitting subsequent definitions
// to use its checked type, avoiding repeated expansion of checkpoint proofs.
const text = fs.readFileSync(input, "utf8");
let boundaries = 0;
fs.writeFileSync(input, text.replace(/^([^\s:]+) :/gm, (line, name) => {
  const leaf = name.slice(name.lastIndexOf(".") + 1);
  if (!/^(checkpoint_\w+|suffix_\d+|chunk_\d+|rounds_0_to_6|rounds_6_to_12|full_rounds_match|full_nist_rounds_match|final_nist_block_match|expanded_block_matches)$/.test(leaf)) return line;
  boundaries++;
  return `opaque ${line}`;
}));
console.log(`Checking ${boundaries} opaque checkpoint boundaries, including every body.`);
console.log(`Bend typecheck passed (${((Date.now() - started) / 1000).toFixed(1)}s). Starting independent kernel: ${input}`);
const result = spawnSync(kernel, [input], { encoding: "utf8", maxBuffer: 8 * 1024 * 1024, env: { ...process.env, LEAN_STACK_SIZE_KB: "4194304" } });
console.log(result.stdout || result.stderr || String(result.error ?? "No kernel diagnostic"));
if (result.status !== 0 || result.stdout.trim() !== "ALL PROOFS CHECK") {
  process.exitCode = 1; console.error(`Retained diagnostic: ${input}`);
} else {
  console.log(`PASS ${roots.join(", ")} (${((Date.now() - started) / 1000).toFixed(1)}s)`);
  const evidence = { checkedAt: new Date().toISOString(), roots, fuel,
    kernelExecutableSHA256: digest(kernel), kernelSourceSHA256: fs.existsSync(kernelSource) ? digest(kernelSource) : null,
    bendSourceSHA256: digest(path.resolve(sourceDir, "bend.ts")), serializedProofSHA256: digest(input),
    lawSourceSHA256: digest("LAWS.bend"), proofSourceSHA256: digest("PROOF.bend") };
  fs.writeFileSync(path.join(dir, "verification.json"), JSON.stringify(evidence, null, 2) + "\n");
  console.log(`Verification evidence: ${path.join(dir, "verification.json")}`);
}
