---
name: backend-design
description: >-
  Reference for server, API, and distributed-systems design decisions. Consult
  before writing code that adds or changes an endpoint or RPC, a schema or data
  model, a datastore or cache, a queue producer/consumer, a retry, timeout, or
  backoff policy, idempotency, transactions and isolation levels, auth
  (OAuth/OIDC/JWT), a zero-downtime migration, leader election, replication,
  consensus, ordering, delivery semantics, outbox/sagas, or any invariant that
  spans services. Background knowledge to reason with, not a workflow to run.
user-invocable: false
---

# Backend and distributed-systems design

Design what stays correct under load, failure, and change. Choose the pattern that fits the constraints, not the one you like most. Name the model, name the failure, cite the paper or the system that solved it — no hand-waving. Verify any version-specific claim against the primary source before citing it — pins rot.

## Conventions worth defaulting to
- **Observability**: OpenTelemetry over OTLP (gRPC or http/protobuf); traces + metrics + structured logs correlated by `trace_id`/`span_id`; propagate W3C `traceparent`/`tracestate`. Use semconv attribute keys (`http.request.method`, `db.system.name`, `server.address`, `error.type`) — don't invent names. Thread context (`context.Context` or equivalent) from the edge on day one; "we'll add tracing later" never happens.
- **Auth**: OAuth 2.1 semantics — PKCE mandatory for all authorization-code clients, implicit flow and ROPC removed, exact redirect-URI matching, refresh-token rotation for public clients; OIDC for identity. Prefer opaque tokens + introspection for internal services; if you must use JWTs, pin `alg`, verify `iss`/`aud`/`exp`, reject `alg:none`, rotate keys via JWKS, keep them short-lived. DPoP for sender-constrained tokens.
- **Idempotency**: the `Idempotency-Key` header is the converging convention for retry-safe POST/PATCH. Persist key → (response, status) with a TTL; guard concurrent replays with a unique constraint or lock.
- **Keys and storage**: time-ordered UUIDv7 (Postgres `uuidv7()`) over random v4 — index locality. The default is still a well-modeled relational schema.
- **Transport**: HTTP/2 and HTTP/3 in production; gRPC over HTTP/2; Protobuf with explicit field numbers and backward-compatible evolution.

## Backend architecture
- **Protocol fit**: REST for resource CRUD and cache-friendly public APIs; **gRPC** for internal service-to-service, streaming, tight contracts; **JSON-RPC** for method-style endpoints; **GraphQL** only when clients genuinely need to shape aggregated reads (and you can afford query-cost limits + persisted queries). Name the tradeoff, don't cargo-cult.
- **Data modeling**: model invariants, not screens. Normalize first; denormalize deliberately with a written reason. Know your **isolation levels** — Postgres default is Read Committed; use `SERIALIZABLE`/`REPEATABLE READ` (SSI) and expect to retry `40001`. Pick SQL vs KV vs document by access pattern and consistency need, not familiarity.
- **Caching**: name the invalidation strategy before adding the cache (TTL, write-through, write-behind, explicit bust). Guard **stampedes** (single-flight / request coalescing, jittered TTL), and prevent **unbounded** caches. Cache-aside is the default; document staleness tolerance.
- **Reliability**: every network call gets a **timeout** and a **budget**. Retries only on idempotent/retryable ops, with **exponential backoff + full jitter** and a cap; add **circuit breakers** and **backpressure** (bounded queues, load-shedding) so failure is contained. **Graceful shutdown**: stop intake, drain in-flight, honor a deadline, then hard-exit.
- **Migrations**: **expand/contract** (add nullable → backfill → dual-write → switch reads → drop) for zero-downtime. Migrations are forward-only and reversible-by-design; never lock a hot table without `CONCURRENTLY`/lock-timeout awareness.
- **Config/secrets**: **12-factor** — config in env, secrets from a manager (not env files in the image, not the repo), fail fast on missing required config at boot.

### Sharp-edge anti-patterns
- Retrying non-idempotent writes (duplicate charges/orders) — demand an idempotency key first.
- JWT as a session you can't revoke; long-lived access tokens; trusting unverified `alg`/claims.
- `SELECT *` across a service boundary; N+1 queries; missing indexes on FK/filter columns; offset pagination on large sets (use keyset).
- Dual-writing to DB + cache/queue with no outbox — use the **transactional outbox** for atomic state+event.
- Unbounded goroutines/threads/queues; no timeout on the DB pool; no `statement_timeout`.
- At-least-once delivery consumed non-idempotently. Exactly-once is a lie at the transport; make consumers idempotent.

## Distributed systems — what others cargo-cult
- "Exactly-once delivery" is impossible over an unreliable network; only **exactly-once effects** are achievable — via idempotency keys, dedup windows, or transactional outbox. Say this every time someone asks for exactly-once.
- Consistency is a spectrum, not a boolean. Distinguish linearizable (single-object, real-time) from serializable (multi-object, no real-time) — you need both words, and strict-serializable when you need both properties.
- Quorums: R+W>N gives overlap, not linearizability (read-repair, sloppy quorums, and hinted handoff leak stale reads). Consensus, leases, or fencing tokens buy real linearizability.
- Time: wall clocks are lies. Prefer HLC for causal ordering without atomic clocks; Lamport for happens-before; vector clocks when you must detect concurrency. TrueTime's `commit-wait` is the trick, not the clock.
- CAP is a coarse triage; PACELC is the real tradeoff — the *else* latency clause governs 99% of steady-state behavior.
- The outbox pattern only works if the write and the outbox row commit in the **same local transaction**; a separate publish is a dual-write bug in disguise.
- Sagas trade atomicity for availability and require compensations that are themselves idempotent and commutative-enough; they expose intermediate states — design for them.
- Retries without idempotency + jittered backoff + a circuit breaker are a self-inflicted DDoS. Retry storms and metastable failure are the common outage shape.

### Sharp-edge anti-patterns
- Committing the queue offset before the side effect (or after, without idempotency).
- Leader election without **fencing tokens** — a paused-then-resumed old leader corrupts state.
- Using a distributed lock (Redis/etcd) for correctness without a monotonic fence; locks expire, GC pauses happen, split-brain follows (Kleppmann, "How to do distributed locking").
- Read-modify-write across services without OCC/CAS or a coordinating transaction.
- Vector clocks that grow unbounded (no node retirement / dotted-version pruning).
- Treating `at-least-once` + non-idempotent handler as "probably fine."
- Unbounded queues instead of real backpressure — latency hides until it collapses.
- Assuming FIFO/global ordering from a partitioned log; order holds per-partition/key only.

### The systems, in one line each
- **Kafka** 4.x is KRaft-only (ZooKeeper removed, not deprecated). Transactions + idempotent producer give exactly-once *within* Kafka; effects on external stores still need idempotency or an outbox. `read_committed` isolation matters.
- **NATS JetStream**: at-least-once streams, KV, and work queues at the edge; per-stream Raft. Not a database — no cross-stream atomicity.
- **etcd**: linearizable reads via ReadIndex; small consistent metadata/coordination only, not bulk data.
- **FoundationDB**: strict-serializable, externally-consistent transactions; the reference substrate when you need a correct transactional KV to build layers on.
- **Temporal**: durable execution / sagas / long-running orchestration — reach for it instead of hand-rolling a state machine over a queue + cron.
- **Spanner**/TrueTime-style external consistency is the bar for globally-linearizable multi-region; CockroachDB/YugabyteDB approximate it with HLC + intent locking (no atomic clock).

## How to reason through a decision
1. State the invariant that must hold and the exact failure (partition, crash, clock skew, duplicate, reorder, slow node) that threatens it.
2. Name the consistency/consensus model and its guarantee in one precise sentence.
3. Give a concrete failure interleaving (a mini timeline) showing where naive designs break.
4. Cite the source: Raft/Paxos/VR, Dynamo, Spanner, Calvin, Bayou/CRDTs, FLP, Kleppmann's DDIA, Jepsen analyses, or the specific KIP/RFC.
5. State the tradeoff (PACELC) and what would *test* it — fault injection, partition tests, deterministic simulation, a linearizability checker.

Give the decision rule ("use X when …, Y when …") and the common mistakes for that choice. If the question hides an XY problem, name it. If the required consistency is unstated, ask or state the assumption explicitly. If a design is load-bearing, sketch the failure modes (partition, retry storm, hot key) before recommending.

## When implementing
- Restate the invariants and the failure model **before** writing code. Prefer a proven system over a hand-rolled protocol; justify any custom coordination.
- Make handlers idempotent by construction (natural keys, dedup tables, CAS); make writes+publishes share one transaction (outbox) or use durable execution.
- Add fencing tokens to anything leader-elected or lock-guarded.
- Every new I/O path gets timeout + error handling + observability. Backpressure, retry (jittered, capped), and circuit-breaker policy are part of correctness, not an afterthought.
- Leave the invariant and the failure-interleaving reasoning as comments at the call site; add a focused test for the new invariant (idempotency, isolation, timeout) and recommend one that can actually falsify the design.
