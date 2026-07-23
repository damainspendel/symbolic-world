# JungKG — Strategy

A step back before scaling. We have proven the method (grounded edges, independent
Fable 5 verification, an amplification layer) on the alchemy trio. Before mining at
volume, this defines *how* we mine for quality, *what* that does to the graph, *how*
we ship it, and *who* it is for.

---

## 1. The mining discipline — differentiated activities

"Mining" is not one activity. Each edge type is extracted differently and held to a
different quality bar. Treating them as one is how knowledge graphs go weak.

| Track | What it extracts | Method | Fable 5 review question |
|---|---|---|---|
| **T1 · Spine** | Interpretive claims (X *symbolizes / personifies / is-analogue-of* Y) | Per-§ scan for definitional assertions | Does this paragraph actually *assert* the claim? |
| **T2 · Amplification — image** | Intra-tradition picture-series (coniunctio ↔ Rex & Regina) | Scan for Jung gathering the alchemical image-set | Is this Jung's own image-series, not ours? |
| **T3 · Amplification — parallel** | Cross-tradition parallels (nigredo ↔ Shulamite) | Scan for named parallels to other traditions | Does *Jung himself* draw it — and is it his claim or his source's? |
| **T4 · Cross-reference** | Jung citing his own other works | Mechanical: footnotes carry CW §-numbers | Confirm the target §; lighter review (structural) |
| **T5 · Node definitions** | The canonical definition of a concept (Aion §9 = the Self) | Locate the authoritative "I call this…" passage | Is this the definitive locus, not a passing mention? |

**Quality gates (the non-negotiables):**
1. **Every T1–T3 edge passes independent Fable 5 review** before it counts — the loop
   has already caught a meaning-flipped quote and a wrong-source citation on 19 edges.
2. **Gold-set precision bar.** The hand-built, verified alchemy edges are the
   benchmark; automated extraction must clear a precision threshold against them
   before it is trusted on a fresh volume.
3. **Provenance typing (new).** Add a `claim_type` to every reference —
   `jung-asserts` · `jung-quotes-source` · `jung-reports-parallel`. This is what lets
   a scholar trust the graph (distinguishing Jung's assertion from Jung citing Knorr
   von Rosenroth), and it keeps *us* honest. Do this **before** scaling mining.
4. **Human sign-off** (`verified`) stays the last step; the machine never certifies
   its own edge.

**Volumes mine differently.** Aion is spine-heavy (T1/T5 — the Self, the shadow).
CW 14 / 5 / 11 are amplification-heavy (T2/T3). Plan the mining track to the volume.

---

## 2. What it looks like in the graph

- **The spine goes multi-volume.** `the-self` stops being a leaf and becomes the
  central hub the moment Aion §9 lands. Alchemy's `lapis → the-self` edge now
  connects into Aion's whole treatment of the Self — the graph starts to feel like
  *one mind*, not one topic.
- **The cross-reference layer is the connective tissue.** T4 edges (`§X → §Y` across
  volumes) are what turn a stack of separate volume-graphs into a single web. This is
  the highest-leverage layer for the "his whole mind" feeling, and it is mechanically
  extractable.
- **Model additions:** `claim_type` on references (provenance); optional CW↔GW edition
  concordance for scholars; `kind` already distinguishes image vs parallel.
- **Two views over one graph.** The same data renders as a *reference* view
  (citation-dense, exportable) and an *explore* view (constellation, image-led). One
  graph, two skins — see the persona tension in §4.
- **Health metrics, per volume:** coverage (§ mined / total), grounded %, verified %,
  and the self-generated "needs work" worklist.

---

## 3. Release paths — one graph, many surfaces

The graph (flat-file triples, the standing source of truth) is the shared core; each
app is a *view* plus a persona-specific capture/interaction layer. Local-first wherever
personal material attaches.

| Surface | Primary persona | The job it does | Why this surface |
|---|---|---|---|
| **macOS** — *reading companion* | Elena (autodidact) | Second-screen "you are here" while reading the physical book | Desk context, persistent, local-first; matches shipped alchemy content. **Ship first.** |
| **iOS** — *capture-first* | Dana (dreamer), Marisol (on the move) | Symbol lookup + private journal at 6:40 a.m. | Dreams/insights are captured in minutes or lost |
| **Web** — *citation instrument* | Whitmore (scholar) | Stable permalink URLs per node/edge, Zotero export, no install | Scholars cite URLs and won't install apps; reach + shareability |

**Sequencing:** macOS → iOS → web, matching both the content we have (alchemy) and the
wedge persona. Reuses your stack: Swift (HexAI experience), on-device MLX for
extraction, web for reach. The apps ship the graph + § pointers only — never the text.

---

## 4. Personas & user journeys (Fable 5)

Full brainstorm by a Fable 5 agent; distilled here. *(Journey § numbers below are
illustrative scenarios, not verified graph facts.)*

- **Elena — the autodidact drowning in *Mysterium*.** 43, serious self-directed reader,
  owns CW 12–14, losing the thread mid-book. Job: *"keep me oriented in a book trying
  to disorient me."* Unique need: **reading-position mode** — a "you are here" §-cursor
  that re-centers the graph around where she is. Spine layer, macOS.
- **Marisol — the analyst-in-training.** 36, Jungian institute, cites under deadline,
  handles clinical material. Job: *"half-remembered concept → defensible citation in
  two minutes."* Unique need: **private, encrypted case workspace** with academic
  citation export. Spine + cross-reference, macOS/iOS. Local-first is an *ethical*
  requirement here.
- **Whitmore — the comparative-religion scholar.** 58, uses Jung as a provenance index,
  professionally suspicious. Job: *"what does Jung claim, where, and is it his claim or
  his source's?"* Unique need: **claim-typing + Zotero/BibTeX export + edition
  concordance.** Amplification + cross-reference, web with stable citable URLs. *His
  standard is what keeps the anchors honest for everyone.*
- **Dana — the dreamer.** 29, in Jungian-leaning therapy, enters by image not concept
  ("black water," not "nigredo"). Job: *"I dreamed something strange — did Jung say
  anything?"* Unique need: **dream journal with symbol tagging** + plain-language image
  search. Amplification-first, iOS. (Product risk: must point to Jung, never *interpret
  Dana*.)
- **Theo — the tarot practitioner.** 34, correspondence-thinker, enters by *tradition*.
  Job: *"a rigorous cross-tradition correspondence engine where every link is sourced."*
  Unique need: **tradition-first reverse index** + exportable visual graph snapshots.
  Amplification layer, web + iOS.

**The common core every persona needs us to nail:**
1. **The §-anchor is the product.** One vague or wrong edge devalues the whole atlas
   for all of them. Anchor accuracy > any feature.
2. **Symbol-as-hub navigation** — arrive at a symbol (by term / image / § / tradition),
   radiate through typed edges.
3. **Points into books, never replaces them.** The copyright constraint is the
   product's identity and moat: *"the atlas to the books you own."*
4. **Privacy by architecture** — three of five attach intimate material; local-first is
   a trust foundation.

**The central product tension:** *precision instrument* (Whitmore, Marisol — exact,
exportable, permalinked) vs *contemplative object* (Dana, Theo — associative, image-led,
beautiful). Resolution is not a mushy middle but **two skins over one graph**: reference
mode and explore mode, same anchors underneath.

**The wedge — build for Elena first.** (1) Perfect content-fit *today*: the shipped
corpus is alchemy, and her whole problem lives in alchemy. (2) Her core feature
(§-anchored navigation + reverse-lookup-by-§) is the load-bearing foundation every
other persona's features sit on. (3) Acute, named, community-visible pain — "I bounced
off *Mysterium*" sells itself in the exact channels her buyers already gather in.
(4) Autodidacts become trainees and run the reading groups the others orbit — she
converts the adjacent personas. **Build the macOS reading companion for Elena; make
Marisol's citation export the fast follow; adopt Whitmore's provenance rigor as the
editorial standard from day one.**

---

## 5. What changes, and the next concrete step

**Plan deltas:**
- Add `claim_type` provenance typing to the reference model **before** scaling mining.
- Mine in differentiated tracks (T1–T5), each with its own Fable 5 gate.
- Beachhead = **Elena → macOS reading companion**; content target = finish the alchemy
  trio to depth, then Aion (so `the-self` becomes a hub).

**Track-1 Aion trial — DONE (gate passed).** Extended the extractor to Aion (429 §,
clean), mined 9 candidate spine edges, ran the Fable 5 gate. Result: **7/9 SUPPORTED,
2 PARTIAL, 0 WRONG — zero fabrications, zero misquotes**, and both cross-volume bridges
(`individuation → coniunctio`, `the-self → quaternity`) confirmed. Verdict: automated
Track-1 mining is trustworthy enough to scale. The two PARTIALs were merged after fixes;
`the-self` is now a degree-5 hub joining the Aion and alchemy clusters.

**New verification rule (from the trial), now part of the gate:** the object node's term
must appear literally in the anchor paragraph, and any conditional ("if… then…") must be
preserved or the relation softened. Both PARTIALs shared this one failure mode
(object-granularity drift); the rule closes it cheaply.

**Aion depth pass, batch 2 — DONE.** Mined the Self-complex (Ego, Shadow, Syzygy, Self,
Christ, God-image): **7/8 SUPPORTED, 1 PARTIAL, 0 WRONG (87.5%, up from 77.8%)** — the
literal-term rule eliminated the object-granularity failure class. The one PARTIAL was a
mis-attribution (a Gnostic view tagged as Jung's own), re-anchored to §79. Graph now
**32 nodes, 36 edges**; `the-self` and `the-shadow` are both degree-6 hubs. New nodes:
ego, shadow, anima, animus, christ, antichrist, wholeness, mandala, god-image,
collective-unconscious.

**Rule tightening (batch 3 onward):** the object term must appear inside the **quote
itself**, not merely somewhere in the anchor paragraph. This closes the last observed
failure mode (a quote that omits the object term even though the paragraph contains it).

**Next:** continue the Aion depth pass (Gnostic symbols of the Self, the fish, Structure
& Dynamics of the Self) to finish the hub, then move to macOS mockups for Elena. Tooling
in place: `build_viz.py` regenerates the visualization from `seed.json` so they never
drift; each batch stays gated by independent Fable 5 review.
