#!/usr/bin/env python3
"""Generate web/public/ledger.html — the public construction log.

Renders the transaction ledger (pipeline/state.json) as a readable page: every
batch's passage through the pipeline, with links to the underlying git commits
on GitHub. The page carries the same provenance disclosure the paper makes.
Run after any batch merge; the page is static and ships with the atlas build.
"""
import html
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
REPO_URL = "https://github.com/damianspendel/symbolic-world"

state = json.load(open(ROOT / "pipeline" / "state.json"))
seed = json.load(open(ROOT / "seed.json"))
refs = sum(len(e["references"]) for e in seed["edges"])


def commits_for(batch):
    """Commits mentioning the batch id, oldest first (sha, date, subject)."""
    out = subprocess.run(
        ["git", "log", "--reverse", "--date=short", "--pretty=%h\t%ad\t%s",
         "-F", "--grep", batch["id"]],
        capture_output=True, text=True, cwd=ROOT).stdout.strip()
    rows = [line.split("\t", 2) for line in out.splitlines() if line]
    # fall back to the commits that touched the batch's candidates file
    if not rows and batch.get("candidates"):
        out = subprocess.run(
            ["git", "log", "--reverse", "--date=short", "--pretty=%h\t%ad\t%s",
             "--follow", "--", batch["candidates"]],
            capture_output=True, text=True, cwd=ROOT).stdout.strip()
        rows = [line.split("\t", 2) for line in out.splitlines() if line]
    return rows


cards = []
for b in reversed(state["batches"]):  # newest first
    rows = commits_for(b)
    commit_html = ""
    if rows:
        links = " · ".join(
            f'<a href="{REPO_URL}/commit/{sha}" title="{html.escape(subj)}">{sha}</a>'
            f'<span class="cdate"> {date}</span>' for sha, date, subj in rows[:6])
        more = f' <span class="cdate">(+{len(rows)-6} more)</span>' if len(rows) > 6 else ""
        commit_html = f'<div class="commits"><b>commits</b> {links}{more}</div>'
    story = b.get("result") or b.get("note") or ""
    window = f'<span class="cite">{html.escape(b["window"])}</span>' if b.get("window") else ""
    cards.append(f"""  <div class="card">
    <div class="row2"><span class="edge">{html.escape(b["id"])}</span>{window}
      <span class="badge b-{html.escape(b["status"])}">{html.escape(b["status"])}</span></div>
    {f'<p class="res">{html.escape(story)}</p>' if story else ""}
    {commit_html}
  </div>""")

page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Construction log — The Symbolic World</title>
<style>
  :root {{ --ground:#0e1116; --gold:#d9b25f; --gold-dim:#a9863f; --ink:#c9d0d6; --ink-faint:#7a828b;
          --surface:rgba(18,23,30,.92); --hairline:#2a323c;
          --serif:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,serif;
          --mono:ui-monospace,"SF Mono",Menlo,monospace; }}
  * {{ box-sizing:border-box; margin:0; padding:0; }}
  body {{ background:radial-gradient(120% 90% at 50% 0%, #141b24 0%, var(--ground) 60%, #0a0d12 100%);
         font-family:var(--serif); color:var(--ink); min-height:100vh; padding:2.5rem 1.2rem 4rem; }}
  main {{ max-width: 860px; margin: 0 auto; }}
  .eyebrow {{ font:.6rem/1 var(--mono); letter-spacing:.26em; text-transform:uppercase; color:var(--gold-dim); }}
  h1 {{ color:#e8e2d0; font-size:1.6rem; font-weight:600; margin:.3rem 0 .8rem; }}
  .intro {{ font-size:.92rem; line-height:1.6; color:var(--ink); max-width:64ch; margin-bottom:.5rem; }}
  .meta {{ font:.62rem var(--mono); color:var(--ink-faint); margin-bottom:1.6rem; }}
  a {{ color:var(--gold); }}
  .card {{ background:var(--surface); border:1px solid var(--hairline); border-radius:10px;
          padding:.85rem 1rem; margin:.6rem 0; }}
  .edge {{ font-size:1rem; color:#f0ead8; font-family:var(--mono); }}
  .cite {{ font:.62rem var(--mono); color:var(--gold-dim); margin-left:.5rem; white-space:nowrap; }}
  .row2 {{ display:flex; gap:.6rem; align-items:baseline; flex-wrap:wrap; margin:.1rem 0 .35rem; }}
  .badge {{ font:.58rem var(--mono); letter-spacing:.06em; padding:.12rem .45rem; border-radius:99px;
           border:1px solid var(--hairline); white-space:nowrap; }}
  .b-merged {{ color:#7fc9a0; border-color:#2f5c46; }}
  .b-complete {{ color:#9ec9c3; border-color:#39575c; }}
  .res {{ font-size:.84rem; line-height:1.5; color:var(--ink); }}
  .commits {{ font:.62rem var(--mono); color:var(--ink-faint); margin-top:.4rem; line-height:1.8; }}
  .commits b {{ color:var(--ink-faint); font-weight:600; font-size:.58rem; letter-spacing:.08em;
               text-transform:uppercase; margin-right:.3rem; }}
  .cdate {{ color:var(--ink-faint); }}
  .back {{ display:inline-block; margin-bottom:1.4rem; font-size:.85rem; text-decoration:none; }}
</style>
</head>
<body>
<main>
  <a class="back" href="/">← back to the atlas</a>
  <div class="eyebrow">The Symbolic World</div>
  <h1>Construction log</h1>
  <p class="intro">How this graph was built, batch by batch. Each entry below is one batch's
  passage through the pipeline — proposed by the mining model, mechanically quote-checked,
  reviewed by an independent model family, cross-checked by a second vendor, and merged —
  with links to the underlying commits, so the construction can be replayed and audited in
  the <a href="{REPO_URL}">public repository</a>. Experiment entries record the audits and
  calibrations run against the published graph; their designs and results are in the
  <a href="{REPO_URL}/blob/master/docs/PAPER.md">paper</a>.</p>
  <p class="intro">Disclosure, mirrored from the paper: verification timestamps for batches
  gated before 2026-07-26 were batch-backfilled rather than recorded per-operation (the
  verification is real; those timestamps are reconstructions). Since then, stamps are written
  by the operations they describe, and any post-verification edit triggers re-gating.</p>
  <div class="meta">graph today: {len(seed["nodes"])} nodes · {len(seed["edges"])} edges · {refs} references ·
    ledger updated {html.escape(str(state.get("updated", "")))} ·
    <a href="{REPO_URL}/commits/master">full commit history</a></div>
{chr(10).join(cards)}
</main>
</body>
</html>
"""
out = ROOT / "web" / "public" / "ledger.html"
out.write_text(page)
print(f"built {out.relative_to(ROOT)}: {len(state['batches'])} batches")
