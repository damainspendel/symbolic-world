#!/usr/bin/env python3
"""Deterministic check of every countable claim in docs/PAPER.md against the
shipped artifact. The paper's thesis is that AI-drafted claims must pass
deterministic checks before publication; this script applies that thesis to the
paper itself. Run by CI on every push and by tools/build_pdf.py before every build.

Exit non-zero, listing each failure, if any asserted fact does not match the
artifact. Facts are asserted as (claim-substring-that-must-appear, computed-truth)
pairs, so a drifting dataset OR a drifting paper both fail loudly.
"""
import json
import pathlib
import re
import subprocess
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
paper = (ROOT / 'docs' / 'PAPER.md').read_text()
seed = json.load(open(ROOT / 'seed.json'))
james = json.load(open(ROOT / 'james' / 'james_seed.json'))

failures = []


def require(substring, why):
    """The paper must contain this exact substring (which encodes a computed fact)."""
    if substring not in paper:
        failures.append(f"MISSING/WRONG: paper lacks '{substring[:90]}' ({why})")


def forbid(pattern, why):
    m = re.search(pattern, paper)
    if m:
        failures.append(f"FORBIDDEN: '{m.group(0)[:80]}' ({why})")


# ---- graph counts ----
nodes, edges = len(seed['nodes']), len(seed['edges'])
refs = sum(len(e['references']) for e in seed['edges'])
require(f"{nodes} nodes", "node count")
require(f"{edges} relations", "edge count in abstract")
require(f"{refs} references", "reference count")

ct = Counter(r['claim_type'] for e in seed['edges'] for r in e['references']
             if r.get('claim_type'))
require(f"{ct['jung-asserts']} asserts / {ct['jung-reports-parallel']} reports / "
        f"{ct['jung-quotes-source']} quotes-source", "claim mix in §6.1")

conf = Counter(r.get('confidence', 'high') for e in seed['edges'] for r in e['references'])
require(f"{conf['medium']} hedged", "medium-confidence count")

paras = {(str(r['volume']), str(r['paragraph'])) for e in seed['edges'] for r in e['references']}
require(f"{len(paras)} distinct paragraphs", "distinct cited paragraphs")

# ---- cross-vendor coverage ----
xv = sum(1 for e in seed['edges'] for r in e['references'] if 'crossvendor_checked' in r)
require(f"{round(100*xv/refs)}% of references", "cross-vendor coverage percent")
cw14 = [r for e in seed['edges'] for r in e['references'] if str(r['volume']) == '14']
cw14_xv = sum(1 for r in cw14 if 'crossvendor_checked' in r)
require(f"{cw14_xv} of CW 14's {len(cw14)}", "CW14 cross-vendor coverage")

# ---- vocabulary_note count ----
vn = sum(1 for e in seed['edges'] for r in e['references'] if 'vocabulary_note' in r)
require(f"{vn} convention-dependent references" if f"{vn} convention-dependent references" in paper
        else f"{vn} references", f"vocabulary_note count is {vn}")

# ---- canaries: count from the test module ----
test_src = (ROOT / 'tests' / 'test_graph.py').read_text()
canary_count = len(re.findall(r'^\s+"[a-z-]+":\s+lambda e:', test_src, re.M))
require(f"{canary_count} canaries", f"canary count is {canary_count}")
forbid(r"five \*\*corruption canaries", "stale canary count in prose")
forbid(r"\b5 canaries\b" if canary_count != 5 else r"$^", "stale canary count")

# ---- fragments: recompute exact-substring rate ----
paras_text = {}
corpus_path = ROOT / 'data' / 'paragraphs.jsonl'
corpus_lines = open(corpus_path) if corpus_path.exists() else []
for line in corpus_lines:
    p = json.loads(line)
    paras_text[(str(p['volume']), str(p['paragraph']))] = p['text']


def words(s):
    import unicodedata
    s = unicodedata.normalize('NFKD', s).lower()
    s = re.sub(r'[‘’“”"\'`]', '', s)
    return re.findall(r'[a-z0-9]+', s)


total_frags = exact = 0
for e in seed['edges'] if paras_text else []:
    for r in e['references']:
        text = paras_text.get((str(r['volume']), str(r['paragraph'])))
        if text is None:
            continue
        norm_text = ' '.join(words(text))
        for frag in re.split(r'\.\.\.|…', r['quote']):
            fw = words(frag)
            if not fw:
                continue
            total_frags += 1
            if ' '.join(fw) in norm_text:
                exact += 1
if paras_text:
    require(f"{exact} of {total_frags} quote fragments" if f"{exact} of {total_frags}" in paper
            else f"{exact}/{total_frags}", f"fragment exactness is {exact}/{total_frags}")

# ---- james counts ----
j_edges = len(james['edges'])
require(f"{j_edges} published", f"james edge count {j_edges}")
require(f"{len(james['nodes'])} nodes · {j_edges} edges" if
        f"{len(james['nodes'])} nodes" in paper else f"{j_edges} edges", "james node/edge")

# ---- gold set (E10): recompute from the committed validation record ----
gold_path = ROOT / 'pipeline' / 'human_validations.json'
if gold_path.exists():
    gold = json.load(open(gold_path))
    MAP = {'should-be-asserts': 'jung-asserts', 'should-be-reports': 'jung-reports-parallel',
           'should-be-quotes': 'jung-quotes-source'}
    sup = Counter(r['support'] for r in gold)
    agree = per = tot = None
    per, tot = Counter(), Counter()
    for r in gold:
        pc = r['pipeline_claim_type']
        tot[pc] += 1
        if r['voice'] == 'voice-correct' or MAP.get(r['voice']) == pc:
            per[pc] += 1
    agree = sum(per.values())
    require(f"{sup['supported']}/{len(gold)} supported", "gold-set support count")
    require(f"{agree}/{len(gold)}", "gold-set voice agreement")
    require(f"asserts {per['jung-asserts']}/{tot['jung-asserts']}", "gold per-class asserts")
    require(f"reports {per['jung-reports-parallel']}/{tot['jung-reports-parallel']}", "gold per-class reports")
    require(f"quotes {per['jung-quotes-source']}/{tot['jung-quotes-source']}", "gold per-class quotes")

# ---- release tag ----
tags = subprocess.run(['git', 'tag', '--list'], capture_output=True, text=True,
                      cwd=ROOT).stdout.split()
for m in re.finditer(r'release `(v[^`]+)`', paper):
    if m.group(1) not in tags:
        failures.append(f"RELEASE TAG: paper cites '{m.group(1)}' not in git tags {tags}")

# ---- companion docs must carry current counts ----
for doc in ['README.md', 'docs/ABSTRACT.md', 'docs/REVIEW.md']:
    dt = (ROOT / doc).read_text()
    if str(refs) not in dt:
        failures.append(f"STALE DOC: {doc} lacks current reference count {refs}")

# ---- banned phrases (claims retired by review) ----
for pat, why in [
    (r'25-fold', "retired headline"),
    (r'rubric effect ≈ 0', "withdrawn claim"),
    (r'hard yards', "retired rhetoric"),
    (r'first published sensitivity', "retired first-ever claim"),
    (r'confound-free support', "E9 shared-instrument confound (Fable M5)"),
]:
    forbid(pat, why)

if failures:
    print(f"PAPER FACTS: {len(failures)} FAILURES")
    for f in failures:
        print(" -", f)
    sys.exit(1)
print(f"PAPER FACTS: all checks pass "
      f"({nodes}/{edges}/{refs}; mix {ct['jung-asserts']}/{ct['jung-reports-parallel']}/"
      f"{ct['jung-quotes-source']}; xv {xv}; frags {exact}/{total_frags}; "
      f"canaries {canary_count}; james {j_edges})")
