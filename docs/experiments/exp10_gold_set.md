# E10 — Author gold-set validation (n=50)

Date: 2026-07-29. Annotator: the author (single-annotator; qualification stated in
the paper, §6.1 — an experienced reader of Jung, not a professional Jungian scholar).
Instrument: `tools/review_server.py` (local, keyboard-driven), implementing
`docs/ANNOTATION_PROTOCOL.md` as two questions per item plus free notes.
Record: `pipeline/human_validations.json` (committed verbatim).
Analysis: `tools/analyze_gold.py`. The paper's E10 numbers are recomputed from the
record by `tools/check_paper_facts.py` on every push.

## Design

- Sample: 50 published references, stratified by voice class with minority classes
  oversampled — 26 `jung-asserts` / 15 `jung-reports-parallel` / 9
  `jung-quotes-source` against a 450/163/60 population. The drawn sample is
  published verbatim (`pipeline/gold_sample_50.json`); the sampling script was not
  retained, so reproducibility runs from the published sample, not from a seed.
- Per item, the annotator sees the claim, the anchored quote, the full source
  paragraph (with the quote highlighted), the volume/§/Bollingen page, and the
  pipeline's claim-type label, and answers: (1) does the paragraph support the
  claim as stated — supported / partly / not supported; (2) is the voice label
  right — correct / should be one of the other two classes.
- Convention: the annotator selected an explicit voice label even when agreeing
  with the pipeline; the analysis script maps a selection identical to the
  pipeline's label to agreement.

## Results

| Measure | Result | 95% Wilson |
|---|---|---|
| Support: supported | 44/50 (88%) | 76–94% |
| Support: partly / needs correction | 5/50 | — |
| Support: not supported | 1/50 | — |
| Voice agreement (overall) | 40/50 (80%) | 67–89% |
| Voice: jung-asserts | 24/26 (92%) | — |
| Voice: jung-quotes-source | 8/9 (89%) | — |
| Voice: jung-reports-parallel | 8/15 (53%) | 30–75% |

Confusion (pipeline → human), disagreements only: asserts→reports 2;
quotes→reports 1; reports→asserts 1; reports→quotes 6.

## Findings

1. **The disagreements are directional.** 8 of 10 move the label away from Jung's
   own voice — the over-attribution direction predicted by every model audit
   (E3, E5, E6/E7), now confirmed by a human.
2. **A failure mode the models missed.** The six reports→quotes rulings are cases
   where Jung renders a *named* source (Boehme, the Aelia Laelia inscription, a
   quoted salt passage) and the pipeline filed the claim as anonymous reported
   tradition — under-crediting the source. This is a source-specificity failure,
   distinct from the commitment-permeation of sympathetic reportage, and no model
   audit had surfaced it.
3. **Support holds.** The 5 partly items are correctable per the annotator's notes
   (a missed hedge, a referent to narrow, an ibid-context loss); the 1 not-supported
   item (coniunctio→regina, CW 14 §2) is an amplification the annotator ruled
   mis-structured, not an invented claim. Nothing fabricated.
4. **Three items remain open**, flagged by the annotator as needing adjudication
   beyond one reader: gold_id 12 (coniunctio→regina, support), 14
   (aelia-laelia-inscription→lapis; the operative reference may be §51 rather than
   §59), and 19 (mercurius→lumen-naturae, reports vs quotes). They are recorded as
   unresolved pending independent human review.

## Honesty constraints

- **Single annotator.** No inter-annotator agreement figure exists yet; a second
  annotator (ideally a professional Jungian) is the planned extension.
- **Anchored review.** The tool displays the pipeline's label before the human
  rules. Our own cross-review experiments (E6/E7 addenda) measured anchoring to
  inflate agreement, so 80% should be read as a favorable estimate; the
  second-annotator pass will be unanchored.
- The three open items can move the headline counts by one or two in either
  direction; the paper reports the counts as they stand and marks the items open.
