# Law fulfillment tasks in priority and dependency order

Plan updated on 2026-10-04. Each of the 89 declarations in `LAWS.bend` has one
law task below; shared prerequisites and final acceptance have separate tasks.
`LAWS.bend` remains the specification. The user approved representing the five
NIST encryption claims by their protocol observations, preserving success and
exact nonce, ciphertext, and tag bytes while excluding certificate identity.

Use task number order as the default execution order. P0 removes verification
blockers; P1 verifies foundations and already available proofs; P2 completes
concrete AES certificates; P3 closes the whole-repository gate. Dependencies
always precede their consumers. Dependencies express this implementation plan,
not a claim that one law logically implies every later law. When several tasks
are ready, prefer the lowest priority number, then the lowest task number.
Independent JSON, URL, AES serialization, and AES computation branches may
proceed in parallel; sibling fixture and block proofs may also proceed in
parallel. Parallelize Bend code where its data dependencies allow it.

Every law task requires an exact proof linked through `PROOF.bend`, accepted by
the independent kernel. A scoped pass may establish a prerequisite but does
not replace the final unfiltered gate. All boxes remain open for this plan:
recorded passes are retained as evidence, and must be revalidated where affected
by edits. Check a task only after its stated verification succeeds.

## Recorded evidence and unresolved work

- Sprint result: all 16 NIST laws passed the independent kernel through
  composed checkpoint proofs, with 167 checked opaque boundaries and
  FUEL=20000000000. Only the resource limit differs from the official kernel.
  The exact checked book and source/input/kernel hashes are archived under
  `proof/evidence/`; `scripts/recheck-aes-certificate.ts` replays that book.
  No NIST law remains unproved in this scope. The default 400-million limit
  still exhausts at the nine-block AAD-and-multiblock GHASH leaf.
- `bend PROOF.bend` completed successfully. The full `--verdict` run completed
  with exit 1 and a compiler/formal-kernel mismatch; the unfiltered gate remains
  unresolved. Scoped NIST success does not check off that gate.

- All five native AES NIST examples and 104 Node/OpenSSL comparisons passed.
- All 32 general AES laws passed a scoped Bend 2.0.35 independent-kernel check.
- All 52 NIST expansion steps and their public key-expansion bridge passed.
- J0 initial key addition, 13 middle rounds, and the final round passed individually;
  generic initial-state substitution and round-composition lemmas also passed.
- Historical pre-composition result: all 16 exact concrete NIST laws passed the scoped independent BendTT check
  with the official 2.0.35 kernel source and a 20-billion execution-fuel limit.
  `PROOF.bend` also contains and checks the composed J0 AES-block checkpoint.
  The law bodies remain exact; no law statements or conclusions were changed.
- Historical pre-composition result: the official 400-million-fuel kernel repeatedly reports `out of fuel` on
  concrete AES composition, first at the NIST multi-block encryption law.
  Raising only the kernel execution-fuel limit resolves that diagnostic. The
  41 JSON/URL laws still need acceptance in the full gate; their remaining
  failure count has not been established. All 89 laws have proof definitions.
- `JSON.render` remains the first isolated full-gate rejection. The full
  repository proof verdict is still unresolved independently of the scoped
  NIST result.
- Current tag representation exposes sixteen explicit XOR bytes and keeps its
  length/byte certificates checked. Generic tag bridges and the updated block-
  length proof passed the standard independent kernel. This supersedes the
  earlier reverted wrapper that hid the tag-length invariant.

## Ordered tasks

### T01 - [ ] Establish a repeatable trusted Bend proof setup

Priority: P0. Depends on: None.

Status: Pending.

Document the Bend version and launch command used for independent checks. The recorded general AES pass used side-by-side Bend 2.0.35; 2.0.34 has a combined-check translator failure in `Word.adc.con`. Use an unmodified kernel. Run `bend guide` before Bend implementation work.

### T02 - [ ] Repair the JSON rendering termination blocker

Priority: P0. Depends on: T01.

Status: Pending.

Refactor recursive `JSON.render` calls that rebuild `Arr{tail}` / `Obj{tail}` so the kernel recognizes structural descent. Preserve unbounded rendering, member order, duplicate keys, and suffix behavior. Adapt affected rendering/lexing helper proofs and independently check the repaired module before rebuilding dependent proofs.

### T03 - [ ] `parses_null`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T04 - [ ] `parses_true`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T05 - [ ] `parses_false`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T06 - [ ] `rejects_invalid_null`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T07 - [ ] `rejects_invalid_true`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T08 - [ ] `rejects_invalid_false`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T09 - [ ] `rejects_empty_input`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T10 - [ ] `rejects_whitespace_only`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T11 - [ ] `rejects_trailing_garbage`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T12 - [ ] `rejects_second_value`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T13 - [ ] `rejects_non_json_whitespace`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Check the exact input and result declared in `LAWS.bend`, using `JSON_PrimitiveProof.bend` and whitespace/assembly helpers where applicable. Reuse the existing proof definition; isolate any kernel rejection rather than changing the parser contract. Invalid cases must reject the entire input.

### T14 - [ ] `parses_empty_string`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T15 - [ ] `parses_simple_string`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T16 - [ ] `parses_newline_escape`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T17 - [ ] `parses_quote_escape`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T18 - [ ] `parses_backslash_escape`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T19 - [ ] `rejects_unterminated_string`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T20 - [ ] `rejects_raw_string_control`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T21 - [ ] `parses_unicode_escape`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T22 - [ ] `parses_unicode_surrogate_pair`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Independently verify the exact string fixture through `JSON_StringProof.bend` and rendering/lexing helpers. Preserve escape decoding, Unicode scalar and surrogate-pair behavior, and rejection of raw controls or incomplete strings as specified by this law.

### T23 - [ ] `parses_fraction_and_exponent`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Reuse `JSON_NumberLexProof.bend`; prove the precise number acceptance, rejection, or original lexeme equality in the declaration. Preserve the smart constructor certificate; do not normalize away the original decimal/exponent spelling.

### T24 - [ ] `rejects_malformed_number_forms`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Reuse `JSON_NumberLexProof.bend`; prove the precise number acceptance, rejection, or original lexeme equality in the declaration. Preserve the smart constructor certificate; do not normalize away the original decimal/exponent spelling.

### T25 - [ ] `preserves_number_lexeme`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Reuse `JSON_NumberLexProof.bend`; prove the precise number acceptance, rejection, or original lexeme equality in the declaration. Preserve the smart constructor certificate; do not normalize away the original decimal/exponent spelling.

### T26 - [ ] `parses_empty_array`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T27 - [ ] `parses_literal_array`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T28 - [ ] `rejects_array_trailing_comma`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T29 - [ ] `parses_empty_object`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T30 - [ ] `rejects_unquoted_object_key`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T31 - [ ] `rejects_object_trailing_comma`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T32 - [ ] `parses_nested_containers`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T33 - [ ] `preserves_array_order`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T34 - [ ] `preserves_object_order_and_duplicates`

Priority: P1. Depends on: T01, T02.

Status: Independent acceptance pending.

Verify the exact container result or rejection using assembly/source helpers. Retain array order, object member order, duplicate keys, and certified number values. Check nested structure and full input consumption without imposing an arbitrary depth limit.

### T35 - [ ] `stringify_parse_roundtrip`

Priority: P1. Depends on: T02.

Status: Independent acceptance pending.

Rebuild and independently accept the universal rendering/lexing/assembly proof for every `Json.Value`, including nested containers and certified numbers. The concrete parser tasks are useful diagnostics, not substitutes for this quantified theorem.

### T36 - [ ] `accepts_leading_space`

Priority: P1. Depends on: T35.

Status: Independent acceptance pending.

Compose the accepted stringify/parse theorem with whitespace-prefix or suffix lemmas. Prove the exact quantified declaration for arbitrary values and only the specified JSON whitespace characters.

### T37 - [ ] `accepts_trailing_space`

Priority: P1. Depends on: T35.

Status: Independent acceptance pending.

Compose the accepted stringify/parse theorem with whitespace-prefix or suffix lemmas. Prove the exact quantified declaration for arbitrary values and only the specified JSON whitespace characters.

### T38 - [ ] `accepts_surrounding_space`

Priority: P1. Depends on: T35.

Status: Independent acceptance pending.

Compose the accepted stringify/parse theorem with whitespace-prefix or suffix lemmas. Prove the exact quantified declaration for arbitrary values and only the specified JSON whitespace characters.

### T39 - [ ] `gpu_single_matches_cpu`

Priority: P1. Depends on: T02.

Status: Independent acceptance pending.

Use `JSON_ParallelProof.bend` to independently prove `parse_gpu(text) == parse(text)` for arbitrary text, including errors. Preserve the existing GPU request and CPU fallback behavior; runtime samples alone cannot prove this law.

### T40 - [ ] `gpu_batch_matches_cpu`

Priority: P1. Depends on: T39.

Status: Independent acceptance pending.

Prove the batch equality by structural induction on `Json.Batch`, composing the single-document equality at leaves. Preserve leaf order and per-document failures. Keep independent branches parallel wherever the implementation supports it.

### T41 - [ ] `url_component_ascii`

Priority: P1. Depends on: T01.

Status: Independent acceptance pending.

Independently check the exact `URL.percent_component` literal equality. Preserve uppercase percent escapes and encode UTF-8 bytes, including the two-byte non-ASCII fixture. This branch can proceed independently of JSON and AES.

### T42 - [ ] `url_component_reserved`

Priority: P1. Depends on: T01.

Status: Independent acceptance pending.

Independently check the exact `URL.percent_component` literal equality. Preserve uppercase percent escapes and encode UTF-8 bytes, including the two-byte non-ASCII fixture. This branch can proceed independently of JSON and AES.

### T43 - [ ] `url_component_utf8`

Priority: P1. Depends on: T01.

Status: Independent acceptance pending.

Independently check the exact `URL.percent_component` literal equality. Preserve uppercase percent escapes and encode UTF-8 bytes, including the two-byte non-ASCII fixture. This branch can proceed independently of JSON and AES.

### T44 - [ ] `aes256gcm_accepts_32_byte_key`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_ConstructorProof.bend` and the existing constructor proof in `PROOF.bend`. Preserve the declaration's length/byte hypotheses and exact result, including certificates. Rerun the constructors checkpoint and the scoped general AES check after relevant edits.

### T45 - [ ] `aes256gcm_rejects_wrong_key_length`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_ConstructorProof.bend` and the existing constructor proof in `PROOF.bend`. Preserve the declaration's length/byte hypotheses and exact result, including certificates. Rerun the constructors checkpoint and the scoped general AES check after relevant edits.

### T46 - [ ] `aes256gcm_rejects_non_byte_key`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_ConstructorProof.bend` and the existing constructor proof in `PROOF.bend`. Preserve the declaration's length/byte hypotheses and exact result, including certificates. Rerun the constructors checkpoint and the scoped general AES check after relevant edits.

### T47 - [ ] `aes256gcm_accepts_12_byte_nonce`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_ConstructorProof.bend` and the existing constructor proof in `PROOF.bend`. Preserve the declaration's length/byte hypotheses and exact result, including certificates. Rerun the constructors checkpoint and the scoped general AES check after relevant edits.

### T48 - [ ] `aes256gcm_rejects_wrong_nonce_length`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_ConstructorProof.bend` and the existing constructor proof in `PROOF.bend`. Preserve the declaration's length/byte hypotheses and exact result, including certificates. Rerun the constructors checkpoint and the scoped general AES check after relevant edits.

### T49 - [ ] `aes256gcm_rejects_non_byte_nonce`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_ConstructorProof.bend` and the existing constructor proof in `PROOF.bend`. Preserve the declaration's length/byte hypotheses and exact result, including certificates. Rerun the constructors checkpoint and the scoped general AES check after relevant edits.

### T50 - [ ] `aes256gcm_rejects_invalid_plaintext`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Recheck the exact validation failure using the existing public API proof. Keep byte-range validation and the specified error; do not replace rejection with truncation or coercion. Include this law in the combined general AES check.

### T51 - [ ] `aes256gcm_rejects_invalid_aad`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Recheck the exact validation failure using the existing public API proof. Keep byte-range validation and the specified error; do not replace rejection with truncation or coercion. Include this law in the combined general AES check.

### T52 - [ ] `aes256gcm_decrypt_rejects_invalid_aad`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Recheck the exact validation failure using the existing public API proof. Keep byte-range validation and the specified error; do not replace rejection with truncation or coercion. Include this law in the combined general AES check.

### T53 - [ ] `aes256gcm_encrypts_valid_input`

Priority: P1. Depends on: T44, T47.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_EncryptProof.bend` to establish the quantified successful encryption result from the exact validity hypotheses. Preserve ciphertext byte validity and the 16-byte tag invariant. Rerun the encrypt checkpoint.

### T54 - [ ] `aes256gcm_roundtrip`

Priority: P1. Depends on: T53.

Status: Recorded scoped pass; final gate pending.

Revalidate the matching theorem in `AES_EncryptProof.bend` and its public law bridge. Use the supplied successful-encryption equality to prove the precise decryption, nonce, or length conclusion; retain arbitrary inputs and the original hypotheses.

### T55 - [ ] `aes256gcm_preserves_nonce`

Priority: P1. Depends on: T53.

Status: Recorded scoped pass; final gate pending.

Revalidate the matching theorem in `AES_EncryptProof.bend` and its public law bridge. Use the supplied successful-encryption equality to prove the precise decryption, nonce, or length conclusion; retain arbitrary inputs and the original hypotheses.

### T56 - [ ] `aes256gcm_preserves_plaintext_length`

Priority: P1. Depends on: T53.

Status: Recorded scoped pass; final gate pending.

Revalidate the matching theorem in `AES_EncryptProof.bend` and its public law bridge. Use the supplied successful-encryption equality to prove the precise decryption, nonce, or length conclusion; retain arbitrary inputs and the original hypotheses.

### T57 - [ ] `aes256gcm_rejects_changed_tag`

Priority: P1. Depends on: T53.

Status: Recorded scoped pass; final gate pending.

Reuse tag comparison/rejection and `AES_TamperProof.bend`; rerun tag-compare, tag-reject, and tamper checkpoints. Prove rejection under the law's same-nonce, same-ciphertext, and changed-tag hypotheses. Do not extend this to universal collision freedom for changed AAD, key, nonce, or ciphertext.

### T58 - [ ] `aes256gcm_envelope_roundtrip`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_IdentityProof.bend` to prove exact envelope identity, including certificate equality, after encode/parse. Rerun identity; retain the canonical lowercase-hex format.

### T59 - [ ] `aes256gcm_envelope_is_canonical`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Reuse `AES_CanonicalProof.bend` to prove every successfully parsed string equals its re-encoding. This converse direction needs its own acceptance; an encode/parse round-trip alone is insufficient.

### T60 - [ ] `aes256gcm_rejects_empty_envelope`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T61 - [ ] `aes256gcm_rejects_unknown_version`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T62 - [ ] `aes256gcm_rejects_missing_version`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T63 - [ ] `aes256gcm_rejects_short_nonce`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T64 - [ ] `aes256gcm_rejects_long_nonce`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T65 - [ ] `aes256gcm_rejects_short_tag`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T66 - [ ] `aes256gcm_rejects_long_tag`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T67 - [ ] `aes256gcm_rejects_odd_ciphertext_hex`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T68 - [ ] `aes256gcm_rejects_non_hex_ciphertext`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T69 - [ ] `aes256gcm_rejects_non_hex_nonce`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T70 - [ ] `aes256gcm_rejects_non_hex_tag`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T71 - [ ] `aes256gcm_rejects_uppercase_hex`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T72 - [ ] `aes256gcm_rejects_extra_field`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T73 - [ ] `aes256gcm_rejects_missing_ciphertext_field`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T74 - [ ] `aes256gcm_rejects_trailing_garbage`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T75 - [ ] `aes256gcm_rejects_surrounding_whitespace`

Priority: P1. Depends on: T01.

Status: Recorded scoped pass; final gate pending.

Independently verify the exact malformed-envelope fixture and `Fail{AES.InvalidEnvelope{}}` result in `PROOF.bend`. Keep version, field count, lowercase hex, nonce/tag lengths, and whole-string validation strict. These literal cases can be checked independently of NIST encryption.

### T76 - [x] `aes256gcm_nist_canonical_encoding`

Priority: P1. Depends on: T01.

Status: Exact law passed the scoped Bend 2.0.35 independent-kernel checkpoint on 2026-10-06; see `proof/AES_CHECKPOINTS.md`.

Check the exact literal encoding of the empty NIST envelope, including the trailing empty ciphertext field. This is a serialization equality and does not depend on certifying the AES computation.

### T77 - [x] `aes256gcm_nist_canonical_parsing`

Priority: P1. Depends on: T76, T58.

Status: Exact law passed the scoped Bend 2.0.35 independent-kernel checkpoint on 2026-10-06; see `proof/AES_CHECKPOINTS.md`.

Rewrite the exact encoding equality into the accepted envelope round-trip theorem, or certify parsing directly. Establish exact empty-envelope equality including certificates; no NIST encryption dependency is required.

### T78 - [ ] Revalidate the NIST key-schedule certificate

Priority: P1. Depends on: T01.

Status: Recorded pass; revalidation pending.

Rerun the key-trace checkpoint for all 52 key-expansion steps and the public `Core.aes256_expand` bridge. These were recorded as independently accepted on Bend 2.0.34; record acceptance under the final supported setup before using them.

### T79 - [ ] Revalidate the J0 block round certificates

Priority: P1. Depends on: T01.

Status: Recorded pass; revalidation pending.

Check `proof/AES_NistBlockProof.bend --verdict`: initial key addition, all 13 middle rounds, and the final round. The previous checklist records `ALL PROOFS CHECK` on 2026-10-04. Preserve those certificates as reusable inputs.

### T80 - [ ] Compose J0 rounds and substitute the public key expansion

Priority: P2. Depends on: T78, T79.

Status: Pending.

Finish `proof/AES_NistBlockTraceProof.bend`: compose all 14 rounds and initial key addition into the public expanded-key block function, then substitute the actual NIST key expansion. The earlier verification was stopped at the user's pause; acceptance is unestablished. Reuse symbolic-fuel substitution. A new block wrapper requires explicit block-output and tag-XOR length proofs first.

### T81 - [ ] Certify the zero block that yields GHASH key H

Priority: P2. Depends on: T78.

Status: Pending.

Prove each required AES round and compose zero-block encryption under the actual NIST key. Reuse the certified key schedule and generic round-composition lemmas. Independently check small proof steps within the existing kernel fuel limit.

### T82 - [ ] Build reusable GHASH step and composition certificates

Priority: P2. Depends on: T01.

Status: Pending.

Certify GF(2^128) multiplication and GHASH accumulation in small independently checked steps. Include zero padding, AAD/ciphertext bit-length encoding, and the final length block. Bridge certificates to the actual public computation; do not rely on a detached reference implementation.

### T83 - [ ] Certify empty GHASH and exact public envelope construction

Priority: P2. Depends on: T81, T82, T80.

Status: Pending.

Prove the empty AAD/ciphertext hash, compose its tag with encrypted J0, and bridge public GCM output accessors. Use `AES_KnownAnswerProof.bend` for exact `Done{Envelope{...}}` construction with nonce identity, byte validity, tag length, and certificate equality. Reuse this bridge for later fixtures.

### T84 - [ ] `aes256gcm_nist_empty_encrypt`

Priority: P2. Depends on: T83.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Compose the certified actual NIST key, J0 tag, empty GHASH, and exact empty envelope. Wire the exact declared equality into `PROOF.bend` and independently accept it; the native vector pass is supporting evidence only.

### T85 - [ ] `aes256gcm_nist_empty_decrypt`

Priority: P2. Depends on: T84, T54.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Instantiate the accepted general decryption round-trip with the exact empty encryption equality and the specified AAD. Prove the literal `Done{[]}` result through the public API.

### T86 - [ ] Certify four counter blocks and ciphertext assembly

Priority: P2. Depends on: T78.

Status: Pending.

Certify counter construction/increment and the four AES block encryptions shared by the 64-byte and 60-byte fixtures. Compose plaintext XOR to obtain the exact 64-byte ciphertext and 60-byte prefix; certify partial-block truncation and empty plaintext. Reuse independently checked round steps instead of evaluating the full vector in one proof.

### T87 - [ ] Certify GHASH for the aad only fixture

Priority: P2. Depends on: T81, T82, T83.

Status: Pending.

Compose certified GHASH steps for 64-byte AAD with empty ciphertext. Include padding and the final encoded length block. XOR the hash with certified encrypted J0, prove the exact 16-byte tag, and bridge to public output accessors. Reuse shared prefixes where possible.

### T88 - [ ] `aes256gcm_nist_aad_only_encrypt`

Priority: P2. Depends on: T87, T80, T83.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Use the certified ciphertext and tag for 64-byte AAD with empty ciphertext to construct the exact public `Done{Envelope{...}}` equality via `AES_KnownAnswerProof.bend`. Include nonce and certificate identity, wire into `PROOF.bend`, and require independent acceptance.

### T89 - [ ] `aes256gcm_nist_aad_only_decrypt`

Priority: P2. Depends on: T88, T54.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Instantiate the general round-trip theorem with this fixture's accepted exact encryption proof and unchanged AAD. Establish the literal plaintext result in `LAWS.bend`; do not substitute a length-only or runtime assertion.

### T90 - [ ] Certify GHASH for the multiblock fixture

Priority: P2. Depends on: T81, T82, T86.

Status: Pending.

Compose certified GHASH steps for empty AAD with 64 ciphertext bytes. Include padding and the final encoded length block. XOR the hash with certified encrypted J0, prove the exact 16-byte tag, and bridge to public output accessors. Reuse shared prefixes where possible.

### T91 - [ ] `aes256gcm_nist_multiblock_encrypt`

Priority: P2. Depends on: T90, T80, T83.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Use the certified ciphertext and tag for empty AAD with 64 ciphertext bytes to construct the exact public `Done{Envelope{...}}` equality via `AES_KnownAnswerProof.bend`. Include nonce and certificate identity, wire into `PROOF.bend`, and require independent acceptance.

### T92 - [ ] `aes256gcm_nist_multiblock_decrypt`

Priority: P2. Depends on: T91, T54.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Instantiate the general round-trip theorem with this fixture's accepted exact encryption proof and unchanged AAD. Establish the literal plaintext result in `LAWS.bend`; do not substitute a length-only or runtime assertion.

### T93 - [ ] Certify GHASH for the aad and multiblock fixture

Priority: P2. Depends on: T81, T82, T86.

Status: Pending.

Compose certified GHASH steps for 64-byte AAD with 64 ciphertext bytes. Include padding and the final encoded length block. XOR the hash with certified encrypted J0, prove the exact 16-byte tag, and bridge to public output accessors. Reuse shared prefixes where possible.

### T94 - [ ] `aes256gcm_nist_aad_and_multiblock_encrypt`

Priority: P2. Depends on: T93, T80, T83.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Use the certified ciphertext and tag for 64-byte AAD with 64 ciphertext bytes to construct the exact public `Done{Envelope{...}}` equality via `AES_KnownAnswerProof.bend`. Include nonce and certificate identity, wire into `PROOF.bend`, and require independent acceptance.

### T95 - [ ] `aes256gcm_nist_aad_and_multiblock_decrypt`

Priority: P2. Depends on: T94, T54.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Instantiate the general round-trip theorem with this fixture's accepted exact encryption proof and unchanged AAD. Establish the literal plaintext result in `LAWS.bend`; do not substitute a length-only or runtime assertion.

### T96 - [ ] Certify GHASH for the partial block fixture

Priority: P2. Depends on: T81, T82, T86.

Status: Pending.

Compose certified GHASH steps for 20-byte AAD with 60 ciphertext bytes. Include padding and the final encoded length block. XOR the hash with certified encrypted J0, prove the exact 16-byte tag, and bridge to public output accessors. Reuse shared prefixes where possible.

### T97 - [ ] `aes256gcm_nist_partial_block_encrypt`

Priority: P2. Depends on: T96, T80, T83.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Use the certified ciphertext and tag for 20-byte AAD with 60 ciphertext bytes to construct the exact public `Done{Envelope{...}}` equality via `AES_KnownAnswerProof.bend`. Include nonce and certificate identity, wire into `PROOF.bend`, and require independent acceptance.

### T98 - [ ] `aes256gcm_nist_partial_block_decrypt`

Priority: P2. Depends on: T97, T54.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Instantiate the general round-trip theorem with this fixture's accepted exact encryption proof and unchanged AAD. Establish the literal plaintext result in `LAWS.bend`; do not substitute a length-only or runtime assertion.

### T99 - [ ] Certify the additional concrete tamper computations

Priority: P2. Depends on: T80, T81, T82.

Status: Pending.

Build certificates for AAD `[1]`, the all-zero 32-byte key, all-zero 12-byte nonce, and ciphertext `[1]`. The changed key needs its own schedule/block outputs; the changed nonce needs its own J0. Prove each recomputed tag differs from the supplied empty NIST tag and use authentication rejection, without asserting universal collision freedom.

### T100 - [ ] `aes256gcm_nist_rejects_changed_aad`

Priority: P2. Depends on: T99.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Apply the certified recomputed-tag inequality for the exact changed aad fixture to the public authentication-rejection theorem. Prove `Fail{AES.AuthenticationFailed{}}`, not merely any failure. Keep the unchanged supplied NIST tag and all other declared inputs exact.

### T101 - [ ] `aes256gcm_nist_rejects_changed_key`

Priority: P2. Depends on: T99.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Apply the certified recomputed-tag inequality for the exact changed key fixture to the public authentication-rejection theorem. Prove `Fail{AES.AuthenticationFailed{}}`, not merely any failure. Keep the unchanged supplied NIST tag and all other declared inputs exact.

### T102 - [ ] `aes256gcm_nist_rejects_changed_nonce`

Priority: P2. Depends on: T99.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Apply the certified recomputed-tag inequality for the exact changed nonce fixture to the public authentication-rejection theorem. Prove `Fail{AES.AuthenticationFailed{}}`, not merely any failure. Keep the unchanged supplied NIST tag and all other declared inputs exact.

### T103 - [ ] `aes256gcm_nist_rejects_changed_ciphertext`

Priority: P2. Depends on: T99.

Status: Scoped independent pass at 20-billion fuel; unfiltered gate pending.

Apply the certified recomputed-tag inequality for the exact changed ciphertext fixture to the public authentication-rejection theorem. Prove `Fail{AES.AuthenticationFailed{}}`, not merely any failure. Keep the unchanged supplied NIST tag and all other declared inputs exact.

### T104 - [ ] Expose repeatable block, GHASH, and NIST proof checkpoints

Priority: P2. Depends on: T80, T83, T86, T99, T87, T90, T93, T96.

Status: Pending.

Extend `scripts/check-aes.ps1` with the new proof layers and record their commands/results in `proof/AES_CHECKPOINTS.md`. Record version, exit code, verdict, and proof scope; runtime success is separate from independent proof acceptance.

### T105 - [ ] Accept every law together in the full repository gate

Priority: P3. Depends on: All preceding law tasks and T104.

Status: Pending.

Run `bend PROOF.bend --verdict` under the documented setup and require `ALL PROOFS CHECK` with exit code zero. Repair every subsequent source/proof rejection and repeat the relevant checkpoint; the JSON blocker is only the first known rejection. Recount all 89 declarations and linked definitions: 38 JSON, 3 URL, 32 general AES, and 16 NIST laws. No filtering, weakened conclusions, added assumptions, unchecked axioms, or disabled verification.

### T106 - [ ] Rerun final proof and runtime regression checks

Priority: P3. Depends on: T105.

Status: Pending.

Rerun all affected proof checkpoints against the final working tree. Run `./scripts/check-aes.ps1 -Checkpoint vectors` and require all five native cases to return `True{}` with a successful exit; run `-Checkpoint interop` and require all 104 OpenSSL comparisons/rejection checks to pass. Run `bend PROOF.bend` before any eventual commit as required by `AGENTS.md`. No commit or publication is requested.

### T107 - [ ] Record final verified results and clean superseded experiments

Priority: P3. Depends on: T106.

Status: Pending.

Update `README.md`, `proof/AES_CHECKPOINTS.md`, and this checklist with actual final results. Remove only superseded experimental helpers after confirming they are unused; rerun affected checks if cleanup changes proof/code. Audit implementation and proof scope against all laws before declaring completion.

