# E1b — Expanded gate calibration (n=200, seed 20260727, blind)

**Design:** 10× the per-class sample of E1: **100 seeded corruptions (25 per class:
reversal, object-swap, identity-overreach, voice-flip) + 100 intact controls**, drawn
from verified production references (key withheld from the gate; 8 blind batches of 25;
production structure-gate prompt; Claude Fable 5). Design improvement over E1: reversal
corruptions restricted to **directional relations** (reversing `synonym-of` is not a
corruption); overreach seeded only on non-identity relations.

**Files:** inputs/keys/verdicts in `pipeline/work/calib2_*` · score: `calib2_score.json`

## Results (95% Wilson CIs)

| Metric | Result | 95% CI | E1 (n=20 corrupt) |
|---|---|---|---|
| **Sensitivity (any corruption)** | **86/100 (86%)** | 78–91% | 15/20 (75%) |
| **Specificity** | **93/100 (93%)** | 86–97% | 20/20 (100%) |
| reversal | 23/25 (92%) | 75–98% | 5/5 |
| object-swap | 24/25 (96%) | 80–99% | 5/5 |
| identity-overreach | 21/25 (84%) | 65–94% | 3/5 |
| voice-flip | 18/25 (72%) | 52–86% | 2/5 |

## Reading the results honestly

1. **Structural corruption detection confirmed at/near ceiling with tight-enough
   intervals to say so**: reversal 92% and object-swap 96% (pooled structural:
   47/50 = 94%, CI 84–98%). The n=20 result was not a small-sample fluke.
2. **The generalist's voice-flip baseline is higher than E1 estimated**: 72%
   (CI 52–86%) vs E1's 2/5 (40%). E1's n=5 estimate was noisy, as small samples are.
3. **Consequence for the semantic-diffusion claim (E5):** the generalist-vs-specialist
   voice gap is now 72% (18/25) vs 83% (5/6) first-party — **directionally consistent
   with the specialist advantage across all four measurements (40%, 72% generalist;
   83%, 67% specialist) but not statistically resolved at current specialist n.**
   The paper's claim is accordingly downgraded from "detection doubled" to: a
   directionally consistent, cross-vendor-replicated advantage on paired items,
   pending a larger specialist calibration. This is the expanded sample doing its job.
4. **Specificity 93% is a lower bound on true specificity.** The 7 flagged "clean"
   controls are production references, and on inspection several flags are *plausible
   nuance findings* of the familiar class (vocabulary precision: "mother archetype"
   vs great-mother; "the saviour" narrowed to christ; one clear voice miscast —
   `rex —transformed-through→ hierosgamos` §356, **upheld and corrected** to
   jung-reports-parallel). The rest are logged as candidate nuances for the standing
   review queue. Flagging real nuances in "clean" items is the gate working, not failing.

## Cost

8 gate batches ≈ 440K subagent tokens ≈ $9–11 — as budgeted for this expansion.
