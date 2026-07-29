# Voice annotation protocol

**Purpose.** The formal definition of "voice" (claim attribution) for this project, with
decision rules, edge cases, and worked examples — for human annotators (starting with
the author's gold-set validation), for reproducing the pipeline on other corpora, and as
the reference the paper's voice claims are measured against. Grounded in the NLP
attribution literature; written for humans first.

## 1. What "voice" means here

A **voice label** answers one question about a claim extracted from an authored text:

> **Who is the source of this claim, and what is the author's commitment to it?**

This combines the two dimensions the literature treats separately:

- **Attribution** — which agent the text presents as the claim's source (the author,
  a reported tradition, a quoted person). Formalized in attribution-relation corpora:
  the [PDTB](https://catalog.ldc.upenn.edu/LDC2019T05) attribution layer and
  [PARC 3.0](https://aclanthology.org/L16-1619.pdf) annotate a *source*, a *cue*
  (the introducing predicate: "says", "held", "according to"), and the attributed span.
- **Commitment/factuality** — how strongly the relevant source stands behind the
  claim. Formalized in [FactBank](https://catalog.ldc.upenn.edu/LDC2009T23) (event
  factuality per source, with reported inter-annotator agreement of κ = 0.81) and in
  MPQA's private-state annotation.

Our three labels are a coarse-grained projection of that space, chosen because they
are the distinctions a *reader of scholarship* needs:

| Label | Definition | Attribution-literature analogue |
|---|---|---|
| `author-asserts` (`jung-asserts`, `james-asserts`) | The author states the claim in their own voice, committed to it as their view | source = writer; factuality committed (CT+) |
| `author-reports` (`jung-reports-parallel`, `james-reports`) | The author presents the claim as a tradition's or another party's doctrine, without (full) commitment | source = other, introduced by a reporting cue; writer commitment underspecified |
| `author-quotes` (`jung-quotes-source`, `james-quotes-source`) + `source` | The claim rests on quoted or closely paraphrased words of a *named* source | source = named other; direct/indirect quotation |

Plus one modifier: **`confidence: medium`** when the claim-carrying sentence is
hedged ("perhaps", "it seems", "I conjecture", conditionals) — a coarse factuality
downgrade (FactBank's probable/possible band).

## 2. Decision procedure (apply in order)

1. **Is there a named source whose (quoted or tightly paraphrased) words carry the
   claim?** → `author-quotes`, with `source` naming them. Named means a person or a
   titled work ("Dorn", "the Rosarium"), not a tradition ("the alchemists" is not a
   named source).
2. **Is the claim introduced by a reporting cue** — "the alchemists say/held/called",
   "according to", "in X's view", "the doctrine that…", a footnoted teaching, dream
   material narrated as the dreamer's — **or otherwise framed as somebody else's
   position?** → `author-reports`.
3. **Otherwise**, the author is speaking: → `author-asserts`. The author's
   *interpretations* count as assertions (Jung reading a dream, James diagnosing a
   conversion) even when the material interpreted is reported.
4. **Hedge check** (independent of 1–3): if the claim-carrying clause is hedged or
   conditional, set `confidence: medium`.

## 3. Edge cases and rulings

- **Sympathetic reportage (the hard case).** The author reports a doctrine *and*
  half-adopts it ("the alchemists held X — and rightly, for…"). This is the
  literature's nested / partial-commitment attribution problem, and it is where every
  model configuration in this project fails, in the same places. **Ruling: default to
  `author-reports` unless the author explicitly re-asserts the content in their own
  clause** ("…and this is in fact the case"). When the passage genuinely straddles,
  annotate the default label and note "sympathetic reportage" — these notes are data
  (they map the permeation boundary), not failures.
- **Reported-then-endorsed in separate sentences.** Label the extracted claim by the
  sentence its quote anchors to. If the quote spans the report, it is `author-reports`
  even if endorsement follows.
- **The author's summary of a named source, without quotation marks.** If the passage
  is functionally a rendering of the named source's content (translated block,
  "Orthelius writes that…"), prefer `author-reports` with the source named in notes;
  `author-quotes` requires the words to be presented as the source's own.
- **Dream/case material.** The dreamer's content is reported; the analyst's reading
  of it is asserted. One paragraph frequently contains both — label the claim, not
  the paragraph.
- **Universalizing a particular.** If the text asserts something of *this* dream/case
  and the extracted claim states it generally, that is not a voice error but a
  support error (mark "partly / needs correction" on support, not on voice).
- **Traditions as sources.** "Kabbalistic teaching", "the Church" → `author-reports`.
  The `source` field is reserved for nameable persons/works.

## 4. Worked examples (from the corpus)

1. *"the experience of the self is always a defeat for the ego"* (CW 14 §778) —
   no cue, no source, Jung's own thesis → **jung-asserts**.
2. *"why it was that Adam should have been selected as a symbol for the prima
   materia"* (CW 14 §552) — alchemical doctrine under discussion → **jung-reports-parallel**.
3. Orthelius's quintessence passage (CW 12 §512) — a rendered summary of a named
   author; ruled **jung-reports-parallel** (source: Orthelius) after cross-review —
   the summary-vs-quotation edge case above.
4. *"It looks as if the fourth were expected"* — whatever its label, **confidence:
   medium** (hedge).

## 5. What human agreement to expect

FactBank reports κ = 0.81 for source-relative factuality with trained annotators and
a staged procedure; attribution-span corpora (PDTB, PARC) report high agreement on
*identifying* sources and lower agreement on nested/partial-commitment cases — the
same asymmetry our models show. For this project's gold set we therefore expect
high human agreement on labels 1 and 3, and we treat disagreement concentrated on
sympathetic-reportage items as a *finding about the text*, to be reported, not
resolved by fiat. Inter-annotator agreement (Cohen's κ) will be reported when a
second annotator joins; the author-only gold set is the anchor until then, and is
labeled as single-annotator throughout.

## 6. Relation to the tooling

The local review tool (`tools/review_server.py`) implements this protocol as its two
questions (support; voice) plus notes. Records land in
`pipeline/human_validations.json`; sanitized status is published to the atlas
(green = human-validated, amber = AI-verified, red = disputed) via
`tools/export_validations.py`.
