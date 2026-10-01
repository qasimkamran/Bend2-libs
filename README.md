# Bend2-libs

Shared Bend HTTP, JSON, and Datasette SQL libraries. Keep this repository beside
`Bend2-eStoreManager` for its relative imports to resolve.

## JSON and GPU execution

`Json.parse(text)` parses one document. `Json.parse_gpu(text)` requests GPU
execution of that parser. To parse independent documents in parallel,
use `Json.parse_many_gpu(texts)` with a `List<&2, String>`; it builds a balanced
fork tree and returns `Maybe<&1, Json.BatchResult>`. Empty input returns `None`.
Result leaves preserve input order and retain errors per document. For explicit
control of the tree, use `Json.parse_batch_gpu(batch)`.

Run the native GPU example with:

```sh
bend usage/JSON_GPU.bend -o /tmp/json-gpu
/tmp/json-gpu --gpu on
/tmp/json-gpu --gpu off
```

`--gpu on` requires a supported GPU; the default permits CPU fallback.
JavaScript execution is sequential. Within a single document, token payloads
are decoded in parallel; lexical scanning and structural assembly are sequential.
GPU execution depends on the host and compilation target.

## JSON correctness laws

Run `bend PROOF.bend` to check the active laws in `LAWS.bend`. Three universal
HTTP laws remain documented there as comments pending general proofs.

## HTTP client

`libs/HTTPClient.bend` implements an HTTP/1.1 client and codec for the supported
subset of [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112.html) message
framing and [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html) semantics.
It provides bounded response decoding, optional JSON parsing, and a
one-connection TCP/TLS client. See `usage/HTTP_Send.bend`
for a local client and `usage/HTTP_GPU.bend` for mixed codec batch processing.
The GPU example exercises CPU fallback on hosts without a supported GPU:

```sh
bend usage/HTTP_GPU.bend -o /tmp/http-gpu
/tmp/http-gpu --gpu off
```

## Datasette SQL client

`libs/SQL.bend` calls a Datasette instance over `HTTPClient.bend`. It supports
read-only SQL queries, named query parameters, and authenticated write-SQL
requests. `SQL.Client` takes the Datasette base URL (without a trailing slash),
database route name, and an optional Datasette API token. Write requests require
a mutable database and a token with the relevant Datasette write permissions.

## Wire package overrides

`libs/wire/` contains the vendored wire package and local TCP/TLS write deadline
overrides, including its C and JavaScript effects, DNS module, and dependencies.
See [the wire notes](libs/wire/README.md) for provenance and override details.
