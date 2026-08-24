---
paths:
  - "**/*.go"
  - "**/go.mod"
---

# Go

Stdlib-first, current idiom, clarity over cleverness. Verify any version-specific claim against the primary source before citing it — pins rot. Respect the `go` line and `toolchain` directive in `go.mod`; don't silently bump them.

## Current idiom — what replaced what
- **Iterators are the norm**: range-over-func (`iter.Seq[V]`, `iter.Seq2[K,V]`, stable since 1.23); `slices`/`maps` have `Collect`, `Sorted`, `All`, `Values`, `Keys`, `Chunk`. Write push iterators returning `iter.Seq*`; consume with `for v := range seq`.
- `sync.WaitGroup.Go(func())` (1.25) — use it instead of manual `Add(1)`/`go`/`defer Done()`.
- `testing/synctest` (stable 1.25) for deterministic concurrency tests with a fake clock; `testing.B.Loop` for benchmarks.
- `errors.AsType[T]` (1.26) — prefer over `errors.As` with a var. `new(expr)` (`new(42)` → `*int`). `log/slog.NewMultiHandler`. `os/signal.NotifyContext` cancels with a cause.
- `os.Root` (1.24) for dir-scoped FS ops; `runtime.AddCleanup` replaces `runtime.SetFinalizer`; generic type aliases.
- Tool deps via `tool` directives in `go.mod` (`go get -tool`, `go tool`) — the `tools.go` blank-import hack is dead.
- `go fix` is the home of the "modernizers" — run it to modernize code.
- `encoding/json/v2` is experimental behind `GOEXPERIMENT=jsonv2` — don't ship it unless the project opted in.
- Deprecated: PKCS#1 v1.5 RSA encryption, `httputil.ReverseProxy.Director`.
- Tooling: `golangci-lint` v2 has a new config schema (not the v1 `.golangci.yml` layout); `govulncheck` runs standalone in CI, not as a linter. `go vet` runs as part of `go test`.

## What separates expert from novice
- **Errors**: wrap with `fmt.Errorf("doing X: %w", err)` to preserve the chain; inspect with `errors.Is`/`errors.As`/`errors.AsType[T]`, never string-match. Aggregate concurrent/multi failures with `errors.Join`. Sentinels are `var ErrFoo = errors.New(...)`; don't wrap when the caller shouldn't couple to the inner type. Return errors, don't log-and-return (double reporting).
- **Context**: first param, named `ctx context.Context`; never store it in a struct; never pass `nil` (use `context.TODO()`). It's for cancellation/deadlines/request-scoped values — not optional params. Check `ctx.Err()` in loops; plumb it into every blocking call.
- **Concurrency**: goroutine lifetime must be owned — who stops it, who waits? Prefer `errgroup.Group` (with `SetLimit` for bounded fan-out) over hand-rolled `WaitGroup`+error-channel. Every `go` needs a clear exit path or it leaks. Channels for orchestration; `sync.Mutex`/`atomic` for protecting state. `sync.Mutex` **zero value is ready** — never a pointer field unless the struct is copied. Don't copy anything containing a `sync.*` (go vet catches this). Close a channel from the sole sender, once. Use `context` for cancellation, not `bool` flags.
- **Interfaces**: define them at the **consumer**, keep them small (1–3 methods), accept interfaces / return concrete types. Don't create an interface "just in case" — add it when there's a second implementation or a test seam. Avoid `interface{}`/`any` at API boundaries; reach for generics when you'd otherwise reflect.
- **Zero-value usability**: design so the zero value works (`bytes.Buffer`, `sync.Mutex`, `slog` handlers). Prefer that over mandatory constructors; use functional options only when config genuinely varies.
- **slog**: structured logging is stdlib now — `slog.Info("msg", "key", val)` or typed attrs `slog.String`. Set a handler once; pass `context` via `InfoContext`. Don't reintroduce logrus/zap for greenfield unless asked.
- **Generics**: constrain with `cmp.Ordered`, `comparable`, or a named constraint; don't parameterize what a plain interface handles. Type inference should carry most call sites — explicit type args are a smell.

## Anti-patterns to kill
Naked returns in non-trivial funcs; `panic` for ordinary errors; ignoring returned errors (`_ =` only with a comment justifying it); `time.Sleep` for synchronization; unbounded goroutine spawning; premature channels where a mutex is simpler; mutating a slice header shared across goroutines; `defer` in a hot loop; empty `select{}` to block; comparing errors with `==` past a wrap.

## Verify
`go build ./...`, `go vet ./...`, `go test ./... -race` (add `-run`/`-bench` as relevant), and `golangci-lint run` / `govulncheck ./...` if the repo uses them — check for a `Makefile`, CI config, or `.golangci.yml`. Add or extend **table-driven tests** for new logic. Prefer stdlib and the module's existing deps over new ones; justify any dependency you add. When teaching, cite the exact API and the Go version it stabilized in, and show a minimal *compiling* example.

## Hand off
Idiom polish → `idiomatic-code-reviewer`. Security/authz/input review → `code-reviewer`. "It's slow" → `/perf`, with pprof or benchmarks in hand. Service topology, persistence shape, consensus, cross-node semantics → the `backend-design` skill.
