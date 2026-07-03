# Testing

Use `Rata.Fetch.Mock` when code needs `{Fetch}` but tests should not make
network requests.

## Always return one response

```saga
import Rata.Fetch as Fetch
import Rata.Fetch.Mock as Mock

fun check_status : String -> Result Int Fetch.FetchError needs {Fetch.Fetch}
check_status url = case Fetch.get url {
  Ok response -> Ok response.status
  Err error -> Err error
}

fun test_demo () = {
  let mock = Mock.always (Mock.text_response Fetch.status_ok "ok")

  dbg (check_status "https://example.com" with mock)
}
```

`Mock.always` is useful when the URL does not matter and the caller only needs
some successful response.

## Always fail

```saga
let mock = Mock.failing Fetch.Timeout
```

Use this for transport error branches: timeout, DNS failure, TLS failure,
unsupported schemes, and backend errors.

## Route matching

Routes match by method and exact URL:

```saga
let mock =
  Mock.routes [
    Mock.route_response
      Fetch.GET
      "https://example.com/users"
      (Mock.text_response Fetch.status_ok "users"),
    Mock.route_error
      Fetch.POST
      "https://example.com/users"
      Fetch.Timeout,
  ]
```

Headers and body are not part of route matching in v1. If no route matches, the
mock returns `BackendError` with the method and URL in the message.

## Response helpers

```saga
pub fun empty_response : Int -> Response
pub fun text_response : Int -> String -> Response
pub fun bytes_response : Int -> List Header -> BitString -> Response
```

`text_response` sets `content-type: text/plain; charset=utf-8`. `bytes_response`
uses exactly the headers and body you provide.
