---
name: review-billing-change
description: >-
  Run the 12-question billing change review checklist against a diff.
  Use when reviewing any diff that touches metering, rating,
  invoicing, ledgers, proration, or billing tables — or when the user
  types /review-billing-change. Applies to any usage-based billing
  system.
---

# Billing change review

Run every question below against the diff. Each answer needs
file:line evidence from the code as it is after the diff — "the queue
mostly doesn't duplicate" and "it should be fine" are wrong answers.
If you can't point to the line that makes an answer true, the answer
is "unproven," and that's a finding.

## The 12 questions

1. **Arrives twice?** Point to the exact unique constraint or
   idempotency key that makes the second arrival a no-op.
2. **Arrives 3 days late? After the metering window closed? After the
   invoice finalized?** Three separate answers (re-aggregate /
   next-period adjustment / credit memo or alert), and the code must
   show all three paths.
3. **Any float on the money path, even transiently?** Check
   intermediate math, JSON (de)serialization, DB column types,
   language defaults. One float hop poisons the pipeline.
4. **Where does rounding happen, and did this diff move it?**
   Sum-of-rounded ≠ round-of-sum. A diff that changes aggregation
   order changed the invoice, even if no rate changed.
5. **Retry or mid-operation crash — what's double-applied?** Is state
   change + emitted event one transaction (outbox), or is there a
   window where we charged without recording?
6. **Does it mutate a ledger entry or finalized invoice?** Any
   `UPDATE`/`DELETE` on those tables is guilty until proven a
   draft-state operation. Corrections are new entries.
7. **Is rating still a pure function of (events, versioned config)?**
   Grep for wall-clock reads, `now()` defaults, flag reads inside
   rating. Nondeterminism breaks replay and reconciliation.
8. **Would a finalized invoice re-render differently?** Then it needs
   a version gate: old periods pin old behavior.
9. **What does reconciliation see?** A new metered quantity with no
   drift check against source-of-truth telemetry ships blind.
10. **Which boundary cases ran?** Demand the table: plan change at
    period boundary, two changes in one day, downgrade below consumed
    usage, Feb 28→31 anchor days, DST in the billing timezone — plus
    whatever boundary cases this system's own meters add.
11. **Blast radius and rollback?** Wrong invoices are outward-facing
    and semi-irreversible. Can we shadow-rate and diff before
    finalization? Can old code re-rate the period?
12. **Who does each ambiguous edge favor — us or the customer?**
    Every rounding direction and dropped late event picks a side. It
    should be policy, not accident.

## Report format

Separate findings into three buckets, each item with file:line:

- **Confirmed defect** — you can state the failing input and the
  wrong output it produces.
- **Plausible risk** — a path you can't prove safe from the diff and
  the code it touches.
- **Open policy question** — the code picks a side (rounding
  direction, grace window, who eats the ambiguous cent) without a
  documented decision behind it.

**Calibration:** policy choices are surfaced to the human, never
decided here. If the diff embeds one silently, flag it as an open
policy question — do not judge it correct or incorrect, and do not
propose a resolution as if it were settled.
