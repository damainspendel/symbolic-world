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


def is_subsequence(needle, haystack):
    """True if `needle` tokens appear in order within `haystack` (gaps allowed —
    the corpus interleaves 'fig. 115' and footnote numbers into the prose)."""
    it = iter(haystack)
    return all(tok in it for tok in needle)


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


def main():
    seed, corpus, pages = load()
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
            for frag in re.split(r"\.\.\.|…", r["quote"]):
                nt = words(frag)
                if nt and not is_subsequence(nt, text):
                    fails.append(f"[quote] not found in CW{r['volume']} §{r['paragraph']}: '{frag.strip()}'  ({tag})")
            if e["relation"] not in STRUCTURAL:
                check(r.get("claim_type") in CLAIM_TYPES, f"[provenance] bad/missing claim_type: {tag}")
            if str(r["volume"]) in vols_with_pages:
                check(key in pages, f"[page] no page for CW{r['volume']} §{r['paragraph']}  ({tag})")

    total_refs = sum(len(e.get("references", [])) for e in edges)
    verified_refs = sum(1 for e in edges for r in e.get("references", []) if r.get("verified"))
    print(f"checked: {len(seed['nodes'])} nodes, {len(edges)} edges, {total_refs} references ({verified_refs} verified)")

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
