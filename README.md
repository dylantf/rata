<p align="center">
  <img src="dev/rata.png" alt="Rata logo" width="180">
</p>

# Rata

Rata is a small Saga HTTP client library for the BEAM. It gives Saga programs a
typed, effect-based `fetch` layer with a first backend built on Erlang/OTP
`inets:httpc`.

The name comes from Ratatoskr, the messenger of Norse myth who runs up and down
Yggdrasil carrying words between worlds. Rata does the less dramatic version:
it carries HTTP messages between Saga code and remote services.

## What It Provides

- A backend-neutral `Rata.Fetch` API.
- An `Rata.Fetch.Httpc.httpc` handler backed by OTP `inets:httpc`.
- Typed request descriptions through `FetchSpec`.
- Raw response bodies as `BitString`, with `Fetch.body_text` for UTF-8 text.
- Status helpers such as `expect_success`, `header`, and `content_type`.
- A pure `Rata.Fetch.Mock` backend for tests.

Rata does not decode JSON. Pass `response.body` to your JSON library or
application decoder.

## Install

While Rata is local, add it as a path dependency:

```toml
[deps]
rata = { path = "/home/dylan/projects/rata" }
```

## Quick Start

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

`Fetch.get`, `Fetch.post`, and `Fetch.send` return
`Result Fetch.Response Fetch.FetchError`.

HTTP status codes are not transport errors. A received `404` or `500` is still
`Ok(response)`. Use `Fetch.expect_success` or `Fetch.expect_status` when caller
code wants to treat statuses as explicit errors.

## POST

```saga
import Rata.Fetch as Fetch
import Rata.Fetch.Httpc as Httpc

main () = {
  let spec =
    Fetch.post_spec "https://example.com" (Fetch.text "hello")
    |> Fetch.with_content_type "text/plain"
    |> Fetch.with_accept "text/plain"

  case Fetch.send spec {
    Ok response -> dbg response.status
    Err error -> dbg error
  }
} with Httpc.httpc
```

## Testing

Use `Rata.Fetch.Mock` to test code that needs `Fetch` without making real
network requests:

```saga
import Rata.Fetch as Fetch
import Rata.Fetch.Mock as Mock

fun check_status : String -> Result Int Fetch.FetchError needs {Fetch.Fetch}
check_status url = case Fetch.get url {
  Ok response -> Ok response.status
  Err error -> Err error
}

fun demo : Unit -> Unit
demo () = {
  let mock = Mock.always (Mock.text_response Fetch.status_ok "ok")

  dbg (check_status "https://example.com" with mock)
}
```

## Guide

- [Getting started](docs/guide/getting-started.md)
- [The fetch model](docs/guide/requests.md)
- [The response model](docs/guide/responses.md)
- [Backends](docs/guide/backends.md)
- [Testing](docs/guide/testing.md)

See `dev/design.md` for the design notes and `dev/todo.md` for the current
implementation checklist.
