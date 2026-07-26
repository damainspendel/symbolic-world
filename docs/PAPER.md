# The Symbolic World: An Independently Verified Knowledge Graph of C. G. Jung's Symbolic Thought

**Damian Spendel**
*AI collaborators: Claude Opus 4.8 (extraction), Claude Fable 5 (independent verification), orchestrated via Claude Code (Anthropic). Roles detailed in §4 and the Authorship Note.*

*Draft v1.0 — 25 July 2026 · Live artifact: [symbolicworld.observer](https://symbolicworld.observer) · Dataset: `seed.json` (this repository), release `v1.0-cw14`*

---

## Abstract

We present The Symbolic World, a knowledge graph of C. G. Jung's symbolic and alchemical thought in which **every edge is anchored to a specific numbered paragraph (§) of the *Collected Works*, carries a verbatim quotation of ≤25 words, is typed by rhetorical provenance (Jung's own assertion vs. doctrine he reports vs. a source he quotes), and has passed an independent verification review by a model from a different family than the one that proposed it.** At release v1.0 the graph contains 220 nodes, 590 edges, and 614 references spanning nine CW volumes, with *Mysterium Coniunctionis* (CW 14) covered end-to-end; 100% of references carry a machine-recorded verification verdict, and an adversarial audit of a random sample found zero content or direction errors (13.3% of sampled references received minor attribution-modality refinements, which were applied). Published LLM knowledge-graph extractors achieve 30–66% fact accuracy without verification; deployed citation systems hallucinate 11–57% of citations. Against that baseline, the contribution here is not extraction novelty but a **pipeline design in which nothing unverified can enter the artifact**, and error rates are measured and published rather than unknown. We argue this closes a specific gap in digital Jung scholarship — no existing resource offers citation-grade *semantic structure* over the Collected Works — and that the method generalizes to any single-author interpretive corpus.

---

## 1. The gap

### 1.1 Jung's corpus resists both search and summarization

The *Collected Works* run to twenty volumes of densely cross-referential prose in which the same symbol (Mercurius, the lion, salt, Luna) recurs across thousands of pages with systematically *different* meanings by context — Mercurius alone is prima materia, lapis, psychopomp, trickster, the unconscious's personification, and the devil's dark double, each claim living in a different paragraph of a different volume. Keyword search (the dominant existing tool — see §1.2) retrieves *occurrences* but not *relations*: it cannot answer "what does Jung say the green lion *is*, and on whose authority?" Meanwhile, asking a large language model produces fluent synthesis with a documented failure mode: LLM citation hallucination rates of 11–57% persist across commercially deployed systems ([survey](https://arxiv.org/html/2508.15396v1)), and general-purpose LLM triple extractors score 30–66% fact accuracy on standard benchmarks — [KGGen](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) reports 66.07% for itself, 47.80% for GraphRAG, and 29.84% for OpenIE. For a corpus whose scholarly use depends on exact attribution ("CW 14, §708"), a one-in-three error rate is not a rough draft; it is disinformation with page numbers.

There is a second, subtler hazard specific to interpretive corpora: **voice conflation**. Much of what Jung writes is exposition of *other people's* doctrine — Dorn, Khunrath, the Rosarium, patristic allegory. A naive extractor turns "the alchemists called salt the arcane substance" into *Jung asserts salt = arcane substance*, silently converting reportage into endorsement. Our verification logs show this is the single most common error class in practice (see §5).

### 1.2 Existing digital Jung resources are lexical, not semantic

The principal digital instruments of Jungian scholarship are the [ARAS concordance](https://aras.org/concordance), which offers word/topic search over the Collected Works with subject headings and context, and the [ARAS image archive](https://aras.org/about-us-0) (~18,000 cross-indexed images with commentary). Both are invaluable and both are *retrieval* tools: they index where words occur, not what relations Jung asserted. To our knowledge no existing resource represents the Collected Works as a typed, §-anchored, machine-readable graph of symbolic relations — the form required for structural queries ("all figures Jung identifies with Mercurius, with citations"), for visualization, and for downstream computational use. General surveys of [knowledge graphs in the digital humanities](https://arxiv.org/abs/1803.03198) confirm the pattern: cultural-heritage KGs are common for *collections metadata* (objects, dates, creators), rare for *interpretive content* — precisely because interpretive claims are where extraction is least trustworthy.

## 2. The artifact

At release `v1.0-cw14` the graph comprises:

| Measure | Value |
|---|---|
| Nodes | 220 (61 Concepts, 47 Figures, 45 Symbols, 33 Motifs, 20 Substances, 14 Operations) |
| Edges | 590, each a subject–relation–object triple |
| References | 614, anchored to 445 distinct CW paragraphs across 9 volumes |
| Coverage core | CW 14 (*Mysterium Coniunctionis*) end-to-end, §3–§792 (396 refs) |
| Breadth | CW 5, 8, 9i, 9ii, 11, 12, 13, 16 (218 refs; CW 12 at 67 and growing) |
| Verification | **614/614 references (100%)** carry an independent gate verdict with model + date provenance |
| Named quoted sources | 64 (Khunrath, Dorn, Mylius, Lambspringk, Paracelsus, the Rosarium…) |

Each reference stores: volume, paragraph, a ≤25-word verbatim quote, a confidence level (hedged claims are marked `medium`), the claim type, the named source where applicable, and the verification record (`verified_by`, `verified_date`). The Bollingen print page for each § is resolved via a page concordance, so every edge is checkable against the physical edition. Only these short quotes and pointers are published; the corpus text itself is never redistributed.

## 3. What is new

**(a) Adversarial two-family verification as a publication gate.** Every batch is proposed by one model (Claude Opus 4.8) and independently reviewed by a model from a different family (Claude Fable 5) that sees the full source paragraph and issues SUPPORTED / PARTIAL (with a concrete correction) / WRONG per edge. Nothing enters the published graph without a verdict; WRONG edges are deleted and logged in version control. The two-family requirement is motivated directly by the [LLM-as-judge self-preference literature](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge): judges systematically over-rate outputs in their own style (measured biases from −38% to +90% on ArenaHard-style comparisons; see also [UDA](https://arxiv.org/pdf/2508.09724)), so a same-family verifier would partially audit itself. Recent triple-verification work (e.g. [schema-aware verification toolsets](https://arxiv.org/pdf/2604.04190), prover–skeptic [dialogue generation](https://arxiv.org/pdf/2603.06974)) shares the adversarial spirit; our differences are that verification is (i) *mandatory for publication*, not a post-hoc score, (ii) grounded in the *full source paragraph* rather than model knowledge, and (iii) itself audited (below).

**(b) Typed rhetorical provenance for interpretive text.** Every reference is classified as `jung-asserts` (446), `jung-reports-parallel` (110), or `jung-quotes-source` (58, with the source named). This three-way typing — *whose claim is this?* — is, to our knowledge, novel as a first-class edge property in a humanities KG, though it consciously echoes the [nanopublication](https://arxiv.org/pdf/1809.06532) tradition of separating assertion from provenance and recent [provenance-enhanced statement](https://arxiv.org/html/2606.15246) models. For an author like Jung, who spends whole chapters ventriloquizing alchemists he does not fully endorse, the distinction is not a nicety: our audit found voice conflation to be the dominant residual error class, and the gate corrected 100+ instances of it during construction.

**(c) Verbatim-quote anchoring at the paragraph level.** Each edge's quote must be a letter-normalized verbatim substring of its cited paragraph, checked mechanically before any model review. This borrows the insight of verbatim-evidence systems like FullCite/[structured inline citation generation](https://arxiv.org/html/2606.07130) and Quote-Tuning, but applies it at *dataset* level: the check is a hard gate, not a training objective, and it makes every edge independently re-verifiable by a human with the book open.

**(d) Published, measured error rates.** The construction history quantifies its own reliability: retro-verification of 238 early (pre-gate) references produced 178 confirmations, 54 corrections, and 6 deletions (~25% flaw rate on *ungated* LLM extraction — consistent with the 30–50% error rates implied by public benchmarks). A subsequent adversarial audit — 30 randomly sampled verified references re-attacked by a differently-prompted reviewer instructed to break each edge — found **0 content/direction/fabrication errors and 4 attribution-modality refinements (13.3%)**, all applied. We know of no comparable LLM-built humanities dataset that publishes an audited error bar; "cited but not verified" is the documented norm ([deep-research attribution study](https://arxiv.org/pdf/2605.06635)).

**(e) A transaction-logged, resumable pipeline.** Every batch moves through `input-built → mined → pre-checked → gated → merged` in a committed ledger (`pipeline/state.json`), making the construction reproducible, interruptible, and auditable commit-by-commit — the graph's *history* is part of its evidence.

## 4. Method summary

1. **Corpus preparation.** The CW epub is parsed mechanically; paragraph numbers are read from markup (never inferred), yielding `{volume, §, text, page}` records. The corpus stays local and unpublished.
2. **Proposal.** An extraction model receives a contiguous paragraph window plus the current node vocabulary and existing triples, and proposes 12–22 candidate edges with verbatim quotes, claim types, and hedges preserved.
3. **Mechanical pre-check.** Quotes are verified as in-order letter-normalized substrings of the cited paragraph; node references and duplicate triples are checked. (Catches transcription drift; cannot catch semantic error.)
4. **Independent gate.** The verifier model reviews each candidate against the full paragraph for direction, support, quote fidelity across ellipses, claim-type honesty, and conflation. Verdicts are applied: corrections merged, WRONG dropped.
5. **Integrity tests, deploy, commit.** A test suite re-validates every quote, node, claim type, page anchor, and verification-provenance field on every change; the public visualization rebuilds from the verified data only.

## 5. What the process itself revealed

Three empirical observations from ~30 gated batches:

- **Error classes are stable and asymmetric.** Fabricated quotes were eliminated entirely by the mechanical pre-check; the gate's catches were overwhelmingly (i) voice conflation (reported doctrine typed as Jung's own), (ii) identity overreach ("is" where the text has "is compared to"), (iii) direction reversal, and (iv) referent drift (the queen credited with the pair's attribute). Content fabrication — the headline fear about LLMs — was the *rarest* failure once verbatim anchoring was enforced.
- **The gate improves the proposer.** Later batches passed 20/20 twice: gate corrections fed back into miner instructions (e.g., "reported synonyms are never jung-asserts") measurably raised first-pass precision.
- **Attribution modality is the residual weakness.** The adversarial audit's four disputes were all hedge/attribution nuances. We estimate ~1 in 8 references may still carry minor modality imprecision; referents and directions audit clean. This is now published as the dataset's known error bar.

## 6. Value

- **For Jungian scholarship:** a citable, structurally queryable index of symbolic relations with §-and-page precision — an instrument complementary to ARAS's lexical concordance, and a candidate for DOI-registered dataset publication.
- **For digital humanities method:** a working demonstration that LLM-built interpretive KGs can be published *with* error bars, at a verification cost (roughly one verifier call per 20 edges, plus audits) far below expert manual construction, while preserving human verifiability edge-by-edge.
- **For AI evaluation:** a naturally adversarial, citation-grounded corpus where every claim has a ground-truth paragraph — usable as a benchmark for extraction, attribution, and voice-typing tasks.

## 7. Limitations

- **Single translation.** The graph is built on the Hull translation (Bollingen); §-numbers are translation-stable but quote wording is not checked against the German *Gesammelte Werke*.
- **Partial coverage.** CW 14 is complete; the other eight volumes are sampled, not exhausted; eleven volumes are untouched.
- **Shared-substrate risk.** Proposer and verifier are different model families from the same vendor; they may share training-data biases invisible to both. A third-party (human or heterogeneous-vendor) audit tier would strengthen the claim of independence.
- **Selection is interpretive.** "The 15–22 strongest relations per window" is a curatorial judgment; the graph is a map of salient assertions, not an exhaustive semantic parse.
- **Modality residual.** The measured ~13% attribution-refinement rate has not been driven to zero, and hedged relations ("seems-to-set-in-motion") trade queryability for fidelity.

## 8. Open questions

1. **Can the verifier's leniency be measured directly?** A gold set of deliberately corrupted edges (seeded reversals, voice flips) would yield gate sensitivity/specificity, replacing the audit's indirect estimate.
2. **What is the right vocabulary discipline?** 100+ relation strings are single-use; consolidating them risks flattening Jung's precision, keeping them risks an unqueryable folksonomy. Is there a principled middle layer (relation *families* over verbatim relation labels)?
3. **Does the method transfer?** The obvious next tests: the German original (cross-translation verification), another interpretive corpus (Eliade, Corbin, patristics), and a hostile corpus (contested political texts) where voice-typing carries higher stakes.
4. **Can readers audit at scale?** The ✓-badge currently signals *that* verification happened; exposing the verdict, reviewer reasoning, and paragraph context per edge would make the artifact self-auditing — at the cost of UI complexity.
5. **What would falsify the trust claim?** We commit to a standing offer: any reader who finds an edge unsupported by its cited paragraph falsifies that edge publicly (issue tracker); accumulated falsifications above the published error bar falsify the pipeline claim itself.

## 9. Assurance roadmap: addressing the risks

Each limitation in §7 maps to a concrete, costed mitigation. Items marked ✅ are already in force; ◻ are proposed next steps in priority order.

| # | Risk | Mitigation | Status / cost |
|---|------|-----------|----------------|
| 1 | Verifier leniency unmeasured | **Seeded-corruption gold set:** take ~40 verified edges, programmatically corrupt half (reverse direction, flip claim-type/voice, swap object for a sibling node), run the gate blind, publish sensitivity/specificity. Converts "we trust the gate" into a measured detection rate. | ◻ **Highest priority** — ~2 gate calls, fully automatable |
| 2 | Shared-substrate bias (proposer & verifier same vendor) | **Heterogeneous third tier:** (a) a cross-vendor verifier pass (GPT/Gemini-class model) over a stratified sample, publishing the cross-vendor disagreement matrix; (b) a standing **public falsification offer** — every edge names its paragraph, so any reader with the book can falsify it via the issue tracker; falsifications above the published error bar falsify the pipeline claim itself. | ◻ (a) needs an external API key; (b) is a site/README change, immediate |
| 3 | Attribution-modality residual (~13%) | **Modality-only sweep:** a dedicated cheap gate pass over all 614 refs checking *only* claim-type and hedge fidelity (the known weak axis), plus an explicit `hedged: true/false` schema field so modality is data, not prose. | ◻ ~4-5 narrow gate calls |
| 4 | Human-expert blind spot | **Domain-reader audit:** recruit 1–2 Jungian scholars to review a 50-edge stratified sample against the Bollingen edition; publish their disagreement rate alongside the machine audit. This is the single strongest external assurance available. | ◻ Outreach task (the artifact is designed to make this cheap: every edge is a 2-minute lookup) |
| 5 | Verification decay as graph evolves | ✅ Integrity tests re-validate every quote/anchor/provenance field on every change; deploy is gated on green tests; the transaction ledger (`pipeline/state.json` + git) makes every batch's evidence chain replayable. ◻ Add: corrupted-edge canaries in the test suite (mutations that MUST fail) to test the tests. | ✅ + small ◻ |
| 6 | Selection subjectivity | **Recall probe:** re-mine 2–3 already-mined windows with a different proposer model and publish edge-overlap (what fraction of "strongest relations" is stable across extractors). Distinguishes "curated map" from "arbitrary sample". | ◻ ~3 miner calls, no gate needed for the probe itself |
| 7 | Reader cannot audit per-edge | **Evidence view in the Atlas:** per-citation expansion showing claim-type explanation, verdict provenance, Bollingen page, and a "dispute this edge" link. The ✓ becomes inspectable rather than decorative. | ◻ UI work, no model cost |
| 8 | Translation dependence | **Cross-translation spot check:** verify a sample's §-alignment and sense against the German *Gesammelte Werke*; mark edges whose wording is translation-sensitive. | ◻ Requires GW access; deferred |
| 9 | Vocabulary sprawl (100+ single-use relations) | **Relation-family layer:** map verbatim relation labels to ~20 canonical families (symbolizes, identity, parallel, generation, transformation, opposition…) kept *alongside* the faithful label — queryability without flattening fidelity. Already tracked by the warn-only vocabulary audit in the test suite. | ◻ Data pass + gate-review of the mapping |
| 10 | Dataset impermanence | ✅ Tagged releases (`v1.0-cw14`); ◻ Zenodo DOI snapshot per release so scholars can cite a frozen, checksummed version. | ✅ + trivial ◻ |

The ordering principle: **measure the measurer first** (1, 2), then close the known weak axis (3), then bring humans in where they are strongest (4), then make assurance visible to every reader (7). Items 1 + 3 + 5-canaries are fully automatable within the existing pipeline and would upgrade the trust claim from "audited once" to "continuously self-testing with published detection rates."

---

### Authorship note

Conception, direction, corpus provision, all publication decisions, and final responsibility: **Damian Spendel**. Edge proposal (mining): *Claude Opus 4.8*. Independent verification and adversarial audit: *Claude Fable 5*. Pipeline orchestration, tooling, and drafting of this paper: *Claude Code* (Anthropic), under the author's instruction. The two-family separation of proposer and verifier is a deliberate design constraint, not an incidental implementation detail.

### Key sources

- [KGGen: Extracting Knowledge Graphs from Plain Text with Language Models](https://papers.neurips.cc/paper_files/paper/2025/file/2b368455e832d2b1a60bcad8c4c6481f-Paper-Conference.pdf) (extraction accuracy baselines)
- [RAG vs. GraphRAG: A Systematic Evaluation](https://arxiv.org/pdf/2502.11371)
- [Attribution, Citation, and Quotation: A Survey of Evidence-based Text Generation with LLMs](https://arxiv.org/html/2508.15396v1) (citation hallucination rates)
- [Cited but Not Verified: Source Attribution in LLM Deep Research Agents](https://arxiv.org/pdf/2605.06635)
- [Self-Preference Bias in LLM-as-a-Judge](https://www.researchgate.net/publication/385353198_Self-Preference_Bias_in_LLM-as-a-Judge); [UDA: Unsupervised Debiasing Alignment](https://arxiv.org/pdf/2508.09724)
- [Explicit Evidence Grounding via Structured Inline Citation Generation](https://arxiv.org/html/2606.07130) (verbatim evidence spans)
- [Nanopublications: A Growing Resource of Provenance-Centric Scientific Linked Data](https://arxiv.org/pdf/1809.06532); [Provenance-Enhanced Statements in Knowledge Graphs](https://arxiv.org/html/2606.15246)
- [Schema-Aware Planning and Hybrid Knowledge Toolset for Reliable KG Triple Verification](https://arxiv.org/pdf/2604.04190)
- [Knowledge Graphs in the Libraries and Digital Humanities Domain](https://arxiv.org/abs/1803.03198)
- [ARAS Concordance](https://aras.org/concordance) and [ARAS archive](https://aras.org/about-us-0) (existing digital Jung instruments)
