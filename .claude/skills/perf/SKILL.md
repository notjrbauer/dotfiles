---
name: perf
description: >-
  Measurement-disciplined performance pass: find the workload, baseline it,
  profile, fix the top hotspot, re-measure on the same workload, report
  before/after numbers. Run as /perf with a path, function, or symptom
  ("the scan loop is slow").
disable-model-invocation: true
---

# /perf — profile, fix, re-measure

Measure before changing, measure after, never trust your gut. An optimization without before/after numbers is a guess.

## The optimizer's oath
1. **Don't optimize what isn't measured to be slow.** Profilers, not opinions.
2. **The bottleneck is rarely where you think it is.** The first profile pass usually surprises.
3. **Microbenchmarks lie.** Real workloads matter; cache effects, GC behavior, network reality.
4. **A 2× win on 1% of the runtime is a rounding error.** Find the 80%-of-runtime functions, work there.
5. **Profile-driven, not vibe-driven.** Premature optimization wastes effort; measured optimization ships.

## Process
1. **Find the workload** that triggers the issue — the real input, the real concurrency, the real data size.
2. **Establish the baseline** — p50/p95/p99 latency, throughput, memory, CPU. Write the numbers down before touching anything.
3. **Profile under that workload** with the runtime's own profiler (pprof and `runtime/trace`, py-spy, `node --prof`, `EXPLAIN (ANALYZE, BUFFERS)`, `perf`, a flamegraph). Sample the real process; a microbenchmark is a last resort, run with enough iterations for a stable number.
4. **Identify the top 3 hotspots** by CPU / wall / allocation.
5. **Implement the fix** — the smallest change that addresses the measured hotspot, nothing speculative alongside it.
6. **Measure the delta** on the same workload. If no improvement, revert and try the next idea.

## Optimization tiers (try in this order)
- **Tier 1 — algorithmic** (huge factor): O(n²) → O(n log n) or O(n); memoize, cache, deduplicate; eliminate redundant scans.
- **Tier 2 — I/O** (big factor): batch RPC / DB calls; concurrent fan-out where independent; connection pooling; HTTP keep-alive, HTTP/2 multiplexing; caching with proper TTLs.
- **Tier 3 — runtime** (moderate factor): reduce allocations in hot loops (Go: `sync.Pool`, slice reuse); avoid reflection in hot paths; SIMD where applicable.
- **Tier 4 — micro** (small factor), only when 1–3 are exhausted: branch prediction, cache lines, intrinsics.

## What to flag on the way through
- Unbounded concurrency (`go func() {...}()` in a loop with no semaphore)
- N+1 query patterns
- Tight loops calling network endpoints serially
- Allocating in hot paths (string concat in loops, slices re-grown thousands of times)
- "Read-through cache that always misses"
- Locks held across slow I/O calls
- Missing rate limiting on outbound calls — the first 429 turns into a self-DDoS

## Calibration for upstream-bound services
- **Upstream call budget is sacred.** Every call you don't make is latency and quota saved.
- **Connection pool sizing matters more than you think.** Same-AZ upstream at <1ms? Pool 100+. Rate-limited third-party API? 4-8.
- **Competing loops share one pool** — observe which dominates it, throttle the loser.
- **Backoff on 429/503 must be exponential AND reset on success** — naive linear backoff turns a transient throttle into a permanent one.

## Report format
For each hotspot:
- **Current behavior**: what's slow + by how much (numbers)
- **Proposed change**: code-level
- **Expected impact**: estimated factor improvement
- **Risk**: what could regress (correctness, memory, observability)

End with a baseline-vs-after table on the same workload, the exact command/workload used, and what was *not* changed. If the numbers didn't move, say so — a reverted attempt with data is a finding.

## Anti-patterns to reject
- "I think this is the bottleneck" without profiling
- "Let me parallelize this" without checking if it's CPU-bound or I/O-bound
- "Switching from JSON to protobuf will fix this" — usually false
- "Rust would be faster" — maybe; a rewrite is the hardest possible optimization
- Optimization PRs without before/after numbers
