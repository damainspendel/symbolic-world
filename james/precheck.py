#!/usr/bin/env python3
"""Mechanical pre-check for the James (VRE) replication — same rules as the Jung
pipeline: letter-normalized, in-order, near-contiguous quote matching (max_gap=3),
node existence, duplicate-triple rejection.
Usage: python3 james/precheck.py <candidates.json> <stage1_input_out.json>
"""
import json, re, sys, unicodedata


def words(s):
    s = unicodedata.normalize('NFKD', s).lower()
    s = re.sub(r'[‘’“”"\'`‐-―-]', ' ', s)
    return re.findall(r'[a-z]+', s)


MAX_ELISION = 30
MAX_QUOTE_WORDS = 25


def find_fragment(needle, hay, max_gap=3, start_from=0):
    if not needle:
        return (start_from, start_from)
    n = len(hay)
    for start in range(start_from, n):
        if hay[start] != needle[0]:
            continue
        pos, ok = start, True
        for tok in needle[1:]:
            nxt = -1
            for j in range(pos + 1, min(pos + 2 + max_gap, n)):
                if hay[j] == tok:
                    nxt = j
                    break
            if nxt < 0:
                ok = False
                break
            pos = nxt
        if ok:
            return (start, pos)
    return None


def quote_matches(fragments, hay):
    """In-order, near-contiguous fragments; inter-fragment elision <= MAX_ELISION."""
    pos, prev_end = 0, None
    for frag in fragments:
        m = find_fragment(frag, hay, start_from=pos)
        if m is None:
            return "fragment not found (or out of order)"
        if prev_end is not None and m[0] - prev_end - 1 > MAX_ELISION:
            return f"elision exceeds {MAX_ELISION} tokens"
        prev_end = m[1]
        pos = m[1] + 1
    return None


def main(cand_path, out_path):
    paras = {}
    for line in open('james/corpus.jsonl'):
        p = json.loads(line)
        paras[(p['lecture'], p['paragraph'])] = p['text']
    c = json.load(open(cand_path))
    ids = {n['id'] for n in c['nodes']}
    triples, ok, drop = set(), [], []
    for ed in c['candidate_edges']:
        r = ed['reference']
        t = (ed['subject'], ed['relation'], ed['object'])
        reasons = []
        if ed['subject'] not in ids or ed['object'] not in ids:
            reasons.append('node')
        if t in triples:
            reasons.append('dup')
        text = paras.get((r['lecture'], r['paragraph']))
        if text is None:
            reasons.append('no-paragraph')
        else:
            hay = words(text)
            frags = [words(f) for f in re.split(r'\.\.\.|…', r['quote']) if words(f)]
            if sum(len(f) for f in frags) > MAX_QUOTE_WORDS:
                reasons.append('quote-over-25-words')
            err = quote_matches(frags, hay)
            if err:
                reasons.append(f'quote: {err}')
        if reasons:
            drop.append((t, reasons))
        else:
            ok.append(ed)
            triples.add(t)
    print(f"pre-check: {len(ok)} pass, {len(drop)} dropped")
    for t, rs in drop:
        print("  dropped:", t, rs)
    items = []
    for n, ed in enumerate(ok, 1):
        r = ed['reference']
        items.append({"n": n, "subject": ed['subject'], "relation": ed['relation'],
                      "object": ed['object'], "claim_type": ed['claim_type'],
                      "source": ed.get('source', ''),
                      "confidence": ed.get('confidence', 'high'),
                      "citation": f"VRE Lecture {r['lecture']} ¶{r['paragraph']}",
                      "quote": r['quote'],
                      "paragraph_text": paras[(r['lecture'], r['paragraph'])]})
    json.dump(items, open(out_path, 'w'), ensure_ascii=False)
    print(f"stage-1 input: {len(items)} -> {out_path}")


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
