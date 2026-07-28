# Experiment 3 — Full-graph attribution-modality sweep

**Date:** 2026-07-26/27 · **Auditor:** claude-fable-5 (narrow prompt: claim-type + hedge only)
**Coverage:** all 634 references, 5 batches

**Results.**
| Batch | Refs | Flagged | Rate | Note |
|---|---|---|---|---|
| 1 (oldest edges E0-E126) | 127 | 24 | 18.9% | pre-gate-era material |
| 2 | 127 | 14 | 11.0% | |
| 3 | 127 | 7 | 5.5% | |
| 4 | 127 | 13 | 10.2% | incl. 4 reverse-direction fixes |
| 5 (newest edges) | 126 | 7 | 5.6% | mostly hedge fixes |
| **Total** | **634** | **65** | **10.3%** | all fixes applied |

Fix composition: 50 claim-type corrections (dominantly reported alchemical/
Cabalistic/patristic doctrine typed as jung-asserts; 5 corrections in the
REVERSE direction — Jung's own theses mistyped as reportage; 3 invalid
anonymous jung-quotes-source demoted), 10 source-field corrections, 15 hedge
downgrades (confidence high → medium on explicitly conditional claims).

Post-sweep claim mix: 420 jung-asserts · 155 jung-reports-parallel ·
59 jung-quotes-source; confidence 553 high · 81 medium. Every corrected ref
carries `modality_swept: 2026-07-27`.

**Interpretation.** (i) The 10.3% full-graph modality-error rate closely matches
the two independent estimates (adversarial audit 13.3%, calibration voice-flip
detection deficit) — two same-instrument measurements agree on the weak axis (the calibration miss rate is a detector property, not a prevalence — correction 2026-07-28). (ii) The
age gradient (18.9% oldest → ~5.5% newest) is suggestive evidence (uncontrolled temporal comparison; see E9 for the controlled test) that gate
corrections fed back into extractor instructions compound: the pipeline's
first-pass modality precision roughly tripled over the project's lifetime.
(iii) The auditor corrects in both directions (asserts↔reports), so the sweep
is not a systematic deflation of Jung's voice.
