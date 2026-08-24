---
paths:
  - "**/*.lua"
  - "**/nvim/**"
---

# Lua and Neovim

Lua is small and honest; the code should be too. Verify any version-specific claim against the primary source before citing it — pins rot. Detect the target (`lua -v`, `luajit -v`, `nvim --version`) before doing version-sensitive work.

## Which Lua
- **Reference Lua 5.4 and 5.5** are the current line; 5.4 is still the most widely deployed/embedded. Know both; ask/detect which the project targets before assuming.
- **LuaJIT is rolling-release** (versioned by commit timestamp, no numbered tarballs — pull from git) and **language-compatible with Lua 5.1** plus a few borrowed extensions (`goto`/labels, `__pairs`-era bits, some string/`table` additions) and its own **FFI**. It is NOT 5.2/5.3/5.4 — no native integer subtype, no `<close>`/`<const>` attributes, no `__idiv`. Code that must run on both 5.4 and LuaJIT is effectively 5.1-with-care.
- **5.5**: optional **global declarations** (`global` keyword; `global <const> * end`-style read-only enforcement catches typo-globals at compile time), **read-only for-loop control variables**, decimal float printing that round-trips, a much lighter GC.
- **5.4**: integer/float subtypes with `//` floor-div and `math.type`, `<const>` and `<close>` (to-be-closed) variable attributes, a generational GC mode, warnings via `warn()`.
- Tooling: stylua (`stylua.toml`), luacheck (`.luacheckrc` — set `std`/`globals`), busted, luarocks (`.rockspec`). Respect whichever are present; don't introduce a toolchain the repo doesn't use.

## What separates expert from novice
- **Value & type model**: only `nil` and `false` are falsy — `0`, `""`, and `NaN` are all **truthy**. `nil` means absent; storing `nil` in a table deletes the key. The eight types: nil, boolean, number, string, table, function, userdata, thread. Use `x == nil` to test presence, not `not x` (which also catches `false`).
- **Tables are the only data structure** — array, hashmap, object, namespace, module, set, all one type. Arrays are just tables with contiguous integer keys from 1. Don't mix a "list part" and arbitrary holes and expect `#` or `ipairs` to behave.
- **1-based indexing & the `#` border rule**: sequences start at 1. `#t` is a *border* (any `n` where `t[n] ~= nil` and `t[n+1] == nil`); on a **sparse** table any border is valid — the result is unspecified, not "the count." Track length explicitly (`n` field) or keep sequences dense. `table.insert`/`table.remove` operate on the sequence.
- **Metatables & metamethods**: `__index` (function or table) drives lookup and prototype chains; `__newindex` intercepts writes to absent keys (the read-only-table and proxy patterns); `__call` makes tables callable; `__eq/__lt/__le`, arithmetic (`__add`...`__concat`), `__tostring`, `__len`, `__gc`, `__close` (5.4+), `__pairs` (LuaJIT/5.2, removed in 5.4). `rawget`/`rawset`/`rawequal`/`rawlen` bypass metamethods — reach for them inside `__index`/`__newindex` to avoid infinite recursion.
- **OOP done idiomatically**: a "class" is a table used as a metatable with `Class.__index = Class`; construct with `setmetatable({}, Class)` in `Class.new`; methods use `:` sugar (implicit `self`). Inheritance = set the class's metatable's `__index` to the parent. Don't reach for a heavyweight class library unless the repo already uses one.
- **Closures & upvalues**: functions close over variables (upvalues), not values — shared, mutable, and the idiomatic way to encapsulate private state (counters, memoizers, iterators). Each closure gets its own upvalues; a `local function` referencing itself must be declared `local function f` (so the name is in scope) not `local f = function`.
- **Modules**: a module is a file that builds a `local M = {}`, attaches functions, and `return M`. Never set globals as a side effect; never rely on the deprecated `module()` (gone since 5.2). `require` caches by module name in `package.loaded` — returning a fresh table each call is wrong.
- **Coroutines**: `create`/`resume`/`yield`/`status` — cooperative, single-threaded, stackful. Use as **generators** (wrap with `coroutine.wrap` to get an iterator that propagates errors) and as **cooperative scheduling** (a scheduler resumes coroutines that yield on I/O). `resume` swallows errors into `false, err`; `wrap` re-raises them.
- **Error handling**: `error(obj[, level])` can throw any value, not just strings — throw a table for structured errors. Catch with `pcall`/`xpcall` (the latter takes a message handler for tracebacks, e.g. `debug.traceback`). Use `assert(v, msg)` for guard clauses. Convention: return `nil, errmsg` for *expected* failures (I/O, parsing); `error()` for programmer/contract violations.
- **Numbers (5.3+/5.4)**: integer and float are subtypes of `number`; `3` is integer, `3.0` is float, `/` always yields float, `//` is floor division, `math.type(x)` distinguishes them. LuaJIT and 5.1 have **only doubles** — no integer subtype. Beware integer-for-loop overflow and float-key table lookups (`t[1]` vs `t[1.0]` are the same key when the float has an integer value).
- **Strings & patterns**: Lua **patterns are NOT regex** — `%a %d %s %w` classes, `%` (not `\`) escapes, `-` is lazy `*`, no alternation/backrefs beyond `%1`. `string.match`/`gmatch`/`gsub`/`find` (pass `true` as 4th arg to `find` for a plain search). Format with `string.format` (`%d %s %q %g`); build big strings with `table.concat`, not `..` in a loop. `("s"):method()` sugar works because strings share a metatable.
- **C API & embedding**: Lua is a stack-based virtual machine embedded in C — `lua_State`, `luaL_*` helpers, push/pop by index, register functions returning an int (number of results), `luaL_newlib`/`luaL_setmetatable`, userdata + a metatable for bindings, `luaL_ref`/`unref` for keeping references. This is the substrate under LuaJIT's FFI alternative — mention it when the task is "call C from Lua" or "expose C to Lua."
- **LuaJIT performance**: the JIT compiles hot **traces**; anything **NYI** (not-yet-implemented, e.g. some `string.*`, `pcall` in old versions, varargs edge cases, `pairs` in traces) aborts the trace to the interpreter — check `-jv`/`-jdump`. Prefer the **FFI** for C structs and calls (zero-overhead, but pointers are unmanaged — no GC safety net). Keep hot loops monomorphic, avoid creating garbage, preallocate tables (`table.new` from `ffi`). Don't hand-inline what the JIT already does well.

## Anti-patterns to kill
0-based indexing assumptions; `#` (or `ipairs`) on a table with holes and trusting the count; leaking globals by forgetting `local` (luacheck and 5.5's `global` decls both catch this); using `pairs` when order/`ipairs` was meant (and vice versa — `pairs` order is unspecified); treating Lua patterns as regex (`\d`, alternation, lookahead — none exist); `..` concatenation in a loop instead of `table.concat`; comparing to falsy with `not x` when you meant `x == nil`; `local f = function() f() end` (self-reference before the local is in scope); depending on `module()`/global side effects; unbounded string keys built per-iteration in LuaJIT hot loops.

When something is unspecified (border rule, `pairs` order, GC timing), say "unspecified — don't rely on it" rather than describing today's accident of implementation. **Always call out version differences explicitly** — "in 5.4 this is X; on LuaJIT/5.1 it's Y". Default to `local` everything, one `local M = {}` module returning the table, `nil, err` for expected failures. Don't add a metatable/class/coroutine where a plain function or table is clearer. State the version target you wrote for; prefer `lua -e`/`luajit -e` snippets the reader can paste.

## Neovim API
Applies to `init.lua`, plugin specs, `vim.api`/`vim.fn`/`vim.opt`, autocmds, LSP/treesitter setup. Assume 0.11+ as baseline; some APIs are 0.12-only (`vim.pack`, native `'autocomplete'`) — check `nvim --version` before relying on them.

- **Native LSP is the default path.** Configure servers with `vim.lsp.config(name, cfg)` (and `vim.lsp.config("*", {...})` for shared defaults), then `vim.lsp.enable({...})`. A file at `lsp/<server>.lua` on the runtimepath is auto-discovered. `nvim-lspconfig` is now just a bundle of these `lsp/` configs, not a framework — you rarely need it. Do **not** teach `require("lspconfig").<server>.setup{}` as the modern way.
- **Deprecated → current:** `vim.lsp.buf_get_clients()`/`get_active_clients()` → `vim.lsp.get_clients({ bufnr = ... })`; `client.resolved_capabilities`/`supports_method` free-fn → `client:supports_method(method, bufnr)`; `vim.loop` → `vim.uv`; `vim.fn.jobstart`/`systemlist` for subprocesses → `vim.system(cmd, opts, on_exit)` (async) or `:wait()`; `vim.highlight.*` → `vim.hl.*` (e.g. `vim.hl.on_yank`, `vim.hl.range`); `vim.diagnostic.goto_next/prev` → `vim.diagnostic.jump` (0.11+); `vim.tbl_add_reverse_lookup`, `vim.validate` old signature — check `:h deprecated`.
- **treesitter:** `nvim-treesitter` **master is archived; `main` is a rewrite** that only installs/updates parsers (needs the `tree-sitter` CLI). Highlighting/indent/folds are core APIs now: enable per-buffer via a `FileType` autocmd calling `pcall(vim.treesitter.start, buf, lang)`, folds via `foldexpr=v:lua.vim.treesitter.foldexpr()`, indent via `require('nvim-treesitter').indentexpr()`. No more `require('nvim-treesitter.configs').setup{ ensure_installed, highlight = {...} }`.
- **Plugin managers:** `lazy.nvim` remains the dominant third-party manager; 0.12 ships built-in `vim.pack` (`vim.pack.add{ {src=url, version=...} }`, `vim.pack.update`, `PackChanged` autocmd). Use whichever the target config already uses — don't impose lazy.nvim on a vim.pack config or vice versa. This dotfiles repo's `.config/nvim` is a single `init.lua` on `vim.pack`, native `vim.lsp.config`/`enable`, treesitter `main`, and blink.cmp.
- **Completion:** `blink.cmp` or `nvim-cmp`; 0.12 adds native insert-mode `'autocomplete'`. Match the config; don't force a swap unasked.

### The Lua API surface
- **Buffers/windows/extmarks:** `vim.api.nvim_buf_*`/`nvim_win_*`, `nvim_buf_set_extmark` with a `nvim_create_namespace`, virtual text/lines (`virt_text`, `virt_lines`), signs and diagnostics via extmarks. Floating windows via `nvim_open_win` (`relative`, `border`, `zindex`, `footer`).
- **Config primitives:** `vim.opt`/`vim.o`/`vim.bo`/`vim.wo`, `vim.keymap.set` (with `desc`, `buffer`, `expr`), `vim.fn` for legacy funcs, `vim.g` for globals.
- **Autocmds:** always `nvim_create_autocmd` bound to a cleared `nvim_create_augroup(name, { clear = true })`. Prefer `callback` (Lua) over `command`.
- **User commands:** `nvim_create_user_command` with `nargs`/`complete`/`bang`.
- **Diagnostics:** `vim.diagnostic.config`, `vim.diagnostic.jump`, virtual_text/virtual_lines toggles.
- **Async:** `vim.uv` (libuv) for timers/fs/spawn, `vim.system` for processes, `vim.schedule`/`vim.defer_fn` to get back on the main loop (most `vim.api` calls are **not** safe off the main loop).
- **lazy.nvim spec idioms:** lazy-load via `event` / `ft` / `keys` / `cmd`; `opts` table is merged and passed to the plugin's `setup()` — prefer it over a `config` function unless you need logic; `config = true` just calls `setup()`; declare `dependencies`; `VeryLazy` for non-blocking startup work.
- **Plugin authoring:** code under `lua/<mod>/`, `plugin/` for eager setup, `after/` for overrides, `ftplugin/` for filetype logic; expose a `setup(opts)` that deep-merges defaults; `:h health` via `require('<mod>.health')` and `vim.health.*`; ship a **minimal reproducible config** (`nvim -u repro.lua`) for bug reports; guard optional deps with `pcall(require, ...)`.

### Anti-patterns you refuse to write
- Deprecated calls (`vim.loop`, `buf_get_clients`, `vim.highlight`, old lspconfig framework, treesitter `configs.setup`).
- Blocking the UI: `vim.fn.system` in hot paths, synchronous `io`/`vim.uv` waits on the main loop, `vim.api` from a non-scheduled callback.
- Autocmds without an augroup (leaks duplicate handlers on reload).
- Over-eager plugin loading (no `event`/`ft`/`keys` where the plugin allows it).
- VimScript (or `vim.cmd([[...]])` string soup) where a direct Lua API call is clearer and typo-safe.

### Verify
Wire keymaps with `desc`, group autocmds, keep diffs surgical. Sanity-check non-trivial changes with `nvim --headless -u <cfg> +'lua ...' +q` or a scratch minimal config, and run `stylua` if the repo uses it. Cite the concrete function/option and quote `:h <tag>` when it settles a dispute; if unsure whether an API is current, check the Neovim docs rather than guessing from an older idiom.
