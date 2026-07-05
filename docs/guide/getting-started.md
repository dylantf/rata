# Getting started

A how-to for making HTTP requests from Saga code with Rata. The intended
consumer is an application or library author who wants a typed HTTP client on
the BEAM. Rata handles outbound HTTP transport.

For language syntax see
[`llms-full.txt`](../../../saga-website/public/llms-full.txt).

## Quick start

```saga
module Main

import Rata.Fetch as Fetch
import Rata.Fetch.Httpc as Httpc

main () = {
  case Fetch.get "https://example.com" {
    Ok response -> {
      dbg response.status
      dbg (Fetch.body_text response)
    }
    Err error -> dbg error
  }
} with Httpc.httpc
```

The `Httpc.httpc` handler satisfies the `Fetch` effect by calling Erlang/OTP
`inets:httpc`. Code that calls `Fetch.get`, `Fetch.post`, or `Fetch.send` can
stay backend-neutral and choose a real or mock handler at the boundary.

## Scope

Rata handles:

- building outbound fetch descriptions,
- running them through a backend handler,
- returning response status, headers, and raw body bytes,
- mapping transport/backend failures into `FetchError`,
- testing `needs {Fetch}` code without network access.

Response bodies are `BitString` values; pass them to your JSON library or
application decoder for structured data.

## Install

For local development, use a path dependency:

```toml
[deps]
rata = { path = "/home/dylan/projects/rata" }
```

The public library modules are:

```saga
Rata.Fetch
Rata.Fetch.Httpc
Rata.Fetch.Mock
```
