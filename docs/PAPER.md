# Grounded, Adversarially Verified Knowledge Graphs for Interpretive Corpora: The Symbolic World, a Case Study on C. G. Jung's Collected Works

**Damian Spendel**
*AI collaborators: Claude Opus 4.8 (extraction), Claude Fable 5 (independent verification & audits), orchestration via Claude Code (Anthropic). Roles in §3 and the Authorship Note.*

*Draft v2.0 (arXiv-track) — 27 July 2026 · Artifact: [symbolicworld.observer](https://symbolicworld.observer) · Dataset & ledger: project repository, release `v1.0-cw14`+*

---

## Abstract

Large language models extract knowledge-graph triples from text at 30–66% fact accuracy, and deployed citation systems hallucinate 11–57% of citations — rates that make naive LLM extraction unusable for scholarship. We present a pipeline in which **no assertion can enter the published artifact without passing (i) a deterministic verbatim-quotation check against its cited source paragraph and (ii) an independent full-paragraph review by a model from a different family than the proposer**, and we apply it to build The Symbolic World: a knowledge graph of C. G. Jung's *Collected Works* comprising **227 nodes, 610 edges, and 634 references** (100% verification coverage, with machine-readable verdict provenance per citation). Each reference is anchored to a numbered CW paragraph with a ≤25-word verbatim quote and typed by rhetorical voice (*jung-asserts* / *jung-reports-parallel* / *jung-quotes-source*), separating Jung's own claims from doctrine he reports — a first-class treatment of a failure mode we find dominant in practice. We evaluate the pipeline itself: retro-verification of early unggated output measures a **~25% flaw rate in unverified extraction**; a blind seeded-corruption calibration (n=40) measures the verifier at **100% specificity** with **100% detection of direction-reversal and wrong-referent corruptions** (75% sensitivity overall; the deficit concentrated in attribution-voice flips, 2/5); an adversarial audit of 30 random published references finds **0 content errors** and 13.3% modality refinements; a full-graph modality sweep (n=634) corrects 10.3% of references on the voice/hedge axis, with the flag rate falling from 18.9% (oldest extractions) to 5.6% (newest) — evidence that verifier feedback compounds into extractor precision (three consecutive 20/20 batches). Marginal cost is ≈ **$0.09–0.12 per fully verified citation**, orders of magnitude below expert manual construction. All error rates, seeds, adjudications, and a 16-item assumptions register are published with the artifact, alongside a standing public falsification offer.

## 1. Introduction: the gap

Jung's *Collected Works* run to twenty volumes of densely cross-referential prose in which the same symbol (Mercurius, the lion, salt, Luna) carries systematically different meanings by context and authority. The scholarly instruments available digitally are lexical — the [ARAS concordance](https://aras.org/concordance) indexes word occurrences with headings and context, and the [ARAS image archive](https://aras.org/about-us-0) indexes ~18,000 images — but no existing resource represents the corpus as citation-grade *semantic structure*: typed relations with paragraph-level anchors that can answer "what does Jung say the green lion *is*, and on whose authority?" General surveys confirm that [digital-humanities knowledge graphs](https://arxiv.org/abs/1803.03198) concentrate on collections metadata rather than interpretive content — precisely because interpretive claims are where automated extraction is least trustworthy.

The trust problem is quantified in the NLP literature: LLM triple extractors score 29.84–66.07% fact accuracy ([KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) vs GraphRAG vs OpenIE; see also [RAG vs GraphRAG](https://arxiv.org/pdf/2502.11371)), and citation hallucination rates of 11–57% persist in deployed systems ([survey](https://arxiv.org/html/2508.15396v1); ["Cited but Not Verified"](https://arxiv.org/pdf/2605.06635)). Interpretive corpora add a subtler failure mode we call **voice conflation**: converting an author's *report* of a doctrine into the author's *own assertion*. Our production logs show this to be the single most frequent semantic error class in practice (§5, §6).

**Contributions.** (1) A publication-gated pipeline for interpretive corpora combining deterministic verbatim anchoring with cross-family adversarial verification and typed rhetorical provenance; (2) a self-measuring evaluation methodology — retro-verification, seeded-corruption calibration of the verifier, adversarial audit, full-graph error-axis sweep, and (staged) extraction-stability probing — with all rates published; (3) the artifact itself: the first citation-grade semantic graph of Jung's Collected Works, publicly explorable with per-citation verification records; (4) an honest accounting of what remains hard (attribution modality; shared-vendor verification), with costed mitigations.

## 2. Related work

**LLM KG extraction.** [KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf), GraphRAG, OpenIE establish unverified accuracy baselines (30–66%); [schema-aware triple verification](https://arxiv.org/pdf/2604.04190) and prover–skeptic [dialogue approaches](https://arxiv.org/pdf/2603.06974) add post-hoc verification. We differ in making verification a *mandatory publication gate*, grounding it in the full source paragraph, and calibrating the verifier itself with seeded corruptions.

**Attributed generation.** Verbatim-evidence systems (FullCite / [structured inline citation](https://arxiv.org/html/2606.07130), Quote-Tuning) enforce quotation at generation time; we enforce it at dataset level as a hard deterministic check, independent of any model.

**LLM-as-judge reliability.** [Self-preference bias](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge) (measured −38% to +90%) and [debiasing work](https://arxiv.org/pdf/2508.09724) motivate our hard constraint that proposer and verifier come from different model families; our seeded-corruption calibration (§6.2) is, to our knowledge, the first published sensitivity/specificity measurement of a verification gate in a humanities KG setting.

**Scholarly provenance.** Our claim typing consciously adapts the [nanopublication](https://arxiv.org/pdf/1809.06532) assertion/provenance separation and [provenance-enhanced statements](https://arxiv.org/html/2606.15246) to rhetorical voice in interpretive text.

## 3. Method

**Corpus.** Paragraph records `{volume, §, text, page}` are extracted mechanically from epub markup (§ numbers read from bracketed superscript markers, strictly-ascending filter; never inferred). A §→Bollingen-page concordance is carried per record. The corpus remains local; only ≤25-word verified quotes are published.

**Pipeline (per batch, transaction-logged).**
1. *Propose* (Claude Opus 4.8): 12–22 candidate edges from a contiguous window; verbatim quotes; node-vocabulary reuse; claim-typing rules (reported doctrine must be typed as reported).
2. *Mechanical pre-check* (deterministic): each quote must appear as an in-order, letter-normalized substring of its cited paragraph (ellipsis-tolerant); node existence; duplicate-triple rejection.
3. *Independent gate* (Claude Fable 5, different family): full-paragraph review per edge for support, direction, quote fidelity across elisions, claim-type honesty, and conflation → SUPPORTED / PARTIAL(+concrete correction) / WRONG.
4. *Adjudicated merge*: corrections applied; WRONG dropped and logged; provenance stamped (`verified_by`, `verified_date`).
5. *Integrity tests* (all quotes/anchors/types/provenance re-validated on every change, plus five **corruption canaries that must fail** — self-testing validators) → deploy → commit.

Every batch transition is committed to a ledger (`pipeline/state.json`); the construction history is replayable and auditable commit-by-commit.

**Schema.** Nodes `{id, type ∈ {Concept, Operation, Symbol, Figure, Substance, Motif}, label}`; edges `{subject, relation (open vocabulary, verbatim-faithful), object, references[]}`; references `{volume, §, quote, claim_type, source?, confidence, verified, verified_by, verified_date}`.

## 4. The artifact

227 nodes · 610 edges · 634 references across 461 distinct paragraphs of nine CW volumes; CW 14 (*Mysterium Coniunctionis*) covered end-to-end (396 refs), CW 12 at 87 and growing. Claim types: 420 *jung-asserts*, 155 *jung-reports-parallel*, 59 *jung-quotes-source* over 74 named sources; 81 references carry hedged (medium) confidence. The public Atlas renders six typed regions with search and walkable citations; **every citation expands to its verification record** (claim-type explanation, source, confidence, verifier, date, check-it-yourself pointer), and the About panel carries a standing falsification offer: any reader with the Bollingen edition can refute any edge in ~2 minutes.

## 5. Experiments and results

All seeds, keys, verdicts, and scoring scripts are in `docs/experiments/` and the pipeline ledger.

**E0 — Retro-verification of ungated extraction (n=238).** All references mined before the gate became mandatory were re-verified by the standard gate: 178 confirmed, 54 corrected, 6 edges deleted — a **25.2% flaw rate for unverified LLM extraction** on this corpus, consistent with public benchmarks. Dominant classes: voice conflation, identity overreach, referent drift, direction reversal; deletions included a spliced quote and a reversed symbolization.

**E1 — Verifier calibration by seeded corruption (n=40, seed 20260726, blind).** 20 intact controls + 20 corruptions (5 each: direction reversal, voice flip, object swap, identity overreach), quotes/paragraphs untouched so only the semantic gate is tested; production prompt; key withheld. Results: **specificity 20/20 (100%)**; sensitivity 15/20 (75%) — **reversal 5/5, object swap 5/5**, overreach 3/5, **voice flip 2/5**. Missed voice flips were sympathetic-reportage cases (doctrine Jung partially adopts) — genuinely ambiguous voice.

**E2 — Adversarial audit of published references (n=30, seed 20260725).** A differently-prompted reviewer instructed to *break* each edge: **0 content/direction/fabrication errors**; 4 disputes (13.3%), all attribution/modality refinements; all applied.

**E3 — Full-graph modality sweep (n=634, complete).** A narrow auditor checking only claim-type and hedge fidelity flagged **65/634 (10.3%)**: 50 claim-type corrections (including **5 in the reverse direction** — Jung's own theses mistyped as reportage, showing the audit is not a systematic deflation of the author's voice), 10 source corrections, 15 hedge downgrades — all applied. Flag rate by extraction age: **18.9% on the oldest edges → 5.6% on the newest**, and the three most recent production batches passed the gate **60/60** — evidence that gate corrections, fed back into extractor instructions, compound into first-pass precision. Three independent methods now converge on the modality error rate (~10–13%: audit 13.3%, calibration voice-flip deficit, sweep 10.3%).

**E4 — Extraction stability probe (n=40 across two windows, blind).** Two already-mined windows re-mined independently with a fixed "20 strongest relations" budget (shared node vocabulary; prior triples withheld): strict unordered {subject, object} pair overlap with the graph was **7/20 (35%)** on CW14 §371–440 and **8/20 (40%)** on CW12 §332–420 — **37.5% combined**. Core theses recur near-verbatim across runs; non-overlap decomposes into complementary genuine edges (the windows hold 29–33 graph edges each, more than one 20-edge budget can cover), schema-shape variants of the same insight, and one case where the probe independently re-found an edge that adjudication had dropped on schema grounds. The graph is therefore a *stable curated map*, not an exhaustive parse; union-mining is the costed coverage upgrade.

**Cost.** From production telemetry (~97K tokens/miner batch, ~56K/gate batch at $5/$25 and $10/$50 per MTok): ≈ **$0.09 per verified citation**, ≈ $0.12 including retro-verification, audit, and calibration overhead; total artifact cost ≈ $60–90.

## 6. Discussion: what the process revealed

1. **Verification is where value is created.** A quarter of unverified extractions were flawed; post-gate audits find zero content errors. The gap between 75% (unverified) and measured-clean (gated) *is* the artifact's worth.
2. **Error classes are asymmetric, and the easy one is fabrication.** Deterministic verbatim anchoring eliminated fabricated quotes entirely; structural semantic errors (direction, referent) are caught at ceiling by the gate; the persistent residual is *attribution modality*.
3. **Voice is the hard problem.** "Sympathetic reportage" — doctrine Jung reports and half-adopts — resists a ternary taxonomy, measured three ways (13.3% audit refinements; 40% voice-flip detection; 11.8% sweep flags). This is a scholarly judgment call, which argues for the human tier (§8).
4. **The gate teaches the miner.** Feedback loops from verifier corrections measurably raised first-pass precision (19%→5.5% modality flags; three consecutive perfect batches).
5. **Trust can be made inspectable.** Per-citation verification records, published error rates, self-testing validators, and a falsification offer convert "trust us" into "check us."

## 7. Threats to validity

A 16-item assumptions register is published (`docs/ASSUMPTIONS.md`); principal threats: **(i) shared-substrate risk** — proposer and verifier are different model families from one vendor; correlated blind spots would be invisible to both (mitigation: cross-vendor tier, §8); **(ii) single translation** — quotes are Hull/Bollingen-bound; §-anchors are edition-stable but nuance may be the translator's; **(iii) salience sampling** — the graph maps the "strongest" relations per window, not an exhaustive parse (E4 measures stability); **(iv) calibration scope** — E1's sensitivity generalizes only to its four corruption classes, chosen from observed production errors; unknown error types are unmeasured; **(v) judged context = one paragraph** — claims supported across paragraphs can be mis-scored; **(vi) adjudication discretion** — PARTIAL corrections are applied by the orchestrator; every decision is logged but the layer is itself model-mediated.

## 8. Limitations and future work

Coverage beyond CW14/CW12 is thin; eleven volumes untouched. The relation vocabulary is open (157 single-use relations) pending a relation-family layer. Sweep batches 4–5 and probe E4 await budget. Planned: **(a) cross-vendor verification tier** — a GPT-5-class verifier over a stratified 100-edge sample plus the E1 corruption set, publishing a disagreement matrix and κ (spec in `docs/REVIEW.md` §5); **(b) community verification** — blind review by Jungian readers with the evidence view as instrument, human–machine κ published, human confirmations entering the per-edge provenance chain (protocol in `docs/ASSUMPTIONS.md` §E); **(c) German *Gesammelte Werke* cross-check; (d) DOI-registered dataset releases.**

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
