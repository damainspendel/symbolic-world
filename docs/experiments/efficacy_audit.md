# Efficacy audit — does the code do what the paper claims?

**Date:** 2026-07-27 · **Auditor:** Gemini 3.1 Pro (most capable reasoning tier on the
project's key, confirmed against the live models list) · **Scope:** paper claims vs
`tests/test_graph.py`, `pipeline/calibrate.py`, `pipeline/crossvendor_run.py`,
`extract.py`, `web/build-atlas.mjs` · **Raw:** `pipeline/work/gemini_efficacy_audit.json`

## Verdicts on claimed mechanisms

| Claim | Verdict |
|---|---|
| § numbers read from markup, never inferred | **faithful** |
| Canaries must be caught on every test run | **faithful** |
| Cross-vendor audits blind, temp 0, rubric + rubric-free | **faithful** |
| Calibration seeding + Wilson-interval scoring | **faithful** (independently re-derived) |
| "Verbatim, letter-for-letter" quote gate | **weaker than claimed** → fixed |
| "No claim published without passing the gates" | **gap in the build step** → fixed |

## Upheld findings and fixes (all applied same-day)

1. **Quote matcher allowed collage quotes (high).** The checker used unbounded-gap
   subsequence matching: a "quote" assembled from words scattered across the paragraph
   (in order) would pass. Fixed to **bounded-gap near-contiguous matching** (≤3
   intervening tokens, absorbing interleaved footnote/figure markers). All **659
   production quotes pass the tightened matcher** — no collage quotes existed — and a
   sixth canary (a deliberately scattered collage) now guards the property permanently.
2. **Atlas build ignored the verified flag (medium).** All production refs are verified,
   so nothing leaked — but the gate was procedural, not structural. The build now
   **fails closed**: any reference without `verified: true` refuses the build
   (verified by planting one).
3. **Salvage parser could accept truncated verdict sets (high).** The bracket-repair
   path (and even a clean parse) now verifies the verdict set covers every submitted
   item; shortfall raises and triggers the chunk retry loop.
4. **Calibration code existed only in session history** (self-identified before the
   audit): now committed as `pipeline/calibrate.py` (build + score), reproducing the
   E1b results exactly.

## Conclusion

The architectural claims are faithfully implemented; the audit's real catch was that
the strongest-sounding claim ("letter-for-letter") had the loosest implementation.
The claim's wording and the implementation now meet in the middle, stronger than
either was: bounded-gap matching, canary-guarded, with a structural fail-closed gate
at build time.
