# JungKG — product backlog

Ideas parked for later, not yet scheduled. The canonical graph and its § discipline
always come first; nothing here may compromise the trust model (every canonical edge
§-anchored + independently verified).

## App

- **Explore node card collides with the bottom control bar.** The selected-node card
  (bottom of Explore) overlaps the floating Mode / search / settings pill — they sit on
  top of each other. Fix: lift the card above the control bar (bottom inset), or dock the
  card to a side, so the two never overlap. *(Added 2026-07-23.)*

- **Reference toolbar title ("Around §N") leaks into Explore.** Because both views are
  kept alive (so Explore keeps its layout), the Reference NavigationSplitView's window
  toolbar/title still shows in Explore mode, where it's meaningless. Fix: suppress the
  reference chrome (title + sidebar toggle) when `mode == .explore`, or give Explore its
  own toolbar context. *(Added 2026-07-23.)*

- **Bidirectional selection (Reference → Explore).** Selecting a claim/node in Reference
  should highlight — and centre — the corresponding node/edge in the Explore graph.
  Selection currently flows only Explore → Reference; make it symmetric so switching to
  Explore lands on (and highlights) what you were reading. *(Added 2026-07-23.)*

- **App icon — Tenets-family style.** Design a Red Thread app icon consistent with the
  Tenets app family's visual identity ⚠ *(match the real suite's icon language — corner
  radius, palette, motif treatment)*. Motif candidates: a red thread / Ariadne's thread,
  a labyrinth, or a single luminous node-and-edge. macOS + iOS sizes.

## Features

- **User-contributed amplifications.** Let people add their own amplifications — the
  images and parallels *they* see around a symbol. **Hard constraint:** these live in a
  **separate, clearly-labeled layer**, visually and structurally distinct from Jung's
  §-anchored amplifications; they never merge into the verified graph or borrow its
  authority. Optional: let a user cite their own source. Serves Theo (correspondence
  practitioner) and Dana (dreamer) especially. *(Added 2026-07-23.)*

- **Local-only note option.** A per-note "do not sync" toggle for the most sensitive
  material (Marisol's clinical case notes) — overrides CloudKit sync for that note.

- **Note export formats beyond Markdown.** BibTeX / formatted academic citation export
  for the scholar/analyst personas.

- **Multi-edition §→page concordances.** Ship Bollingen first; add other printings /
  the Gesammelte Werke so "open the paragraph" works for more owned editions.

- **Stable citable URLs (web app).** Permalink per node and per edge, for scholars who
  cite and share (Whitmore).

- **Tradition-first reverse index.** Browse the graph by tradition (Kabbalah, Gnostic,
  alchemy, Christian mysticism) rather than by psychological concept (Theo).

- **Explore mode inside the app chrome.** The dark constellation view as a mode within
  the reading companion, not just the standalone atlas.
