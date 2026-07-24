// Build step for Direction B ("The Atlas"): detect thematic communities and
// compute a STABLE, baked layout, so every visit shows the same learnable map.
// Reads ../seed.json (+ page concordance), writes src/atlas.json.
//   node → { id, label, type, color, cluster, x, y }
//   edge → { id, source, target, relation, layer, volumes, refs }
//   clusters → [{ id, label, color, size }]
import { readFileSync, writeFileSync } from 'fs'

const here = (p) => new URL(p, import.meta.url)
const seed = JSON.parse(readFileSync(here('../seed.json')))
let pages = {}
try { pages = JSON.parse(readFileSync(here('../app/Sources/Resources/pages.json'))) } catch {}

const TYPE_COLOR = { Concept: '#8fb7c9', Operation: '#cf9a6a', Symbol: '#d9b25f', Figure: '#d0685a', Substance: '#86a86d', Motif: '#b48ad0', Archetype: '#c98f6a' }
const PHASE = { black: '#1c1c1c', white: '#e8e2d0', red: '#b23a2e' }
const PALETTE = ['#d9b25f', '#8fb7c9', '#d0685a', '#86a86d', '#b48ad0', '#cf9a6a', '#5ec8be', '#c98f6a', '#9ec96f', '#c98fb0', '#7fb0d0', '#d0a85e']

const nodeById = Object.fromEntries(seed.nodes.map(n => [n.id, n]))
const nbr = new Map(seed.nodes.map(n => [n.id, new Set()]))
for (const e of seed.edges) {
  if (nbr.has(e.subject) && nbr.has(e.object)) { nbr.get(e.subject).add(e.object); nbr.get(e.object).add(e.subject) }
}
const deg = id => nbr.get(id).size

// --- regions = curated domains keyed off node type (stable & meaningful) ---
// Region ids are namespaced ('dom-…') so a compound region parent can never
// collide with a real node id (e.g. the CW8 concept node 'psyche').
const DOMAIN = {
  Concept:   { id: 'dom-psyche',  label: 'The Psyche',           color: '#8fb7c9' },
  Archetype: { id: 'dom-psyche',  label: 'The Psyche',           color: '#8fb7c9' },
  Operation: { id: 'dom-opus',    label: 'The Opus',             color: '#cf9a6a' },
  Substance: { id: 'dom-materia', label: 'The Materia',          color: '#86a86d' },
  Symbol:    { id: 'dom-symbols', label: 'The Symbols',          color: '#d9b25f' },
  Figure:    { id: 'dom-figures', label: 'The Figures',          color: '#d0685a' },
  Motif:     { id: 'dom-motifs',  label: 'Motifs & Traditions',  color: '#b48ad0' }
}
const nodeCluster = new Map()
const sizes = new Map()
for (const n of seed.nodes) {
  const d = DOMAIN[n.type] || { id: 'dom-other', label: 'Other', color: '#888' }
  nodeCluster.set(n.id, d.id)
  sizes.set(d.id, (sizes.get(d.id) || 0) + 1)
}
const clusters = []
const seenDomain = new Set()
for (const n of seed.nodes) {
  const d = DOMAIN[n.type] || { id: 'other', label: 'Other', color: '#888' }
  if (seenDomain.has(d.id)) continue
  seenDomain.add(d.id)
  clusters.push({ id: d.id, label: d.label, color: d.color, size: sizes.get(d.id) })
}
clusters.sort((a, b) => b.size - a.size)

// --- stable regional layout: anchor each region on a ring, then place its nodes
//     on a phyllotaxis (sunflower) spiral. Deterministic and force-free, so
//     spacing is guaranteed even for nodes whose only links cross regions
//     (a force layout collapses those into a corner). Highest-degree nodes sit
//     at each region's centre; SPREAD sets the minimum gap between nodes. ---
const GOLDEN = Math.PI * (3 - Math.sqrt(5))
const SPREAD = 125
const CX = 2050, CY = 1650, RING = 2100
const anchors = {}
clusters.forEach((c, i) => {
  const a = (i / clusters.length) * 2 * Math.PI - Math.PI / 2
  anchors[c.id] = { x: CX + RING * Math.cos(a), y: CY + RING * Math.sin(a) }
})
let pos = {}
for (const c of clusters) {
  const ids = seed.nodes.filter(n => nodeCluster.get(n.id) === c.id).map(n => n.id)
    .sort((x, y) => deg(y) - deg(x))   // hubs first -> centre
  const a = anchors[c.id]
  ids.forEach((id, i) => {
    const r = SPREAD * Math.sqrt(i + 0.5)
    const th = i * GOLDEN
    pos[id] = { x: Math.round(a.x + r * Math.cos(th)), y: Math.round(a.y + r * Math.sin(th)) }
  })
}

const atlasNodes = seed.nodes.map(n => ({
  id: n.id, label: n.label, type: n.type, tradition: n.tradition || '',
  color: n.color_phase ? PHASE[n.color_phase] : (TYPE_COLOR[n.type] || '#888'),
  cluster: nodeCluster.get(n.id), x: pos[n.id].x, y: pos[n.id].y
}))
const atlasEdges = seed.edges.map((e, i) => {
  const layer = e.bridge ? 'bridge' : e.layer === 'amplification' ? 'amplification' : (!e.references || !e.references.length) ? 'structural' : 'spine'
  return { id: 'e' + i, source: e.subject, target: e.object, relation: e.relation, layer,
    volumes: [...new Set((e.references || []).map(r => String(r.volume)))], refs: e.references || [] }
})

writeFileSync(here('./src/atlas.json'), JSON.stringify({ nodes: atlasNodes, edges: atlasEdges, clusters, pages }))
console.log(`atlas: ${atlasNodes.length} nodes, ${atlasEdges.length} edges, ${clusters.length} regions`)
console.log('regions:', clusters.map(c => `${c.label} (${c.size})`).join(' · '))
