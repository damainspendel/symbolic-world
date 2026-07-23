# JungKG

A knowledge graph of Jung's alchemical thought, where **every interpretive edge
is anchored to a specific Collected Works paragraph (§)**. Grounding is the whole
point — it's what a concepts-and-vague-arrows graph lacks.

Scope for v1: the alchemy volumes — **CW 12** (*Psychology and Alchemy*),
**CW 13** (*Alchemical Studies*), **CW 14** (*Mysterium Coniunctionis*).

## Files
| File | What it is |
|---|---|
| `extract.py` | Turns the Collected Works epub into `data/paragraphs.jsonl` — one record per numbered §. Paragraph numbers are read from the markup, never inferred. |
| `seed.json` | The hand-built v1 graph: nodes (concepts/symbols/operations/figures) + typed edges, each interpretive edge carrying its § citation. |
| `query.py` | Demonstrates the graph answering real questions, including its own "what still needs a source" worklist. |

## Copyright posture
The epub and `data/` (full text) are **gitignored and stay local**. Only the
derived facts + § pointers in `seed.json` are ever published — a citation like
"CW12 §334" is a fact, not a reproduction. Quotes in `seed.json` are kept under
15 words for the same reason.

## Corpus status (Phase 0a — passed)
1,838 numbered paragraphs extracted cleanly: CW12 = 565, CW13 = 482, CW14 = 791.

## Reproduce
```bash
python3 extract.py --epub /path/to/CollectedWorks.epub
python3 query.py
```
