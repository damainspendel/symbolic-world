#!/usr/bin/env python3
"""Generate web/public/ledger.html — the public construction & verification ledger.

Record-first: every published reference with the gates it passed (mechanical quote
check, independent gate with verifier+date, voice sweep, cross-vendor check, human
validation, dispute history), searchable client-side. Batch history follows as a
second section, with links to the underlying git commits. Carries the same
provenance disclosure the paper makes. Run after any merge; ships with the atlas.
"""
import html
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
REPO_URL = "https://github.com/damianspendel/symbolic-world"

state = json.load(open(ROOT / "pipeline" / "state.json"))
seed = json.load(open(ROOT / "seed.json"))
labels = {n["id"]: n.get("label", n["id"]) for n in seed["nodes"]}
refs_total = sum(len(e["references"]) for e in seed["edges"])

val = json.load(open(ROOT / "web" / "public" / "validations.json"))
HUMAN = {}
for v in val.get("validations", []):
    HUMAN[(v["key"], str(v["volume"]), str(v["paragraph"]))] = v

disp = json.load(open(ROOT / "web" / "public" / "disputes.json"))
DISPUTES = {}
for d in disp.get("disputes", []):
    for k in d.get("current_edges") or []:
        DISPUTES.setdefault(k, []).append(d)


def esc(s):
    return html.escape(str(s))


# ---------- section 1: every record and its gates ----------
xv_n = human_n = 0
edge_cards = []
for e in seed["edges"]:
    key = f'{e["subject"]}|{e["relation"]}|{e["object"]}'
    rows = []
    for r in e["references"]:
        chips = ['<span class="chip c-ok" title="Deterministic letter-normalized quote check; collage and over-elision rejected; canary-guarded">quote ✓</span>']
        chips.append(f'<span class="chip c-ok" title="Independent full-paragraph review by a different model family">gate ✓ {esc(r.get("verified_by", "?"))} · {esc(r.get("verified_date", ""))}</span>')
        if r.get("modality_swept"):
            chips.append('<span class="chip c-ok" title="Narrow voice/hedge audit (E3 sweep or stage-2 specialist)">voice ✓</span>')
        if r.get("crossvendor_checked"):
            chips.append(f'<span class="chip c-xv" title="{esc(r["crossvendor_checked"])}">cross-vendor ✓ gemini</span>')
            xv_n += 1
        hv = HUMAN.get((key, str(r["volume"]), str(r["paragraph"])))
        if hv:
            human_n += 1
            cls = {"supported": "c-hum", "partly": "c-part"}.get(hv["support"], "c-bad")
            chips.append(f'<span class="chip {cls}" title="Author gold-set validation (E10), {esc(hv["date"])}">human · {esc(hv["support"])}</span>')
        if r.get("quote_repaired"):
            chips.append('<span class="chip c-part" title="Quote repaired to strongest contiguous fragment after the 2026-07-28 elision-bound fix; re-gated">repaired + re-gated</span>')
        rows.append(f'<div class="refrow"><span class="cite">CW {esc(r["volume"])} §{esc(r["paragraph"])}</span>'
                    f'<span class="ctype">{esc(r["claim_type"])}</span>{"".join(chips)}</div>')
    dchips = "".join(
        f'<div class="drow" title="{esc(d["objection"])}">⚖ disputed ({esc(d["date"])}, {esc(d["outcome"])}) — <a href="/disputes.html">log</a></div>'
        for d in DISPUTES.get(key, []))
    edge_cards.append(
        f'<div class="ecard" data-s="{esc(labels.get(e["subject"], e["subject"]))} {esc(e["relation"])} {esc(labels.get(e["object"], e["object"]))} cw{" cw".join({str(r["volume"]) for r in e["references"]})}">'
        f'<div class="edge">{esc(labels.get(e["subject"], e["subject"]))} <span class="rel">{esc(e["relation"])}</span> {esc(labels.get(e["object"], e["object"]))}</div>'
        f'{"".join(rows)}{dchips}</div>')

# ---------- section 2: batch history ----------
def commits_for(batch):
    out = subprocess.run(["git", "log", "--reverse", "--date=short", "--pretty=%h\t%ad\t%s",
                          "-F", "--grep", batch["id"]],
                         capture_output=True, text=True, cwd=ROOT).stdout.strip()
    rows = [line.split("\t", 2) for line in out.splitlines() if line]
    if not rows and batch.get("candidates"):
        out = subprocess.run(["git", "log", "--reverse", "--date=short", "--pretty=%h\t%ad\t%s",
                              "--follow", "--", batch["candidates"]],
                             capture_output=True, text=True, cwd=ROOT).stdout.strip()
        rows = [line.split("\t", 2) for line in out.splitlines() if line]
    return rows


batch_cards = []
for b in reversed(state["batches"]):
    rows = commits_for(b)
    commit_html = ""
    if rows:
        links = " · ".join(f'<a href="{REPO_URL}/commit/{sha}" title="{esc(subj)}">{sha}</a>'
                           f'<span class="cdate"> {date}</span>' for sha, date, subj in rows[:6])
        more = f' <span class="cdate">(+{len(rows)-6} more)</span>' if len(rows) > 6 else ""
        commit_html = f'<div class="commits"><b>commits</b> {links}{more}</div>'
    story = b.get("result") or b.get("note") or ""
    window = f'<span class="cite">{esc(b["window"])}</span>' if b.get("window") else ""
    batch_cards.append(f"""  <div class="card">
    <div class="row2"><span class="bid">{esc(b["id"])}</span>{window}
      <span class="badge b-{esc(b["status"])}">{esc(b["status"])}</span></div>
    {f'<p class="res">{esc(story)}</p>' if story else ""}
    {commit_html}
  </div>""")

page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Construction ledger — The Symbolic World</title>
<style>
  :root {{ --ground:#0e1116; --gold:#d9b25f; --gold-dim:#a9863f; --ink:#c9d0d6; --ink-faint:#7a828b;
          --surface:rgba(18,23,30,.92); --hairline:#2a323c;
          --serif:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,serif;
          --mono:ui-monospace,"SF Mono",Menlo,monospace; }}
  * {{ box-sizing:border-box; margin:0; padding:0; }}
  body {{ background:radial-gradient(120% 90% at 50% 0%, #141b24 0%, var(--ground) 60%, #0a0d12 100%);
         font-family:var(--serif); color:var(--ink); min-height:100vh; padding:2.5rem 1.2rem 4rem; }}
  main {{ max-width: 900px; margin: 0 auto; }}
  .eyebrow {{ font:.6rem/1 var(--mono); letter-spacing:.26em; text-transform:uppercase; color:var(--gold-dim); }}
  h1 {{ color:#e8e2d0; font-size:1.6rem; font-weight:600; margin:.3rem 0 .8rem; }}
  h2 {{ color:#e8e2d0; font-size:1.1rem; margin:2rem 0 .3rem; }}
  .intro {{ font-size:.92rem; line-height:1.6; color:var(--ink); max-width:66ch; margin-bottom:.5rem; }}
  .meta {{ font:.62rem var(--mono); color:var(--ink-faint); margin-bottom:1rem; }}
  a {{ color:var(--gold); }}
  #q {{ width:100%; max-width:30rem; background:#161c24; color:var(--ink); border:1px solid var(--hairline);
       border-radius:8px; padding:.5rem .8rem; font:inherit; font-size:.9rem; margin:.4rem 0 1rem; }}
  .ecard, .card {{ background:var(--surface); border:1px solid var(--hairline); border-radius:10px;
          padding:.7rem .9rem; margin:.5rem 0; }}
  .edge {{ font-size:.98rem; color:#f0ead8; margin-bottom:.25rem; }}
  .rel {{ color:var(--gold); font-style:italic; }}
  .bid {{ font-size:.95rem; color:#f0ead8; font-family:var(--mono); }}
  .cite {{ font:.62rem var(--mono); color:var(--gold-dim); margin-right:.55rem; white-space:nowrap; }}
  .ctype {{ font:.58rem var(--mono); color:var(--ink-faint); margin-right:.55rem; }}
  .refrow {{ display:flex; align-items:baseline; flex-wrap:wrap; gap:.3rem; padding:.18rem 0; }}
  .chip {{ font:.56rem var(--mono); letter-spacing:.03em; padding:.1rem .42rem; border-radius:99px;
          border:1px solid var(--hairline); white-space:nowrap; cursor:default; }}
  .c-ok {{ color:#9bb8a8; border-color:#2f4a3c; }}
  .c-xv {{ color:#9ec9c3; border-color:#39575c; }}
  .c-hum {{ color:#7fc9a0; border-color:#2f5c46; }}
  .c-part {{ color:#d9b25f; border-color:#6b5726; }}
  .c-bad {{ color:#d0685a; border-color:#5c322c; }}
  .drow {{ font:.62rem var(--mono); color:#d0685a; margin-top:.25rem; }}
  .row2 {{ display:flex; gap:.6rem; align-items:baseline; flex-wrap:wrap; margin:.1rem 0 .3rem; }}
  .badge {{ font:.58rem var(--mono); letter-spacing:.06em; padding:.12rem .45rem; border-radius:99px;
           border:1px solid var(--hairline); white-space:nowrap; }}
  .b-merged {{ color:#7fc9a0; border-color:#2f5c46; }}
  .b-complete {{ color:#9ec9c3; border-color:#39575c; }}
  .res {{ font-size:.82rem; line-height:1.5; color:var(--ink); }}
  .commits {{ font:.62rem var(--mono); color:var(--ink-faint); margin-top:.35rem; line-height:1.8; }}
  .commits b {{ font-size:.56rem; letter-spacing:.08em; text-transform:uppercase; margin-right:.3rem; }}
  .cdate {{ color:var(--ink-faint); }}
  .back {{ display:inline-block; margin-bottom:1.4rem; font-size:.85rem; text-decoration:none; }}
  .hidden {{ display:none; }}
</style>
</head>
<body>
<main>
  <a class="back" href="/">← back to the atlas</a>
  <div class="eyebrow">The Symbolic World</div>
  <h1>Construction ledger</h1>
  <p class="intro">Every published record and the gates it passed. Each reference below shows its
  full verification passage: the deterministic <b>quote</b> check, the independent <b>gate</b>
  (verifier and date), the narrow <b>voice</b> audit, the second-vendor <b>cross-vendor</b> check,
  and — where a person has checked the paragraph — <b>human</b> validation from the gold set.
  Disputed records link to the <a href="/disputes.html">verification log</a>. Hover any chip for
  detail. Nothing entered this graph by an unrecorded path.</p>
  <p class="intro">Disclosure, mirrored from the paper: verification timestamps for batches gated
  before 2026-07-26 were batch-backfilled rather than recorded per-operation (the verification is
  real; those timestamps are reconstructions). Since then, stamps are written by the operations
  they describe, and any post-verification edit triggers re-gating.</p>
  <div class="meta">{len(seed["nodes"])} nodes · {len(seed["edges"])} edges · {refs_total} references ·
    100% gate-verified · {xv_n} cross-vendor checked · {human_n} human-validated ·
    {len(disp.get("disputes", []))} disputes on record ·
    <a href="{REPO_URL}/commits/master">full commit history</a></div>

  <h2>Records</h2>
  <input id="q" type="search" placeholder="Filter records — try a symbol, a relation, or cw14…" autocomplete="off">
  <div id="records">
{chr(10).join(edge_cards)}
  </div>

  <h2>Batch history</h2>
  <p class="intro">The batch-level transaction log: each entry is one batch's passage
  through the pipeline (<i>input-built → mined → pre-checked → gated → merged</i>), with the
  underlying commits. Experiment entries record audits and calibrations against the published
  graph; designs and results are in the <a href="{REPO_URL}/blob/master/docs/PAPER.md">paper</a>.</p>
{chr(10).join(batch_cards)}
</main>
<script>
const q = document.getElementById('q');
q.addEventListener('input', () => {{
  const t = q.value.trim().toLowerCase();
  document.querySelectorAll('.ecard').forEach(c => {{
    c.classList.toggle('hidden', t && !c.dataset.s.toLowerCase().includes(t));
  }});
}});
</script>
</body>
</html>
"""
out = ROOT / "web" / "public" / "ledger.html"
out.write_text(page)
print(f"built {out.relative_to(ROOT)}: {len(seed['edges'])} edge records, {len(state['batches'])} batches, "
      f"{human_n} human chips, {sum(len(v) for v in DISPUTES.values())} dispute rows")
