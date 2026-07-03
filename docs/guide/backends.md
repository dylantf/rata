# Backends

Rata's public fetch API is backend-neutral. The effect in `Rata.Fetch` describes
the operation:

```saga
pub effect Fetch {
  fun fetch : FetchSpec -> Result Response FetchError
}
```

Backend modules provide handlers for that effect.

## `Rata.Fetch.Httpc`

The first backend wraps Erlang/OTP `inets:httpc`:

```saga
import Rata.Fetch as Fetch
import Rata.Fetch.Httpc as Httpc

main () = {
  Fetch.get "https://example.com"
} with Httpc.httpc
```

The lower-level `Httpc.request` function is also public for direct backend
checks:

```saga
pub fun request : FetchSpec -> Result Response FetchError
```

Most application code should prefer the effectful `Fetch.get`, `Fetch.post`,
and `Fetch.send` helpers with `Httpc.httpc` at the boundary.

## TLS

HTTPS requests verify certificates by default through OTP TLS options and the
operating system CA store. TLS setup, certificate validation, and hostname
verification failures are returned as `Fetch.TlsError`.

Rata does not currently expose options for disabling verification, custom CA
bundles, client certificates, proxies, connection pooling, or a private `httpc`
profile. Those belong to future backend options, not the core `FetchSpec`.

## Future backends

Additional backend modules can implement the same `Fetch` effect without
changing user code:

```saga
} with SomeOtherBackend.handler
```

The core API intentionally returns raw bytes and ordinary Saga records so later
backends do not leak their Erlang-specific shapes into application code.
