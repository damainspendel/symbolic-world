# JungKG — project plan

A knowledge graph of Jung's alchemical thought where **every interpretive edge is
anchored to a Collected Works paragraph (§)** and **no edge is trusted until an
independent agent has read the source**. Scope for v1: CW 12, 13, 14.

## The verification principle (applies to every phase)

The core discipline of this project is **independent verification**. The model
that *proposes* an edge never gets to certify it. A separate agent — run as
**Fable 5** — reads the actual cited paragraph and returns SUPPORTED / PARTIAL /
WRONG before any edge counts as sound. This was proven in the Phase 1 pilot,
where the Fable 5 pass caught a truncated quote that had flipped an edge's
meaning to its exact opposite (Sol → *unconscious*, when the text says Sol
corresponds to *consciousness*). Provenance is stamped by machinery; **meaning is
checked by an independent reader.**

## Phases

- **Phase 0a — Corpus check.** ✅ *Done.* All three volumes present, § numbers
  machine-readable from markup. 1,838 paragraphs extracted (`extract.py`).

- **Phase 0b — Ontology lock.** ✅ *Done.* Node/edge types + reference model,
  committed as `seed.json`'s structure.

- **Phase 1 — Manual pilot + independent verification.** ✅ *Done.* ~15 edges
  hand-built with real § anchors, then **independently verified by a Fable 5
  agent** (`query.py` reports status). Result: 1 WRONG caught and fixed, 4 PARTIAL
  flagged as the human worklist, gaps anchored. Graph now 15 edges, 9
  high-confidence, 0 unsourced.

- **Phase 2 — Visualize & judge.** ◀ *In progress.* Stand up an interactive
  visualization of `seed.json` so the graph can be seen and explored — the gate
  for the go/no-go judgment call. (Wikibase Cloud publishing deferred to Phase 5;
  the git repo remains the source of truth regardless of platform.)

- **Phase 3 — Extraction pipeline.** Local MLX pass over the volumes, chunked by
  paragraph so provenance is stamped from markup, emitting candidate triples in
  the `seed.json` shape. Must clear a precision bar against the Phase 1 edges
  (used as a gold set) before scaling.

- **Phase 4 — Scale + verify (CW 12 first).** Run extraction volume by volume.
  Every batch of candidate edges passes through the **Fable 5 independent
  verification step** before a human flips `verified: true`. The graph's own
  "what's unsourced/PARTIAL" query is the worklist.

- **Phase 5 — Publish.** Load verified triples into Wikibase Cloud from the repo
  files, open the SPARQL endpoint, write the methodology note (schema + citation
  discipline + independent-verification protocol + copyright line). Publish § +
  facts only; text stays local.

- **Phase 6 — The amplification layer.** A second lens over the same graph: not
  *what a symbol means* (the interpretive spine) but *what Jung gathers around it*
  — the image-series and cross-tradition parallels that give a symbol its
  archetypal depth. Modelled as a `Motif` node type and an `amplified-by` edge
  type, rendered as a toggleable overlay (each symbol grows a corona of its
  amplifications). Two flavors, both first-class (the `kind` field):
  - **image** — intra-alchemical amplifications: the coniunctio imaged as *Rex &
    Regina*, *Sol & Luna*, *Gabricus & Beya*. These are Jung's own gathering of
    the alchemical picture-series.
  - **parallel** — cross-tradition amplifications: the coniunctio ↔ the
    Kabbalistic *Tifereth & Malchuth*, the nigredo ↔ the black *Shulamite*, the
    rebis ↔ the androgynous *Adam Kadmon*.

  **Sourced primarily from Mysterium Coniunctionis (CW 14) and Alchemical Studies
  (CW 13)** — the volumes that *are* largely amplification. The discipline that
  keeps it from sprawling into free-association: **every amplification edge must
  cite the paragraph where Jung himself draws the parallel** — never a parallel we
  find clever. Same verification loop applies.

## Standing decisions
- **Source of truth:** the git repo (flat files). Any platform is a disposable
  publishing target.
- **Copyright:** raw text and the epub are gitignored and local-only. Only facts +
  § pointers are published; quotes kept < 15 words.
- **v1 success = CW 12 fully extracted and independently verified.** Volumes 13
  and 14 are v1.1.

## Product vision

JungKG is not a graph with a viewer bolted on. The graph is the **content layer
of an explorable atlas of Jung's symbolic world** — where every claim taps
through to the exact Collected Works paragraph that grounds it. The eventual form
is a **local-first macOS app** (a companion to HexAI): SwiftUI + a native graph
view, extraction running on-device against local MLX models, corpus never leaving
the machine. It ships the *graph of facts + § pointers* — which are ours — not the
copyrighted text; readers who own the volumes navigate to the paragraphs
themselves. A **citation atlas / navigator, not a text reader.**

### Volume roadmap (the spine grows past alchemy)
The alchemy trio (CW 12/13/14) is the spine. Expansions share its vocabulary
(Self, opposites, quaternity), so new nodes wire straight in:
- **CW 9ii — Aion.** The Self and the shadow. Highest-value next volume: turns
  `the-self` from a leaf into a hub. **Recommended first expansion.**
- **CW 9i — Archetypes & the Collective Unconscious.** Makes archetype, mother,
  rebirth, mandala first-class nodes.
- **CW 16 — The Psychology of the Transference.** The Rosarium woodcuts as the
  coniunctio drama; bridges alchemy to clinical work.
- **CW 11 (Religion) & CW 5 (Symbols of Transformation).** Amplification
  goldmines — more traditions for the Motif layer.

### Layer types (what turns a topic graph into "his whole mind")
1. **Interpretive spine** — what a symbol *means* (live).
2. **Amplification** — image + parallel (Phase 6).
3. **Cross-reference** — where Jung cites his own other works; the footnotes carry
   CW paragraph numbers, so `§X → §Y` inter-volume links are mechanically
   extractable. This is the layer that makes it feel like one connected mind.
4. **Development** — how a concept (coniunctio, Self) evolves across the decades.
