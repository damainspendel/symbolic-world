# Assumptions Register

A living list of every assumption the pipeline and its experiments rest on.
Feeds the paper's *Threats to Validity* section. Each entry: the assumption,
why it was made, what would break if it's wrong, and its measurement status.

## A. Corpus

1. **Single translation.** The Hull/Bollingen translation *is* the corpus. §-numbers
   are stable across editions, but quote wording is translation-bound; no
   cross-check against the German *Gesammelte Werke* has been done. *If wrong:*
   quotes remain verbatim-correct for this edition but interpretive nuance may
   be the translator's. Status: **unmeasured** (deferred; needs GW access).
2. **Mechanical paragraph extraction is correct.** § numbers are read from epub
   markup (bracketed superscripts) with a strictly-ascending filter; never inferred.
   *If wrong:* citations point to the wrong paragraph. Status: spot-validated
   (extraction sanity checks, §1 openings verified per volume); canary-tested for
   missing paragraphs.
3. **Page concordance is edition-faithful.** §→Bollingen-page mapping comes from
   print-page anchors in the same digitization. Status: mechanically enforced by
   tests for volumes carrying anchors.

## B. Representation

4. **Triples suffice.** Jung's relational prose can be usefully (not losslessly)
   captured as subject–relation–object + one citation. Nuance loss is accepted
   and partially mitigated by verbatim relation labels. Status: design choice.
5. **Six node types** (Concept, Operation, Symbol, Figure, Substance, Motif)
   adequately partition the symbol-space; typing is curatorial. Status: design choice.
6. **Open relation vocabulary.** Relations are verbatim-faithful phrases, not a
   controlled vocabulary (157 single-use relations at last count). Assumes
   fidelity > queryability; a relation-family layer is the planned reconciliation.
   Status: tracked (warn-only vocabulary audit in the test suite).
7. **Voice is discretizable (the claim-type ternary).** Every citation is exactly
   one of `jung-asserts` / `jung-reports-parallel` / `jung-quotes-source`. Real
   paragraphs mix voices; *sympathetic reportage* (doctrine Jung reports **and**
   partly adopts) is the boundary case forced into one class. Status: **measured
   weak axis** — calibration caught only 2/5 planted **voice flips** (see D),
   and the misses were precisely sympathetic-reportage cases; the modality sweep
   (Experiment 2) is the mitigation.
8. **Hedges map to `confidence: medium`** (or a hedged relation label). Assumes a
   binary high/medium scale captures Jung's modality ("perhaps", "it seems",
   "one is driven to the conjecture"). Status: partially measured (audit found
   hedge-flattening; sweep re-checks all refs).

## C. Pipeline

9. **Letter-normalized substring = quote fidelity.** The mechanical pre-check
   normalizes case/punctuation and tolerates `...` elisions; it cannot detect a
   *misleading* splice (fragments in order but joined deceptively). The semantic
   gate is assumed to catch those (it has: e.g. the Philaletha dove/dog splice).
   Status: partially measured.
10. **Cross-family verification ≈ independence.** Proposer (Opus family) and
    verifier (Fable family) are different model families but the same vendor and
    overlapping training distributions. Correlated blind spots are possible and
    unmeasured; the planned cross-vendor tier and human community verification
    (§E) are the mitigations. Status: **assumed, partially mitigated**.
11. **The cited paragraph is a sufficient judging context.** The gate sees one
    full paragraph. Claims whose support spans paragraphs (anaphora, running
    arguments) may be judged too harshly or too leniently. Observed both ways in
    practice (gates sometimes re-cite to a neighboring §). Status: known limitation.
12. **"Strongest 15–22 relations per window" is a meaningful selection.** Mining
    is salience sampling, not exhaustive parsing; the graph is a curated map.
    Status: **measured by Experiment 3** (stability probe: independent re-mine,
    overlap statistics).
13. **The four corruption classes span the realistic error space.** Calibration
    (Experiment 1) planted reversals, voice flips, object swaps, and identity
    overreach — chosen because they are the four error classes actually observed
    across ~30 production gate batches. Novel error types remain unmeasured;
    calibration numbers generalize only to these classes. Status: explicit scope limit.
14. **The adjudication layer is conservative.** The orchestrator applies gate
    corrections and decides drop/merge/new-node for PARTIALs — a third model
    voice with discretion. Assumed to err toward dropping rather than stretching.
    Every adjudication is logged in commit messages. Status: auditable, unmeasured.
15. **Per-edge verification implies graph-level coherence.** Dedup is by exact
    triple; near-duplicate phrasings and cross-edge contradictions are not
    systematically checked. Status: known gap.
16. **The gate's SUPPORTED is trustworthy.** Now measured: 100% specificity,
    100% detection of direction reversals and wrong referents, 60% on identity
    overreach, 40% on voice flips (Experiment 1, n=40, seed 20260726).

## D. Experiment vocabulary (fixed definitions)

- **Voice flip** — corruption/error where a reported or quoted claim
  (`jung-reports-parallel` / `jung-quotes-source`) is retyped as Jung's own
  assertion (`jung-asserts`), with the source dropped. Models the most common
  real error class (attribution dishonesty).
- **Identity overreach** — an analogy/correspondence relation upgraded to
  identity (`is-analogue-of` → `is`, `corresponds-to` → `identical-to`).
- **Object swap** — the object replaced with a same-type node absent from the
  cited paragraph (wrong referent, plausible surface).
- **Reversal** — subject and object exchanged on a directional relation
  (symbolizes, prefigures, produces, …).
- **Sensitivity** — share of planted corruptions flagged (PARTIAL or WRONG).
- **Specificity** — share of clean controls passed (SUPPORTED).

## E. Planned tier: community verification (methodology sketch)

Outsourcing verification to Jungian readers/scholars is the strongest available
mitigation for assumption 10 (shared-substrate risk). Design principles:

- **Unit of work = one edge, ~2 minutes.** The evidence view already shows the
  claim, quote, claim-type, and exact §/page; a reviewer with the Bollingen
  edition confirms or disputes. Instrument = the site itself.
- **Stratified sample first, open crowd second.** Phase 1: 50–100 edges sampled
  across volumes/claim-types, sent to 2–3 known reviewers; report agreement with
  the machine gate (Cohen's κ) and inter-rater agreement between humans.
  Phase 2: open standing-falsification channel for the whole graph.
- **Blind where it matters.** Reviewers see the edge but not the gate's verdict
  or reasoning, so human judgment isn't anchored by the machine's.
- **Disputes are data.** Every dispute gets re-gated with the human's objection
  attached; outcomes (upheld/corrected/rejected) are published. Human-machine
  disagreement rate becomes a headline number alongside the audit.
- **Credit and provenance.** Reviewer confirmations recorded per-edge
  (`verified_by` gains a human entry), making the trust chain
  mechanical→model→human, visible in the evidence view.
- **Open question:** incentive design (co-authorship credit, acknowledgment,
  or a community leaderboard) and reviewer qualification (self-declared vs
  demonstrated familiarity).

*Register maintained alongside the pipeline; update on every methodology change.*
