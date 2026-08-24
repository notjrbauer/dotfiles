---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "**/.zsh*"
  - "**/bin/**"
---

# Shell and the UNIX surface beneath it

Portable, defensive shell that survives real input, and precision about the machinery under it. Daily reality is macOS (Darwin/BSD userland) *and* Linux (GNU). Verify any version-specific claim against the primary source before citing it — pins rot.

## macOS ≠ Linux — the divergences that bite
| | Linux (GNU) | macOS (BSD) |
|---|---|---|
| userland | GNU coreutils | BSD: `sed -i ''` needs an arg; `-r` → `-E`; `date`, `stat`, `readlink -f`, `xargs -r`, `grep -P`, `mktemp` all differ. Install `coreutils`/`gnu-sed` via Homebrew (`gsed`, `gdate`, `gstat`, `grealpath`) or write to the POSIX intersection |
| `/bin/sh` | dash or bash | **not bash**; `/bin/bash` is frozen at 3.2 (GPLv3) — no associative arrays, no `${x,,}`. Login shell is zsh |
| introspection | `/proc`, `/sys`, `strace`, `ss`, `ip` | `sysctl`, `ioreg`, `dtruss`/`dtrace`, `netstat`/`lsof`, `scutil` |
| tracing | `perf`, eBPF via `bpftrace` | `dtruss`, `dtrace` scripts, Instruments/`sample`/`spindump`. **`strace` and eBPF do not exist on macOS** |
| cgroups | v2 unified hierarchy everywhere modern | n/a; SIP is on by default |

Modern Rust CLI (ripgrep, fd, bat, eza, zoxide, fzf, delta, btop) is great interactively; in scripts prefer POSIX tools or pin the dependency explicitly.

## Distinguishing expertise
- **Safe POSIX/zsh scripting:** quote every expansion (`"$var"`, `"${arr[@]}"`); use arrays, never space-split strings into "lists". Know `set -euo pipefail` **and its caveats** — `-e` is suppressed in commands feeding `if`/`&&`/`||` and inside functions called in those contexts, `-u` breaks naive `"$1"` access, `pipefail` is bash/zsh not POSIX `sh`. Prefer `[[ ]]` over `[ ]` in bash/zsh (no word-split, `=~`, `&&`); reserve `[ ]`/`test` for strict POSIX. Master parameter expansion (`${x:-}`, `${x:?}`, `${x#pat}`, `${x//a/b}`, `${x:offset:len}`) to avoid spawning `sed`/`cut`. Use `trap` for cleanup (`trap 'rm -rf "$tmp"' EXIT INT TERM`) and `mktemp -d`. Know that **subshells** (pipelines, `( )`, command substitution) don't propagate variables — reach for **process substitution** `while read; do …; done < <(cmd)` or lastpipe. zsh specifics: 1-indexed arrays, no word-splitting by default, `setopt` matters.
- **Process/signal/fd/pipe model:** fork/exec/wait, PGIDs & sessions, controlling TTY, orphans/zombies/reaping, SIGCHLD; signal delivery, `SIGKILL`/`SIGSTOP` uncatchable, EINTR; fd inheritance & `O_CLOEXEC`, dup2 redirection, `SIGPIPE`/EPIPE on broken pipes, blocking vs `O_NONBLOCK`, pipe buffering vs line buffering (`stdbuf`, `unbuffer`).
- **Permissions & setuid:** rwx/octal, setuid/setgid/sticky, real vs effective vs saved UID, umask, ACLs, capabilities (`getcap`/`setcap`) as the modern setuid alternative.
- **Text processing:** `awk` for field/record logic, `sed` for stream edits, `jq` for JSON (never regex JSON), `rg`/`fd` for search. Prefer one `awk` over a `grep|cut|sed` chain.
- **Kernel surface:** syscalls (`strace -f -e trace=...`, `ltrace`), `/proc/<pid>/{fd,maps,status,limits}` & `/sys` on Linux vs `sysctl`/`ioreg`/`vmmap` on macOS; cgroups v2 controllers & limits; namespaces (`unshare`, `lsns`, `nsenter`); `ulimit`/`getrlimit`.
- **Perf & tracing:** Linux `perf stat/record/report`, `perf top`, eBPF via `bpftrace` one-liners, off-CPU & on-CPU flamegraphs (Brendan Gregg's method); macOS `dtruss`, `dtrace` scripts, Instruments/`sample`/`spindump`. Always **measure first**.
- **Networking:** `ss -tlnp` (not `netstat`) on Linux, `ip a`/`ip r`; `lsof -i`, `tcpdump`/`wireshark`, `dig`/`drill`, `nc`, `curl -v`. On macOS: `lsof`, `netstat`, `scutil --dns`, `dtruss` for syscall-level socket tracing.

## Anti-patterns you refuse to ship
Parsing `ls` output (use globs/`find`/`fd`/`stat`). Unquoted `$var`/`$(cmd)`. `cat file | grep` (grep reads files). Useless loops over what `awk`/`xargs`/`comm` do in one pass. GNUisms (`sed -i` no-arg, `readlink -f`, `grep -P`, `date -d`) assumed present on macOS. `echo $x` for arbitrary data (use `printf '%s\n'`). `[ $x = y ]` unquoted. `rm -rf $VAR/` without `${VAR:?}`. `for f in $(cmd)` instead of a `while read` / array. `curl | sh` without at least reading it.

## Script defaults
Default to `#!/usr/bin/env bash`, `set -euo pipefail` (and call out where `-e` won't fire), traps for cleanup, quoted expansions, arrays. Call out and guard every macOS-vs-Linux divergence in the script (feature-detect: `command -v gsed`, `uname -s` branches, or stick to the POSIX intersection). Run `shellcheck` and fix findings before handing back; run the script in a scratch dir when it's safe to. Prefer built-ins and single-pass tools over process chains. Show the command you ran and its output, not just the final file.

When explaining behaviour, name the syscalls/structures involved, cite the man page and section (`signal(7)`, `execve(2)`, `credentials(7)`, `bash(1)` EXPANSION), state whether it differs on macOS vs Linux and how to check on *this* box, and give a minimal reproducing command. Correct the mental model, don't just answer the literal question.

## Hand off
Scripts becoming a system that needs real design → the `backend-design` skill. App-level bottleneck once the syscall/IO/tracing picture is clear → `/perf`.
