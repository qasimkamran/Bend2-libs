import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// Uses Bend's own checker, translator and independent kernel. This is a
// deliberately scoped checkpoint; PROOF.bend --verdict remains the final gate.
const sourceDir = process.argv[2];
assert(sourceDir, "Usage: bun scripts/check-aes-general.ts <Bend bend2 source directory>");
const B = await import(pathToFileURL(path.resolve(sourceDir, "bend.ts")).href);
const S = await import(pathToFileURL(path.resolve(sourceDir, "safe.ts")).href);
const nameKey = B.name_key ?? ((key: string) => key);
const workspace = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
process.chdir(workspace);
const laws = [...fs.readFileSync("LAWS.bend", "utf8").matchAll(/^law (aes256gcm_\w+):/gm)].map(match => match[1]);
const concrete = new Set(laws.filter(name => name.startsWith("aes256gcm_nist_")));
const general = new Set(laws.filter(name => !concrete.has(name)));
const leaf = (key: string) => nameKey(key).slice(nameKey(key).lastIndexOf(".") + 1);
const book = B.book_nil();
await B.book_load(book, "PROOF.bend", "", new Map());
book.order = book.order.filter((key: string) => !concrete.has(leaf(key)));
B.book_valid(book);
book.order = book.order.filter((key: string) => /^(libs\/AES|proof\/AES|LAWS\.aes256gcm_)/.test(nameKey(key)));
const checked = new Set<string>();
for (const key of book.order) {
  if (nameKey(key).startsWith("LAWS.") && general.has(leaf(key))) {
    assert(book.tlds[key].e !== undefined, `Missing checked proof: ${nameKey(key)}`);
    checked.add(leaf(key));
  }
}
assert.equal(checked.size, general.size, "Every general AES law must be included");
console.log(`Checking ${checked.size} general AES laws; ${concrete.size} concrete NIST laws excluded.`);
if (!S.safe_check(book)) {
  console.error("General AES independent-kernel checkpoint failed.");
  process.exit(1);
}
console.log(`${checked.size} general AES laws passed the independent kernel. Full laws checkpoint still required.`);
