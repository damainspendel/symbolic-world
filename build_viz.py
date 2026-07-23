#!/usr/bin/env python3
"""
Regenerate the embedded graph data in viz.html from seed.json — the single
source of truth. Run after any change to seed.json:

    python3 build_viz.py

Keeps the visualization and the canonical graph from ever drifting apart.
"""
import json
import re

seed = json.load(open('seed.json'))

nodes = []
for n in seed['nodes']:
    o = {'id': n['id'], 'type': n['type'], 'label': n['label']}
    if 'color_phase' in n:
        o['phase'] = n['color_phase']
    if 'tradition' in n:
        o['tradition'] = n['tradition']
    nodes.append(o)

edges = []
for e in seed['edges']:
    o = {'s': e['subject'], 'r': e['relation'], 'o': e['object']}
    if e.get('layer'):
        o['layer'] = e['layer']
    if e.get('kind'):
        o['kind'] = e['kind']
    if e.get('bridge'):
        o['bridge'] = True
    o['refs'] = [{'v': r['volume'], 'p': r['paragraph'], 'q': r['quote'],
                  'c': r['confidence'], 'ct': r.get('claim_type'),
                  'src': r.get('source')}
                 for r in e.get('references', [])]
    edges.append(o)

data = {'nodes': nodes, 'edges': edges}
js = 'const DATA = ' + json.dumps(data, ensure_ascii=False, indent=2) + ';'

html = open('viz.html', encoding='utf-8').read()
html, n = re.subn(r'const DATA = \{.*?\n\};', js, html, count=1, flags=re.S)
assert n == 1, 'DATA block not found in viz.html'
open('viz.html', 'w', encoding='utf-8').write(html)
print(f'viz.html rebuilt: {len(nodes)} nodes, {len(edges)} edges')
