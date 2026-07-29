#!/usr/bin/env python3
"""Generate web/public/james.html (self-contained visual graph) from james/james_seed.json."""
import json, math, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
seed = json.load(open(ROOT / 'james' / 'james_seed.json'))
nodes, edges = seed['nodes'], seed['edges']
TYPE_COLOR = {"Concept":"#8fb7c9","Process":"#cf9a6a","State":"#b48ad0","Figure":"#d0685a","Motif":"#9ec9c3"}
types = sorted({n['type'] for n in nodes})
centers = {}
R = 340
for i, t in enumerate(types):
    a = 2*math.pi*i/len(types) - math.pi/2
    centers[t] = (600 + R*math.cos(a), 430 + 0.82*R*math.sin(a))
pos, by_type = {}, {}
for n in nodes: by_type.setdefault(n['type'], []).append(n)
GA = math.pi*(3-math.sqrt(5))
for t, ns in by_type.items():
    cx, cy = centers[t]
    for k, n in enumerate(ns):
        r = 26*math.sqrt(k+0.6); th = k*GA
        pos[n['id']] = (round(cx + r*math.cos(th)), round(cy + 0.9*r*math.sin(th)))
data = {"nodes":[{**n, "x":pos[n['id']][0], "y":pos[n['id']][1], "color":TYPE_COLOR.get(n['type'],'#888')} for n in nodes],
        "edges":[{"s":e['subject'],"o":e['object'],"rel":e['relation'],"ref":e['references'][0]} for e in edges],
        "types": [{"t":t,"cx":round(centers[t][0]),"cy":round(centers[t][1]),"color":TYPE_COLOR.get(t,'#888')} for t in types]}
tpl = open(ROOT / 'tools' / 'james_page_template.html').read()
out = tpl.replace('__DATA__', json.dumps(data, ensure_ascii=False))
open(ROOT / 'web' / 'public' / 'james.html', 'w').write(out)
print(f"james.html regenerated: {len(nodes)} nodes / {len(edges)} edges")
