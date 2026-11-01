# User defaults for omp

- For `eval`, prefer the JavaScript (Bun) kernel for HTTP calls and output verification. If a Python library is required, or the repository's verification contract calls for `python3`, use the Python kernel.
- Never import eng-mode source (`~/eng-mode/src/*`) inside `eval`; the eval kernel resolves packages only from its own cached environments, not the checkout's `node_modules`. Run eng-mode scripts as a subprocess: `bun run --cwd ~/eng-mode <script> [args]` (for example `roles:prepare`, `sync-skills:check <repo>`).
- Call registered tools (`eng_orch`, `loop`, `goal`) directly, never through `eval`. An eval-side call runs in the eval worker, so its errors and "unavailable in this session" results say nothing about the real tool.
