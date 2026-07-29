# E9 — Controlled teaching test (taught vs untaught miner)

**Date:** 2026-07-28 · **Design:** the controlled test a hostile review demanded (temporal confound removed; the shared-instrument confound was later identified and remains) for
Imperative 4. Two miners, same model (Opus 4.8), same held-out window (CW 12 §111–180,
never previously mined), same node vocabulary. One received minimal instructions; the
other the correction-derived instructions the pipeline has accumulated (claim-typing
rules, hedge rules, referent discipline, splice limits). Both candidate sets (20 each)
were shuffled together and blind-gated by the same reviewer (Fable 5), which could not
know which arm produced which edge. Key: `pipeline/work/e9_key.json`; verdicts:
`e9_gate_verdicts_b*.json`.

## Result

| Arm | SUPPORTED | PARTIAL | WRONG | Flag rate |
|---|---|---|---|---|
| **Taught** | 17/20 | 3 | 0 | **15%** |
| **Untaught** | 13/20 | 6 | 1 | **35%** |

The untaught arm's failures are the classic classes the instructions encode: hedged
claims at high confidence (3), dream-specific interpretations generalized (2), a
reported explanation miscast, and one outright conflation (Mercurius/Hermes-
Trismegistus — WRONG). The taught arm's three flags are subtler: one generalization,
one scope restriction, one source-attribution nuance.

## Honest statement

A 2.3× flag-rate reduction in the predicted direction — but n=20 per arm is small
(Fisher's exact p ≈ 0.27, not significant), and a later review identified a remaining
confound: the outcome judge is the same gate whose corrections defined the teaching,
so accuracy gains cannot be distinguished from stylistic accommodation to the gate.
This removes the temporal confound only; a different-vendor re-grade is the next control. Cost: ~$4.
