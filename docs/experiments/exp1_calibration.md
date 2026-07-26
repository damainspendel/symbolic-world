# Experiment 1 — Verifier calibration by seeded corruption

**Date:** 2026-07-26 · **Seed:** 20260726 · **Verifier:** claude-fable-5 (production gate prompt, blind)

**Method.** 40 items: 20 verified edges left intact (controls), 20 edges corrupted
programmatically across four classes (5 each): direction reversal (subject/object
swapped on directional relations), voice flip (jung-reports-parallel / jung-quotes-source
retyped as jung-asserts, source dropped), object swap (object replaced by a same-type
node absent from the paragraph), identity overreach (analogy relations upgraded to
is/identical-to). Quotes and paragraphs untouched, so every item passes the mechanical
pre-check — the experiment isolates the semantic gate. Items shuffled; the gate received
the standard production prompt with no indication of seeding. Key withheld from the gate.

**Results.**
| Metric | Value |
|---|---|
| Specificity (clean passed) | 20/20 = 100% |
| Sensitivity (overall) | 15/20 = 75% |
| — direction reversal | 5/5 |
| — object swap | 5/5 |
| — identity overreach | 3/5 |
| — voice flip | 2/5 |

**Interpretation.** Structural corruption — wrong direction, wrong referent — is
detected at ceiling, and the gate never flags clean data (no over-correction pressure).
The measured weakness is attribution modality (voice flips), consistent with the
independent 30-ref adversarial audit (0 content errors, 13.3% modality refinements).
Missed voice-flips were cases where Jung's own stance partially aligns with the
reported doctrine (e.g. correspondences he adopts), i.e. genuinely ambiguous voice.
Files: exp1_calibration_key.json (ground truth), exp1_calibration_verdicts.json (gate output).
