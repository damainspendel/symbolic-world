#!/usr/bin/env python3
"""
JungKG — seed graph queries (Phase 1)

Proves the grounded graph answers real questions. Run: python3 query.py
"""
import json

G = json.load(open('seed.json', encoding='utf-8'))
NODES = {n['id']: n for n in G['nodes']}
EDGES = G['edges']


def label(nid):
    return NODES.get(nid, {}).get('label', nid)


def cite(ref):
    return f"CW{ref['volume']} §{ref['paragraph']}"


print("Q1  What does Jung read as a symbol of the Self? (with sources)")
for e in EDGES:
    if e['relation'] == 'symbolizes' and e['object'] == 'the-self':
        srcs = ", ".join(cite(r) for r in e['references'] if r['paragraph'])
        print(f"    {label(e['subject'])}  →  the Self   [{srcs}]")

print("\nQ2  The transformation axis (structural path)")
chain, cur = [], 'nigredo'
seen = set()
while cur and cur not in seen:
    seen.add(cur); chain.append(label(cur))
    cur = next((e['object'] for e in EDGES
                if e['subject'] == cur and e['relation'] == 'precedes'), None)
print("    " + "  →  ".join(chain))

# Structural relations are taxonomic facts, not claims about the text, so they
# are exempt from the citation requirement.
STRUCTURAL = {'precedes', 'is-stage-of', 'alias-of', 'broader', 'narrower'}

print("\nQ3  Worklist — interpretive edges the graph itself flags for work")
for e in EDGES:
    if e['relation'] in STRUCTURAL:
        continue
    real = [r for r in e['references'] if r['paragraph']]
    if not real:
        print(f"    [NO SOURCE]   {label(e['subject'])} --{e['relation']}--> {label(e['object'])}")
    elif any(r['confidence'] == 'low' for r in real):
        print(f"    [WEAK ANCHOR] {label(e['subject'])} --{e['relation']}--> {label(e['object'])}")

print("\nQ4  Verification status")
total = sum(len(e['references']) for e in EDGES)
done = sum(1 for e in EDGES for r in e['references'] if r['verified'])
hi = sum(1 for e in EDGES for r in e['references'] if r['confidence'] == 'high')
print(f"    {len(EDGES)} edges, {total} citations — {hi} high-confidence, {done} human-verified")
