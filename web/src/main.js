import cytoscape from 'cytoscape'
import atlas from './atlas.json'
import './style.css'

const LAYER = { spine: '#d9b25f', amplification: '#b48ad0', bridge: '#5ec8be', structural: '#5a636e' }
const VOL_LABEL = { '5': 'CW 5 · Symbols of Transformation', '8': 'CW 8 · Structure & Dynamics of the Psyche', '9i': 'CW 9i · Archetypes', '9ii': 'CW 9ii · Aion', '11': 'CW 11 · Psychology & Religion', '12': 'CW 12 · Psychology & Alchemy', '13': 'CW 13 · Alchemical Studies', '14': 'CW 14 · Mysterium', '16': 'CW 16 · Practice of Psychotherapy' }
// sort key: numeric by volume, with 9i before 9ii
const volKey = v => { const m = String(v).match(/^(\d+)(i*)$/); return m ? parseInt(m[1], 10) + (m[2] === 'ii' ? 0.2 : m[2] === 'i' ? 0.1 : 0) : 999 }
const esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))

const labelOf = id => (atlas.nodes.find(n => n.id === id) || {}).label || id

// dispute history per current edge (key: "subject|relation|object") — loaded async
const DISPUTES = {}
const CONFIRMS = {}
fetch('./disputes.json').then(r => r.json()).then(d => {
  d.disputes.forEach(x => (x.current_edges || []).forEach(k => { (DISPUTES[k] = DISPUTES[k] || []).push(x) }))
  const sel = cy.$('node:selected'); if (sel.nonempty()) renderPanel(sel[0])
}).catch(() => {})
fetch('./confirmations.json').then(r => r.json()).then(d => {
  d.confirmations.forEach(x => (x.current_edges || []).forEach(k => { (CONFIRMS[k] = CONFIRMS[k] || []).push(x) }))
  const sel = cy.$('node:selected'); if (sel.nonempty()) renderPanel(sel[0])
}).catch(() => {})
const page = (v, p) => atlas.pages[`${v}:${p}`]

const cy = cytoscape({
  container: document.getElementById('cy'),
  minZoom: 0.06, maxZoom: 12, wheelSensitivity: 0.45,
  elements: [
    ...atlas.clusters.map(c => ({ data: { id: c.id, label: c.label, kind: 'region', color: c.color } })),
    ...atlas.nodes.map(n => ({ data: { id: n.id, label: n.label, type: n.type, tradition: n.tradition, color: n.color, parent: n.cluster }, position: { x: n.x, y: n.y } })),
    ...atlas.edges.map(e => ({ data: { id: e.id, source: e.source, target: e.target, relation: e.relation, layer: e.layer, volumes: e.volumes, refs: e.refs }, classes: e.layer }))
  ],
  layout: { name: 'preset' },
  style: [
    { selector: 'node[kind = "region"]', style: {
      'background-color': 'data(color)', 'background-opacity': 0.06,
      'border-color': 'data(color)', 'border-opacity': 0.38, 'border-width': 1.5,
      'shape': 'round-rectangle', 'padding': '80px',
      'label': 'data(label)', 'text-valign': 'top', 'text-halign': 'center', 'text-margin-y': 10,
      'font-family': 'Iowan Old Style, Palatino, Georgia, serif', 'font-size': 26, 'font-style': 'italic',
      'color': 'data(color)', 'text-opacity': 0.85, 'min-zoomed-font-size': 5, 'events': 'no', 'z-compound-depth': 'bottom'
    }},
    { selector: 'node[kind != "region"]', style: {
      'background-color': 'data(color)', 'border-color': 'data(color)', 'border-width': 2,
      'width': 20, 'height': 20, 'label': 'data(label)', 'color': '#c9d0d6',
      'font-family': 'Iowan Old Style, Palatino, Georgia, serif', 'font-size': 11,
      'text-valign': 'bottom', 'text-margin-y': 3, 'text-wrap': 'wrap', 'text-max-width': 120,
      'text-outline-color': '#0e1116', 'text-outline-width': 2, 'min-zoomed-font-size': 10
    }},
    { selector: 'node:selected', style: { 'border-color': '#f0cf82', 'border-width': 4, 'color': '#fff', 'width': 26, 'height': 26, 'min-zoomed-font-size': 0 }},
    { selector: 'edge', style: {
      'width': 1.5, 'curve-style': 'straight', 'line-color': '#666', 'opacity': 0.8,
      'target-arrow-shape': 'triangle', 'target-arrow-color': '#666', 'arrow-scale': 0.65
    }},
    { selector: 'edge.spine', style: { 'line-color': LAYER.spine, 'target-arrow-color': LAYER.spine }},
    { selector: 'edge.amplification', style: { 'line-color': LAYER.amplification, 'target-arrow-color': LAYER.amplification, 'line-style': 'dashed' }},
    { selector: 'edge.bridge', style: { 'line-color': LAYER.bridge, 'target-arrow-color': LAYER.bridge, 'width': 2.6 }},
    { selector: 'edge.structural', style: { 'line-color': LAYER.structural, 'target-arrow-color': LAYER.structural, 'line-style': 'dotted' }},
    { selector: '.faded', style: { 'opacity': 0.06, 'text-opacity': 0.04 }},
    { selector: 'node:selected.faded, node.nbr', style: { 'opacity': 1, 'text-opacity': 1, 'min-zoomed-font-size': 0 }},
    { selector: '.hidden', style: { 'display': 'none' }}
  ]
})

// ---- selection / neighborhood highlight ----
function selectNode(node) {
  hideAbout()
  cy.$(':selected').unselect(); node.select()
  cy.elements().addClass('faded'); cy.nodes('[kind = "region"]').removeClass('faded')
  const hood = node.closedNeighborhood()
  hood.removeClass('faded'); hood.nodes().addClass('nbr')
  renderPanel(node)
}
function clearSelection() {
  cy.$(':selected').unselect(); cy.elements().removeClass('faded nbr')
  document.getElementById('panel').classList.add('hidden')
}
cy.on('tap', 'node[kind != "region"]', e => selectNode(e.target))
cy.on('tap', e => { if (e.target === cy) clearSelection() })

// ---- about / how-it-works panel (shares the right slot with the detail panel) ----
const aboutEl = document.getElementById('about'), aboutOpenEl = document.getElementById('about-open')
function hideAbout() { aboutEl.classList.add('hidden'); aboutOpenEl.classList.remove('hidden') }
function showAbout() { clearSelection(); aboutEl.classList.remove('hidden'); aboutOpenEl.classList.add('hidden') }
document.getElementById('about-min').addEventListener('click', hideAbout)
aboutOpenEl.addEventListener('click', showAbout)

function renderPanel(node) {
  const p = document.getElementById('panel'); const id = node.id()
  const conn = node.connectedEdges().filter(e => !e.hasClass('hidden'))
  const rows = conn.map(e => {
    const other = e.data('source') === id ? e.data('target') : e.data('source')
    const dir = e.data('source') === id
      ? `<span class="rel">${esc(e.data('relation'))} →</span> ${esc(labelOf(other))}`
      : `${esc(labelOf(other))} <span class="rel">→ ${esc(e.data('relation'))}</span>`
    const r = (e.data('refs') || [])[0]
    const eKey = `${e.data('source')}|${e.data('relation')}|${e.data('target')}`
    const dHist = DISPUTES[eKey] || []
    const cHist = CONFIRMS[eKey] || []
    const cite = r ? `<span class="cite-toggle" title="Show verification record">CW ${r.volume} §${r.paragraph}${r.verified ? ' <span class="vcheck">✓</span>' : ''}${dHist.length ? ' <span class="dmark" title="This edge has public dispute history">⚖</span>' : ''}</span>` : ''
    const pg = r ? page(r.volume, r.paragraph) : null
    const q = r ? `<blockquote>${esc(r.quote)}</blockquote>` : ''
    const prov = r && r.claim_type ? `<span class="prov">${esc(r.claim_type)}${r.source ? ' · ' + esc(r.source) : ''}</span>` : ''
    const open = pg ? `<span class="pageref">Bollingen · p.${pg}</span>` : ''
    const CT_DESC = { 'jung-asserts': "Jung's own interpretive claim, in his own voice", 'jung-reports-parallel': 'a doctrine or tradition Jung reports without asserting it himself', 'jung-quotes-source': 'a named source Jung quotes' }
    const evidence = r ? `<div class="evidence hidden">
        <div><b>Claim type:</b> ${esc(r.claim_type || '—')} — ${esc(CT_DESC[r.claim_type] || '')}</div>
        ${r.source ? `<div><b>Source:</b> ${esc(r.source)}</div>` : ''}
        <div><b>Confidence:</b> ${esc(r.confidence || '—')}</div>
        <div><b>Verification:</b> ${r.verified ? `passed independent review (${esc(r.verified_by || 'gate')}, ${esc(r.verified_date || '')}) — the full paragraph was checked for support, direction, quote fidelity, and attribution` : 'not yet independently reviewed'}</div>
        <div><b>Check it yourself:</b> CW ${r.volume} §${r.paragraph}${pg ? `, Bollingen p.${pg}` : ''}</div>
        ${dHist.map(x => `<div class="dhist"><b>Disputed</b> (${esc(x.date)}, ${esc(x.outcome)}): ${esc(x.objection)} <span class="dhist-res">→ ${esc(x.resolution)}</span> <a href="/disputes.html" class="dhist-link">full log</a></div>`).join('')}
        ${cHist.length ? `<div class="chist"><b>Reader-confirmed ×${cHist.length}</b> — a human checked the cited paragraph${cHist.length>1?'s':''} (${cHist.map(x=>esc(x.date)).join(', ')}) <a href="/disputes.html" class="dhist-link">log</a></div>` : ''}
        <button class="confirm-btn" data-report="${encodeURIComponent(JSON.stringify({ edge: `${e.data('source')} —${e.data('relation')}→ ${e.data('target')}`, citation: `CW ${r.volume} §${r.paragraph}` + (pg ? ` (Bollingen p.${pg})` : ''), quote: r.quote, claim_type: r.claim_type || '' }))}">Confirm this edge — I checked the book</button>
        <button class="dispute-btn" data-report="${encodeURIComponent(JSON.stringify({ edge: `${e.data('source')} —${e.data('relation')}→ ${e.data('target')}`, citation: `CW ${r.volume} §${r.paragraph}` + (pg ? ` (Bollingen p.${pg})` : ''), quote: r.quote, claim_type: r.claim_type || '', verified_by: r.verified_by || '', verified_date: r.verified_date || '' }))}">Dispute this edge — copy report</button>
      </div>` : ''
    return `<div class="conn" data-node="${esc(other)}"><div class="conn-h">${dir}<span class="cite">${cite}</span></div>${q}<div class="conn-f">${prov}${open}</div>${evidence}</div>`
  }).join('')
  p.innerHTML = `<div class="p-type">${esc(node.data('type'))}${node.data('tradition') ? ' · ' + esc(node.data('tradition')) : ''}</div>
    <h2>${esc(node.data('label'))}</h2>
    <div class="p-count">${conn.length} connection${conn.length !== 1 ? 's' : ''} — click to walk</div>${rows}`
  p.classList.remove('hidden')
  p.querySelectorAll('.conn').forEach(el => el.addEventListener('click', () => {
    const n = cy.getElementById(el.dataset.node); if (n.nonempty()) { selectNode(n); cy.animate({ center: { eles: n }, zoom: Math.max(cy.zoom(), 0.9) }, { duration: 350 }) }
  }))
  // clicks inside the evidence record must never walk the graph
  p.querySelectorAll('.evidence').forEach(el => el.addEventListener('click', ev => ev.stopPropagation()))
  // citation click toggles the verification record instead of walking the graph
  p.querySelectorAll('.cite-toggle').forEach(el => el.addEventListener('click', ev => {
    ev.stopPropagation()
    const box = el.closest('.conn').querySelector('.evidence')
    if (box) box.classList.toggle('hidden')
  }))
  // confirm button: copy a structured, prefilled human-confirmation report
  p.querySelectorAll('.confirm-btn').forEach(el => el.addEventListener('click', ev => {
    ev.stopPropagation()
    const d = JSON.parse(decodeURIComponent(el.dataset.report))
    const report = [
      'CONFIRMATION REPORT — The Symbolic World',
      `Edge: ${d.edge}`,
      `Citation: ${d.citation}`,
      `Quote: "${d.quote}"`,
      `Claim type: ${d.claim_type}`,
      '',
      'I checked the cited paragraph in the Collected Works and confirm the edge.',
      'Edition checked: [fill in]',
      'Notes (optional): [anything the record should say]',
      '',
      'Submit at: https://github.com/damianspendel/symbolic-world/issues/new?template=confirm.yml',
      'Confirmations become part of the edge\u2019s public verification record.'
    ].join('\n')
    navigator.clipboard.writeText(report).then(() => {
      el.textContent = 'Report copied \u2713 \u2014 submit via the confirm template'
      setTimeout(() => { el.textContent = 'Confirm this edge \u2014 I checked the book' }, 3000)
    })
  }))
  // dispute button: copy a structured, prefilled dispute report to the clipboard
  p.querySelectorAll('.dispute-btn').forEach(el => el.addEventListener('click', ev => {
    ev.stopPropagation()
    const d = JSON.parse(decodeURIComponent(el.dataset.report))
    const report = [
      'DISPUTE REPORT — The Symbolic World',
      `Edge: ${d.edge}`,
      `Citation: ${d.citation}`,
      `Quote: "${d.quote}"`,
      `Claim type: ${d.claim_type}`,
      `Verified by: ${d.verified_by} (${d.verified_date})`,
      '',
      'My objection (what the cited paragraph actually says):',
      '  [describe here — please quote the paragraph]',
      '',
      'Submit at: https://github.com/damianspendel/symbolic-world/issues/new?template=dispute.yml',
      '(use the dispute template). Disputed edges are',
      're-reviewed with this objection attached; outcomes are published at',
      'https://symbolicworld.observer/disputes.html'
    ].join('\n')
    navigator.clipboard.writeText(report).then(() => {
      el.textContent = 'Report copied ✓ — submit at github.com/damianspendel/symbolic-world/issues'
      setTimeout(() => { el.textContent = 'Dispute this edge — copy report' }, 3000)
    })
  }))
}

// ---- filters ----
const volumes = [...new Set(atlas.edges.flatMap(e => e.volumes))].sort((a, b) => volKey(a) - volKey(b))
const activeVol = new Set(volumes)
const activeLayer = new Set(['spine', 'amplification', 'bridge', 'structural'])
function applyFilters() {
  cy.batch(() => {
    cy.edges().forEach(e => {
      const ok = activeLayer.has(e.data('layer')) && (e.data('volumes').length === 0 || e.data('volumes').some(v => activeVol.has(v)))
      e.toggleClass('hidden', !ok)
    })
    cy.nodes('[kind != "region"]').forEach(n => n.toggleClass('hidden', !n.connectedEdges().some(e => !e.hasClass('hidden'))))
    cy.nodes('[kind = "region"]').forEach(r => r.toggleClass('hidden', r.children().every(c => c.hasClass('hidden'))))
  })
  updateStats()
}
const volBox = document.getElementById('filter-volume')
volBox.innerHTML = '<div class="ftitle">Volumes</div>' + volumes.map(v => `<label><input type="checkbox" checked data-vol="${esc(v)}"> ${esc(VOL_LABEL[v] || 'CW ' + v)}</label>`).join('')
volBox.querySelectorAll('input').forEach(cb => cb.addEventListener('change', () => { cb.checked ? activeVol.add(cb.dataset.vol) : activeVol.delete(cb.dataset.vol); applyFilters() }))
const layerBox = document.getElementById('filter-layer')
layerBox.innerHTML = '<div class="ftitle">Layers</div>' + Object.keys(LAYER).map(l => `<label><span class="sw" style="background:${LAYER[l]}"></span><input type="checkbox" checked data-layer="${l}"> ${l}</label>`).join('')
layerBox.querySelectorAll('input').forEach(cb => cb.addEventListener('change', () => { cb.checked ? activeLayer.add(cb.dataset.layer) : activeLayer.delete(cb.dataset.layer); applyFilters() }))

// ---- search ----
document.getElementById('search').addEventListener('input', e => {
  const q = e.target.value.trim().toLowerCase()
  cy.elements().removeClass('faded nbr')
  if (!q) return
  const match = cy.nodes('[kind != "region"]').filter(n => n.data('label').toLowerCase().includes(q))
  if (!match.length) return
  cy.elements().addClass('faded'); cy.nodes('[kind = "region"]').removeClass('faded')
  match.removeClass('faded'); match.connectedEdges().removeClass('faded'); match.addClass('nbr')
  if (match.length === 1) { selectNode(match[0]); cy.animate({ center: { eles: match[0] }, zoom: 1.1 }, { duration: 350 }) }
})

// ---- buttons + stats ----
document.getElementById('fit').addEventListener('click', () => cy.animate({ fit: { padding: 50 } }, { duration: 450 }))
document.getElementById('relayout').textContent = 'Reset'
document.getElementById('relayout').addEventListener('click', () => { clearSelection(); document.getElementById('search').value = ''; cy.animate({ fit: { padding: 50 } }, { duration: 450 }) })
function updateStats() {
  document.getElementById('stats').textContent = `${cy.nodes('[kind != "region"]').not('.hidden').length} nodes · ${cy.edges().not('.hidden').length} edges · ${atlas.clusters.length} regions`
}
cy.ready(() => { cy.fit(undefined, 50); updateStats() })
