# Novelty assessment (researched 2026-07-29)

Systematic search for prior art against each element of the claimed contribution.
Verdict up front: **no single mechanism is unprecedented; the integration, the domain,
and the public accountability apparatus are where the contribution lives.** All
"first-ever" phrasing is banned from the paper accordingly.

## Per-mechanism prior art (nearest neighbors)

| Our element | Nearest prior art | Difference that remains |
|---|---|---|
| Per-claim anchoring + verification gate | [AEVS](https://www.mdpi.com/2073-431X/15/3/178): anchor-constrained extraction, per-triplet restoration verification, provenance tracking | AEVS verifies within one model family and reports no calibration of the verifier; no voice typing; not a published scholarly artifact with reader channels |
| Seeded-corruption calibration of the judge | [Judge Reliability Harness](https://arxiv.org/pdf/2603.05399) (perturbation stress-tests of LLM judges); [judge-evaluation reporting](https://arxiv.org/html/2511.21140) (judge sensitivity/specificity with human calibration sets) | applying the harness idea to the publication gate of a KG pipeline, with per-error-class catch rates published as artifact metadata |
| Cross-vendor checking | practitioner multi-vendor judge ensembles ([overview](https://www.emergentmind.com/topics/multi-llm-verification-pipeline); provider-mixing advice; reported cross-vendor κ≈0.55) | used here as an auditing/adjudication tier with published disagreement adjudications, not score averaging |
| Claim-level verification with evidence | [ClaimVer](https://arxiv.org/pdf/2403.09724) (claim-level verification + evidence attribution through KGs) | direction reversed: they verify text against KGs; we gate a KG being built from text |
| Voice/factuality typing in extraction | biomedical factuality values ([SemRep factuality](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5497973/)); FactBank/PDTB annotation traditions | voice as first-class provenance in a *published humanities* KG, with an annotation protocol; biomedical work types hedging, not attribution-source |
| Humanities extraction methodology | [ATR4CH](https://arxiv.org/html/2511.10354) (cultural-heritage extraction methodology); PhilKG; Darshana Graph | risk-register structure; every-claim gating; public dispute/confirm channels; self-audit trail |

## What remains defensible as the contribution

1. **The integrated methodology**: named risks → one mitigation each → one measurement
   each, applied end-to-end to a live scholarly artifact. (No found system combines
   per-claim gating + calibrated judges + cross-vendor audit + published adjudications.)
2. **The domain instantiation**: interpretive humanities corpora, where voice/attribution
   is the load-bearing annotation — with a formal protocol and a public artifact.
3. **The accountability apparatus**: RAG status overlay, dispute/confirm channels,
   published hostile reviews and adjudications — trust machinery as part of the artifact.

## Consequences applied to the paper

- All mechanism-level novelty claims removed or attributed (AEVS, judge-harness,
  judge-reporting, multi-vendor practice, ClaimVer, SemRep, ATR4CH now cited in §3).
- The contribution statement claims integration + domain + accountability, nothing else.
