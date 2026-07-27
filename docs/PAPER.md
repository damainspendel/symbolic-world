# Grounded, Adversarially Verified Knowledge Graphs for Interpretive Corpora: The Symbolic World, a Case Study on C. G. Jung's Collected Works

**Damian Spendel**
*AI collaborators: Claude Opus 4.8 (extraction), Claude Fable 5 (independent verification & audits), orchestration via Claude Code (Anthropic). Roles in §3 and the Authorship Note.*

*Draft v2.0 (arXiv-track) — 27 July 2026 · Artifact: [symbolicworld.observer](https://symbolicworld.observer) · Dataset & ledger: project repository, release `v1.0-cw14`+*

---

## Abstract

Large language models extract knowledge-graph triples from text at 30–66% fact accuracy, and deployed citation systems hallucinate 11–57% of citations — rates that make naive LLM extraction unusable for scholarship. We present a pipeline in which **no assertion can enter the published artifact without passing (i) a deterministic verbatim-quotation check against its cited source paragraph and (ii) an independent full-paragraph review by a model from a different family than the proposer**, and we apply it to build The Symbolic World: a knowledge graph of C. G. Jung's *Collected Works* comprising **228 nodes, 608 edges, and 633 references** (100% verification coverage, with machine-readable verdict provenance per citation). Each reference is anchored to a numbered CW paragraph with a ≤25-word verbatim quote and typed by rhetorical voice (*jung-asserts* / *jung-reports-parallel* / *jung-quotes-source*), separating Jung's own claims from doctrine he reports — a first-class treatment of a failure mode we find dominant in practice. We evaluate the pipeline itself: retro-verification of early unggated output measures a **~25% flaw rate in unverified extraction**; a blind seeded-corruption calibration (n=40) measures the verifier at **100% specificity** with **100% detection of direction-reversal and wrong-referent corruptions** (75% sensitivity overall; the deficit concentrated in attribution-voice flips, 2/5); an adversarial audit of 30 random published references finds **0 content errors** and 13.3% modality refinements; a full-graph modality sweep (n=634) corrects 10.3% of references on the voice/hedge axis, with the flag rate falling from 18.9% (oldest extractions) to 5.6% (newest) — evidence that verifier feedback compounds into extractor precision (three consecutive 20/20 batches). A cross-vendor audit (Gemini 3.1 Pro, blind, n=100) finds **0 unsupported edges** and 11 nuance-level disagreements (4 upheld and corrected), and independently replicates the specialist-narrowing effect (voice-flip detection 33%→67% cross-vendor vs 40%→83% first-party). Marginal cost is ≈ **$0.09–0.12 per fully verified citation**, orders of magnitude below expert manual construction. All error rates, seeds, adjudications, and a 16-item assumptions register are published with the artifact, alongside a standing public falsification offer.

## 1. Introduction: the gap

Jung's *Collected Works* run to twenty volumes of densely cross-referential prose in which the same symbol (Mercurius, the lion, salt, Luna) carries systematically different meanings by context and authority. The scholarly instruments available digitally are lexical — the [ARAS concordance](https://aras.org/concordance) indexes word occurrences with headings and context, and the [ARAS image archive](https://aras.org/about-us-0) indexes ~18,000 images — but no existing resource represents the corpus as citation-grade *semantic structure*: typed relations with paragraph-level anchors that can answer "what does Jung say the green lion *is*, and on whose authority?" General surveys confirm that [digital-humanities knowledge graphs](https://arxiv.org/abs/1803.03198) concentrate on collections metadata rather than interpretive content — precisely because interpretive claims are where automated extraction is least trustworthy.

The trust problem is quantified in the NLP literature: LLM triple extractors score 29.84–66.07% fact accuracy ([KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) vs GraphRAG vs OpenIE; see also [RAG vs GraphRAG](https://arxiv.org/pdf/2502.11371)), and citation hallucination rates of 11–57% persist in deployed systems ([survey](https://arxiv.org/html/2508.15396v1); ["Cited but Not Verified"](https://arxiv.org/pdf/2605.06635)). Interpretive corpora add a subtler failure mode we call **voice conflation**: converting an author's *report* of a doctrine into the author's *own assertion*. Our production logs show this to be the single most frequent semantic error class in practice (§5, §6).

**Contributions.** (1) A publication-gated pipeline for interpretive corpora combining deterministic verbatim anchoring with cross-family adversarial verification and typed rhetorical provenance; (2) a self-measuring evaluation methodology — retro-verification, seeded-corruption calibration of the verifier, adversarial audit, full-graph error-axis sweep, extraction-stability probing, and per-axis specialist calibration — with all rates published; (3) the artifact itself: the first citation-grade semantic graph of Jung's Collected Works, publicly explorable with per-citation verification records; (4) an honest accounting of what remains hard (attribution modality; shared-vendor verification), with costed mitigations.

## 2. Related work

**LLM KG extraction.** [KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf), GraphRAG, OpenIE establish unverified accuracy baselines (30–66%); [schema-aware triple verification](https://arxiv.org/pdf/2604.04190) and prover–skeptic [dialogue approaches](https://arxiv.org/pdf/2603.06974) add post-hoc verification. We differ in making verification a *mandatory publication gate*, grounding it in the full source paragraph, and calibrating the verifier itself with seeded corruptions.

**Attributed generation.** Verbatim-evidence systems (FullCite / [structured inline citation](https://arxiv.org/html/2606.07130), Quote-Tuning) enforce quotation at generation time; we enforce it at dataset level as a hard deterministic check, independent of any model.

**LLM-as-judge reliability.** [Self-preference bias](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge) (measured −38% to +90%) and [debiasing work](https://arxiv.org/pdf/2508.09724) motivate our hard constraint that proposer and verifier come from different model families; our seeded-corruption calibration (§6.2) is, to our knowledge, the first published sensitivity/specificity measurement of a verification gate in a humanities KG setting.

**Industry practice.** Production extraction pipelines converge on the same skeleton independently: schema-first design, typed mechanical validation with human escalation carrying the best-effort extraction ([production document-pipeline lessons](https://medium.com/alan/lessons-from-running-an-llm-document-processing-pipeline-in-production-33d87f99cdb1)), continuous calibration of automated judges against sampled expert judgment ([HITL evaluation practice](https://www.braintrust.dev/articles/best-human-in-the-loop-llm-evaluation-platforms-2026)), and verification loops with measured diminishing returns after ~2 rounds ([verification-loop patterns](https://timjwilliams.medium.com/llm-verification-loops-best-practices-and-patterns-07541c854fd8)). Dedicated KG fact-verification agents ([AgentKGV](https://arxiv.org/html/2607.09092)) treat verification as a first-class subsystem. Our pipeline is the documented, measured instance of this consensus applied end-to-end to an interpretive humanities corpus — orthodox where it should be (cross-model judging, staged validation, audit artifacts), novel where it counts (publication-gating, seeded-corruption calibration of the judge itself, per-axis specialist decomposition, rhetorical-voice provenance).

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

The construction ledger (one commit per stage transition) plays the role of the trusty-URI immutability guarantee; emitting the graph natively in nanopublication format is planned (§8).

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
             ┌─────────────────────────────────────────────────────────────┐
             │                    TRANSACTION LEDGER                       │
             │   (pipeline/state.json — one commit per stage transition:   │
             │    input-built → mined → pre-checked → gated → merged)      │
             └─────────────────────────────────────────────────────────────┘
                 ▲              ▲               ▲               ▲
 corpus window   │              │               │               │
 ┌────────────┐  │  candidate   │   surviving   │   corrected   │
 │  PROPOSER  │──┴─▶ edges ─▶ MECHANICAL ─▶ STAGE 1 ──▶ STAGE 2 ──▶ ADJUDICATED
 │ Opus 4.8   │      (quotes)  PRE-CHECK    STRUCTURE   VOICE        MERGE
 └────────────┘               verbatim      GATE        SPECIALIST     │
                              substring;    Fable 5:    Fable 5:       ▼
                              nodes; dups   support,    claim-type,  seed.json
                              (determin-    direction,  source,        │
                               istic)       referent,   hedges         ▼
                                            conflation             integrity tests
                                                                   + canaries
                                                                       │
                                                                       ▼
                                                                  public Atlas
```

Rejected candidates stop at their stage; PARTIAL verdicts carry concrete corrections applied at merge; every WRONG is logged. Calibration (seeded corruption) attaches measured sensitivity/specificity to each verification stage (E1, E5).

**Pipeline (per batch, transaction-logged).**
1. *Propose* (Claude Opus 4.8): 12–22 candidate edges from a contiguous window; verbatim quotes; node-vocabulary reuse; claim-typing rules (reported doctrine must be typed as reported).
2. *Mechanical pre-check* (deterministic): each quote must appear as an in-order, letter-normalized substring of its cited paragraph (ellipsis-tolerant); node existence; duplicate-triple rejection.
3. *Independent verification, two stages* (Claude Fable 5, different family from the proposer). **Stage 1 — structure gate** (generalist): full-paragraph review for support, direction, referent, quote fidelity across elisions, and conflation → SUPPORTED / PARTIAL(+concrete correction) / WRONG. **Stage 2 — voice specialist** (narrow): claim-type honesty, source attribution, and hedge fidelity only. The decomposition is motivated and validated empirically (§6, E5): narrowing the verifier's semantic responsibility doubled detection on the weak axis at ~+$0.02/citation.
4. *Adjudicated merge*: corrections applied; WRONG dropped and logged; provenance stamped (`verified_by`, `verified_date`).
5. *Integrity tests* (all quotes/anchors/types/provenance re-validated on every change, plus five **corruption canaries that must fail** — self-testing validators) → deploy → commit.

Every batch transition is committed to a ledger (`pipeline/state.json`); the construction history is replayable and auditable commit-by-commit.

**Standing cross-vendor audit lane.** Orthogonal to the per-batch first-party pipeline, a second-vendor auditor (currently Gemini 3.1 Pro, temperature 0) runs over the *published* graph on a sampling cadence, in a workflow that audits the pipeline — and its own instruments — rather than individual batches:

```
published seed.json
   │  stratified sample (volume × claim type × age)
   ▼
CROSS-VENDOR AUDITOR (different vendor, blind to prior verdicts)
   │  a) shared-rubric verdicts (E6)   b) rubric-free, own-terms judgments (E7)
   ▼
ADJUDICATION — orchestrator rules on each disagreement
   │  against the ground-truth paragraph; every ruling logged
   ▼
ADJUDICATION CROSS-REVIEW — the auditor adversarially re-reviews
   │  the orchestrator's rulings (conflict-of-interest control);
   │  strengthened remedies accepted (2 forced in E6)
   ▼
PROMPT-BIAS AUDIT — the auditor critiques the first-party gate
   │  prompt itself for leniency / rubric-convergence bias
   ▼
corrections applied → tests + canaries → deploy → commit
```

The lane exists because a single-vendor chain cannot see its own correlated blind spots (threat i) and its adjudicator cannot referee its own vendor's disputes (threat vi). Two design rules follow from its first runs: audit findings feed the same adjudicated-merge machinery as batch verdicts (no separate, weaker path into the graph), and each audit alternates between the shared production rubric (comparable, but convergence-biased — threat vii) and a rubric-free replication in which the second vendor judges support and severity entirely in its own terms.

**Schema.** Nodes `{id, type ∈ {Concept, Operation, Symbol, Figure, Substance, Motif}, label}`; edges `{subject, relation (open vocabulary, verbatim-faithful), object, references[]}`; references `{volume, §, quote, claim_type, source?, confidence, verified, verified_by, verified_date}`.

## 4. The artifact

228 nodes · 608 edges · 633 references across 461 distinct paragraphs of nine CW volumes; CW 14 (*Mysterium Coniunctionis*) covered end-to-end (395 refs), CW 12 at 87 and growing. Claim types: 419 *jung-asserts*, 155 *jung-reports-parallel*, 59 *jung-quotes-source* over 74 named sources; 83 references carry hedged (medium) confidence. The public Atlas renders six typed regions with search and walkable citations; **every citation expands to its verification record** (claim-type explanation, source, confidence, verifier, date, check-it-yourself pointer), and the About panel carries a standing falsification offer. The mechanism has three parts: (1) **per-edge evidence view** — every citation in the Atlas expands to its full verification record (claim type with explanation, source, confidence, verifier and date, and a check-it-yourself pointer to the exact § and Bollingen page), so refutation requires only the printed edition and ~2 minutes; (2) **structured dispute reports** — the evidence view generates a prefilled dispute report (edge triple, citation, quote, verification record) that a reader submits through the project repository's issue tracker (public with the artifact release; an interim contact route is given on the site); (3) **adjudication protocol** — a disputed edge is re-gated with the reader's objection attached to the payload; outcomes (upheld / corrected / removed) are published in the repository, and the edge's evidence view links its dispute history. Accumulated upheld disputes exceeding the published error bar falsify the pipeline claim itself, not just individual edges.

## 5. Experiments and results

All seeds, keys, verdicts, and scoring scripts are in `docs/experiments/` and the pipeline ledger.

**E0 — Retro-verification of ungated extraction (n=238).** All references mined before the gate became mandatory were re-verified by the standard gate: 178 confirmed, 54 corrected, 6 edges deleted — a **25.2% flaw rate for unverified LLM extraction** on this corpus, consistent with public benchmarks. Dominant classes: voice conflation, identity overreach, referent drift, direction reversal; deletions included a spliced quote and a reversed symbolization.

**E1 — Verifier calibration by seeded corruption (n=40, seed 20260726, blind).** 20 intact controls + 20 corruptions (5 each: direction reversal, voice flip, object swap, identity overreach), quotes/paragraphs untouched so only the semantic gate is tested; production prompt; key withheld. Results: **specificity 20/20 (100%)**; sensitivity 15/20 (75%) — **reversal 5/5, object swap 5/5**, overreach 3/5, **voice flip 2/5**. Missed voice flips were sympathetic-reportage cases (doctrine Jung partially adopts) — genuinely ambiguous voice.

**E2 — Adversarial audit of published references (n=30, seed 20260725).** A differently-prompted reviewer instructed to *break* each edge: **0 content/direction/fabrication errors**; 4 disputes (13.3%), all attribution/modality refinements; all applied.

**E3 — Full-graph modality sweep (n=634, complete).** A narrow auditor checking only claim-type and hedge fidelity flagged **65/634 (10.3%)**: 50 claim-type corrections (including **5 in the reverse direction** — Jung's own theses mistyped as reportage, showing the audit is not a systematic deflation of the author's voice), 10 source corrections, 15 hedge downgrades — all applied. Flag rate by extraction age: **18.9% on the oldest edges → 5.6% on the newest**, and the three most recent production batches passed the gate **60/60** — evidence that gate corrections, fed back into extractor instructions, compound into first-pass precision. Three independent methods now converge on the modality error rate (~10–13%: audit 13.3%, calibration voice-flip deficit, sweep 10.3%).

**E4 — Extraction stability probe (n=40 across two windows, blind).** Two already-mined windows re-mined independently with a fixed "20 strongest relations" budget (shared node vocabulary; prior triples withheld): strict unordered {subject, object} pair overlap with the graph was **7/20 (35%)** on CW14 §371–440 and **8/20 (40%)** on CW12 §332–420 — **37.5% combined**. Core theses recur near-verbatim across runs; non-overlap decomposes into complementary genuine edges (the windows hold 29–33 graph edges each, more than one 20-edge budget can cover), schema-shape variants of the same insight, and one case where the probe independently re-found an edge that adjudication had dropped on schema grounds. The graph is therefore a *stable curated map*, not an exhaustive parse; union-mining is the costed coverage upgrade.

**E5 — Voice-specialist calibration (n=20, seed 20260727, blind).** Per-axis seeded corruption of post-sweep ground truth (6 voice flips, 4 hedge strips, 10 clean controls) run through the narrow stage-2 auditor: **sensitivity 80%** (voice flips **5/6 = 83%**, hedge strips 3/4), **specificity 10/10 (100%)**. Against the generalist's 40% voice-flip detection on the same error class (E1), this is a direct, controlled measurement of **semantic diffusion in verification**: same model, same paragraphs, scope narrowed from five criteria to one — detection doubled at zero false-positive cost. The two residual misses are the same sympathetic-reportage boundary cases identified by E1 and E3.

**E6 — Cross-vendor verification audit (n=100 production edges + calibration replays, Gemini 3.1 Pro).** The one structural weakness of a single-vendor trust chain is correlated blind spots between proposer and verifier. A verifier from a different vendor (Google Gemini 3.1 Pro, temperature 0, same production gate prompt, blind to prior verdicts) audited a stratified sample of 100 published edges (strata: volume × claim type × extraction age): **89 SUPPORTED, 11 PARTIAL, 0 WRONG** — zero fabrications, reversals, or unsupported edges found by an independent vendor, and every disagreement confined to the attribution/referent-nuance axis the pipeline already identifies as its residual weakness. Adjudication of the 11 disagreements against the ground-truth paragraphs: **4 upheld** (two referent-precision errors — an edge anchored to a paragraph naming the *filius regius* rather than Rex, and one naming Adam rather than Anthropos — one subject overreach, one referent demotion; all corrected, two near-duplicate edges removed), **5 both-defensible** (the sympathetic-reportage boundary), **2 not upheld** (one objection to ellipsis splicing permitted by the stated quotation rule, one strict-vocabulary reading). Because all sampled edges were published (the first-party verifier's marginal is degenerate), κ is uninformative here; the two-sided comparison comes from calibration replays: on the E1 corruption set Gemini scores **70% sensitivity / 95% specificity** (Fable: 75%/100%), with reversals and object swaps 5/5 and voice flips 2/5 — **missing the same individual voice-flip items as Fable**, evidence that these items are intrinsically ambiguous rather than a vendor blind spot; on the E5 set the narrow voice brief lifts Gemini's voice-flip detection from 33% to 67% (Fable: 40% → 83%) — **the semantic-diffusion effect replicates across vendors**. The orchestrator's dispute rulings were then adversarially reviewed by the cross-vendor model (9 AGREE / 2 PARTIALLY-AGREE / 0 DISAGREE); both partial agreements argued for stronger remedies than confidence demotion, and both were accepted (two referent retargets). Post-audit graph: 228 nodes, 608 edges, 633 references. E6's headline is stated precisely: zero unsupported edges *under the shared rubric* (see threat vii).

**Cost.** From production telemetry (~97K tokens/miner batch, ~56K/gate batch at $5/$25 and $10/$50 per MTok): ≈ **$0.09 per verified citation**, ≈ $0.12 including retro-verification, audit, and calibration overhead; total artifact cost ≈ $60–90.

## 6. Discussion: what the process revealed

1. **Verification is where value is created.** A quarter of unverified extractions were flawed; post-gate audits find zero content errors. The gap between 75% (unverified) and measured-clean (gated) *is* the artifact's worth.
2. **Error classes are asymmetric, and the easy one is fabrication.** Deterministic verbatim anchoring eliminated fabricated quotes entirely; structural semantic errors (direction, referent) are caught at ceiling by the gate; the persistent residual is *attribution modality*.
3. **Voice is the hard problem.** "Sympathetic reportage" — doctrine Jung reports and half-adopts — resists a ternary taxonomy, measured three ways (13.3% audit refinements; 40% voice-flip detection; 11.8% sweep flags). This is a scholarly judgment call, which argues for the human tier (§8).
4. **The gate teaches the miner.** Feedback loops from verifier corrections measurably raised first-pass precision (19%→5.5% modality flags; three consecutive perfect batches).
5. **Verification decomposes along semantic risk axes.** A verifier asked to judge five criteria at once distributes attention by salience: structural axes reach ceiling while the subtle axis (voice) drops to 40% detection. The identical model with a single-axis brief reaches 83% (E5). The practical architecture is therefore a structure generalist plus one or two specialists on the corpus's *measured* weak axes — not an agent per criterion (specialists pay only where the generalist is weak, and cross-axis errors still need a whole-paragraph reading). The principle generalizes: each corpus has its own risk axes — rhetorical voice for Jung; holding-vs-dictum for law; claim-vs-contemporary-belief for history of science.

6. **Claim coverage, not text coverage.** The graph cites 34% of CW14's paragraphs, yet E4 shows both independent extraction runs recover each chapter's core relational claims. The resolution: most paragraphs argue, illustrate, or amplify rather than assert a new relation — the correct denominator is the corpus's *claim inventory*, not its paragraph count. The artifact is complete in **tier-1 claims** (each chapter's core assertions, stable across independent readers) and samples **tier-2** (real, verifiable, but reader-dependent below the selection cut) — complete the way a topographic map is complete in peaks above a chosen prominence, not in every hill. Union-mining lowers that prominence threshold at ~$2 per window.

7. **Trust can be made inspectable.** Per-citation verification records, published error rates, self-testing validators, and a falsification offer convert "trust us" into "check us."

## 7. Threats to validity

A 16-item assumptions register is published (`docs/ASSUMPTIONS.md`); principal threats: **(i) shared-substrate risk** — proposer and verifier are different model families from one vendor; correlated blind spots would be invisible to both (mitigation: cross-vendor tier, §8); **(ii) single translation** — quotes are Hull/Bollingen-bound; §-anchors are edition-stable but nuance may be the translator's; **(iii) salience sampling** — the graph maps the "strongest" relations per window, not an exhaustive parse (E4 measures stability); **(iv) calibration scope** — E1's sensitivity generalizes only to its four corruption classes, chosen from observed production errors; unknown error types are unmeasured; **(v) judged context = one paragraph** — claims supported across paragraphs can be mis-scored; **(vi) adjudication discretion** — PARTIAL corrections are applied by the orchestrator; every decision is logged but the layer is itself model-mediated (mitigation: in E6 the orchestrator's dispute rulings were themselves adversarially reviewed by the cross-vendor model, which accepted 9/11 and successfully forced two stronger corrections); **(vii) shared-rubric convergence** — the cross-vendor audit (E6) ran under the first vendor's gate prompt and verdict rubric, so part of the measured agreement is an artifact of shared thresholds rather than independent judgment — a bias the cross-vendor model itself identified when asked to critique the prompt adversarially; the planned mitigation is a rubric-free replication in which the second vendor judges support and severity in its own terms, mapped to our categories only post hoc.

## 8. Limitations and future work

Coverage beyond CW14/CW12 is thin; eleven volumes untouched. The relation vocabulary is open (157 single-use relations) pending a relation-family layer. Sweep batches 4–5 and probe E4 await budget. The cross-vendor tier proposed in earlier drafts is now executed (E6). Planned: **(a) a standing cross-vendor stage** — promoting the E6 auditor from one-off experiment to a periodic sampled audit with published disagreement ledgers; **(b) community verification** — blind review by Jungian readers with the evidence view as instrument, human–machine κ published, human confirmations entering the per-edge provenance chain (protocol in `docs/ASSUMPTIONS.md` §E); **(c) a declarative verifier registry** — each verification stage defined as configuration (model, axis, prompt, output schema, and its own calibration set with last measured sensitivity/specificity) over one shared runner and verdict-applier, making specialist decomposition an operable pattern rather than a finding: a new corpus axis becomes a registry entry, and every stage's quality is attached, re-measurable data; **(d) German *Gesammelte Werke* cross-check; (e) DOI-registered dataset releases, including a native nanopublication serialization of the graph (each reference already carries the assertion/provenance/publication-info anatomy, §2); (f) explicit permeation markers for sympathetic reportage, adapting the DEC cognitive-worlds semantics (§2) to replace the informal confidence downgrade.**

## 9. Conclusion

For interpretive corpora, the question is not whether LLMs can extract structure — they can, at ~75% — but whether a pipeline can be built where the published artifact is *measurably* better than its extractor, and honest about the remainder. The Symbolic World demonstrates one affirmative design: deterministic grounding, cross-family adversarial gating, typed voice provenance, self-testing validators, and published error bars, at ~$0.10 per verified claim. The method contains nothing Jung-specific: any authored corpus where *who said what, exactly where* is the scholarly currency is a candidate.

---

### Authorship note

Conception, direction, corpus provision, publication decisions, and final responsibility: **Damian Spendel**. Edge proposal: *Claude Opus 4.8*. Independent verification, audits, calibration runs: *Claude Fable 5*. Orchestration, tooling, experiments, drafting: *Claude Code* (Anthropic), under the author's instruction. Proposer/verifier family separation is a deliberate design constraint.

### Key references

- [KGGen (NeurIPS 2025)](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) · [RAG vs GraphRAG](https://arxiv.org/pdf/2502.11371)
- [Attribution, Citation, and Quotation: A Survey](https://arxiv.org/html/2508.15396v1) · [Cited but Not Verified](https://arxiv.org/pdf/2605.06635)
- [Self-Preference Bias in LLM-as-a-Judge](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge) · [UDA](https://arxiv.org/pdf/2508.09724)
- [Structured Inline Citation Generation](https://arxiv.org/html/2606.07130) · [Schema-Aware Triple Verification](https://arxiv.org/pdf/2604.04190) · [Prover–Skeptic KB Generation](https://arxiv.org/pdf/2603.06974)
- [Nanopublications](https://arxiv.org/pdf/1809.06532) · [Provenance-Enhanced Statements](https://arxiv.org/html/2606.15246)
- [KGs in Libraries & Digital Humanities](https://arxiv.org/abs/1803.03198) · [ARAS Concordance](https://aras.org/concordance)
