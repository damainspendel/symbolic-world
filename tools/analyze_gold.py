#!/usr/bin/env python3
"""Analyze the author's gold-set validations against pipeline labels.

Annotation convention (author's, 2026-07-29): the author selects the voice label
they judge correct (w/e/r) EVEN WHEN it matches the pipeline's label; 'voice-correct'
(q) also counts as agreement. Agreement is therefore computed by mapping the selected
label to a claim_type and comparing with pipeline_claim_type.
"""
import json, sys
from collections import Counter

MAP = {'should-be-asserts': 'jung-asserts',
       'should-be-reports': 'jung-reports-parallel',
       'should-be-quotes': 'jung-quotes-source'}

recs = json.load(open('pipeline/human_validations.json'))
n = len(recs)
sup = Counter(r['support'] for r in recs)
agree = disagree = 0
confusion = Counter()   # (pipeline, human)
disagreements = []
for r in recs:
    pipe = r['pipeline_claim_type']
    human = pipe if r['voice'] == 'voice-correct' else MAP[r['voice']]
    confusion[(pipe, human)] += 1
    if human == pipe: agree += 1
    else:
        disagree += 1
        disagreements.append((r['gold_id'], r['subject'], r['object'], f"CW{r['volume']} §{r['paragraph']}", pipe, human, r.get('notes','')))

print(f"n={n}/50")
print(f"SUPPORT: {dict(sup)}  -> human-anchored support rate: {sup['supported']}/{n}")
print(f"VOICE: agree {agree}/{n} ({100*agree/max(n,1):.0f}%), disagree {disagree}")
print("\nconfusion (pipeline -> human):")
for (p, h), c in sorted(confusion.items()):
    mark = "" if p == h else "  <-- disagreement"
    print(f"  {p:24s} -> {h:24s} {c}{mark}")
if disagreements:
    print("\ndisagreements:")
    for d in disagreements: print("  ", d)
