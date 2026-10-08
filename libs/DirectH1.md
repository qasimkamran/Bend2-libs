# DirectH1

Reusable direct HTTP/1.1 client for `http://` and verified `https://` URLs.
Import `libs/DirectH1.bend` as `DirectH1`.

## Public API

| Function | Behavior |
| --- | --- |
| `defaults()` | Finite phase timeouts, 30-second shared budget, identity encoding, follow up to 20 redirects |
| `fetch(method, url, headers, body)` | One request using defaults |
| `fetch.with(method, url, headers, body, options)` | One request with explicit options |
| `get(url)` / `head(url)` | Convenience requests |
| `pool.new()` / `pool.new.with(capacity, idle_ms)` | Create a bounded pool |
| `pool.fetch.with(pool, method, url, headers, body, options)` | Return updated pool and response |
| `pool.fetch(pool, method, url, headers, body)` / `pool.get(pool, url)` | Pooled requests using defaults |
| `pool.close(pool)` | Close all retained sockets |
| `fetch.all(requests, workers)` | Bounded concurrent batch, input-order results |
| `fetch.all.with(requests, workers, options)` | Concurrent batch with per-request options |

Headers, responses, errors and batch request records are the pinned original
HTTP types: `Http.empty`, `Http.set`, `Http.add`, `Http.Res`, `Http.Err`, and
`Http.Fetch`. Bodies are binary `Bytes.Bytes`; `Http.from_string` accepts an
octet string. Use UTF-8 encoding explicitly for Unicode text.

```bend
import Base
import ./libs/DirectH1.bend as DirectH1
import 0x2ef00d214bb4173160420b61a1472572/http.bend as Http

def request(url: String, token: String) -> IO(Result<&1, &1, Http.Err, Http.Res>):
    DirectH1.fetch("GET", url,
        Http.set(Http.empty(), "authorization", "Bearer " ++ token),
        Http.from_string(""))
```

Build the helper and example from the library repository root:

```sh
mkdir -p build
bend usage/DirectH1Worker.bend -o build/direct-h1-worker
bend usage/DirectH1Pool.bend -o build/direct-h1-pool
export DIRECT_H1_WORKER="$PWD/build/direct-h1-worker"
```

The compiler does not make requests. Running the pool example with
`DIRECT_H1_URL` set makes two GET requests and prints only their statuses.
The helper is a short-lived compiled Bend executable, with no listener or PM2
entry. An absolute trusted path is recommended. If the environment variable
is absent, the client looks for `direct-h1-worker` on PATH. A missing executable
fails the request explicitly; it never silently falls back to blocking DNS.

DNS lookup runs in the helper on a connection cache miss. IPv4/IPv6 address
fallback and the existing hosts/OS resolver behavior are retained. Decompression
uses the helper only for a nonempty encoded response. Headers and API keys are
not passed as command arguments; protocol data uses private pipes. Base's native
process runner closes inherited descriptors before exec, so pooled sockets
remain solely in the caller.

## Options

`Options` fields, in constructor order:

- `connect_ms`, `read_ms`, `write_ms`: finite phase timeouts. The connection
  timeout applies separately to dialing and TLS, within the shared budget.
- `total_ms`: shared elapsed-time budget across DNS, dialing, TLS, reads,
  writes, redirects and decoding. Zero disables this shared budget.
- `header_bytes`: cumulative bytes for interim and final response heads.
- `body_bytes`: maximum encoded body retained and final decoded body accepted.
- `wire_bytes`: maximum response wire bytes per hop, including framing.
- `redirects`: number of redirects permitted after the initial request.
- `mode`: `Http.ModeFollow`, `Http.ModeManual`, or `Http.ModeError`.
- `encoding`: default `"identity"`; e.g. `"gzip, deflate"` enables the
  original decoder path. Brotli/Zstandard depend on available runtime libraries.
- `cert`: `None` or `Some{Http.Cert{chain_path, key_path}}` for mutual TLS.

All phase timeouts and byte limits must be nonzero. Invalid options, malformed
responses and byte-limit failures use the original `Http.ErrBad` error.
Timeout errors use `Http.ErrTimeout`. Redirect errors use `Http.ErrRedirect`.
An HTTP error status, such as 401, is still a successfully received response.

The header and wire caps bound each read. Content-Length is rejected above the
body cap before accumulating the body. Chunked and close-delimited fragments
are counted before retaining them or concatenating the final body. A temporary
read/decoder fragment can occupy up to one read (64 KiB) beyond the retained
body budget. Decoding uses upstream's fixed 16 MiB output allocation cap;
a smaller configured body cap is checked after decoding. Header count, trailer
count, chunk-line length and interim-response count are not configurable here;
the original parser behavior and wire-byte cap still apply.

## Reuse and scope

Original implementation: <https://github.com/paymog/bend-kit/tree/main/http>.
Pinned HTTP source: `0x2ef00d214bb4173160420b61a1472572/http.bend`.
The client calls that source directly for request/header encoding, header
parsing, body framing/chunk decoding, redirect policy, decompression and errors.
It does not copy those implementations. Redirects preserve upstream method/body
rewrites and remove authorization/cookies when the origin changes.

DNS and verified TLS use the existing local `libs/wire` package; address fallback
reuses the pinned HTTP dialer. No new C or JavaScript effects were introduced.
TCP/TLS writes use the local wire override's interruptible write deadline.
That API takes an octet string, so outgoing bytes are converted to a string;
large uploads can therefore have more allocation overhead than packed writes.

Pools keep up to eight idle sockets globally by default, for 30 seconds of
idle time. Keys include origin and client-certificate paths. `pool.new.with`
changes these bounds; zero capacity disables retention. Pools have affine
ownership: pass the returned pool into the next request, and call `pool.close`
when finished. See `usage/DirectH1Pool.bend` for that pattern.

Only complete, self-delimited HTTP/1.1 responses without `Connection: close`,
upgrades, or unexpected trailing bytes are reusable. Close-delimited and
HTTP/1.0 responses close their sockets. A stale reused connection can retry
once on a new socket only for an idempotent method with no response bytes;
POST/PATCH are never automatically replayed. A retry uses the original total
budget. Ordinary `fetch`/`get` create and close a temporary pool; preserve an
explicit pool to reuse connections across pagination requests. Batch workers
each retain their own pool across jobs and close it when the batch ends.

There is no HTTP/2 negotiation, proxy environment routing, automatic cookie
jar, WebSocket upgrade or streaming public response API. Caller-provided cookies are ordinary headers.
This supplies a reusable request API rather than every feature of the original
general client. Internal upstream helper APIs are pinned and must be reviewed
when changing that dependency. The import still loads HTTP/2 definitions, so
this is not a fix for compiler namespace conflicts while loading the package.

## Overall deadline

`total_ms` starts before URL/header processing and is shared across all hops,
connection reuse, retries and decoding. Every blocking network operation is
clamped to the remaining time. A zero remaining budget fails immediately and
is never sent to an effect as an unlimited timeout.

Synchronous OS DNS and decompression are isolated in the helper. Base's existing
process API terminates and reaps that child on timeout instead of leaving the
operation running. DNS is also bounded by `connect_ms`; decoding by `read_ms`.
Request serialization is charged before the write budget is sampled. No new
C/JS bridge, HTTP service or uncancelled `IO.within` task is introduced.

Timeouts close the active socket, and terminal errors clear the returned pool.
No late successful response is accepted. This provides enforced deadlines for
blocking operations, including DNS/decompression. It is not a real-time return
latency guarantee: bounded parsing, base64 pipe serialization, runtime argument
marshalling, child termination/reaping, cleanup and OS scheduling can add
latency beyond `total_ms`. Bend does not provide preemptive cancellation of
arbitrary in-process pure computations. Helper startup/base64 transfer also
adds overhead on DNS cache misses and compressed responses; pooled identity
requests avoid both after the first connection.

Implementation has been compiled through Bend C generation and native Clang.
Loopback checks through eStoreManager's adapter passed for pooling, gzip,
chunked framing, redirects, Connection: close, stale-socket recovery, and the
shared deadline. An intentionally blocked Bend helper was terminated in about
0.20 seconds. External storefront requests and production deployment have not
been exercised.
