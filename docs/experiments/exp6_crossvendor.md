# E6 — Cross-vendor verification audit (Gemini 3.1 Pro)

**Date:** 2026-07-27 · **Vendor:** Google, `gemini-3.1-pro-preview`, temperature 0, JSON mode
**Runner:** `pipeline/crossvendor_run.py audit` (resumable 20-edge chunks; key gitignored, sent only as request header)
**Inputs:** `pipeline/work/audit100_input.json` (stratified n=100: volume × claim type × extraction age)
**Verdicts:** `pipeline/work/gemini_audit100_verdicts.json` (merged from 5 chunks)

## Design

The pipeline's one structural trust weakness: proposer (Opus) and verifier (Fable) are
different model families from **one vendor** — correlated blind spots would be invisible
to both (assumption #10). E6 runs a verifier from a **different vendor** over a
stratified sample of 100 published (already gate-verified) edges, with the *same*
production gate prompt, blind to prior verdicts, full paragraph text as ground truth.

## Results

| Verdict | n |
|---|---|
| SUPPORTED | **89** |
| PARTIAL | **11** |
| WRONG | **0** |

Zero fabrications, reversals, or unsupported edges found by an independent vendor.
All 11 disagreements are attribution/referent nuance — the axis every first-party
experiment (E1/E2/E3) already identifies as the residual weakness.

## Adjudication of the 11 disagreements (paragraph as ground truth)

| n | Edge | Gemini objection | Ruling |
|---|---|---|---|
| 23 | rex —renewed-as→ anthropos (CW14 §443) | ¶ names the *filius regius*, not Rex | **Upheld** — near-duplicate of existing `filius-regius —transforms-into→ anthropos` (same §, same sentence); misreferent edge **deleted** |
| 66 | anthropos —symbolizes→ prima-materia (CW14 §552) | ¶ names Adam | **Upheld** — ref moved to `adam —identified-with→ prima-materia`; overreach edge **deleted** |
| 48 | human-blood —synonym-of→ aqua-permanens (CW14 §401) | ¶ says blood generally (green lion's) | **Upheld** — confidence → medium |
| 37 | thief —personifies→ the-shadow (CW14 §203) | ¶: "the ego with its shadow", not solely shadow | **Upheld** — confidence → medium |
| 12 | quintessence/christ (CW12 §512) | quote is summary of Orthelius, not direct quote | **Both-defensible** — sentence sits in a translated quotation block with Latin interpolations; doctrine is Orthelius's under either claim type |
| 13 | dragon —represents→ prima-materia (CW12 §26) | Jung asserts, not reports | **Both-defensible** — sympathetic-exposition boundary (same item class both vendors miss in calibration) |
| 59 | rebis —amplified-by→ anthropos (CW14 §652) | term "rebis" absent | **Both-defensible** — ¶'s "hermaphroditic Adam" maps to rebis under the graph's node-vocabulary-reuse convention |
| 74 | coniunctio —amplified-by→ gabricus-beya (CW14 §409) | term "coniunctio" absent | **Both-defensible** — bridal-chamber/union imagery is the coniunctio content |
| 95 | incest —expresses→ rebirth (CW5 §312) | term "incest" absent | **Both-defensible** — "he who possesses the mother… united with the mother" is the content without the word |
| 72 | aelia-laelia-inscription —symbolizes→ arcane-substance (CW14 §57) | it's Crispis, not the inscription | **Not upheld** — the whole inscription's referent is the arcane substance in Maier's reading |
| 81 | night-sea-journey —amplified-by→ sol (CW5 §308) | quote splices two sentences | **Not upheld** — ellipsis splicing across adjacent sentences is permitted by the stated quotation rule; content fully supported |

**Tally: 4 upheld (all corrected) · 5 both-defensible · 2 not upheld.**
Post-audit graph: **227 nodes · 608 edges · 633 references** (all tests + canaries green).

## Cohen's κ caveat

All sampled edges were published, so the first-party verifier's marginal distribution is
degenerate (100% SUPPORTED) and κ is uninformative on this sample. The two-sided
comparison comes from the calibration replays below.

## Calibration replays (same seeded-corruption sets, cross-vendor)

| Set | Gemini | Fable (first-party) |
|---|---|---|
| E1 (n=40: 20 corrupt / 20 clean) | **70% sens / 95% spec** — reversal 5/5, object-swap 5/5, overreach 2/5*, voice-flip 2/5 | 75% / 100% — reversal 5/5, object-swap 5/5, overreach 3/5, voice-flip 2/5 |
| E5 (voice specialist, narrow brief) | voice flips **4/6 (67%)** vs 2/6 (33%) generalist | voice flips **5/6 (83%)** vs 40% generalist |

*Gemini missed the **same individual voice-flip items** (sympathetic-reportage cases) as
Fable — evidence of intrinsic ambiguity, not a vendor blind spot.*

## Conclusions

1. **The published-graph claim survives an independent vendor:** 0 unsupported edges in
   a 100-edge blind audit; the 4 upheld disputes are referent-precision nuance, and two
   were duplicates the graph is better without.
2. **No evidence of shared-substrate blind spots** on the measured error classes: both
   vendors reach ceiling on structure and stumble on the identical voice items.
3. **Semantic diffusion replicates across vendors:** narrowing the verifier's brief
   doubles weak-axis detection for Gemini (33%→67%) just as for Fable (40%→83%) —
   the specialist-decomposition finding is architecture, not model idiosyncrasy.

## Operational notes

- Gemini returned persistent 503s on 50-item payloads and intermittently emitted JSON
  arrays missing the closing bracket (`finishReason: STOP`). Fixes now in the runner:
  20-item chunks, resumable skip-if-done, retry-with-backoff on HTTP *and* parse errors,
  salvage parser for the dropped bracket.
- Cost: ~50K tokens in / ~5K out for the audit (+ replays) — ≈ $0.15 total at Gemini
  preview pricing.

## Adjudication cross-review (Gemini reviews the adjudicator)

Because the adjudicator of the 11 disputes is a Claude model (the vendor whose model
verified the edges — a structural conflict of interest), all 11 rulings + rationales
were sent back to Gemini for adversarial review (`pipeline/work/gemini_adjudication_review.json`):
**9 AGREE, 2 PARTIALLY-AGREE, 0 DISAGREE.** Both partial agreements (n48, n37) argued the
confidence-demotion remedy was too weak and the referent should actually be corrected.
**Both accepted and applied**: n48 subject retargeted to a new `blood` node (¶ supports
blood generally); n37 object retargeted to `the-ego` with quote extended to "the ego with
its shadow". Final graph: **228 nodes · 608 edges · 633 references.**

## Prompt-bias audit (Gemini critiques the gate prompt itself)

Risk: the gate prompt was written by the first-party vendor's model, so a cross-vendor
audit run under that prompt could inherit its biases. Gemini's adversarial critique of the
prompt (`pipeline/work/gemini_prompt_critique.json`) found:

- **Rubric leniency:** "PARTIAL (core link real but something off)" and WRONG's
  "beyond repair" bar nudge verifiers toward salvaging edges; misattributed voice is
  hardcoded as PARTIAL, never WRONG. (In pipeline semantics PARTIAL is not survival —
  corrections are mandatory at merge — but the critique stands for *audit* readings of
  the verdicts: "0 WRONG" partly reflects the shared rubric.)
- **Shared-rubric convergence:** giving a second vendor the first vendor's rubric and
  claim-type ontology forces convergent thresholds — cross-vendor agreement is partly
  an artifact of the shared prompt, not fully independent judgment.
- **Missing error classes** for future verifier-registry axes: conditional/contextual
  dependency stripping, metaphorical-vs-literal flattening, node-label fidelity.
- **Smuggled ontology:** the claim-type trichotomy assumes Jung's voice separates
  cleanly — the same sympathetic-reportage blending our calibrations identify.

**Mitigation adopted (planned as E7):** a *rubric-free replication* — the cross-vendor
auditor judges a sample in its own terms (support yes/no + severity in its own words,
no verdict enum, no claim-type definitions), mapped to our categories only afterwards.
Until then, E6's headline is stated as "0 unsupported edges *under the shared rubric*".
