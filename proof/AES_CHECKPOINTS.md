# AES proof checkpoints

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
