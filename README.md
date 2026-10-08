# Bend2-libs

Shared Bend JSON, URL component encoding, and AES-256-GCM libraries, plus the local wire package override. The BendHub package entry point includes these modules, their laws and proofs, and usage examples.

## URL component encoding

Import `libs/URL.bend` as `URL` and call `URL.percent_component(text)` for a path segment, query value, or form field. It UTF-8 encodes the input and percent-escapes each byte, preserving the former SQL helper behavior.

## AES-256-GCM

Import `libs/AES256GCM.bend` as `AES`. `AES.key(bytes)` accepts a 32-byte key and `AES.nonce(bytes)` accepts a 12-byte nonce; both reject values outside the byte range. `AES.encrypt(key, nonce, aad, plaintext)` returns an authenticated `Envelope`, and `AES.decrypt(key, aad, envelope)` verifies the tag before returning plaintext. `AES.encode` and `AES.parse` use the canonical `v1.<nonce>.<tag>.<ciphertext>` lowercase-hex form.

This deterministic API leaves nonce generation to the caller. Never reuse a nonce with the same key; applications should obtain nonces from an operating-system cryptographic random generator and persist them safely. AAD is not stored in the envelope and must be supplied unchanged for decryption.

`usage/AES_NistTest.bend` checks all five NIST AES-256-GCM vectors in `LAWS.bend`: empty, multiblock, AAD-only, AAD with multiblock, and partial-block messages. Each checks encryption, decryption, and envelope parsing. Build and run it with `bend usage/AES_NistTest.bend -o aes-nist` and then run the generated binary.

On Windows, `./scripts/check-aes.ps1 -Checkpoint vectors` builds and validates the native NIST test. `-Checkpoint interop` compares the JavaScript build with Node/OpenSSL across 104 cases, including AES block boundaries, AAD padding, tag tampering, serialization, and invalid inputs.

## JSON and GPU execution

Json.parse(text) parses one document. Json.parse_gpu(text) requests GPU execution of that parser. To parse independent documents in parallel, use Json.parse_many_gpu(texts) with a List<&2, String>; it builds a balanced fork tree and returns Maybe<&1, Json.BatchResult>. Empty input returns None. Result leaves preserve input order and retain errors per document. For explicit control of the tree, use Json.parse_batch_gpu(batch).

Run the native GPU example with:

    bend usage/JSON_GPU.bend -o /tmp/json-gpu
    /tmp/json-gpu --gpu on
    /tmp/json-gpu --gpu off

--gpu on requires a supported GPU; the default permits CPU fallback. JavaScript execution is sequential. Within a single document, token payloads are decoded in parallel; lexical scanning and structural assembly are sequential. GPU execution depends on the host and compilation target.

## Correctness laws

Run `bend PROOF.bend` to check the JSON, URL, and AES-256-GCM laws declared in `LAWS.bend` and proved in the proof modules. For staged AES verification, use `./scripts/check-aes.ps1 -Checkpoint <name>`; the available checkpoints are documented in [proof/AES_CHECKPOINTS.md](proof/AES_CHECKPOINTS.md). The AES laws include NIST known-answer vectors for empty, partial-block, and multiblock messages, plus malformed-envelope and authentication-failure checks.

## Wire package override

libs/wire/ contains the vendored wire package and local TCP/TLS write deadline overrides, including its C and JavaScript effects, DNS module, and dependencies. See the wire notes in libs/wire/README.md for provenance and override details.

## Direct HTTP/1.1 client

`libs/DirectH1.bend` provides methods, repeated headers, binary bodies, verified
TLS/mutual TLS, redirects, optional decompression, response limits, phase
timeouts, connection pooling, and bounded parallel batches. DNS/decompression
run in a compiled Bend helper that can be terminated on deadline. It reuses
the pinned bend-kit HTTP codecs without HTTP/2 connection dispatch. See [DirectH1 API and limitations](libs/DirectH1.md)
and [the usage example](usage/DirectH1.bend).
