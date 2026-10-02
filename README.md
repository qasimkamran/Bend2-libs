# Bend2-libs

Shared Bend JSON and URL component encoding libraries, plus the local wire package override. The BendHub package entry point includes these modules, their laws and proofs, and the JSON usage examples.

## URL component encoding

Import `libs/URL.bend` as `URL` and call `URL.percent_component(text)` for a path segment, query value, or form field. It UTF-8 encodes the input and percent-escapes each byte, preserving the former SQL helper behavior.

## JSON and GPU execution

Json.parse(text) parses one document. Json.parse_gpu(text) requests GPU execution of that parser. To parse independent documents in parallel, use Json.parse_many_gpu(texts) with a List<&2, String>; it builds a balanced fork tree and returns Maybe<&1, Json.BatchResult>. Empty input returns None. Result leaves preserve input order and retain errors per document. For explicit control of the tree, use Json.parse_batch_gpu(batch).

Run the native GPU example with:

    bend usage/JSON_GPU.bend -o /tmp/json-gpu
    /tmp/json-gpu --gpu on
    /tmp/json-gpu --gpu off

--gpu on requires a supported GPU; the default permits CPU fallback. JavaScript execution is sequential. Within a single document, token payloads are decoded in parallel; lexical scanning and structural assembly are sequential. GPU execution depends on the host and compilation target.

## JSON correctness laws

Run bend PROOF.bend to check the JSON laws declared in LAWS.bend and proved in the proof modules.

## Wire package override

libs/wire/ contains the vendored wire package and local TCP/TLS write deadline overrides, including its C and JavaScript effects, DNS module, and dependencies. See the wire notes in libs/wire/README.md for provenance and override details.
