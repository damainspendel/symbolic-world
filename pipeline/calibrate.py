#!/usr/bin/env python3
"""Seeded-corruption calibration: build blind test sets and score gate verdicts.

Used for E1b (n=200). Usage:
  python3 pipeline/calibrate.py build   # writes calib2_input_b*.json + calib2_key.json
  python3 pipeline/calibrate.py score   # scores calib2_verdicts_b*.json against the key

The gate itself is run separately (one blind batch per input file, production
structure-gate prompt, key withheld); verdict files are JSON arrays of
{"n": int, "verdict": "SUPPORTED|PARTIAL|WRONG", "reason": str}.
Scoring counts any non-SUPPORTED verdict as a flag.
"""
import json, sys, glob, math, random, re, unicodedata
from collections import defaultdict

SEED = 20260727
N_PER_CLASS = 25
N_CLEAN = 100
BATCH = 25

# Reversing a symmetric relation is not a corruption; guard the reversal class.
SYMMETRIC = {'synonym-of','parallels','is-analogue-of','corresponds-to','identical-to',
             'is-identified-with','coincides-with','identified-with','equated-with',
             'united-with','paired-with','analogous-to'}


def load_paragraphs():
    paras = {}
    for line in open('data/paragraphs.jsonl'):
        p = json.loads(line)
        paras[(str(p['volume']), str(p['paragraph']))] = p['text']
    return paras


def build():
    random.seed(SEED)
    seed = json.load(open('seed.json'))
    paras = load_paragraphs()
    node_ids = [n['id'] for n in seed['nodes']]

    pool = [(e, r) for e in seed['edges'] for r in e['references']
            if (str(r['volume']), str(r['paragraph'])) in paras
            and r.get('verified') and r.get('claim_type')]
    random.shuffle(pool)

    def item(e, r):
        return {"subject": e['subject'], "relation": e['relation'], "object": e['object'],
                "claim_type": r['claim_type'], "source": r.get('source', ''),
                "citation": f"CW{r['volume']} §{r['paragraph']}", "quote": r['quote'],
                "paragraph_text": paras[(str(r['volume']), str(r['paragraph']))]}

    used = set()
    def take(pred):
        for j, (e, r) in enumerate(pool):
            if j not in used and pred(e, r):
                used.add(j)
                return e, r
        raise RuntimeError("pool exhausted")

    items, keymap = [], []
    for cls in ['reversal', 'object-swap', 'overreach', 'voice-flip']:
        for _ in range(N_PER_CLASS):
            if cls == 'reversal':
                e, r = take(lambda e, r: e['relation'] not in SYMMETRIC)
                it = item(e, r); it['subject'], it['object'] = it['object'], it['subject']
            elif cls == 'object-swap':
                e, r = take(lambda e, r: True)
                it = item(e, r)
                it['object'] = random.choice([x for x in node_ids
                                              if x not in (it['subject'], it['object'])])
            elif cls == 'overreach':
                e, r = take(lambda e, r: e['relation'] not in ('is-identical-to', 'identical-to'))
                it = item(e, r); it['relation'] = 'is-identical-to'
            else:  # voice-flip
                e, r = take(lambda e, r: True)
                it = item(e, r)
                it['claim_type'] = ('jung-asserts' if it['claim_type'] != 'jung-asserts'
                                    else 'jung-reports-parallel')
            items.append(it); keymap.append(cls)
    for _ in range(N_CLEAN):
        e, r = take(lambda e, r: True)
        items.append(item(e, r)); keymap.append('clean')

    order = list(range(len(items)))
    random.shuffle(order)
    final, key = [], {}
    for n, idx in enumerate(order, 1):
        it = dict(items[idx]); it['n'] = n
        final.append(it)
        key[str(n)] = {"status": "clean" if keymap[idx] == "clean" else "corrupt",
                       "class": None if keymap[idx] == "clean" else keymap[idx]}
    json.dump(key, open('pipeline/work/calib2_key.json', 'w'), indent=1)
    n_batches = (len(final) + BATCH - 1) // BATCH
    for b in range(n_batches):
        json.dump(final[b*BATCH:(b+1)*BATCH],
                  open(f'pipeline/work/calib2_input_b{b+1}.json', 'w'), ensure_ascii=False)
    print(f"built {len(final)} items in {n_batches} batches (seed {SEED})")


def wilson(k, n, z=1.96):
    if n == 0:
        return (0.0, 0.0)
    p_ = k / n
    d = 1 + z*z/n
    c = (p_ + z*z/(2*n)) / d
    h = z * math.sqrt(p_*(1-p_)/n + z*z/(4*n*n)) / d
    return (max(0.0, c-h), min(1.0, c+h))


def score():
    key = json.load(open('pipeline/work/calib2_key.json'))
    verdicts = {}
    for f in sorted(glob.glob('pipeline/work/calib2_verdicts_b*.json')):
        for v in json.load(open(f)):
            verdicts[v['n']] = v
    cls_hit = defaultdict(lambda: [0, 0])
    tp = fp = tn = fn = 0
    misses = []
    for ns, k in key.items():
        n = int(ns)
        flagged = verdicts[n]['verdict'] != 'SUPPORTED'
        if k['status'] == 'corrupt':
            cls_hit[k['class']][1] += 1
            if flagged:
                tp += 1; cls_hit[k['class']][0] += 1
            else:
                fn += 1; misses.append((n, k['class']))
        else:
            if flagged: fp += 1
            else: tn += 1
    lo, hi = wilson(tp, tp+fn); slo, shi = wilson(tn, tn+fp)
    print(f"SENSITIVITY {tp}/{tp+fn} = {100*tp/(tp+fn):.0f}% (95% CI {100*lo:.0f}-{100*hi:.0f}%)")
    print(f"SPECIFICITY {tn}/{tn+fp} = {100*tn/(tn+fp):.0f}% (95% CI {100*slo:.0f}-{100*shi:.0f}%)")
    for c, (h, t) in sorted(cls_hit.items()):
        l, u = wilson(h, t)
        print(f"  {c:12s} {h}/{t} = {100*h/t:.0f}% (CI {100*l:.0f}-{100*u:.0f}%)")
    print("missed:", misses)
    json.dump({"n": len(key), "sensitivity": [tp, tp+fn], "specificity": [tn, tn+fp],
               "by_class": dict(cls_hit), "missed": misses},
              open('pipeline/work/calib2_score.json', 'w'), indent=1)


if __name__ == '__main__':
    {"build": build, "score": score}[sys.argv[1]]()
