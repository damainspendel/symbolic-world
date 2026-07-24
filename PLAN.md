# JungKG — project plan

**The Symbolic World** — a grounded, explorable atlas of Jung's symbolic world, where
**every interpretive edge is anchored to a Collected Works paragraph (§)** and **no edge
is trusted until an independent agent has read the source**. The graph *is* the product.

## Status & direction (current — supersedes stale details below)

- **Coverage: 6 volumes, 83 nodes / 180 edges**, every edge §-anchored, Fable-5-verified,
  integrity-tested. Volumes: CW 12 (24), CW 13 (24), CW 14 (53), Aion 9ii (~24),
  CW 9i Archetypes (25), CW 16 Transference (19), CW 5 Symbols of Transformation (22).
  It is no longer an alchemy graph — it spans alchemy, the Self-complex, the archetypes,
  the clinical dimension, and the mythological layer. CW 11 (Religion) is mining.
- **Web-first (the pivot).** The primary product is now a **web app on a real graph
  engine (Vite + Cytoscape.js)** — organic layout, drag, zoom, volume/layer filters,
  search, citation detail. Reason: the graph *is* the value, and the web is the better
  vehicle (shareable by URL, richer rendering at density, minutes-not-builds iteration).
  The native macOS/iOS app (SwiftUI, Explore-first 3-tab) is **paused, not deleted** —
  it's committed and revivable.
- **The mining pipeline is a proven machine** (~6 min/batch): background propose →
  local pre-check → **Fable 5 gate** → merge with fixes → `test_graph.py` → rebuild
  viz + web + app data. Zero fabrications have survived the gate across ~10 batches.

## Roadmap

- **Content — remaining volumes** (one corpus-extension each, then mine): CW 11 (Religion:
  Trinity / Mass / Answer to Job) *in progress* → CW 8 (synchronicity, the psychoid) →
  CW 7 (Two Essays: persona, anima/animus) → CW 6 (Types: the definitions glossary) →
  CW 10. Then depth passes on the thin volumes.
- **Web features** — "open the paragraph in your Bollingen copy"; a cluster / neighborhood
  focus mode to tame density; a friendlier visual design pass; mobile polish; the T4
  cross-reference layer (footnote §→§ links) once mined.
- **Publishing** — deploy the web app to a permanent URL (GitHub Pages / Netlify); and
  publish the graph as **data** (Wikibase / Neo4j + a queryable, citable endpoint) — the
  content is the moat. *(Investigate options + effort.)*
- **Marketing / positioning** — to be developed (audience: serious Jung readers, students,
  analysts-in-training, comparative-religion scholars; the wedge pitch is "finish
  *Mysterium* / never lose the thread").

---
*Historical detail below (phases 0–6, native-app design, personas) predates the web-first
pivot; kept for the reasoning, not as current instruction.*

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

## Settings & bookmarks — Elena-first (revised after Fable 5 review)

Fable 5's verdict: the first draft managed bookmarks but *forgot reading*. It matched the
Tenets family instead of Elena's Sunday-morning loop (open → oriented → read → capture in
2s → retrieve by symbol). Restructured around that loop. Visual/settings polish can still
echo Tenets ⚠ *(confirm against the real suite)*, but the feature set below is Elena's, not
the family's.

**Add (highest priority — these were missing):**
- **Resume position.** Auto-save last-read § per volume; restore on launch ("You were at CW
  14 §182"). The single most important "keep me oriented" feature. Replaces any "default
  volume" setting.
- **Search my own notes + bookmark labels.** §-anchored results, one tap to jump. Turns
  bookmarks from write-only into recall ("green lion" → her §182 note).
- **One-gesture capture** of the current § from Reference (inline label edit, no navigation).
- **Fast §/volume jump** field (keyboard-first on macOS) — her most frequent action.

**Keep (simple bookmark model):** `Bookmark = { volume, §, label, optional note, dates }`,
SwiftData+CloudKit, **sidebar as the sole home** (quick-jump *and* manage). Auto-sorted by §,
auto-grouped by volume. Rename + swipe-delete-with-undo + jump-to-and-return.

**Cut / defer:** manual reorder and folders (canonical § order *is* the organization);
bookmark management inside Settings; per-note local-only toggle; JSON import (defer);
node/claim bookmarks as a distinct type — **fold them into §-bookmarks** (bookmarking a
node/claim captures its anchoring § and prefills the label).

**Settings, trimmed:** (1) iCloud — status, last-synced, sync-now; (2) Data — export
Markdown+JSON (ordered by vol/§, zero CW text), what-syncs explainer; (3) Reading —
light/dark, text size; (4) About — version, copyright note, acknowledgements.

## Testing

Two layers, both worth automating early:

- **Graph-integrity tests (highest value — they protect the trust model).** A test
  suite over `seed.json` that asserts: every reference's (volume, §) exists in the
  corpus; every quote string actually appears in that paragraph's text; no edge points
  at an undefined node; amplification edges carry a `kind`; interpretive edges carry a
  `claim_type`; the §→page concordance resolves for every cited paragraph. This turns
  "the graph is honest" from a promise into a CI check, and it's the natural home for a
  **Fable 5 verification pass in CI** on any newly added edges.
- **App tests.** Unit tests for `GraphStore` (JSON decode incl. mixed int/string volume
  codes; `edgesNear` window logic; page lookup) and a few UI smoke tests (reading
  companion renders, mode toggle, add-note round-trips through SwiftData). Run under
  `xcodebuild test` on the simulator.
