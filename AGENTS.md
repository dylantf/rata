# Repository Guidelines

## Project Structure & Module Organization

Rata is a Saga HTTP client library for the BEAM. The initial backend wraps
Erlang/OTP `inets:httpc`, while the public API stays backend-neutral.

Library modules live under `lib/`. Public library modules must begin with `Rata.`.
The first planned modules are
`Rata.Fetch`, `Rata.Fetch.Httpc`, and `Rata.Fetch.Mock`. Keep user-facing HTTP
types, helpers, and the `Fetch` effect in `Rata.Fetch`; keep backend interop in
backend-specific modules such as `Rata.Fetch.Httpc`.

Planning documents live in `dev/`:

- `dev/design.md`: architectural design and API surface.
- `dev/todo.md`: implementation checklist and release criteria.

The current demo entry point is `src/Main.saga`. Keep reusable library code in
`lib/`; keep examples and demo code separate from reusable modules.

## Build, Test, and Development Commands

- `saga fmt <filename>`: format changed Saga source files.
- `saga build`: compile the project. Run this before handing back code changes
  when the compiler is expected to work.
- `saga test`: run the `Std.Test` suite once tests exist.
- `saga run`: run the demo binary from `src/Main.saga`, if the binary remains
  enabled in `project.toml`.

Use `~/projects/saga-website/public/llms.txt` as the Saga guide index, and
`~/projects/saga-website/public/syntax-reference.md` as the compact syntax
reference.

## Coding Style & Naming Conventions

Use idiomatic Saga style: two-space indentation inside records, handlers, and
case arms; `snake_case` function names; `PascalCase` types and variants. Keep
public APIs small, typed, and documented with `#@` comments when they are meant
for generated reference docs.

Prefer ordinary Saga records, ADTs, functions, and effects over backend-shaped
abstractions. The public Rata API should expose raw response bodies as
`BitString`; JSON decoding belongs to downstream JSON libraries.

HTTP status codes are not transport errors. `fetch` should return `Ok(Response)`
for received `4xx` and `5xx` responses, and reserve `FetchError` for transport,
TLS, DNS, timeout, protocol, or backend failures. Avoid public `Request` naming;
use `FetchSpec` for the outbound client fetch description.

## Testing Guidelines

Prefer pure tests for fetch builders, header lookup, status helpers, body
conversion, and mock handlers. Keep network integration tests isolated and easy
to skip in CI.

When implementing `Rata.Fetch.Httpc`, include integration coverage for:

- plain HTTP GET,
- HTTPS GET,
- POST with text and binary bodies,
- response headers,
- redirects,
- timeout mapping,
- a `404` returning `Ok(Response)`.

Use `Rata.Fetch.Mock` for downstream tests that need `needs {Fetch}` without real
network access.

## Agent-Specific Instructions

Read `dev/design.md` and `dev/todo.md` before making architectural changes.
Keep all public modules under the `Rata.` namespace. Do not add JSON decoding to
Rata; keep the fetch layer focused on HTTP transport and raw response bodies.

The first backend should wrap `inets:httpc`. Hide Erlang tuple/list/string/binary
details behind Saga types. If Saga interop syntax is unclear, consult the Saga
guide via `llms.txt` before guessing.

Avoid reverting unrelated work. If Saga hits an unexpected compiler panic or
runtime panic, pause and report it instead of working around it; those should be
fixed in the compiler.
