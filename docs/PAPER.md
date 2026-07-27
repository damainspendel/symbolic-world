# Verification-First Knowledge Extraction from Interpretive Corpora: A Methodology with Measured Error Bars, Demonstrated on C. G. Jung's Collected Works

**Damian Spendel**
*AI collaborators: Claude Opus 4.8 (extraction), Claude Fable 5 (independent verification & audits), orchestration via Claude Code (Anthropic). Roles in §3 and the Authorship Note.*

*Draft v2.0 (arXiv-track) — 27 July 2026 · Artifact: [symbolicworld.observer](https://symbolicworld.observer) · Dataset & ledger: project repository, release `v1.0-cw14`+*

---

## Abstract

**This paper's contribution is primarily a methodology — and secondarily the verified dataset it produced.** Language models extract knowledge-graph facts at 30–66% accuracy and hallucinate 11–57% of citations in deployed systems; for scholarship, that is unusable. We build a knowledge graph of C. G. Jung's *Collected Works* — 233 concepts and symbols, 634 relations, 659 references, each anchored to a numbered paragraph with a verbatim quote of at most 25 words — under one rule: **no claim is published until it passes a mechanical check that its quote exists in the cited paragraph, an independent review by a model from a different family than the proposer, and an audit by a model from a different vendor.** Every reference is also typed by rhetorical voice — Jung's own claim, doctrine he reports, or a source he quotes — because voice confusion is the error that dominated every audit we ran (E2–E3, E6–E7). We measure the pipeline rather than ask anyone to trust it. Five numbers carry the result: unverified extraction ran at a **~25% flaw rate** on this corpus; the calibrated verifier catches **86% of deliberately seeded corruptions** (95% CI 78–91%) while wrongly flagging at most 7% of clean items; an adversarial audit of published references found **zero content errors**; a full-volume audit by a second vendor, judging in its own words, upheld a **1.0% residual error rate** — none of them fabrications or reversals; and the marginal cost is **$0.09–0.12 per verified citation**. All error rates, corruption seeds, and adjudications are published with the artifact (a plain-language guide to the statistics is included). The trust chain ends in humans, not models: every edge carries a check-it-yourself pointer, and live dispute and confirmation channels feed a public per-edge verification log. The machines do the hard yards; human judgement has the last word.

## 1. Introduction: the gap

Jung's *Collected Works* run to twenty volumes of densely cross-referential prose in which the same symbol (Mercurius, the lion, salt, Luna) carries systematically different meanings by context and authority. The scholarly instruments available digitally are lexical — the [ARAS concordance](https://aras.org/concordance) indexes word occurrences with headings and context, and the [ARAS image archive](https://aras.org/about-us-0) indexes ~18,000 images — but no existing resource represents the corpus as citation-grade *semantic structure*: typed relations with paragraph-level anchors that can answer "what does Jung say the green lion *is*, and on whose authority?" General surveys confirm that [digital-humanities knowledge graphs](https://arxiv.org/abs/1803.03198) concentrate on collections metadata rather than interpretive content — precisely because interpretive claims are where automated extraction is least trustworthy.

The trust problem is quantified in the NLP literature: LLM triple extractors score 29.84–66.07% fact accuracy ([KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) vs GraphRAG vs OpenIE; see also [RAG vs GraphRAG](https://arxiv.org/pdf/2502.11371)), and citation hallucination rates of 11–57% persist in deployed systems ([survey](https://arxiv.org/html/2508.15396v1); ["Cited but Not Verified"](https://arxiv.org/pdf/2605.06635)). Interpretive corpora add a subtler failure mode we call **voice conflation**: converting an author's *report* of a doctrine into the author's *own assertion*. Our production logs show this to be the single most frequent semantic error class in practice (§5, §6).

**Contributions.** (1) A publication-gated pipeline for interpretive corpora combining deterministic verbatim anchoring with cross-family adversarial verification and typed rhetorical provenance; (2) a self-measuring evaluation methodology — retro-verification, seeded-corruption calibration of the verifier, adversarial audit, full-graph error-axis sweep, extraction-stability probing, and per-axis specialist calibration — with all rates published; (3) the artifact itself: the first citation-grade semantic graph of Jung's Collected Works, publicly explorable with per-citation verification records; (4) an honest accounting of what remains hard (attribution modality; shared-vendor verification), with costed mitigations.

A note on what is primary here. The graph is the *demonstration*; the claimed contribution is the **approach**: (i) verification as a publication precondition rather than post-hoc measurement; (ii) verifiers that are themselves calibrated instruments with published sensitivity/specificity; (iii) audit lanes that cross vendor boundaries and audit the auditors' instruments; and (iv) a trust chain that is explicitly *human-terminal* — evidence views, dispute and confirmation channels, and a community tier — because a chain of models, however cross-checked, cannot certify itself. The honest status of this artifact today is: machine floor complete and measured; human ceiling operational as channels, with accumulated human verification still small. The methodology is designed so that the second grows monotonically on top of the first.

**Reader's map.** Four words are used precisely in this paper:

| Term | Meaning here | Where |
|---|---|---|
| **Method** | The rules: verbatim anchoring, independent gating, cross-vendor checking, calibration, human-terminal trust | §3 |
| **Pipeline** | The per-batch machinery that enforces the rules (proposer → pre-check → gates → cross-vendor → merge), with its transaction ledger | §3 |
| **Architecture** | The running system: corpus extraction, `seed.json`, integrity tests + canaries, the public Atlas, the verification log | §3–4 |
| **Experiments (E0–E7)** | The measurements *of* the pipeline — each answers one question, indexed at the top of §5 | §5 |

## 2. Related work

**LLM KG extraction.** [KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf), GraphRAG, OpenIE establish unverified accuracy baselines (30–66%); [schema-aware triple verification](https://arxiv.org/pdf/2604.04190) and prover–skeptic [dialogue approaches](https://arxiv.org/pdf/2603.06974) add post-hoc verification. We differ in making verification a *mandatory publication gate*, grounding it in the full source paragraph, and calibrating the verifier itself with seeded corruptions.

**Attributed generation.** Verbatim-evidence systems (FullCite / [structured inline citation](https://arxiv.org/html/2606.07130), Quote-Tuning) enforce quotation at generation time; we enforce it at dataset level as a hard deterministic check, independent of any model.

**LLM-as-judge reliability.** [Self-preference bias](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge) (measured −38% to +90%) and [debiasing work](https://arxiv.org/pdf/2508.09724) motivate our hard constraint that proposer and verifier come from different model families; our seeded-corruption calibration (§6.2) is, to our knowledge, the first published sensitivity/specificity measurement of a verification gate in a humanities KG setting.

**Industry practice.** Production extraction pipelines converge on the same skeleton independently: schema-first design, typed mechanical validation with human escalation carrying the best-effort extraction ([production document-pipeline lessons](https://medium.com/alan/lessons-from-running-an-llm-document-processing-pipeline-in-production-33d87f99cdb1)), continuous calibration of automated judges against sampled expert judgment ([HITL evaluation practice](https://www.braintrust.dev/articles/best-human-in-the-loop-llm-evaluation-platforms-2026)), and verification loops with measured diminishing returns after ~2 rounds ([verification-loop patterns](https://timjwilliams.medium.com/llm-verification-loops-best-practices-and-patterns-07541c854fd8)). Dedicated KG fact-verification agents ([AgentKGV](https://arxiv.org/html/2607.09092)) treat verification as a first-class subsystem. Our pipeline is the documented, measured instance of this consensus applied end-to-end to an interpretive humanities corpus — orthodox where it should be (cross-model judging, staged validation, audit artifacts), novel where it counts (publication-gating, seeded-corruption calibration of the judge itself, per-axis specialist decomposition, rhetorical-voice provenance).

**Nearest existing artifacts.** No knowledge graph of Jung's Collected Works exists, to our knowledge. Jung's existing digital tooling is search, not relations: the [ARAS Concordance](https://aras.org/concordance) (a 25-year manual project offering word/topic search with quotes and context) and Princeton's New Complete Digital Edition (navigation and full-text search) both retrieve *occurrences* — neither represents what Jung said a symbol *is*, on whose authority, nor verifies such claims. The closest methodological neighbor is the [Darshana Graph](https://arxiv.org/abs/2606.18222) (2026): a 125K-record corpus of Indian philosophy with an LLM extraction pipeline and a candid account of its limitations — including cases where an independent embedding analysis *disagrees* with the graph's findings. The instructive contrast: Darshana reports extraction unreliability as a finding — its author explicitly identifies a randomly sampled precision evaluation as "the most valuable immediate extension of this work" — while our pipeline operationalizes exactly that extension and goes further: sampled precision evaluation is here a *publication precondition* (verbatim anchoring, calibrated gates, stratified and full-volume sampled audits E6–E7), with the measured residual published. Our annotators are so far models from two vendors rather than multiple humans; the human-annotator tier is the planned completion (§8). [Cultural-heritage KG work on scholarly debates](https://arxiv.org/pdf/2511.10354) combines LLMs with ontological engineering but likewise without per-claim verbatim gating or verifier calibration. We believe the combination presented here — mandatory mechanical quotation anchoring, independent cross-family gating as a publication gate, seeded-corruption calibration of the verifiers themselves, typed rhetorical voice, and a standing cross-vendor audit — has no published precedent as an integrated artifact.

**Scholarly provenance.** Our claim typing consciously adapts two lines of work, and each of our references can be read as an instance of both.

*Nanopublications* ([Kuhn et al. 2018](https://arxiv.org/pdf/1809.06532)) package every atomic scientific claim as a self-contained triple of named graphs — **assertion** (the claim), **provenance** (how it is known), **publication info** (who packaged it, when) — identified by content-hashed "trusty URIs"; 10.8M exist, averaging 11.3 provenance triples per claim. Every reference in our dataset already carries exactly this anatomy, and would serialize directly. One of ours, as a nanopublication:

```
:assertion {
  :blood  sw:synonym-of  :aqua-permanens .
}
:provenance {
  :assertion  prov:wasQuotedFrom  cw:vol14_par401 ;      # CW 14, §401
              sw:quote "one of the best-known synonyms
                        for the aqua permanens" ;         # verbatim, mechanically checked
              sw:claimType sw:jung-asserts .              # whose claim it is
}
:pubinfo {
  :  prov:wasGeneratedBy  sw:pipeline-v2 ;
     sw:proposedBy "claude-opus-4-8" ;
     sw:verifiedBy "claude-fable-5" ;  sw:verifiedDate "2026-07-27" ;
     sw:crossVendorAudit "gemini-3.1-pro (E6)" .
}
```

The construction ledger (one commit per stage transition) plays the role of the trusty-URI immutability guarantee; emitting the graph natively in nanopublication format is planned but not yet implemented (§8).

*Provenance-enhanced statements* ([Vitali & Pasqual 2026](https://arxiv.org/html/2606.15246)) argue that provenance is not neutral metadata but **epistemic stance**: attributed claims live in distinct "cognitive worlds" (known / believed / conjectured) with formal rules — *permeation* — for when a claim crosses from someone's belief-world into accepted fact. Our claim-type trichotomy is precisely such a stance annotation, worked example:

| Paragraph evidence | claim_type | Cognitive world |
|---|---|---|
| "the experience of the self is always a defeat for the ego" (CW 14 §778) | `jung-asserts` | Jung's own assertoric layer |
| "why it was that Adam should have been selected as a symbol for the prima materia" (CW 14 §552) | `jung-reports-parallel` | the alchemists' belief-world, which Jung reports without owning |
| Orthelius on the quintessence "whose action may be compared with that of Christ" (CW 12 §512) | `jung-quotes-source` (source: Orthelius) | a named author's world, quoted |

The correspondence is diagnostic, not decorative: our one systematically hard residual — *sympathetic reportage*, doctrine Jung reports **and** partially adopts — is exactly Vitali & Pasqual's permeation in mid-transit: a claim between the alchemists' world and Jung's own. Both our verifiers (across two vendors) fail on the same permeating items (E1/E6), which suggests the difficulty is a property of the epistemic structure of the text, not of any model — and that the right representation for such cases is an explicit permeation marker (our `confidence: medium` and logged both-defensible adjudications are informal versions of one) rather than a forced binary.

## 3. Method

**Corpus.** Paragraph records `{volume, §, text, page}` are extracted mechanically from epub markup (§ numbers read from bracketed superscript markers, strictly-ascending filter; never inferred). A §→Bollingen-page concordance is carried per record. The corpus remains local; only ≤25-word verified quotes are published.

**Pipeline overview.**

```
        TRANSACTION LEDGER  (pipeline/state.json — one commit per stage transition)
           ▲            ▲            ▲             ▲               ▲
corpus     │            │            │             │               │
window     │            │            │             │               │
┌─────────┐│            │            │             │               │
│PROPOSER ││   MECHANICAL      STAGE 1        STAGE 2        CROSS-VENDOR      ADJUDICATED
│Opus 4.8 │┴─▶ PRE-CHECK   ─▶  STRUCTURE  ─▶  VOICE      ─▶  CHECK         ─▶  MERGE
└─────────┘    verbatim        GATE           SPECIALIST     Gemini 3.1 Pro      │
               substring;      Fable 5:       Fable 5:       (different          ▼
               nodes; dups     support,       claim-type,    VENDOR, blind)   seed.json
               (determin-      direction,     source,                            │
               istic)          referent,      hedges only                        ▼
                               conflation                            integrity tests + canaries
                                                                                 │
                                                                                 ▼
                                                                            public Atlas
                                                                                 │
   periodic full-graph audits (shared-rubric and rubric-free) ◀─────────────────┘
   + adversarial cross-review of adjudications + prompt-bias audit
   — findings re-enter the adjudicated merge above
```


Rejected candidates stop at their stage; PARTIAL verdicts carry concrete corrections applied at merge; every WRONG is logged. Calibration (seeded corruption) attaches measured sensitivity/specificity to each verification stage (E1, E5).

**Pipeline (per batch, transaction-logged).**
1. *Propose* (Claude Opus 4.8): 12–22 candidate edges from a contiguous window; verbatim quotes; node-vocabulary reuse; claim-typing rules (reported doctrine must be typed as reported).
2. *Mechanical pre-check* (deterministic): each quote must appear as an in-order, letter-normalized substring of its cited paragraph (ellipsis-tolerant); node existence; duplicate-triple rejection.
3. *Independent verification, two stages* (Claude Fable 5, different family from the proposer; a second-**vendor** auditor stands behind both — step 6). **Stage 1 — structure gate** (generalist): full-paragraph review for support, direction, referent, quote fidelity across elisions, and conflation → SUPPORTED / PARTIAL(+concrete correction) / WRONG. **Stage 2 — voice specialist** (narrow): claim-type honesty, source attribution, and hedge fidelity only. The decomposition is motivated and validated empirically (§6, E5): narrowing the verifier's semantic responsibility doubled detection on the weak axis at ~+$0.02/citation.
4. *Adjudicated merge*: corrections applied; WRONG dropped and logged; provenance stamped (`verified_by`, `verified_date`).
5. *Integrity tests* (all quotes/anchors/types/provenance re-validated on every change, plus five **corruption canaries that must fail** — self-testing validators) → deploy → commit.
6. *Cross-vendor check* (Google Gemini 3.1 Pro — different **vendor**, not merely different family). **This is a standing stage of the methodology, and going forward it runs before publication**: each gated batch is re-judged by the second vendor prior to merge, with disagreements adjudicated (and the adjudication itself open to the auditor's adversarial cross-review). The graph built before this stage existed was audited retroactively instead — a stratified sample under the shared rubric (E6) and a full volume rubric-free (E7) — which is what validated promoting the check from experiment to gate. At measured cost (~a tenth of a cent per citation) there is no economic reason to leave it post-hoc. Periodic full-graph audits continue on a cadence as drift insurance (full workflow below).

Every batch transition is committed to a ledger (`pipeline/state.json`); the construction history is replayable and auditable commit-by-commit.

**The cross-vendor loop in detail.** Beyond the per-batch pre-merge check (stage 6 above), the second-vendor auditor also runs periodic full-graph audits — a workflow that audits the pipeline *and its own instruments*, not just edges. This is the loop that validated promoting the cross-vendor check into the pipeline (E6–E7 were its first two runs, executed retroactively over the already-published graph):

```
graph (stratified sample or full volume)
   ▼
CROSS-VENDOR AUDITOR — blind to prior verdicts
   │  mode a) shared production rubric (comparable)
   │  mode b) rubric-free, own-terms judgment (independent)
   ▼
ADJUDICATION — each disagreement ruled on against the paragraph; all rulings logged
   ▼
ADVERSARIAL CROSS-REVIEW — the auditor re-reviews the adjudicator's rulings
   │  (conflict-of-interest control; 2 stronger remedies forced in E6)
   ▼
PROMPT-BIAS AUDIT — the auditor critiques the first-party gate prompt itself
   ▼
corrections → adjudicated merge → tests + canaries → deploy → commit
```


The lane exists because a single-vendor chain cannot see its own correlated blind spots (threat i) and its adjudicator cannot referee its own vendor's disputes (threat vi). Two design rules follow from its first runs: audit findings feed the same adjudicated-merge machinery as batch verdicts (no separate, weaker path into the graph), and each audit alternates between the shared production rubric (comparable, but convergence-biased — threat vii) and a rubric-free replication in which the second vendor judges support and severity entirely in its own terms.

**Schema.** Nodes `{id, type ∈ {Concept, Operation, Symbol, Figure, Substance, Motif}, label}`; edges `{subject, relation (open vocabulary, verbatim-faithful), object, references[]}`; references `{volume, §, quote, claim_type, source?, confidence, verified, verified_by, verified_date}`.

## 4. The artifact

233 nodes · 634 edges · 659 references across 468 distinct paragraphs of nine CW volumes; CW 14 (*Mysterium Coniunctionis*) covered end-to-end (413 refs), CW 12 at 87 and growing. Claim types: 438 *jung-asserts*, 160 *jung-reports-parallel*, 61 *jung-quotes-source* over 74 named sources; 84 references carry hedged (medium) confidence. The public Atlas renders six typed regions with search and walkable citations; **every citation expands to its verification record** (claim-type explanation, source, confidence, verifier, date, check-it-yourself pointer), and the About panel carries a standing falsification offer. The mechanism has three parts: (1) **per-edge evidence view** — every citation in the Atlas expands to its full verification record (claim type with explanation, source, confidence, verifier and date, and a check-it-yourself pointer to the exact § and Bollingen page), so refutation requires only the printed edition and ~2 minutes; (2) **structured dispute reports** — the evidence view generates a prefilled dispute report (edge triple, citation, quote, verification record) that a reader submits through the [repository issue tracker](https://github.com/damianspendel/symbolic-world/issues); (3) **adjudication protocol** — dispute admissibility is itself gated (the channel requires an authenticated account, and a dispute must state what the cited paragraph actually says; reports that do not engage the paragraph are closed as incomplete without adjudication — the same paragraph-grounding rule the pipeline applies to itself); an admissible disputed edge is re-gated with the reader's objection attached to the payload; outcomes (upheld / corrected / removed) are published in the repository, and the edge's evidence view links its dispute history. Accumulated upheld disputes exceeding the published error bar falsify the pipeline claim itself, not just individual edges; (4) **reader confirmations** — the symmetric positive channel: a reader who checks a cited paragraph submits a confirmation report (same gated intake, same admissibility rule), and accepted confirmations are published in the verification log and displayed in the edge's evidence view ("reader-confirmed ×N") — human verification accumulating as per-edge provenance, edge by edge, which is the operational form of the human tier rather than a one-off study.

## 5. Experiments and results

All seeds, keys, verdicts, and scoring scripts are in `docs/experiments/` and the pipeline ledger. A plain-language guide to every statistic used below is in `docs/STATS_GUIDE.md`. One line per experiment:

| E | Question it answers | Headline result |
|---|---|---|
| E0 | How bad is *unverified* extraction? | ~25% flawed (238 refs re-verified) |
| E1/E1b | How good is the verifier, measured with planted errors? | 86% sensitivity (CI 78–91%) / 93% specificity (n=200) |
| E2 | Do published edges survive an audit told to *break* them? | 0 content errors in 30 |
| E3 | How often is the *voice* of a claim mislabeled graph-wide? | 10.3% corrected; error rate falls with pipeline age |
| E4 | Would an independent re-extraction find the same graph? | Core claims stable; 37.5% strict pair overlap |
| E5 | Does narrowing the verifier's brief help on the weak axis? | Directionally yes (5/6 vs generalist), pending larger n |
| E6 | Does a *different vendor* agree with the published graph? | 0 unsupported in 100; 4 nuance corrections upheld |
| E7 | …even without our rubric, on a full volume? | 1.0% upheld residual in 407; rubric effect ≈ zero |

And the same experiments placed where they bite — each stage of the pipeline is measured by the experiment(s) beneath it:

```
 PROPOSER ──▶ MECHANICAL ──▶ STAGE 1  ──▶ STAGE 2  ──▶ CROSS-VENDOR ──▶ MERGE ──▶ PUBLISHED
 Opus 4.8     PRE-CHECK      STRUCTURE    VOICE         CHECK                      GRAPH
    ▲             ▲          GATE ▲       SPECIALIST    Gemini ▲                     ▲
    │             │               │            ▲               │                     │
┌───┴────────┐┌───┴───────┐┌──────┴─────┐┌─────┴─────┐┌────────┴───────┐┌────────────┴──────────┐
│ E0 what if ││ canaries: ││ E1/E1b     ││ E5 seeded ││ E6 shared-     ││ E2 adversarial audit  │
│ we skipped ││ 5 planted ││ seeded     ││ voice     ││ rubric audit   ││    (0 errors in 30)   │
│ the gates? ││ corrupt-  ││ errors:    ││ errors:   ││ (0 unsupported ││ E3 full-graph voice   │
│ (~25%      ││ ions MUST ││ 86% sens / ││ 5/6       ││  in 100)       ││    sweep (10.3% fixed)│
│ flawed)    ││ be caught ││ 93% spec   ││ caught    ││ E7 rubric-free ││ E4 independent        │
│ E4 re-mine:││ on every  ││ (n=200,    ││ (small n) ││ full volume    ││    re-extraction:     │
│ same core  ││ test run  ││ with CIs)  ││           ││ (1.0% residual)││    core claims stable │
│ claims?    ││           ││            ││           ││                ││                       │
└────────────┘└───────────┘└────────────┘└───────────┘└────────────────┘└───────────────────────┘
  measures      tests the    calibrates    calibrates    validates the     audits the published
  the raw       validators   this gate     this gate     new stage         artifact end-to-end
  proposer      themselves
```


**E0 — Retro-verification of ungated extraction (n=238).** All references mined before the gate became mandatory were re-verified by the standard gate: 178 confirmed, 54 corrected, 6 edges deleted — a **25.2% flaw rate for unverified LLM extraction** on this corpus, consistent with public benchmarks. Dominant classes: voice conflation, identity overreach, referent drift, direction reversal; deletions included a spliced quote and a reversed symbolization.

**E1 — Verifier calibration by seeded corruption (n=40, seed 20260726, blind).** 20 intact controls + 20 corruptions (5 each: direction reversal, voice flip, object swap, identity overreach), quotes/paragraphs untouched so only the semantic gate is tested; production prompt; key withheld. Results: **specificity 20/20 (100%)**; sensitivity 15/20 (75%) — **reversal 5/5, object swap 5/5**, overreach 3/5, **voice flip 2/5**. Missed voice flips were sympathetic-reportage cases (doctrine Jung partially adopts) — genuinely ambiguous voice.

**E1b — Expanded calibration (n=200, seed 20260727, blind).** The per-class sample was expanded tenfold (25 corruptions per class + 100 intact controls; reversal corruptions restricted to directional relations — a design fix, since reversing a symmetric relation is not a corruption). Results with 95% Wilson intervals: **sensitivity 86/100 (86%, CI 78–91%)**, **specificity 93/100 (93%, CI 86–97%)**; reversal **23/25 (92%)**, object-swap **24/25 (96%)**, overreach 21/25 (84%), voice-flip **18/25 (72%, CI 52–86%)**. Two honest consequences: (i) E1's n=5 voice-flip estimate (2/5) was noisy — the generalist's true voice baseline is materially higher, which **narrows the measured generalist–specialist gap** (72% vs 5/6; directionally consistent across all four first-party and cross-vendor measurements, but not statistically resolved at current specialist n — the E5 claim is downgraded accordingly); (ii) measured specificity is a **lower bound**: the 7 flagged controls are production references, and several flags are plausible nuance findings of the familiar vocabulary/voice class — one was upheld and corrected in the graph. Full tables: `docs/experiments/exp1b_expanded_calibration.md`.

**E2 — Adversarial audit of published references (n=30, seed 20260725).** A differently-prompted reviewer instructed to *break* each edge: **0 content/direction/fabrication errors**; 4 disputes (13.3%), all attribution/modality refinements; all applied.

**E3 — Full-graph modality sweep (n=634, complete).** A narrow auditor checking only claim-type and hedge fidelity flagged **65/634 (10.3%)**: 50 claim-type corrections (including **5 in the reverse direction** — Jung's own theses mistyped as reportage, showing the audit is not a systematic deflation of the author's voice), 10 source corrections, 15 hedge downgrades — all applied. Flag rate by extraction age: **18.9% on the oldest edges → 5.6% on the newest**, and the three most recent production batches passed the gate **60/60** — evidence that gate corrections, fed back into extractor instructions, compound into first-pass precision. Three independent methods now converge on the modality error rate (~10–13%: audit 13.3%, calibration voice-flip deficit, sweep 10.3%).

**E4 — Extraction stability probe (n=40 across two windows, blind).** Two already-mined windows re-mined independently with a fixed "20 strongest relations" budget (shared node vocabulary; prior triples withheld): strict unordered {subject, object} pair overlap with the graph was **7/20 (35%)** on CW14 §371–440 and **8/20 (40%)** on CW12 §332–420 — **37.5% combined**. Core theses recur near-verbatim across runs; non-overlap decomposes into complementary genuine edges (the windows hold 29–33 graph edges each, more than one 20-edge budget can cover), schema-shape variants of the same insight, and one case where the probe independently re-found an edge that adjudication had dropped on schema grounds. The graph is therefore a *stable curated map*, not an exhaustive parse; union-mining is the costed coverage upgrade.

**E5 — Voice-specialist calibration (n=20, seed 20260727, blind).** Per-axis seeded corruption of post-sweep ground truth (6 voice flips, 4 hedge strips, 10 clean controls) run through the narrow stage-2 auditor: **sensitivity 80%** (voice flips **5/6 = 83%**, hedge strips 3/4), **specificity 10/10 (100%)**. Against the generalist's 40% voice-flip detection on the same error class (E1), this is a direct, controlled measurement of what we shorthand *semantic diffusion* in verification — task decomposition is well documented for generation (least-to-most prompting, chain-of-thought decomposition, plan-and-solve); our contribution is not the decomposition idea but its seeded-corruption *measurement on the verification side*, replicated cross-vendor: same model, same paragraphs, scope narrowed from five criteria to one — detection improved on paired items (2/5→5/6 first-party; 2/6→4/6 cross-vendor) at zero false-positive cost. The expanded calibration (E1b) revises the generalist voice baseline upward to 72%, narrowing the measured gap; we therefore state the specialist advantage as **directionally consistent across four measurements but pending a larger specialist calibration for statistical resolution** — an honest downgrade the larger sample forced, and an example of the methodology auditing its own earlier claims. The two residual misses are the same sympathetic-reportage boundary cases identified by E1 and E3.

**E6 — Cross-vendor verification audit (n=100 production edges + calibration replays, Gemini 3.1 Pro).** The one structural weakness of a single-vendor trust chain is correlated blind spots between proposer and verifier. A verifier from a different vendor (Google Gemini 3.1 Pro, temperature 0, same production gate prompt, blind to prior verdicts) audited a stratified sample of 100 published edges (strata: volume × claim type × extraction age): **89 SUPPORTED, 11 PARTIAL, 0 WRONG** — zero fabrications, reversals, or unsupported edges found by an independent vendor, and every disagreement confined to the attribution/referent-nuance axis the pipeline already identifies as its residual weakness. Adjudication of the 11 disagreements against the ground-truth paragraphs: **4 upheld** (two referent-precision errors — an edge anchored to a paragraph naming the *filius regius* rather than Rex, and one naming Adam rather than Anthropos — one subject overreach, one referent demotion; all corrected, two near-duplicate edges removed), **5 both-defensible** (the sympathetic-reportage boundary), **2 not upheld** (one objection to ellipsis splicing permitted by the stated quotation rule, one strict-vocabulary reading). Because all sampled edges were published (the first-party verifier's marginal is degenerate), κ is uninformative here; the two-sided comparison comes from calibration replays: on the E1 corruption set Gemini scores **70% sensitivity / 95% specificity** (Fable: 75%/100%), with reversals and object swaps 5/5 and voice flips 2/5 — **missing the same individual voice-flip items as Fable**, evidence that these items are intrinsically ambiguous rather than a vendor blind spot; on the E5 set the narrow voice brief lifts Gemini's voice-flip detection from 33% to 67% (Fable: 40% → 83%) — **the semantic-diffusion effect replicates across vendors**. The orchestrator's dispute rulings were then adversarially reviewed by the cross-vendor model (9 AGREE / 2 PARTIALLY-AGREE / 0 DISAGREE); both partial agreements argued for stronger remedies than confidence demotion, and both were accepted (two referent retargets). Post-audit graph at the time of E6: 228 nodes, 608 edges, 633 references (the graph has since grown under the same pipeline rules; §4 states current counts). E6's headline is stated precisely: zero unsupported edges *under the shared rubric* (see threat vii).

**E7 — Rubric-free cross-vendor audit (n=407, full CW14 + calibration replay, Gemini 3.1 Pro).** E6's prompt-bias audit raised *shared-rubric convergence*: agreement measured under the first vendor's rubric partly reflects shared thresholds. E7 removes the rubric — no verdict enum, no claim-type definitions, no strictness persona; the second vendor judges every CW 14 reference (the full volume, n=407) in its own terms. Results: **356 supported / 47 partly / 4 no**; on the auditor's own severity scale, 350 none / 47 minor / 8 moderate / 2 serious. Adjudication of the 10 moderate+serious findings upheld **4 (1.0%)** — one misanchored edge deleted, one relation and one subject retargeted, one relation relabeled; none was a fabrication or reversal. The decisive measurement is the calibration replay: Gemini's rubric-free detection profile is **identical** to its with-rubric profile (70% sensitivity, 95% specificity, same per-class breakdown, same three missed sympathetic-reportage voice flips), and on the 58 doubly-audited references, verdict consistency across modes is **55/58 (95%)** with all three divergences in the *stricter* direction. Shared-rubric convergence — a legitimate concern — has a measured impact of ≈ zero on these error classes: detection is driven by the paragraph evidence, and the rubric's real function is output comparability, not verdict steering (threat vii, discharged with measurement).

**Cost.** From production telemetry (~97K tokens/miner batch, ~56K/gate batch at $5/$25 and $10/$50 per MTok): ≈ **$0.09 per verified citation**, ≈ $0.12 including retro-verification, audit, and calibration overhead; total artifact cost ≈ $60–90.

## 6. Discussion: what the process revealed

1. **Verification is where the value is created.** A quarter of unverified extractions were flawed; after gating, adversarial audits find zero content errors. *Takeaway: the checking is not overhead on the product — it is the product.*

2. **Two kinds of mistakes, and machines are only good at one of them.** *Shape* mistakes — who does what to whom: wrong direction, wrong object — are caught almost every time (92–96% in calibration). *Voice* mistakes — who is speaking: Jung himself, or the alchemists he is describing — are caught only about three times in four. So nearly everything that slips through is a voice mistake. Like proofreading: the spellchecker catches spelling nearly perfectly; whether a sentence is sincere or sarcastic survives it. *Takeaway: the residual risk in this graph is almost entirely "whose claim is this," not "is this claim there."*

3. **Voice is genuinely hard — for machines and probably for people.** "Sympathetic reportage" — doctrine Jung reports *and* half-adopts — resists a clean three-way label; every model configuration we tested, across two vendors, missed the same borderline items. *Takeaway: where our verifiers disagree or fail marks real ambiguity in Jung's text — a finding about Jung, not just about models — and it is exactly where human judgement is required (§8).*

4. **The gate teaches the miner — by editing its instructions, not its weights.** When the verifier corrects a batch ("you typed reported doctrine as Jung's own claim"), those corrections are folded into the *next* batch's extraction instructions as explicit rules and examples. The extraction model never changes; its briefing does. Result: error flags fell from 18.9% on the oldest batches to 5.6% on the newest, and recent batches pass 20/20. *Takeaway: a feedback loop between checker and extractor steadily improves first-pass quality, with no model training involved.*

5. **A checker given five things to check does the obvious ones well and the subtle one poorly; given one thing, it does that one well.** The same model that caught 40–72% of voice errors as a five-criteria generalist caught 5/6 as a single-axis specialist, and the same improvement appears with the other vendor's model (2/6 → 4/6). The expanded calibration narrowed the measured gap, so we state this as directionally consistent across four measurements, pending larger samples. *Takeaway: don't ask one reviewer to check everything — measure where checking is weak, then assign a narrow specialist to that axis.*

6. **The graph is complete in claims, not in pages.** It cites 34% of CW 14's paragraphs, yet independent re-extraction recovers each chapter's core claims (E4) — because most paragraphs argue, illustrate, or amplify rather than assert a new relation. Like a topographic map, it is complete above a chosen prominence, not in every hill; union-mining lowers that threshold at ~$2 per window. *Takeaway: judge coverage by whether the chapter's load-bearing claims are present, not by paragraph counts.*

7. **Trust can be made inspectable.** Per-citation verification records, published error rates, self-testing validators, and live dispute/confirmation channels convert "trust us" into "check us." *Takeaway: every claim in the atlas can be checked by anyone with the book, in about two minutes — and the mechanisms for saying so publicly are built in.*

## 7. Threats to validity

A 16-item assumptions register is published (`docs/ASSUMPTIONS.md`). The principal threats, with what is actually done about each and what the data says:

| # | Threat | Mitigation in force | Evidence / data | Residual |
|---|---|---|---|---|
| i | **Shared-substrate risk** — proposer and verifier share one vendor; correlated blind spots invisible to both | Cross-vendor check now a pipeline stage; full retro audits E6–E7 | 0 unsupported edges (n=100); 1.0% upheld residual (n=407); both vendors miss the *same* voice items → text ambiguity, not vendor blind spot | Low; both audits so far use one second vendor |
| ii | **Single translation** — quotes are Hull/Bollingen-bound | § anchors are edition-stable; documented as assumption #1 | — | German *GW* cross-check deferred (§8) |
| iii | **Salience sampling** — "strongest relations" per window, not exhaustive parse | Stability probe; union-mining; claim-coverage framing (§6.6) | E4: independent re-extraction recovers core claims (37.5% strict pair overlap, theses stable); union batch: 13/20 re-findings | Tier-2 claims sampled, not complete |
| iv | **Calibration scope** — sensitivity measured only on four seeded corruption classes | Classes chosen from observed production errors; expanded to n=200 | E1b: 86% (CI 78–91%) / 93% spec; per-class 72–96% | Unknown error types unmeasured, by construction |
| v | **Single-paragraph judging context** — cross-paragraph claims can be mis-scored | Documented; flagged cases adjudicated case-by-case | E7: 2 of 10 moderate flags were cross-paragraph context cases (both-defensible) | Standing; a windowed-context gate would cost ~2× |
| vi | **Adjudication discretion** — the orchestrator (an Anthropic model) rules on disputes | All rulings published verbatim; adversarial cross-review by the second vendor | E6: cross-review accepted 9/11 rulings and forced 2 stronger corrections | Cross-review is one round; full independence awaits the human tier |
| vii | **Shared-rubric convergence** — agreement partly an artifact of handing the auditor our rubric | Rubric-free replication mode (E7) | Identical detection profile with and without rubric; 95% cross-mode verdict consistency | Measured ≈ zero on tested classes |
| viii | **Human tier still thin** — channels live, accumulated human data ≈ zero | Confirm/dispute channels shipped; community pilot planned (§8) | Channel e2e-tested; 0 reader confirmations to date (stated plainly) | The main open gap — see §8 |

## 8. Limitations and future work

Coverage beyond CW14/CW12 is thin; eleven volumes untouched. The relation vocabulary is open (single-use relations pending a relation-family layer). The cross-vendor stage is implemented and standing (E6–E7; pre-publication for all future batches, §3); what remains is only its ongoing cadence commitment as the graph grows. Planned: **(a) expanded specialist calibration** — the E5 voice-specialist sample is still small (n=6 per axis) and the specialist-advantage claim awaits statistical resolution; **(b) community verification** — blind review by Jungian readers with the evidence view as instrument, human–machine κ published, human confirmations entering the per-edge provenance chain (protocol in `docs/ASSUMPTIONS.md` §E); **(c) a declarative verifier registry** — each verification stage defined as configuration (model, axis, prompt, output schema, and its own calibration set with last measured sensitivity/specificity) over one shared runner and verdict-applier, making specialist decomposition an operable pattern rather than a finding: a new corpus axis becomes a registry entry, and every stage's quality is attached, re-measurable data; **(d) German *Gesammelte Werke* cross-check; (e) DOI-registered dataset releases, including a native nanopublication serialization of the graph (each reference already carries the assertion/provenance/publication-info anatomy, §2); (f) explicit permeation markers for sympathetic reportage, adapting the DEC cognitive-worlds semantics (§2) to replace the informal confidence downgrade.**

## 9. Conclusion

For interpretive corpora, the question is not whether LLMs can extract structure — they can, at ~75% — but whether a pipeline can be built where the published artifact is *measurably* better than its extractor, and honest about the remainder. The Symbolic World demonstrates one affirmative design: deterministic grounding, cross-family adversarial gating, typed voice provenance, self-testing validators, and published error bars, at ~$0.10 per verified claim. The method contains nothing Jung-specific: any authored corpus where *who said what, exactly where* is the scholarly currency is a candidate.

---

### Authorship note

Conception, direction, corpus provision, publication decisions, and final responsibility: **Damian Spendel**. Edge proposal: *Claude Opus 4.8* (Anthropic). Independent verification, audits, calibration runs: *Claude Fable 5* (Anthropic). Cross-vendor auditing, adjudication cross-review, and prompt-bias critique: *Gemini 3.1 Pro* (Google). Orchestration, tooling, experiments, drafting: *Claude Code* (Anthropic), under the author's instruction. Proposer/verifier family separation — and the second-vendor audit tier — are deliberate design constraints.

**Artifact availability.** Dataset, pipeline code, transaction ledger, all experiment inputs/verdicts/adjudications, and this paper: [github.com/damianspendel/symbolic-world](https://github.com/damianspendel/symbolic-world) (public; the issue tracker is the standing dispute channel described in §4). Live atlas: [symbolicworld.observer](https://symbolicworld.observer).

### Key references

- [KGGen (NeurIPS 2025)](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) · [RAG vs GraphRAG](https://arxiv.org/pdf/2502.11371)
- [Attribution, Citation, and Quotation: A Survey](https://arxiv.org/html/2508.15396v1) · [Cited but Not Verified](https://arxiv.org/pdf/2605.06635)
- [Self-Preference Bias in LLM-as-a-Judge](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge) · [UDA](https://arxiv.org/pdf/2508.09724)
- [Structured Inline Citation Generation](https://arxiv.org/html/2606.07130) · [Schema-Aware Triple Verification](https://arxiv.org/pdf/2604.04190) · [Prover–Skeptic KB Generation](https://arxiv.org/pdf/2603.06974)
- [Nanopublications](https://arxiv.org/pdf/1809.06532) · [Provenance-Enhanced Statements](https://arxiv.org/html/2606.15246)
- [KGs in Libraries & Digital Humanities](https://arxiv.org/abs/1803.03198) · [ARAS Concordance](https://aras.org/concordance)
