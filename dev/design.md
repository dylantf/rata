# Rata Fetch Design

Rata is a Saga HTTP client library. The first backend will wrap Erlang/OTP
`inets:httpc`, but the public API should not expose `httpc` details. User code
should depend on Rata's Saga records, ADTs, helpers, and `Fetch` effect.

All public modules must begin with `Rata.Foo`, such as `Rata.Fetch` or
`Rata.Fetch.Httpc`.

## Goals

- Provide a small, idiomatic Saga API for making HTTP requests.
- Return raw response bodies as `BitString` so JSON, text, binary, and custom
  decoders can live outside the transport layer.
- Treat HTTP status codes as successful responses, not transport failures.
- Make the backend swappable: `httpc` first, `hackney` or `gun` later.
- Keep convenience helpers layered over one primitive fetch operation.
- Support tests through effect handlers without making network calls.
- Avoid public `Request` naming; web frameworks should own that vocabulary.

## Non-Goals

- JSON decoding. A pure Saga JSON library already exists.
- WebSocket support in the first version.
- HTTP/2 or HTTP/3 in the first version.
- Streaming outgoing or response bodies in the first version.
- Browser/fetch support. Rata targets the BEAM first.

## Module Map

### `Rata.Fetch`

Primary user-facing module. Exposes the core types, the `Fetch` effect, fetch
builders, response helpers, and status helpers.

Suggested exports:

```saga
module Rata.Fetch

pub type Method =
  | GET
  | POST
  | PUT
  | PATCH
  | DELETE
  | HEAD
  | OPTIONS

pub type Body =
  | Empty
  | Bytes(BitString)
  | Text(String)

pub record Header {
  name : String,
  value : String,
}

pub record FetchSpec {
  method : Method,
  url : String,
  headers : List Header,
  body : Body,
  timeout_ms : Maybe Int,
  follow_redirects : Maybe Bool,
}

pub record Response {
  status : Int,
  reason : String,
  headers : List Header,
  body : BitString,
}

pub type FetchError =
  | InvalidUrl(String)
  | Timeout
  | TlsError(String)
  | ConnectionError(String)
  | DnsError(String)
  | ProtocolError(String)
  | TooManyRedirects
  | Unsupported(String)
  | BackendError(String)

pub type FetchStatusError =
  | UnexpectedStatus(Int, Response)

pub effect Fetch {
  fun fetch : FetchSpec -> Result Response FetchError
}
```

Core helper functions:

```saga
pub fun get : String -> Result Response FetchError needs {Fetch}
pub fun delete : String -> Result Response FetchError needs {Fetch}
pub fun head : String -> Result Response FetchError needs {Fetch}
pub fun post : String -> Body -> Result Response FetchError needs {Fetch}
pub fun put : String -> Body -> Result Response FetchError needs {Fetch}
pub fun patch : String -> Body -> Result Response FetchError needs {Fetch}
pub fun send : FetchSpec -> Result Response FetchError needs {Fetch}

pub fun with_header : String -> String -> FetchSpec -> FetchSpec
pub fun with_headers : List Header -> FetchSpec -> FetchSpec
pub fun with_timeout : Int -> FetchSpec -> FetchSpec
pub fun with_redirects : Bool -> FetchSpec -> FetchSpec
pub fun with_body : Body -> FetchSpec -> FetchSpec

pub fun header : String -> Response -> Maybe String
pub fun headers : String -> Response -> List String
pub fun content_type : Response -> Maybe String
pub fun content_length : Response -> Maybe Int
pub fun body_text : Response -> Result String String
pub fun is_success : Response -> Bool
pub fun is_redirect : Response -> Bool
pub fun is_client_error : Response -> Bool
pub fun is_server_error : Response -> Bool
pub fun expect_status : Int -> Response -> Result Response FetchStatusError
pub fun expect_success : Response -> Result Response FetchStatusError
```

`fetch` is the only primitive effect operation and should be called internally
as `fetch!`. Do not add a same-name public function wrapper around it; that
shadows the effect operation. Use `send` for user code that already has a
prebuilt `FetchSpec`.

### `Rata.Fetch.Spec`

Optional focused module for fetch builders if `Rata.Fetch` grows too large.
This can re-export or define the builder functions listed above.

Potential exports:

```saga
pub fun empty : Method -> String -> FetchSpec
pub fun get : String -> FetchSpec
pub fun post : String -> Body -> FetchSpec
pub fun put : String -> Body -> FetchSpec
pub fun patch : String -> Body -> FetchSpec
pub fun delete : String -> FetchSpec
pub fun head : String -> FetchSpec
pub fun options : String -> FetchSpec
```

### `Rata.Fetch.Response`

Optional focused module for response utilities.

Potential exports:

```saga
pub fun header : String -> Response -> Maybe String
pub fun headers : String -> Response -> List String
pub fun content_type : Response -> Maybe String
pub fun content_length : Response -> Maybe Int
pub fun body_text : Response -> Result String String
pub fun status_class : Response -> StatusClass
pub fun expect_status : Int -> Response -> Result Response FetchStatusError
pub fun expect_success : Response -> Result Response FetchStatusError
```

### `Rata.Fetch.Body`

Helpers for outgoing and response bodies. This module must not depend on JSON.

Potential exports:

```saga
pub fun empty : Body
pub fun text : String -> Body
pub fun bytes : BitString -> Body
pub fun form_urlencoded : List (String, String) -> Body
pub fun to_bytes : Body -> BitString
```

If Saga gains standard URL encoding helpers, `form_urlencoded` can live here.
Until then, keep it out or implement it carefully.

### `Rata.Fetch.Httpc`

Backend handler for Erlang/OTP `inets:httpc`.

Suggested exports:

```saga
module Rata.Fetch.Httpc

pub handler httpc for Fetch
pub fun with_options : HttpcOptions -> Handler Fetch

pub record HttpcOptions {
  profile : Maybe String,
  default_timeout_ms : Maybe Int,
  default_follow_redirects : Maybe Bool,
  verify_tls : Bool,
}
```

Exact handler factory syntax may need to follow the current Saga handler
patterns. Conceptually, the module owns:

- Starting required OTP applications: `inets` and `ssl` when needed.
- Converting Saga `FetchSpec` into `httpc:request` arguments.
- Converting `httpc` response tuples into Saga `Response`.
- Converting `httpc` errors into `FetchError`.
- Hiding Erlang tuple/list/string/binary quirks from user code.

### `Rata.Fetch.Mock`

Test handler for deterministic tests.

Potential exports:

```saga
pub fun always : Response -> Handler Fetch
pub fun failing : FetchError -> Handler Fetch
pub fun routes : List Route -> Handler Fetch
pub fun route_response : Method -> String -> Response -> Route
pub fun route_error : Method -> String -> FetchError -> Route
pub fun empty_response : Int -> Response
pub fun text_response : Int -> String -> Response
pub fun bytes_response : Int -> List Header -> BitString -> Response

pub record Route {
  method : Method,
  url : String,
  response : Result Response FetchError,
}
```

This lets downstream libraries test code using `needs {Fetch}` without network
access. Routes match by method and exact URL only in v1. Headers and body are
not part of matching, and routes are reusable rather than consumed.

## FetchSpec Semantics

`FetchSpec` should be a pure value. It should include enough information to make
a single outbound HTTP fetch, but not backend-specific process state.

Initial fields:

- `method`: HTTP method ADT.
- `url`: absolute URL as a string.
- `headers`: ordered list of headers.
- `body`: empty, bytes, or text.
- `timeout_ms`: per-request timeout override.
- `follow_redirects`: per-request redirect override.

Do not normalize or validate the URL in builders. Validation belongs in the
backend handler so all malformed backend failures are reported consistently as
`InvalidUrl` or `Unsupported`.

## Response Semantics

`Response` should represent an HTTP response even when the status is `404` or
`500`. The transport operation succeeds if a response was received.

`Result Response FetchError` should only be `Err` for failures such as:

- Invalid or unsupported URL.
- DNS failure.
- TCP connection failure.
- TLS setup or certificate failure.
- Timeout.
- Malformed protocol response.
- Backend crash or unexpected backend return shape.

Status interpretation is pure and explicit:

```saga
do {
  Ok(response) <- get "https://example.com"
  Ok(ok) <- expect_success response
  Ok(value) <- Json.decode decoder ok.body
  Ok(value)
} else {
  Err(e) -> Err(e)
}
```

## Header Semantics

Headers are represented as a list of `{name, value}` pairs.

Rules:

- Preserve response header order where possible.
- Lookups are case-insensitive.
- `header` returns the first matching value.
- `headers` returns all matching values.
- Do not merge repeated headers by default.
- Fetch builders append headers rather than replacing them.

Potential future helper:

```saga
pub fun set_header : String -> String -> FetchSpec -> FetchSpec
```

`set_header` would remove existing headers with the same case-insensitive name
before adding the new one.

## Body Semantics

Outgoing bodies:

- `Empty` sends no body.
- `Bytes` sends a binary body.
- `Text` encodes as UTF-8 bytes.

Rata should not guess `Content-Type` for arbitrary bodies. Convenience helpers
may add headers explicitly:

```saga
pub fun text_plain : String -> Body
pub fun with_content_type : String -> FetchSpec -> FetchSpec
```

Response bodies:

- Always expose raw body as `BitString`.
- Text decoding belongs in helpers that can fail.
- JSON decoding belongs in the user's existing JSON library.

## Error Model

Keep `FetchError` transport-focused. Suggested variants:

- `InvalidUrl(String)`
- `Timeout`
- `TlsError(String)`
- `ConnectionError(String)`
- `DnsError(String)`
- `ProtocolError(String)`
- `TooManyRedirects`
- `Unsupported(String)`
- `BackendError(String)`

Avoid putting response status into `FetchError`. Use `FetchStatusError` for
explicit status expectations.

## `httpc` Backend Plan

Use OTP `inets:httpc` first because it ships with Erlang/OTP and avoids adding a
dependency story before the Saga API is settled.

Expected implementation outline:

1. Ensure `inets` is started before the first request.
2. Ensure `ssl` is started for HTTPS requests.
3. Convert Saga method constructors to Erlang method atoms.
4. Convert Saga headers to `httpc` header tuples.
5. Convert Saga body to the request form expected by `httpc`.
6. Pass timeout, redirect, and HTTPS TLS options through `http_options`.
7. Call `httpc:request`.
8. Convert status line, headers, and body back to `Response`.
9. Map known `{error, Reason}` values to `FetchError`.
10. Catch unexpected backend exceptions and return `BackendError`.

### TLS Behavior

The `httpc` backend uses certificate verification for HTTPS by default. The
bridge passes `httpc:ssl_verify_host_options(true)` for HTTPS requests, which
uses OS CA certificates through `public_key:cacerts_get()` and enables HTTPS
hostname verification, including wildcard hostname matching.

Rata does not currently expose a public `verify_tls : Bool` option. Disabling
verification, custom CA bundles, client certificates, and proxy TLS behavior are
future backend options rather than part of the first public `FetchSpec`.

TLS setup, certificate validation, and hostname verification failures map to
`TlsError(String)` where `httpc` exposes enough reason detail. Rata inherits
`httpc` and OTP `ssl` behavior, including reliance on an available OS CA bundle
for public HTTPS verification.

Open questions to verify in implementation:

- The exact Saga interop syntax for calling Erlang modules.
- Whether Saga strings map to Erlang strings, binaries, or need explicit
  conversion at the boundary.
- Whether `BitString` maps directly to Erlang binaries in foreign calls.
- How to package `inets` and `ssl` application startup in a handler.
- Whether `httpc` should use the default profile or a private profile.
- Whether `Response` should become `FetchResponse` before implementation if it
  conflicts with the web framework's response type.

## Future Backends

### `Rata.Fetch.Hackney`

Possible production backend once dependency management is wanted.

Reasons to add:

- Connection pooling.
- Better streaming support.
- More modern HTTP client ergonomics.
- Potentially better behavior under concurrent load.

### `Rata.Fetch.Gun`

Possible advanced backend for persistent connections, HTTP/2, WebSockets, and
streaming. This may deserve a separate client abstraction instead of sharing the
simple one-shot fetch API.

## Example User Code

```saga
module Example

import Rata.Fetch (Fetch, get, expect_success)
import Rata.Fetch.Httpc (httpc)

pub fun fetch_user : String -> Result User FetchError needs {Fetch}
fetch_user id =
  do {
    Ok(response) <- get ($"https://api.example.com/users/{id}")
    Ok(ok) <- expect_success response
    Ok(user) <- Json.decode User.decoder ok.body
    Ok(user)
  } else {
    Err(e) -> Err(e)
  }

main () = {
  fetch_user "42"
} with httpc
```

The exact `do...else` error shape may need small adjustment once the real JSON
decoder and error union are chosen.
