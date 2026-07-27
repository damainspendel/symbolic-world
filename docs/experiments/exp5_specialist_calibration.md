# Experiment 5 — Voice-specialist calibration (per-axis seeded corruption)

**Date:** 2026-07-27 · **Seed:** 20260727 · **Auditor:** claude-fable-5, narrow voice/hedge prompt, blind

**Method.** 20 items drawn from post-sweep (voice-clean) ground truth: 6 voice flips
(reported/quoted -> jung-asserts, source dropped), 4 hedge strips (medium -> high on
hedged claims), 10 clean controls. Shuffled; specialist received the production
narrow prompt with no indication of seeding.

**Results.**
| Metric | Specialist (narrow scope) | Generalist gate (5-criteria scope, E1) |
|---|---|---|
| Voice-flip detection | **5/6 (83%)** | 2/5 (40%) |
| Hedge-strip detection | 3/4 | — (not separately planted in E1) |
| Overall sensitivity | 8/10 (80%) | 75% (all classes) |
| Specificity | **10/10 (100%)** | 100% |

**Interpretation.** Direct measurement of semantic-diffusion in verification:
narrowing the auditor's responsibility from five simultaneous criteria to one
axis doubled detection on that axis (40% -> 83%) with zero false-positive cost.
Combined two-stage architecture (structure generalist + voice specialist) has
measured per-axis ceilings: structure 100%, voice 83%, at ~+$0.02/citation.
The two misses (one sympathetic-reportage flip, one soft hedge) are the same
genuinely-ambiguous boundary cases identified in E1/E3 — the residual that
motivates the human tier.
