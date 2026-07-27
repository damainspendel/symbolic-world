# E8 — Second-corpus replication: William James, *The Varieties of Religious Experience*

**Date:** 2026-07-27 · **Corpus:** Project Gutenberg #621 (1902; public domain) — 1,277
anchored paragraphs across 14 lectures (`james/corpus.jsonl`, distributable in full)
**Windows:** Lecture IX (Conversion) and Lectures XVI–XVII (Mysticism), 20 candidates each
**Pipeline:** identical to the Jung pipeline, unchanged: mine → mechanical pre-check
(bounded-gap verbatim) → structure gate (Fable) → voice specialist (Fable) →
cross-vendor check (Gemini, pre-merge) → publish. Voice vocabulary instantiated as
`james-asserts` / `james-reports` / `james-quotes-source`.

## Build results

| Stage | Result |
|---|---|
| Mining | 40 candidates, 55 nodes proposed; claim mix 25 asserts / 4 reports / 9 quotes-source (+4 hedged medium) |
| Mechanical pre-check | **40/40 quotes pass verbatim** (0 dropped) |
| Structure gate | 37 SUPPORTED / 3 PARTIAL / 0 WRONG; 1 corrected, 2 dropped under the conservative no-one-off-nodes rule |
| Voice specialist | 5 hedge fixes (James's "it seems to me a true account" endorsements correctly demoted to medium) |
| Cross-vendor check (pre-merge) | **38/38 SUPPORTED** |
| Published | `james/james_seed.json` — 52 nodes · 38 edges · 38 references, 100% verified + cross-checked; visual graph at [symbolicworld.observer/james.html](https://symbolicworld.observer/james.html) |

## Seeded-corruption calibration (n=60: 40 corruptions + 20 controls, blind)

| Metric | James | Jung (E1b) |
|---|---|---|
| Sensitivity | **36/40 (90%, CI 77–96%)** | 86% (CI 78–91%) |
| Specificity | **20/20 (100%, CI 84–100%)** | 93% (CI 86–97%) |
| reversal | 10/10 | 23/25 |
| object-swap | 10/10 | 24/25 |
| overreach | 9/10 | 21/25 |
| voice-flip | **7/10 (70%)** | 18/25 (72%) |

**The finding:** the risk profile *replicates across corpora* — structural corruptions
at or near ceiling, voice the weak axis, at almost identical rates (70% vs 72%),
on a different author, century, and genre. The paper's claim that "each corpus has its
own risk axes" needs an amendment the data forced: for authored interpretive prose,
the voice axis appears to be the *shared* weak axis, not a Jung idiosyncrasy.

## Honesty notes

1. The miner's instructions embed the claim-typing lessons learned in the Jung
   pipeline, so James's low raw error rate (3/40 pre-correction = 7.5%, vs Jung's
   ungated 25%) measures a *taught* miner, not a naive one — evidence that the
   gate-teaches-miner effect transfers across corpora, and not comparable to E0.
2. Pilot scale: two windows, 38 edges, one calibration run; per-class n=10.
3. Unlike the Jung corpus, everything ships: raw text, anchored corpus, candidates,
   verdicts, seed, calibration — the complete reproduction package
   (`james/` in the repository).

**Cost:** ≈ $6 (miners ~$1.5, gates ~$3.5, cross-vendor ~$0.02, calibration ~$1).
