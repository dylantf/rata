# Rata Todo

This is the implementation backlog for the first Rata release. The goal is a
Saga HTTP fetch layer backed by Erlang/OTP `inets:httpc`, with raw response
bodies suitable for downstream JSON decoding.

## Project Setup

- [x] Decide whether Rata is a library-only project or keeps the example binary.
- [x] Enable the `[library]` section in `project.toml`.
- [x] Confirm the Saga library root remains `Rata`, with `Rata.Fetch` exposed.
- [x] If Saga requires a root `Rata` module, keep it package-internal or
      re-export-only and keep the public API under `Rata.Foo` modules.
- [x] Expose the public modules needed for the first release.
- [x] Add a short top-level `README.md` with installation and first fetch.
- [x] Add a changelog file before publishing.
- [x] Confirm Saga package naming conventions for a package named `rata`.
- [x] Confirm whether generated BEAM modules should mirror `Rata.Foo` names.

## Public Module Surface

- [x] Create `lib/Rata/Fetch.saga` for the main user-facing API.
- [x] Create `lib/Rata/Fetch/Httpc.saga` for the `httpc` backend handler.
- [x] Create `lib/Rata/Fetch/Mock.saga` for test handlers.
- [x] Decide whether to split helpers into `Rata.Fetch.Spec`,
      `Rata.Fetch.Response`, and `Rata.Fetch.Body` in v1.
- [x] If split modules are used, re-export common helpers from `Rata.Fetch`.
- [x] Ensure every public module begins with `Rata.`.

## Core Types

- [x] Define `Method`.
- [x] Include `GET`.
- [x] Include `POST`.
- [x] Include `PUT`.
- [x] Include `PATCH`.
- [x] Include `DELETE`.
- [x] Include `HEAD`.
- [x] Include `OPTIONS`.
- [x] Decide whether to support custom methods in v1.
- [x] Define `Body`.
- [x] Include `Empty`.
- [x] Include `Bytes(BitString)`.
- [x] Include `Text(String)`.
- [x] Decide whether `Body` should include form bodies in v1.
- [x] Define `Header`.
- [x] Define `FetchSpec`.
- [x] Add `method : Method`.
- [x] Add `url : String`.
- [x] Add `headers : List Header`.
- [x] Add `body : Body`.
- [x] Add `timeout_ms : Maybe Int`.
- [x] Add `follow_redirects : Maybe Bool`.
- [x] Decide whether to add `max_redirects : Maybe Int`.
- [x] Decide whether to add proxy fields in v1.
- [x] Define `Response`.
- [x] Decide whether `Response` should be renamed to `FetchResponse` to avoid
      web framework naming conflicts.
- [x] Add `status : Int`.
- [x] Add `reason : String`.
- [x] Add `headers : List Header`.
- [x] Add `body : BitString`.
- [x] Define `FetchError`.
- [x] Include `InvalidUrl(String)`.
- [x] Include `Timeout`.
- [x] Include `TlsError(String)`.
- [x] Include `ConnectionError(String)`.
- [x] Include `DnsError(String)`.
- [x] Include `ProtocolError(String)`.
- [x] Include `TooManyRedirects`.
- [x] Include `Unsupported(String)`.
- [x] Include `BackendError(String)`.
- [x] Define `FetchStatusError`.
- [x] Include `UnexpectedStatus(Int, Response)`.
- [x] Decide whether errors should derive `Show` and `Eq`.
- [x] Decide whether response records should derive `Show` and `Eq`.

## Fetch Effect

- [x] Define `effect Fetch`.
- [x] Add primitive operation `fetch : FetchSpec -> Result Response FetchError`.
- [x] Do not add a same-name public helper around `fetch!`.
- [x] Confirm naming to avoid conflict between effect operation and helpers.
- [x] Decide whether to expose a lower-level unsafe fetch function.
- [x] Document that `FetchError` is only for transport/backend failures.

## FetchSpec Builders

- [x] Implement `empty_spec : Method -> String -> FetchSpec`.
- [x] Implement `get_spec : String -> FetchSpec`.
- [x] Implement `post_spec : String -> Body -> FetchSpec`.
- [x] Implement `put_spec : String -> Body -> FetchSpec`.
- [x] Implement `patch_spec : String -> Body -> FetchSpec`.
- [x] Implement `delete_spec : String -> FetchSpec`.
- [x] Implement `head_spec : String -> FetchSpec`.
- [x] Implement `options_spec : String -> FetchSpec`.
- [x] Implement `with_header : String -> String -> FetchSpec -> FetchSpec`.
- [x] Implement `with_headers : List Header -> FetchSpec -> FetchSpec`.
- [x] Implement `set_header : String -> String -> FetchSpec -> FetchSpec`.
- [x] Implement `with_body : Body -> FetchSpec -> FetchSpec`.
- [x] Implement `with_timeout : Int -> FetchSpec -> FetchSpec`.
- [x] Implement `with_redirects : Bool -> FetchSpec -> FetchSpec`.
- [x] Implement `with_accept : String -> FetchSpec -> FetchSpec`.
- [x] Implement `with_content_type : String -> FetchSpec -> FetchSpec`.
- [x] Decide whether builders validate timeout values.

## Convenience Fetch Functions

- [x] Implement `get : String -> Result Response FetchError needs {Fetch}`.
- [x] Implement `delete : String -> Result Response FetchError needs {Fetch}`.
- [x] Implement `head : String -> Result Response FetchError needs {Fetch}`.
- [x] Implement `options : String -> Result Response FetchError needs {Fetch}`.
- [x] Implement `post : String -> Body -> Result Response FetchError needs {Fetch}`.
- [x] Implement `put : String -> Body -> Result Response FetchError needs {Fetch}`.
- [x] Implement `patch : String -> Body -> Result Response FetchError needs {Fetch}`.
- [x] Implement `send : FetchSpec -> Result Response FetchError needs {Fetch}`.
- [x] Use `send spec` for prebuilt `FetchSpec` values in user code.
- [x] Decide naming for "send this prebuilt fetch spec" versus effect operation.

## Body Helpers

- [x] Implement `empty_body : Body`.
- [x] Implement `text : String -> Body`.
- [x] Implement `bytes : BitString -> Body`.
- [x] Implement `body_to_bytes : Body -> BitString`.
- [x] Implement UTF-8 conversion for `Text`.
- [x] Decide whether text conversion can fail.
- [x] Add `content_length` helper if useful.
- [ ] Add `form_urlencoded` only after URL encoding helpers exist.
- [x] Keep JSON helpers out of Rata.

## Response Helpers

- [x] Implement case-insensitive header name comparison.
- [x] Implement `header : String -> Response -> Maybe String`.
- [x] Implement `headers : String -> Response -> List String`.
- [x] Implement `content_type : Response -> Maybe String`.
- [x] Implement `content_length : Response -> Maybe Int`.
- [x] Implement `body_text : Response -> Result String String`.
- [x] Implement `is_informational : Response -> Bool`.
- [x] Implement `is_success : Response -> Bool`.
- [x] Implement `is_redirect : Response -> Bool`.
- [x] Implement `is_client_error : Response -> Bool`.
- [x] Implement `is_server_error : Response -> Bool`.
- [x] Implement `expect_status : Int -> Response -> Result Response FetchStatusError`.
- [x] Implement `expect_success : Response -> Result Response FetchStatusError`.
- [x] Decide whether `expect_success` means 200-299 only.
- [x] Decide whether `HEAD` responses should get special helpers.

## Status Code API

- [x] Decide whether to expose common status constants.
- [x] Add `status_ok : Int`.
- [x] Add `status_created : Int`.
- [x] Add `status_no_content : Int`.
- [x] Add `status_bad_request : Int`.
- [x] Add `status_unauthorized : Int`.
- [x] Add `status_forbidden : Int`.
- [x] Add `status_not_found : Int`.
- [x] Add `status_conflict : Int`.
- [x] Add `status_too_many_requests : Int`.
- [x] Add `status_internal_server_error : Int`.
- [x] Add `status_bad_gateway : Int`.
- [x] Add `status_service_unavailable : Int`.
- [x] Decide whether status constants belong in `Rata.Fetch.Status`.

## `httpc` Interop

- [x] Read the Saga interop guide before implementing backend calls.
- [x] Confirm syntax for calling Erlang functions from Saga.
- [x] Confirm how Saga `String` maps to Erlang values.
- [x] Confirm how Saga `BitString` maps to Erlang binaries.
- [x] Confirm how Erlang tuples, lists, atoms, and binaries appear in Saga.
- [x] Add any required foreign declarations for `httpc:request`.
- [x] Add any required foreign declarations for `application:ensure_all_started`.
- [x] Add any required foreign declarations for URL or binary conversion helpers.
- [x] Convert `Method` to Erlang method atoms.
- [x] Convert Saga headers to `httpc` request headers.
- [x] Convert `Body` to the shape expected by `httpc`.
- [x] Convert `timeout_ms` to `httpc` options.
- [x] Convert `follow_redirects` to `httpc` options.
- [x] Decide whether to use the default `httpc` profile.
- [x] Decide whether to create a named Rata `httpc` profile.
- [x] Ensure `inets` is started before the first request.
- [x] Ensure `ssl` is started before HTTPS requests.
- [x] Decide whether startup happens on every request or in handler setup.
- [x] Call `httpc:request`.
- [x] Convert successful `httpc` response tuple to `Response`.
- [x] Preserve response status code.
- [x] Preserve response reason phrase when available.
- [x] Preserve response headers as `List Header`.
- [x] Preserve response body as `BitString`.
- [x] Convert `{error, timeout}` to `Timeout`.
- [x] Convert DNS failures to `DnsError`.
- [x] Convert TLS failures to `TlsError`.
- [x] Convert connection failures to `ConnectionError`.
- [x] Convert redirect exhaustion to `TooManyRedirects`.
- [x] Convert malformed backend returns to `BackendError`.
- [x] Catch backend exceptions and convert them to `BackendError`.
- [ ] Add logging hooks later only if Saga has an appropriate effect story.

## TLS and Security

- [x] Decide default TLS verification behavior.
- [x] Prefer certificate verification on by default.
- [ ] Add `verify_tls : Bool` to backend options if `httpc` supports it cleanly.
- [x] Decide whether to expose CA certificate configuration.
- [x] Decide whether to expose client certificate configuration.
- [x] Decide whether to expose proxy configuration.
- [x] Document any `httpc` TLS limitations.
- [ ] Test HTTPS against a known endpoint.
- [x] Test bad certificate behavior if practical.

## Redirects

- [ ] Decide default redirect behavior.
- [x] Add per-request redirect override.
- [ ] Decide default maximum redirects.
- [x] Map redirect exhaustion to `TooManyRedirects`.
- [ ] Document that redirected response history is not available in v1.
- [ ] Decide whether future `Response` should include final URL.

## Timeouts

- [ ] Decide default timeout.
- [x] Support per-request timeout.
- [ ] Decide whether to expose connect timeout separately.
- [ ] Decide whether to expose receive timeout separately.
- [x] Map timeout failures to `Timeout`.
- [ ] Test timeout behavior with a slow local endpoint.

## Mock/Test Backend

- [x] Implement handler that always returns a response.
- [x] Implement handler that always returns an error.
- [x] Implement route-based handler.
- [x] Match routes by method and URL.
- [x] Decide whether route matching should include headers.
- [x] Decide whether route matching should consume routes in order.
- [x] Add helper for building test responses.
- [x] Add helper for building test errors.
- [x] Add docs showing downstream code tested with `needs {Fetch}`.

## Tests

- [x] Add tests for fetch builders.
- [x] Add tests for header append behavior.
- [x] Add tests for case-insensitive header lookup.
- [x] Add tests for status classification helpers.
- [x] Add tests for `expect_status`.
- [x] Add tests for `expect_success`.
- [x] Add tests for body conversion.
- [x] Add tests for mock handler success.
- [x] Add tests for mock handler failure.
- [x] Add tests for mock route matching.
- [ ] Add integration test for plain HTTP using `httpc`.
- [ ] Add integration test for HTTPS using `httpc`.
- [ ] Add integration test for timeout behavior.
- [ ] Add integration test for redirect behavior.
- [ ] Add integration test that 404 returns `Ok(Response)`.
- [ ] Keep network integration tests skippable or local-only for CI stability.

## Documentation

- [x] Document the core model: transport errors versus status errors.
- [x] Document all public modules.
- [x] Document all public types.
- [x] Document all public functions.
- [x] Include a minimal GET example.
- [x] Include a POST with headers example.
- [x] Include a JSON decode example using an external JSON library.
- [x] Include a mock handler testing example.
- [x] Include notes on `httpc` as the initial backend.
- [x] Include notes on future backend compatibility.

## Examples

- [x] Add `examples/get.saga`.
- [x] Add `examples/post.saga`.
- [x] Add `examples/status.saga`.
- [x] Add `examples/json_decode.saga`.
- [x] Add `examples/mock_test.saga`.
- [x] Ensure examples use modules beginning with `Rata.` only for library code.

## Release Criteria

- [x] `saga build` passes.
- [x] `saga test` passes.
- [x] Public modules are exposed in `project.toml`.
- [ ] Basic GET works against HTTP.
- [ ] Basic GET works against HTTPS.
- [ ] POST with text body works.
- [ ] POST with binary body works.
- [ ] Headers round-trip correctly.
- [ ] 404 returns `Ok(Response)` and can be handled with `expect_success`.
- [ ] Timeout returns `Err(Timeout)`.
- [x] Mock handler can test user code without network access.
- [x] README has at least one complete runnable example.

## Future Features

- [ ] Add `Rata.Fetch.Hackney` backend.
- [ ] Add connection pooling options.
- [ ] Add streaming response support.
- [ ] Add streaming request body support.
- [ ] Add multipart form support.
- [ ] Add cookie helpers.
- [ ] Add auth helpers for bearer tokens.
- [ ] Add auth helpers for basic auth.
- [ ] Add retry helpers as pure combinators over `needs {Fetch}`.
- [ ] Add rate-limit helpers if a general time/sleep effect exists.
- [ ] Add `Rata.Fetch.Gun` backend for persistent connections.
- [ ] Add WebSocket support, probably outside the one-shot request API.
- [ ] Add HTTP/2 support through a backend that supports it well.
- [ ] Add response history for redirects.
- [ ] Add tracing/instrumentation hooks once Saga has a standard pattern.
