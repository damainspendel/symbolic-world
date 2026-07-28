#!/usr/bin/env python3
"""
Graph-integrity tests — the automated guard on the trust model.
Run as Opus (no network, no Fable 5): python3 tests/test_graph.py

Asserts, over seed.json + data/paragraphs.jsonl:
  1. every reference (volume, §) exists in the corpus
  2. every quote actually appears in that paragraph's text (ellipsis-tolerant)
  3. no edge points at an undefined node
  4. amplification edges carry a `kind` (image|parallel)
  5. interpretive (non-structural) edges carry a `claim_type` on each reference
  6. the §->page concordance resolves for every cited paragraph
  7. node ids are unique
  8. every reference marked verified:true carries gate provenance (verified_by)
  9. every edge has at least one reference
 10. (warn only) one-off relation strings are listed for vocabulary review
"""
import json
import re
import sys
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRUCTURAL = {"precedes", "is-stage-of", "alias-of", "broader", "narrower"}
CLAIM_TYPES = {"jung-asserts", "jung-reports-parallel", "jung-quotes-source"}


def words(s):
    """Letter-only lowercased tokens — drops digits (footnote refs), punctuation,
    and quote-mark style, matching the tolerance used during verification."""
    return re.findall(r"[a-z]+", s.lower())


MAX_FRAGMENT_GAP = 3      # tokens absorbed inside a fragment (footnote markers)
MAX_ELISION = 30          # tokens an ellipsis may skip between fragments (~1 sentence)
MAX_QUOTE_WORDS = 25      # total quoted words per reference


def find_fragment(needle, haystack, max_gap=MAX_FRAGMENT_GAP, start_from=0):
    """Earliest near-contiguous occurrence of `needle` in `haystack` at or after
    `start_from`; returns (start, end) token indices or None. At most `max_gap`
    non-matching tokens between consecutive quote tokens."""
    if not needle:
        return (start_from, start_from)
    n = len(haystack)
    for start in range(start_from, n):
        if haystack[start] != needle[0]:
            continue
        pos = start
        ok = True
        for tok in needle[1:]:
            nxt = -1
            for j in range(pos + 1, min(pos + 2 + max_gap, n)):
                if haystack[j] == tok:
                    nxt = j
                    break
            if nxt < 0:
                ok = False
                break
            pos = nxt
        if ok:
            return (start, pos)
    return None


def quote_matches(fragments, haystack):
    """All fragments must occur in order, each near-contiguously, with at most
    MAX_ELISION tokens skipped between consecutive fragments. Returns an error
    string or None. Rejects both scattered collages and unbounded ellisions."""
    pos = 0
    prev_end = None
    for frag in fragments:
        m = find_fragment(frag, haystack, start_from=pos)
        if m is None:
            return "fragment not found"
        if prev_end is not None and m[0] - prev_end - 1 > MAX_ELISION:
            return f"elision exceeds {MAX_ELISION} tokens"
        prev_end = m[1]
        pos = m[1] + 1
    return None


def is_subsequence(needle, haystack, max_gap=MAX_FRAGMENT_GAP):
    """Back-compat single-fragment check."""
    return find_fragment(needle, haystack, max_gap) is not None


def load():
    seed = json.load(open(os.path.join(ROOT, "seed.json"), encoding="utf-8"))
    corpus, pages = {}, {}
    for line in open(os.path.join(ROOT, "data/paragraphs.jsonl"), encoding="utf-8"):
        p = json.loads(line)
        key = (str(p["volume"]), p["paragraph"])
        corpus[key] = words(p["text"])
        if p.get("page") is not None:
            pages[key] = p["page"]
    return seed, corpus, pages


def validate(seed, corpus, pages):
    """Run every integrity check; return the list of failure messages."""
    fails = []

    def check(cond, msg):
        if not cond:
            fails.append(msg)

    node_ids = [n["id"] for n in seed["nodes"]]
    check(len(node_ids) == len(set(node_ids)), "duplicate node ids present")
    ids = set(node_ids)

    # Volumes that carry print-page anchors in the epub. Some volumes (e.g. CW 5)
    # have none in this digitization — § citations still work, "open p.X" just
    # falls back to §-only there, so we don't require a page for those volumes.
    vols_with_pages = {k[0] for k in pages}

    edges = seed["edges"]
    for e in edges:
        tag = f"{e['subject']} --{e['relation']}--> {e['object']}"
        check(e["subject"] in ids, f"[node] undefined subject: {tag}")
        check(e["object"] in ids, f"[node] undefined object: {tag}")
        # Structural scaffolding (stage ordering, aliases) may be citation-free;
        # every interpretive edge must carry at least one reference.
        if e["relation"] not in STRUCTURAL:
            check(len(e.get("references", [])) > 0, f"[refs] interpretive edge has no references: {tag}")
        if e.get("layer") == "amplification":
            check(e.get("kind") in {"image", "parallel"}, f"[kind] amplification missing kind: {tag}")
        for r in e.get("references", []):
            if r.get("verified"):
                check(r.get("verified_by"), f"[provenance] verified ref missing verified_by: {tag}")
            key = (str(r["volume"]), r["paragraph"])
            if key not in corpus:
                fails.append(f"[corpus] §missing: CW{r['volume']} §{r['paragraph']}  ({tag})")
                continue
            text = corpus[key]
            if not words(r.get("quote", "")):
                fails.append(f"[quote] empty/blank quote: {tag}")
            frags = [words(f) for f in re.split(r"\.\.\.|…", r["quote"]) if words(f)]
            if sum(len(f) for f in frags) > MAX_QUOTE_WORDS:
                fails.append(f"[quote] exceeds {MAX_QUOTE_WORDS} words: {tag}")
            err = quote_matches(frags, text)
            if err:
                fails.append(f"[quote] {err} in CW{r['volume']} §{r['paragraph']}  ({tag})")
            if e["relation"] not in STRUCTURAL:
                check(r.get("claim_type") in CLAIM_TYPES, f"[provenance] bad/missing claim_type: {tag}")
            if str(r["volume"]) in vols_with_pages:
                check(key in pages, f"[page] no page for CW{r['volume']} §{r['paragraph']}  ({tag})")

    return fails


def canaries(seed, corpus, pages):
    """Deliberately corrupt copies of real data; every mutation MUST be caught
    by validate() or the validators themselves have regressed. Returns a list
    of canary names that were NOT caught (empty = all good)."""
    import copy

    def _collage_from(ref):
        key = (str(ref["volume"]), ref["paragraph"])
        toks = corpus.get(key, [])
        if len(toks) < 40:
            return "collage canary needs a longer paragraph zzqx"
        step = max(8, len(toks) // 8)
        return " ".join(toks[::step][:8])

    # pick a real verified edge with >=1 reference as the mutation target
    base_idx = next(i for i, e in enumerate(seed["edges"])
                    if e.get("references") and e["references"][0].get("verified")
                    and e["relation"] not in STRUCTURAL)

    def mutated(fn):
        s = copy.deepcopy(seed)
        fn(s["edges"][base_idx])
        return s

    cases = {
        "fabricated-quote": lambda e: e["references"][0].__setitem__(
            "quote", "this exact sentence certainly never appears in the corpus zzqx"),
        "nonexistent-paragraph": lambda e: e["references"][0].__setitem__("paragraph", 999999),
        "undefined-node": lambda e: e.__setitem__("subject", "no-such-node-zzqx"),
        "missing-provenance": lambda e: e["references"][0].pop("verified_by", None),
        "bad-claim-type": lambda e: e["references"][0].__setitem__("claim_type", "someone-asserts"),
        # words individually present in the paragraph, in order, but scattered —
        # guards against regression to gap-unbounded subsequence matching
        "collage-quote": lambda e: e["references"][0].__setitem__(
            "quote", _collage_from(e["references"][0])),
        # the same scattered words joined with ellipses — guards the elision bound
        # (the pre-2026-07-28 canary used spaces only and missed this form)
        "ellipsis-collage": lambda e: e["references"][0].__setitem__(
            "quote", _collage_from(e["references"][0]).replace(" ", " ... ")),
    }
    uncaught = []
    for name, fn in cases.items():
        if not validate(mutated(fn), corpus, pages):
            uncaught.append(name)
    return uncaught, len(cases)


def main():
    seed, corpus, pages = load()
    fails = validate(seed, corpus, pages)
    edges = seed["edges"]

    total_refs = sum(len(e.get("references", [])) for e in edges)
    verified_refs = sum(1 for e in edges for r in e.get("references", []) if r.get("verified"))
    print(f"checked: {len(seed['nodes'])} nodes, {len(edges)} edges, {total_refs} references ({verified_refs} verified)")

    # Canaries: corrupted copies that the validators MUST reject.
    uncaught, cases_run = canaries(seed, corpus, pages)
    if uncaught:
        fails.extend(f"[canary] validators failed to catch: {c}" for c in uncaught)
    else:
        print(f"canaries: {cases_run}/{cases_run} planted corruptions caught")

    # Vocabulary review (warn-only): relations used by exactly one edge tend to
    # be one-off phrasings worth consolidating; not a failure.
    from collections import Counter
    rel_counts = Counter(e["relation"] for e in edges)
    singles = sorted(r for r, c in rel_counts.items() if c == 1)
    if singles:
        print(f"note: {len(singles)} single-use relations (vocabulary review candidates)")
    if fails:
        print(f"\nFAILED ({len(fails)}):")
        for f in fails:
            print("  ✗", f)
        sys.exit(1)
    print("\nALL PASSED ✓")


if __name__ == "__main__":
    main()
