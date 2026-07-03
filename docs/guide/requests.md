# The fetch model

Rata calls outbound HTTP work a **fetch**. The public request description is
`FetchSpec` rather than `Request`, so web frameworks can keep the `Request`
name for inbound server requests.

```saga
pub record FetchSpec {
  method: Method,
  url: String,
  headers: List Header,
  body: Body,
  timeout_ms: Maybe Int,
  follow_redirects: Maybe Bool,
}
```

## Methods

```saga
pub type Method =
  | GET
  | POST
  | PUT
  | PATCH
  | DELETE
  | HEAD
  | OPTIONS
```

Convenience functions build common fetches directly:

```saga
pub fun get : String -> Result Response FetchError needs {Fetch}
pub fun post : String -> Body -> Result Response FetchError needs {Fetch}
pub fun send : FetchSpec -> Result Response FetchError needs {Fetch}
```

Use `send` when you need headers, timeouts, redirects, or any other option on a
prebuilt `FetchSpec`.

## Building a spec

```saga
let spec =
  Fetch.post_spec "https://example.com/messages" (Fetch.text "hello")
  |> Fetch.with_content_type "text/plain"
  |> Fetch.with_accept "application/json"
  |> Fetch.with_timeout 5000
  |> Fetch.with_redirects True

Fetch.send spec
```

`with_header` appends a header. `set_header`, `with_accept`, and
`with_content_type` replace any existing header with the same case-insensitive
name before adding the new value.

## Bodies

```saga
pub type Body =
  | Empty
  | Bytes BitString
  | Text String
```

Helpers cover the common constructors:

```saga
pub fun empty_body : Body
pub fun text : String -> Body
pub fun bytes : BitString -> Body
```

`Text` is encoded as UTF-8. Rata does not infer `Content-Type`; set it
explicitly with `with_content_type`.

## Transport errors

Every fetch returns `Result Response FetchError`.

`FetchError` is reserved for transport, TLS, DNS, timeout, protocol, unsupported
URL, and backend failures. A received HTTP response with status `404` or `500`
is still `Ok(response)`.
