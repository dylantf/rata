# Changelog

## Unreleased

- Started the `Rata.Fetch` public API.
- Added the initial Erlang/OTP `inets:httpc` bridge.
- Added `Rata.Fetch.Mock` handlers and route helpers for network-free tests.
- Enabled explicit HTTPS certificate and hostname verification in the `httpc`
  bridge.
- Added `Fetch.send` for user code that already has a `FetchSpec`.
- Added `Debug` deriving for public fetch types and example programs.
