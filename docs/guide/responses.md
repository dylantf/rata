# The response model

```saga
pub record Response {
  status: Int,
  reason: String,
  headers: List Header,
  body: BitString,
}
```

`Response` represents a response received from the server. HTTP status codes are
not transport errors in Rata, so `404`, `409`, and `500` all arrive as
`Ok(response)` when the network request completed successfully.

## Status helpers

```saga
pub fun is_success : Response -> Bool
pub fun is_redirect : Response -> Bool
pub fun is_client_error : Response -> Bool
pub fun is_server_error : Response -> Bool
pub fun expect_status : Int -> Response -> Result Response FetchStatusError
pub fun expect_success : Response -> Result Response FetchStatusError
```

Use `expect_success` when an application branch wants to reject non-2xx
responses:

```saga
case Fetch.get "https://example.com/data.json" {
  Err error -> dbg error
  Ok response -> case Fetch.expect_success response {
    Ok successful -> dbg successful.status
    Err status_error -> dbg status_error
  }
}
```

## Headers

Response headers are preserved as a list of `Header` records:

```saga
pub record Header {
  name: String,
  value: String,
}
```

Lookup helpers are case-insensitive:

```saga
pub fun header : String -> Response -> Maybe String
pub fun headers : String -> Response -> List String
pub fun content_type : Response -> Maybe String
pub fun content_length : Response -> Maybe Int
```

`header` returns the first matching value. Use `headers` for values that may
repeat, such as `Set-Cookie`.

## Bodies

Response bodies are raw `BitString` values:

```saga
response.body
```

For UTF-8 text responses, use:

```saga
pub fun body_text : Response -> Result String String
```

The conversion can fail because HTTP bodies can be arbitrary bytes. JSON
decoding belongs in your JSON library or application layer:

```saga
case Fetch.expect_success response {
  Ok successful -> decode_json successful.body
  Err status_error -> Err status_error
}
```
