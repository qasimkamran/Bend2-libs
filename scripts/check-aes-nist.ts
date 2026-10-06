import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { pathToFileURL } from "node:url";
import { proofScope, checkWithProgress } from "./aes-proof-scope.ts";

// Verify selected NIST laws and their AES dependencies without running the
// unrelated JSON proof gate. This is scoped verification, never a replacement
// for the repository verdict.
const [sourceDir, selection = "canonical"] = process.argv.slice(2);
assert(sourceDir, "Usage: bun scripts/check-aes-nist.ts <bend2-source> [canonical|all|law-name]");
const B = await import(pathToFileURL(path.resolve(sourceDir, "bend.ts")).href);
const S = await import(pathToFileURL(path.resolve(sourceDir, "safe.ts")).href);
const kernelHash = crypto.createHash("sha256").update(fs.readFileSync(path.resolve(sourceDir, "bendtt.lean"))).digest("hex");
const cachedKernel = path.join(os.homedir(), ".bend", "bendtt", kernelHash.slice(0, 16), "bendtt.exe");
if (process.platform === "win32" && !process.env.BENDTT && fs.existsSync(cachedKernel)) {
  process.env.BENDTT = cachedKernel;
}
const activeKernel = process.env.BENDTT ?? cachedKernel;
assert(fs.existsSync(activeKernel), `Independent BendTT kernel not found: ${activeKernel}`);
const activeKernelHash = crypto.createHash("sha256").update(fs.readFileSync(activeKernel)).digest("hex");
const activeKernelSource = path.join(path.dirname(activeKernel), "bendtt.lean");
const activeFuel = fs.existsSync(activeKernelSource)
  ? fs.readFileSync(activeKernelSource, "utf8").match(/def FUEL : Nat := (\d+)/)?.[1] ?? "unknown"
  : process.env.BENDTT_FUEL ?? "unknown";
const all = [...fs.readFileSync("LAWS.bend", "utf8").matchAll(/^law (aes256gcm_nist_\w+):/gm)].map(m => m[1]);
assert.equal(all.length, 16);
const selected = new Set(selection === "all" ? all : selection === "canonical"
  ? all.filter(n => n.includes("canonical_")) : all.filter(n => n === selection));
assert(selected.size > 0, "Unknown law selection");
const book = B.book_nil();
await B.book_load(book, "PROOF.bend", "", new Map());
const name = (key: string) => B.name_key?.(key) ?? key;
proofScope(B, book, [...selected].map(law => `LAWS.${law}`));
console.log(`Checking ${selected.size}/16 exact NIST laws with AES-only dependencies: ${[...selected].join(", ")}`);
try { checkWithProgress(B, book); }
catch (error) { console.error(B.err_show(error)); process.exit(1); }
for (const law of selected) {
  const key = book.order.find((k: string) => name(k) === `LAWS.${law}`);
  assert(key && book.tlds[key].e !== undefined, `Missing checked proof: ${law}`);
}
assert(book.hols === 0, "Checkpoint must contain no holes");
// Base and imported package proofs have been validated above. Let Bend's
// translator emit their models/dependencies rather than re-rooting all Base.
book.order = book.order.filter((key: string) => /^(libs\/AES|proof\/AES|LAWS\.aes256gcm_nist_)/.test(name(key)));
console.log(`Bend typecheck passed; checking independent kernel (FUEL=${activeFuel}, executable SHA256 ${activeKernelHash}).`);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "aes-nist-verdict-"));
try {
  const emitted = path.join(dir, "laws.bendtt");
  const errors = S.safe_emit(book, emitted);
  assert.equal(errors.length, 0, errors.join("\n"));
  // safe_check builds/selects the official kernel. If rejected, retain the
  // emitted input to reproduce its precise diagnostic with that same kernel.
  if (!S.safe_check(book)) {
    console.error(`Independent kernel rejected checkpoint; diagnostic input: ${emitted}`);
    process.exitCode = 1;
  } else {
    console.log(`PASS ${selected.size}/16 exact NIST laws; BendTT source SHA256 ${kernelHash}; executable SHA256 ${activeKernelHash}; FUEL=${activeFuel}`);
    fs.rmSync(dir, { recursive: true });
  }
} catch (error) {
  console.error(`Diagnostic directory: ${dir}`);
  throw error;
}
