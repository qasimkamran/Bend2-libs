# AES proof checkpoints

## Sprint checkpoint composition - 2026-10-06

**Result: all 16 NIST laws pass through the composed checkpoint book.**
The independent kernel returned `ALL PROOFS CHECK`, exit 0, on the exact
source-checked input with 167 checked opaque checkpoint bodies and
`FUEL=20000000000`. Only FUEL differs from the official proven kernel.
Evidence and the compressed checked book are retained in `proof/evidence/`.
The input SHA256 is
`afadacdad1905b076c75293503423bef9cd1007b7261a59a3614fd1776e41daf`.

`bend PROOF.bend` also completed with `ALL PROOFS CHECK`, exit 0.
The separate unfiltered `bend PROOF.bend --verdict` completed with exit 1
and a compiler/formal-kernel mismatch diagnostic. This result closes the
16-law NIST goal, not the full repository independent gate.

The five encryption laws now compare the protocol observation: successful
encryption and exact nonce, ciphertext, and tag bytes. Envelope certificates
still enforce the byte ranges and fixed nonce/tag lengths; their term identity
is excluded from these known-answer comparisons. Failure observes an empty
list, while every expected success contains at least the 12-byte nonce and
16-byte tag. With these fixed field lengths the flattened observation preserves
each field unambiguously. Decryption, tamper rejection, and canonical encoding
and parsing statements are unchanged.

`PROOF.bend` now delegates all fourteen computational NIST laws to composed
proofs in `AES_NistVectorProof.bend` and `AES_NistTamperVectorProof.bend`.
The two small canonical laws remain direct computational leaf proofs.
The generic observation, encryption, and decryption bridges have passed
BendTT. The NIST key schedule also passed the unmodified 400-million-fuel
kernel after adding an explicit transport for equal round counts (4.8 seconds).
The first composed empty-encryption law passed at 20-billion fuel before the
further tag and counter-block decomposition.

The final law definitions also use `AES_NistInputProof.bend` to transport exact
law inputs to their equal fixture aliases before calling a composed proof.
The two generic input transports passed the standard independent kernel in
1.6 seconds. `scripts/wire-aes-nist-laws.mjs` reads the actual call arguments
from LAWS and rewrites only the fourteen linked proof bodies; it does not
change the specification.

Tag composition now connects the H and J0 AES block checkpoints to GHASH and
tag XOR. Counter-mode stream proofs connect four AES counter-block checkpoints
to exact 64-byte and 60-byte streams. Every intermediate candidate still
requires independent checking; runtime-generated intermediate values are
never accepted as certificates by themselves.

The current generic tag shape, hash transport, and tag composition passed
with the unmodified 400-million-fuel kernel in 1.5 seconds. Envelope tag
parameter transport and the generic AES block-length proof passed in 1.7
seconds. The tag XOR now exposes exactly sixteen bytes, so its size and byte
certificates do not require symbolic AES/GHASH evaluation. Abstract key
schedules and AAD remain guarded; both branches retain identical calculations.
All five native NIST examples and all 104 Node/OpenSSL cases passed after these
implementation changes.

Both canonical NIST laws were also independently rechecked at standard fuel
in 2.4 seconds. The standard 400-million-fuel complete checkpoint run accepted
the AES block/counter compositions but exhausted fuel at
`AES_NistVectorProof.checkpoint_aad_and_multiblock_ghash`, the nine-block GHASH
leaf. The identical input passed at 20-billion fuel. Further decomposition of
that GHASH leaf remains a resource optimization; no current NIST law is left
unproved in the higher-fuel independent scope.

`scripts/check-aes-checkpoint.ts` selects the full dependency closure of its
roots before typechecking, then emits the actual proof book and asks BendTT to
check every checkpoint body with its standard `opaque` boundaries. It checks
both the process exit status and the exact `ALL PROOFS CHECK` verdict. Its
source checks show progress at each checkpoint. Successful runs retain the
serialized book and JSON evidence with source/input/kernel hashes.

```powershell
$env:BENDTT = '<path-to-bendtt.exe>'
bun scripts/check-aes-checkpoint.ts <bend2-source-directory> all
```

Bend Hub was revisited against the [official guide](https://github.com/bendlang/bend/blob/main/guide/GUIDE.md).
It can distribute separately packaged proofs by content hash or package name.
No reusable AES checkpoint package was found in the inspected sources; this
implementation therefore keeps its composed certificates local. Nothing was
published to Hub.

To replay the archived certificate with the recorded kernel, avoiding the
713.5-second source check:

```powershell
$env:BENDTT = '<path-to-recorded-20-billion-fuel-bendtt.exe>'
bun scripts/recheck-aes-certificate.ts
```

The replay script verifies every recorded Bend source hash and the archive,
input, and kernel hashes before invoking the independent kernel. Use
`--integrity-only` for hash validation without a proof-verification claim.

This scoped result does not replace `bend PROOF.bend --verdict`. That full
independent gate remains rejected by a compiler/kernel mismatch; the earlier
isolated JSON.render rejection is recorded below.

## New scoped results - 2026-10-06

### Updated result

For this historical result, the exact law statements and BendTT proof rules were unchanged. The official
kernel's `FUEL=400000000` repeatedly exhausted on concrete AES evaluation. A
reproducible build changing only that resource limit is available through
`scripts/build-bendtt-fuel.ps1`.

With the independent Bend 2.0.35 kernel at `FUEL=20000000000`:

- All 16 exact NIST laws in `LAWS.bend` passed together through
  `scripts/check-aes-nist.ts all` (`PASS 16/16 exact NIST laws`, exit 0).
- The full 13-round J0 AES block composition passed through
  `scripts/check-aes-trace.ts ... 13` (`ALL PROOFS CHECK`, exit 0).
- `PROOF.bend` includes a named helper linked to that composed block proof;
  the helper and all 16 law definitions passed in the same scoped book.

The NIST law bodies still use their existing reflexivity proofs, so that law
checkpoint evaluates the exact concrete computations. The composed block
checkpoint is independently checked alongside them but does not yet replace
the direct computation inside each NIST law proof. No law statement changed.

The official kernel source SHA256 is
`e15042434e73aab07ab05cea4b77b5619082c00a6d4924ea2d4a2cdec05facce`. The source
with `FUEL=20000000000` hashes to
`dfa5f250bd6e6891642059e13a166350a3bcf453fd0bff0023829d9a449341fc`; its
executable SHA256 is
`25bf11106d6e86a1dc7263c481051fbc04ec24312487e8d35bf11581dd8c525b`.

Reproduce from the repository root:

```powershell
$source = '<bend2-source-directory>'
./scripts/build-bendtt-fuel.ps1 -Bend2Source $source -Fuel 20000000000 `
  -OutputDirectory "$env:TEMP/bendtt-fuel-20b"
$env:BENDTT = "$env:TEMP/bendtt-fuel-20b/bendtt.exe"
$env:BENDTT_FUEL = '20000000000'
bun scripts/check-aes-nist.ts $source all
bun scripts/check-aes-trace.ts $source 13 proof/AES_NistBlockComposeProof.bend
```

The older two-law and shallow-depth results below are historical lower-fuel
checkpoints; this result supersedes their NIST law count.

Current progress was committed as `7136895` before this checkpoint work.
The required `bend PROOF.bend` run was attempted and interrupted without a
completed verdict; the commit is explicitly work in progress.

Using the unmodified side-by-side Bend 2.0.35 checker and kernel:

- `aes256gcm_nist_canonical_encoding` and
  `aes256gcm_nist_canonical_parsing` passed their exact `LAWS.bend` claims.
  This establishes 2 of the 16 NIST laws; 14 remain pending.
- NIST J0 block composition depths 0, 1, and 2 passed the independent kernel.
  Depth 2 composes the last two middle rounds and final round, not the full block.
- Kernel source SHA256:
  `e15042434e73aab07ab05cea4b77b5619082c00a6d4924ea2d4a2cdec05facce`.

Reproduce from the repository root:

```powershell
bun scripts/check-aes-nist.ts <bend2-source-directory> canonical
bun scripts/check-aes-trace.ts <bend2-source-directory> 1
bun scripts/check-aes-trace.ts <bend2-source-directory> 2
```

Both commands exited zero. These scoped results do not establish the full
repository verdict. The NIST runner validates the original proof definitions
and dependencies before selecting AES roots for the independent kernel;
unselected laws are never counted as accepted. The trace runner excludes
unneeded leaf proofs and checks all referenced dependencies, without treating
prior process successes as assumptions. No law statements have been changed.

On Windows, the runners use the existing official kernel executable from
the cache directory matching the selected source hash, avoiding Bend 2.0.35's
missing `.exe` cache lookup and concurrent compiler overwrite issue.

## Recorded status — 2026-10-04

These are results for the current working tree, not a guarantee for later edits.
Rerun the affected checkpoint after changing its code or proofs.

| Checkpoint | Last result |
| --- | --- |
| `core` | Passed independent kernel |
| `wrapper` | Passed independent kernel |
| `constructors` | Passed exact key and nonce construction proofs |
| `identity` | Passed exact envelope round-trip and encoder injectivity |
| `trace` | Passed arithmetic-step composition lemmas |
| `key-trace` | Passed all 52 NIST expansion steps and the public `Core.aes256_expand` bridge with Bend 2.0.34 |
| `tag-compare` | Passed independent kernel |
| `tag-reject` | Passed independent kernel |
| `encrypt` | Passed independent kernel |
| `tamper` | Passed independent kernel |
| `vectors` | Passed all five native NIST cases |
| `interop` | Passed 104 Node/OpenSSL comparisons and rejection checks |
| `laws` | Failed: TypeScript checker / BendTT kernel mismatch |

All 89 declared laws have corresponding proof definitions (48 are AES laws).
That coverage does not mean all 89 proofs have been accepted. A scoped check
with the Bend 2.0.35 independent kernel accepted all 32 general AES laws;
the 16 concrete NIST laws remain pending formal verification. The runtime
NIST cases pass. Other libraries are not covered by that scoped result.

The full gate's first isolated rejection is `JSON.render`: the kernel cannot
recognize its recursive calls as descending. The standalone
`proof/AES_KnownAnswerCheck.bend` has a separate problem: the kernel reports
`out of fuel` while evaluating concrete encryption. Its experimental helper
is not wired into `PROOF.bend`. Mask ordering alone did not resolve that fuel
limit. These are concrete diagnostics, not a successful final verdict.

The next checkpoint is to isolate the kernel rejection, repair the affected
proofs, then rerun `laws`. Do not treat the runtime checks as formal law proofs.

## Running checkpoints

Run one checkpoint at a time so failures stay attached to the smallest relevant
proof layer:

```powershell
./scripts/check-aes.ps1 -Checkpoint core
./scripts/check-aes.ps1 -Checkpoint wrapper
./scripts/check-aes.ps1 -Checkpoint constructors
./scripts/check-aes.ps1 -Checkpoint identity
./scripts/check-aes.ps1 -Checkpoint trace
./scripts/check-aes.ps1 -Checkpoint key-trace
./scripts/check-aes.ps1 -Checkpoint tag-compare
./scripts/check-aes.ps1 -Checkpoint tag-reject
./scripts/check-aes.ps1 -Checkpoint encrypt
./scripts/check-aes.ps1 -Checkpoint tamper
./scripts/check-aes.ps1 -Checkpoint vectors
./scripts/check-aes.ps1 -Checkpoint interop
./scripts/check-aes.ps1 -Checkpoint laws
```

The proof checkpoints run `bend <file> --verdict`, so a pass includes the
independent proof kernel. `vectors` builds and runs the native NIST test and
requires both a successful exit and `True{}`. `interop` compiles the actual AES
library to JavaScript and compares 104 combinations of plaintext and AAD lengths
with Node/OpenSSL, including empty, partial-block, multiblock, and 1024-byte
messages. It also checks decryption, serialization, tampering, and invalid input.
It requires Node.js. Each command reports its elapsed
time. Scripts resolve files relative to the repository, even when invoked from
another working directory.

`encrypt` proves successful encryption, byte validity, length preservation,
nonce preservation, and decryption round-trip. `tamper` proves rejection of a
changed tag for unchanged nonce and ciphertext. `identity` proves exact
envelope identity after parsing its encoding, including certificate equality.
`constructors` proves exact successful key and nonce construction.
`trace` proves composition of individual key-expansion and AES round steps;
it does not prove a concrete NIST vector by itself.
`key-trace` checks all 52 expansion steps for the NIST example key and their
composition, including the final bridge to the public `Core.aes256_expand`
function. The NIST encryption laws are still pending. The attempted block-round
wrapper was reverted because it hid the tag-length invariant; a future block
bridge needs an explicit length proof before that wrapper can be introduced.
`laws` checks every law,
including the concrete known-answer and malformed-envelope cases, and can take
longer because the checker evaluates the cryptographic test vectors. Run `laws`
after wiring a law into `PROOF.bend`; it is the final gate before committing.

For the combined general AES law checkpoint, supply the directory containing
Bend's `bend.ts` and `safe.ts` (Bend 2.0.35 was used for the recorded pass):

```powershell
bun scripts/check-aes-general.ts <path-to-bend2-source-directory>
```

This script checks the current `LAWS.bend` and `PROOF.bend`, requires a checked
proof for every general AES law, and uses Bend's own translator and independent
kernel. It explicitly excludes concrete NIST laws and other libraries from
the kernel check. Bend 2.0.34 has a separate translator failure in `Word.adc.con`
on this combined checkpoint. It is not a replacement for `laws`.
