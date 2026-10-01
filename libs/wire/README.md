# Vendored bend-kit-wire

This is bend-kit-wire 0.4.3.0 from `paymog/bend-kit`, source commit
`b1afc39ff743cc889e0d9fb1465bbedd4856bf70` (2026-09-29 checkout). The HTTP
library vendors it so the local deadline extension can be reviewed and built
with the project. Upstream source is in `wire.bend` and `effs/`.

Local additions:

- `Wire.send.timeout` and `Wire.tls.send.timeout` apply one deadline across the
  full write and return `ETIMEDOUT` when a TCP/TLS write remains blocked.

The original no-deadline send functions remain available. TLS certificate and
hostname verification are unchanged. The C and JavaScript effects both need to
stay in sync when editing the write path.
