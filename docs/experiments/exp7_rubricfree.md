# E7 — Rubric-free cross-vendor audit (Gemini 3.1 Pro)

**Date:** 2026-07-27 · **Design:** mitigation for shared-rubric convergence (E6 prompt-bias audit)
**Runner:** `pipeline/crossvendor_run.py e7` · **Verdicts:** `pipeline/work/gemini_e7_verdicts.json`, `gemini_e7_calib_verdicts.json`

## Design

E6's prompt-bias audit found that giving a second vendor the first vendor's verdict rubric
and claim-type ontology risks *shared-rubric convergence*: agreement that partly reflects
shared thresholds rather than independent judgment. E7 removes the rubric entirely: no
verdict enum, no claim-type definitions, no strictness persona. Gemini judges each item in
its own terms — supported yes/partly/no, problems described in its own words, seriousness
on its own scale — over **all 407 CW14 references** (the full volume, not a sample) plus a
replay of the E1 seeded-corruption set.

## Results — full CW14 sweep (n=407)

| supported | n | | seriousness | n |
|---|---|---|---|---|
| yes | **356** | | none | 350 |
| partly | 47 | | minor | 47 |
| no | 4 | | moderate | 8 |
| | | | serious | 2 |

## Adjudication of the 10 moderate/serious findings

**Upheld — 4 (all corrected):**

| Edge | Finding | Fix |
|---|---|---|
| regina —amplified-by→ green-lion (§414) | queen *drinks* the lion's blood; the ¶'s amplification is queen ↔ whore of Babylon | relation → `drinks-blood-of`; claim → reports-parallel (Cantilena content) |
| anthropos —parallels→ atman (§488) | ¶ names Purusha and Gayomart; Atman absent | single-ref edge **deleted** (an atman parallel must be re-mined with its own anchor) |
| filius-regius —synonym-of→ rebis (§472) | ¶'s "filius unius diei" ≠ filius regius; the designation is for the Hermaphrodite of nature = arcane substance | subject → `arcane-substance`, quote re-anchored |
| active-imagination —symbolizes→ individuation (§705) | text says *representation of* the individuation process, an equation not a symbolization | relation → `represents` |

**Partially upheld — 1:** diana —is-analogue-of→ luna (§200): the Diana identification
depends on the previous paragraph (threat v: judged context = one ¶) → confidence `medium`.

**Both-defensible — 5:** three "second Adam" ↔ anthropos mappings (§565, §484, §631 — the
graph's documented vocabulary convention; note the *second* Adam is distinct from the
first-Adam/prima-materia case upheld in E6), one unio-mentalis term-adjacency (§671), one
Cantilena speaker-from-context (§380).

The 47 minor flags are catalogued (same classes: strict-vocabulary readings and
cross-paragraph context); none alleges an unsupported or reversed claim.

**Post-audit graph: 231 nodes · 627 edges · 652 references.** Residual content-error rate
from a full-volume, own-terms, second-vendor sweep: **4/407 ≈ 1.0%** upheld errors, none
of them fabrications or reversals (all referent/relation nuance).

## The headline: the rubric was not doing the work

**Rubric-free calibration replay (E1 corruption set, n=40):**

| Metric | Gemini rubric-free (E7) | Gemini with rubric (E6 replay) | Fable with rubric (E1) |
|---|---|---|---|
| Sensitivity | **14/20 (70%)** | 14/20 (70%) | 15/20 (75%) |
| Specificity | **19/20 (95%)** | 19/20 (95%) | 20/20 (100%) |
| reversal | 5/5 | 5/5 | 5/5 |
| object-swap | 5/5 | 5/5 | 5/5 |
| overreach | 2/5 | 2/5 | 3/5 |
| voice-flip | 2/5 | 2/5 | 2/5 |

Gemini's detection profile **without the rubric is identical to its profile with it** —
same totals, same per-class breakdown, and the same missed voice-flip items (n13, n16,
n37: the sympathetic-reportage cases every configuration misses). On the 58 references
audited under both modes, verdict consistency is **55/58 (95%)**, with the 3 divergences
all rubric-SUPPORTED → rubric-free-partly (the free mode is marginally *stricter*, not
more lenient).

**Conclusion:** shared-rubric convergence was a legitimate methodological concern with a
measured impact of ≈ zero on these error classes. Detection is driven by the paragraph
evidence, not the grading scale; the rubric's real function is output *comparability*.
The E6 headline can accordingly be strengthened: zero unsupported edges under the shared
rubric, and a 1.0% nuance-level upheld-error rate under the second vendor's own terms.

## Cost

~410K tokens in / ~30K out across 23 chunked calls ≈ $1.1 at Gemini preview pricing.
Cumulative Gemini spend ≈ $2.6 of the allotted $15.
