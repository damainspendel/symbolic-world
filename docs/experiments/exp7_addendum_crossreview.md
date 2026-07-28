# E7 addendum — unanchored adjudication cross-review (2026-07-28)

A hostile review (Opus 4.8, artifact-re-executing) identified two gaps in E7: its
adjudication received no auditor cross-review (unlike E6's), and E6's cross-review had
been **anchored** — the auditor saw the adjudicator's rationales before judging them.

This addendum closes both: the E7 adjudication's 10 rulings were sent back to the
auditor (Gemini 3.1 Pro) with **outcome categories only — no rationales** — and an
explicit instruction to disagree if "both-defensible" was masking a warranted change.

## Result (`docs/experiments/data/gemini_e7_adjudication_review.json`)

| Ruling class | Unanchored assessment |
|---|---|
| 4 upheld corrections (n91, n110, n187, n335) | **4/4 AGREE** |
| 5 both-defensible + 1 partially-upheld | **6/6 DISAGREE** |

The corrections survive independent review unanimously. The convention-based rulings
do not: every "both-defensible" verdict — the second-Adam↔anthropos vocabulary
mappings, the cross-paragraph context cases — is rejected by the unanchored auditor,
which reads them as term-absent-from-paragraph errors.

## What this changes

1. **The anchoring effect is real and measured**: anchored cross-review (E6 style)
   yielded 9/11 agreement; unanchored yields 4/10. Anchored cross-review overstates
   adjudication independence and is retired as a control.
2. **Residual accounting**: under the strict single-paragraph reading the unanchored
   auditor applies, the E7 residual is the both-defensible-as-errors bound, **2.2%**,
   rather than 1.0%; under the project's documented vocabulary conventions it remains
   1.0–1.6%. The paper reports the range, not the friendly endpoint.
3. **Conventions are now inspectable**: the six convention-dependent references carry
   a `vocabulary_note` field in `seed.json` stating exactly what was mapped and why,
   so a reader can apply either reading.
4. The 41 auditor-rated-minor E7 flags remain unadjudicated (disclosed in the paper).
