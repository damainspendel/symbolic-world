import cytoscape from 'cytoscape'
import fcose from 'cytoscape-fcose'
import graph from './graph.json'
import pages from './pages.json'
import './style.css'

cytoscape.use(fcose)

const TYPE_COLOR = {
  Concept: '#8fb7c9', Operation: '#cf9a6a', Symbol: '#d9b25f',
  Figure: '#d0685a', Substance: '#86a86d', Motif: '#b48ad0'
}
const PHASE = { black: '#1c1c1c', white: '#e8e2d0', red: '#b23a2e' }
const LAYER = { spine: '#d9b25f', amplification: '#b48ad0', bridge: '#5ec8be', structural: '#5a636e' }
const VOL_LABEL = { '12': 'CW 12', '13': 'CW 13', '14': 'CW 14', '9ii': 'Aion (9ii)', '9i': 'CW 9i', '16': 'CW 16', '5': 'CW 5' }

const esc = s => String(s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]))

function main() {
  const label = id => (graph.nodes.find(n => n.id === id) || {}).label || id
  const page = (v, p) => pages[`${v}:${p}`]

  const nodes = graph.nodes.map(n => ({
    data: {
      id: n.id, label: n.label, type: n.type, tradition: n.tradition || '',
      color: n.color_phase ? PHASE[n.color_phase] : (TYPE_COLOR[n.type] || '#888'),
      ring: TYPE_COLOR[n.type] || '#888'
    }
  }))
  const edges = graph.edges.map((e, i) => {
    const layer = e.bridge ? 'bridge'
      : e.layer === 'amplification' ? 'amplification'
      : (!e.references || e.references.length === 0) ? 'structural' : 'spine'
    const volumes = [...new Set((e.references || []).map(r => String(r.volume)))]
    return {
      data: { id: 'e' + i, source: e.subject, target: e.object, relation: e.relation, layer, volumes, refs: e.references || [] },
      classes: layer
    }
  })

  const cy = cytoscape({
    container: document.getElementById('cy'),
    elements: [...nodes, ...edges],
    minZoom: 0.15, maxZoom: 4, wheelSensitivity: 0.25,
    style: [
      { selector: 'node', style: {
        'background-color': 'data(color)', 'border-color': 'data(ring)', 'border-width': 2,
        'width': 22, 'height': 22, 'label': 'data(label)', 'color': '#c9d0d6',
        'font-family': 'Iowan Old Style, Palatino, Georgia, serif', 'font-size': 11,
        'text-valign': 'bottom', 'text-margin-y': 4, 'text-wrap': 'wrap', 'text-max-width': 120,
        'text-outline-color': '#0e1116', 'text-outline-width': 2, 'min-zoomed-font-size': 7
      }},
      { selector: 'node:selected', style: { 'border-color': '#f0cf82', 'border-width': 4, 'color': '#fff', 'width': 28, 'height': 28 }},
      { selector: 'edge', style: {
        'width': 1.5, 'curve-style': 'straight', 'line-color': '#666',
        'target-arrow-shape': 'triangle', 'target-arrow-color': '#666', 'arrow-scale': 0.7, 'opacity': 0.85
      }},
      { selector: 'edge.spine', style: { 'line-color': LAYER.spine, 'target-arrow-color': LAYER.spine }},
      { selector: 'edge.amplification', style: { 'line-color': LAYER.amplification, 'target-arrow-color': LAYER.amplification, 'line-style': 'dashed' }},
      { selector: 'edge.bridge', style: { 'line-color': LAYER.bridge, 'target-arrow-color': LAYER.bridge, 'width': 2.6 }},
      { selector: 'edge.structural', style: { 'line-color': LAYER.structural, 'target-arrow-color': LAYER.structural, 'line-style': 'dotted' }},
      { selector: '.faded', style: { 'opacity': 0.07, 'text-opacity': 0.04 }},
      { selector: '.hidden', style: { 'display': 'none' }}
    ],
    layout: fcoseLayout()
  })

  function fcoseLayout() {
    return { name: 'fcose', quality: 'proof', animate: true, animationDuration: 700, randomize: true,
      nodeRepulsion: 9000, idealEdgeLength: 95, edgeElasticity: 0.45, gravity: 0.2, numIter: 2500, packComponents: true, nodeSeparation: 90 }
  }

  // ---- selection / neighborhood highlight ----
  function selectNode(node) {
    cy.$(':selected').unselect(); node.select()
    cy.elements().addClass('faded')
    node.closedNeighborhood().removeClass('faded')
    renderPanel(node)
  }
  function clearSelection() {
    cy.$(':selected').unselect(); cy.elements().removeClass('faded')
    document.getElementById('panel').classList.add('hidden')
  }
  cy.on('tap', 'node', e => selectNode(e.target))
  cy.on('tap', e => { if (e.target === cy) clearSelection() })

  function renderPanel(node) {
    const p = document.getElementById('panel')
    const id = node.id()
    const conn = node.connectedEdges().filter(e => !e.hasClass('hidden'))
    const rows = conn.map(e => {
      const otherId = e.data('source') === id ? e.data('target') : e.data('source')
      const dir = e.data('source') === id
        ? `<span class="rel">${esc(e.data('relation'))} →</span> ${esc(label(otherId))}`
        : `${esc(label(otherId))} <span class="rel">→ ${esc(e.data('relation'))}</span>`
      const r = (e.data('refs') || [])[0]
      const cite = r ? `CW ${r.volume} §${r.paragraph}` : ''
      const pg = r ? page(r.volume, r.paragraph) : null
      const q = r ? `<blockquote>${esc(r.quote)}</blockquote>` : ''
      const prov = r && r.claim_type ? `<span class="prov">${esc(r.claim_type)}${r.source ? ' · ' + esc(r.source) : ''}</span>` : ''
      const open = pg ? `<span class="pageref">Bollingen · p.${pg}</span>` : ''
      return `<div class="conn" data-node="${esc(otherId)}">
        <div class="conn-h">${dir}<span class="cite">${cite}</span></div>${q}
        <div class="conn-f">${prov}${open}</div></div>`
    }).join('')
    p.innerHTML = `
      <div class="p-type">${esc(node.data('type'))}${node.data('tradition') ? ' · ' + esc(node.data('tradition')) : ''}</div>
      <h2>${esc(node.data('label'))}</h2>
      <div class="p-count">${conn.length} connection${conn.length !== 1 ? 's' : ''} — click to walk</div>
      ${rows}`
    p.classList.remove('hidden')
    p.querySelectorAll('.conn').forEach(el => el.addEventListener('click', () => {
      const n = cy.getElementById(el.dataset.node); if (n.nonempty()) { selectNode(n); cy.animate({ center: { eles: n } }, { duration: 300 }) }
    }))
  }

  // ---- filters ----
  const volumes = [...new Set(edges.flatMap(e => e.data.volumes))].sort()
  const activeVol = new Set(volumes)
  const activeLayer = new Set(['spine', 'amplification', 'bridge', 'structural'])

  function applyFilters() {
    cy.batch(() => {
      cy.edges().forEach(e => {
        const okLayer = activeLayer.has(e.data('layer'))
        const okVol = e.data('volumes').length === 0 || e.data('volumes').some(v => activeVol.has(v))
        e.toggleClass('hidden', !(okLayer && okVol))
      })
      cy.nodes().forEach(n => {
        const vis = n.connectedEdges().some(e => !e.hasClass('hidden'))
        n.toggleClass('hidden', !vis)
      })
    })
    updateStats()
  }

  const volBox = document.getElementById('filter-volume')
  volBox.innerHTML = '<div class="ftitle">Volumes</div>' + volumes.map(v =>
    `<label><input type="checkbox" checked data-vol="${esc(v)}"> ${esc(VOL_LABEL[v] || 'CW ' + v)}</label>`).join('')
  volBox.querySelectorAll('input').forEach(cb => cb.addEventListener('change', () => {
    cb.checked ? activeVol.add(cb.dataset.vol) : activeVol.delete(cb.dataset.vol); applyFilters()
  }))

  const layerBox = document.getElementById('filter-layer')
  layerBox.innerHTML = '<div class="ftitle">Layers</div>' + Object.keys(LAYER).map(l =>
    `<label><span class="sw" style="background:${LAYER[l]}"></span><input type="checkbox" checked data-layer="${l}"> ${l}</label>`).join('')
  layerBox.querySelectorAll('input').forEach(cb => cb.addEventListener('change', () => {
    cb.checked ? activeLayer.add(cb.dataset.layer) : activeLayer.delete(cb.dataset.layer); applyFilters()
  }))

  // ---- search ----
  document.getElementById('search').addEventListener('input', e => {
    const q = e.target.value.trim().toLowerCase()
    if (!q) { cy.elements().removeClass('faded'); return }
    const match = cy.nodes().filter(n => n.data('label').toLowerCase().includes(q))
    cy.elements().addClass('faded'); match.removeClass('faded'); match.connectedEdges().removeClass('faded')
    if (match.length === 1) selectNode(match[0])
  })

  // ---- buttons + stats ----
  document.getElementById('fit').addEventListener('click', () => cy.animate({ fit: { padding: 40 } }, { duration: 400 }))
  document.getElementById('relayout').addEventListener('click', () => cy.layout(fcoseLayout()).run())

  function updateStats() {
    const nv = cy.nodes().not('.hidden').length, ev = cy.edges().not('.hidden').length
    document.getElementById('stats').textContent = `${nv} nodes · ${ev} edges`
  }
  cy.ready(() => { cy.fit(undefined, 40); updateStats() })
}

main()
