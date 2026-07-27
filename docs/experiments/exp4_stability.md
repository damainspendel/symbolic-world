# Experiment 4 — Extraction stability probe (blind re-mine)

**Date:** 2026-07-27 · **Extractor:** Claude Opus 4.8 (independent runs; existing node
vocabulary supplied, prior triples withheld)

**Method.** Two already-mined windows re-mined blind with a fixed budget of the
"20 strongest relations": Window A = CW14 §371-440 (Rex & Regina; 33 reference
edges in graph), Window B = CW12 §332-420 (Basic Concepts; 29 reference edges).
Overlap metric: strict unordered {subject, object} pair match against the graph's
edges from the same window (relation phrasing ignored; node-id space shared).

**Results.**
| Window | Probe edges | Pair matches | Overlap |
|---|---|---|---|
| A (CW14 Rex) | 20 | 7 | 35% |
| B (CW12 Basic Concepts) | 20 | 8 | 40% |
| **Combined** | 40 | 15 | **37.5%** |

**Interpretation.** "Top-20 salience" is moderately stable: the sections' core
psychological theses recur across independent runs (Rex = dominant of consciousness;
cauda pavonis → filius; meditatio/imaginatio/active-imagination/amplification
edges re-found near-verbatim). Non-overlap splits into (a) complementary genuine
edges — both runs anchor real claims, the sections are richer than any single
20-edge budget (reference sets themselves hold 29-33 edges); (b) schema-shape
variants of the same insight (e.g. probe "venus is-anima-of rex" vs graph
"venus personifies anima", same §416 insight); (c) one notable case: the probe
independently re-found arcane-substance ≈ God (§374), an edge earlier adjudication
had dropped on node-schema grounds — evidence the underlying signal is real and
the drop was a conservative schema decision, not an extraction artifact.
**Implication:** the graph should be read as a curated map, not an exhaustive
parse; union-mining (multiple independent passes, gate-verified union) is the
obvious coverage upgrade and is costed in Future Work.

Files: probeA_output.json, probeB_output.json, probe_reference.json.
