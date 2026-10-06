import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import zlib from "node:zlib";
import { spawnSync } from "node:child_process";

// Replay the exact checked book without repeating the expensive source pass.
// Reject stale certificates when any recorded Bend source changes.
const manifestPath = "proof/evidence/aes-nist-checkpoints-2026-10-06.json";
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const hash = (bytes: Uint8Array) => crypto.createHash("sha256").update(bytes).digest("hex");
for (const [file, expected] of Object.entries(manifest.sourceSHA256)) {
  if (hash(fs.readFileSync(file)) !== expected) throw new Error(`Source changed: ${file}; regenerate and check the certificate.`);
}
const archive = fs.readFileSync(path.join(path.dirname(manifestPath), manifest.proofArchive));
if (hash(archive) !== manifest.archiveSHA256) throw new Error("Certificate archive hash mismatch");
const input = zlib.gunzipSync(archive);
if (hash(input) !== manifest.serializedProofSHA256) throw new Error("Serialized proof hash mismatch");
if (process.argv.includes("--integrity-only")) {
  console.log("Archive and source integrity pass. The independent kernel has not run.");
} else {
  const kernel = process.env.BENDTT;
  if (!kernel) throw new Error("Set BENDTT to the recorded higher-fuel kernel.");
  if (hash(fs.readFileSync(kernel)) !== manifest.kernelExecutableSHA256) throw new Error("Kernel executable differs from the recorded build.");
  const source = fs.readFileSync(path.join(path.dirname(kernel), "bendtt.lean"));
  if (hash(source) !== manifest.kernelSourceSHA256) throw new Error("Kernel source differs from the recorded build.");
  const folder = fs.mkdtempSync(path.join(os.tmpdir(), "aes-certificate-"));
  const file = path.join(folder, "proof.bendtt");
  fs.writeFileSync(file, input);
  const result = spawnSync(kernel, [file], { encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
    env: { ...process.env, LEAN_STACK_SIZE_KB: "4194304" } });
  console.log(result.stdout || result.stderr || String(result.error ?? "No kernel diagnostic"));
  if (result.status !== 0 || result.stdout.trim() !== "ALL PROOFS CHECK") process.exitCode = 1;
  else console.log(`PASS ${manifest.roots.length}/16 NIST laws; ${manifest.opaqueBodiesChecked} checked checkpoint bodies; FUEL=${manifest.fuel}.`);
}
