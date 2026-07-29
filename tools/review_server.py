#!/usr/bin/env python3
"""Local gold-set review tool. Serves a keyboard-driven UI for the author to
validate sampled references against the full source paragraphs (which never
leave this machine), and records verdicts to pipeline/human_validations.json.

Usage:  python3 tools/review_server.py        (then open http://127.0.0.1:8791)
Resumable: already-validated items are skipped on restart.
"""
import json
import pathlib
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'pipeline' / 'human_validations.json'
PORT = 8791


def load():
    sample = json.load(open(ROOT / 'pipeline' / 'gold_sample_50.json'))
    paras, pages = {}, {}
    for line in open(ROOT / 'data' / 'paragraphs.jsonl'):
        p = json.loads(line)
        key = (str(p['volume']), str(p['paragraph']))
        paras[key] = p['text']
        if p.get('page') is not None:
            pages[key] = p['page']
    for s in sample:
        key = (s['volume'], str(s['paragraph']))
        s['paragraph_text'] = paras.get(key, '(paragraph not found)')
        s['page'] = pages.get(key)
    done = json.load(open(OUT)) if OUT.exists() else []
    return sample, done


PAGE = """<!doctype html><html><head><meta charset="utf-8"><title>Gold-set review</title>
<style>
body{font-family:Georgia,serif;max-width:880px;margin:2rem auto;padding:0 1rem;background:#0e1116;color:#c9d0d6;line-height:1.55}
h1{color:#e8e2d0;font-size:1.2rem} .prog{color:#7a828b;font-family:monospace;font-size:.8rem}
.edge{font-size:1.25rem;color:#f0ead8;margin:.8rem 0 .2rem} .rel{color:#d9b25f;font-style:italic}
.meta{font-family:monospace;font-size:.75rem;color:#a9863f;margin-bottom:.6rem}
blockquote{border-left:3px solid #d9b25f;padding:.4rem .8rem;margin:.6rem 0;color:#e8e2d0;font-style:italic;background:rgba(217,178,95,.06)}
.para{background:#161c24;border:1px solid #2a323c;border-radius:8px;padding:1rem;font-size:.95rem;max-height:45vh;overflow-y:auto}
.para mark{background:#4a3d1e;color:#f0e6c8}
.q{margin-top:1rem;color:#e8e2d0;font-weight:bold}
.btns{margin:.5rem 0 1.2rem}
button{font:inherit;font-size:.85rem;margin:.2rem .3rem .2rem 0;padding:.45rem .8rem;border-radius:7px;border:1px solid #2a323c;background:#161c24;color:#c9d0d6;cursor:pointer}
button:hover{border-color:#d9b25f}
button.sel{border-color:#7fc9a0;color:#7fc9a0}
.key{color:#7a828b;font-size:.7rem;font-family:monospace}
textarea{width:100%;background:#161c24;color:#c9d0d6;border:1px solid #2a323c;border-radius:7px;padding:.5rem;font:inherit;font-size:.85rem}
#save{background:#20342a;border-color:#5f9c78;color:#c9e8d4;font-weight:bold;padding:.6rem 1.4rem}
.done{color:#7fc9a0}
</style></head><body>
<h1>Gold-set review — human validation <span class="prog" id="prog"></span></h1>
<div id="app">loading…</div>
<script>
let items=[], done={}, idx=0, verdict={};
async function init(){
  const r = await fetch('/api/state'); const d = await r.json();
  items = d.sample; d.done.forEach(x => done[x.gold_id] = x);
  idx = items.findIndex(it => !done[it.gold_id]);
  if (idx < 0) idx = 0;
  render();
}
function esc(s){return String(s).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}
function hl(text, quote){
  let t = esc(text);
  for (const frag of quote.split('...')){
    const f = frag.trim(); if (f.length < 8) continue;
    const i = t.toLowerCase().indexOf(esc(f).toLowerCase().slice(0,60));
    if (i >= 0) t = t.slice(0,i) + '<mark>' + t.slice(i, i+f.length) + '</mark>' + t.slice(i+f.length);
  }
  return t;
}
function render(){
  const remaining = items.filter(it => !done[it.gold_id]).length;
  document.getElementById('prog').textContent = ` ${items.length - remaining}/${items.length} validated`;
  if (remaining === 0){ document.getElementById('app').innerHTML =
    '<p class="done">All 50 validated. File: pipeline/human_validations.json — tell Claude to analyze it.</p>'; return; }
  const it = items[idx]; verdict = {};
  document.getElementById('app').innerHTML = `
    <div class="edge">${esc(it.subject)} <span class="rel">${esc(it.relation)}</span> ${esc(it.object)}</div>
    <div class="meta">#${it.gold_id} · CW ${it.volume} §${it.paragraph}${it.page ? ` · Bollingen p.${it.page}` : ''} · pipeline says: ${it.claim_type} · confidence ${it.confidence}</div>
    <blockquote>${esc(it.quote)}</blockquote>
    <div class="para">${hl(it.paragraph_text, it.quote)}</div>
    <div class="q">1. Does the paragraph support this claim, as stated? <span class="key">(keys 1–3)</span></div>
    <div class="btns" id="q1">
      <button data-v="supported">1 · Supported</button>
      <button data-v="partly">2 · Partly / needs correction</button>
      <button data-v="not-supported">3 · Not supported</button>
    </div>
    <div class="q">2. Whose claim is it — is the voice label (${esc(it.claim_type)}) right? <span class="key">(keys q/w/e/r)</span></div>
    <div class="btns" id="q2">
      <button data-v="voice-correct">q · Label correct</button>
      <button data-v="should-be-asserts">w · Should be jung-asserts</button>
      <button data-v="should-be-reports">e · Should be jung-reports-parallel</button>
      <button data-v="should-be-quotes">r · Should be jung-quotes-source</button>
    </div>
    <div class="q">3. Notes (optional)</div>
    <textarea id="notes" rows="2" placeholder="borderline? sympathetic reportage? anything the record should say"></textarea>
    <div class="btns"><button id="save">Save & next (Enter)</button>
      <button id="skip">Skip for now (s)</button></div>`;
  for (const qid of ['q1','q2'])
    document.querySelectorAll('#'+qid+' button').forEach(b => b.onclick = () => {
      document.querySelectorAll('#'+qid+' button').forEach(x=>x.classList.remove('sel'));
      b.classList.add('sel'); verdict[qid] = b.dataset.v;
    });
  document.getElementById('save').onclick = save;
  document.getElementById('skip').onclick = () => { advance(); render(); };
}
function advance(){
  for (let k=1; k<=items.length; k++){
    const j = (idx + k) % items.length;
    if (!done[items[j].gold_id]){ idx = j; return; }
  }
}
async function save(){
  if (!verdict.q1 || !verdict.q2){ alert('Answer both questions (support + voice).'); return; }
  const it = items[idx];
  const rec = { gold_id: it.gold_id, edge_index: it.edge_index, ref_index: it.ref_index,
    subject: it.subject, relation: it.relation, object: it.object,
    volume: it.volume, paragraph: it.paragraph, pipeline_claim_type: it.claim_type,
    support: verdict.q1, voice: verdict.q2,
    notes: document.getElementById('notes').value.trim(),
    validated_by: 'author', date: new Date().toISOString().slice(0,10) };
  await fetch('/api/save', {method:'POST', body: JSON.stringify(rec)});
  done[it.gold_id] = rec; advance(); render();
}
document.addEventListener('keydown', e => {
  if (e.target.tagName === 'TEXTAREA') return;
  const map = {'1':['q1',0],'2':['q1',1],'3':['q1',2],'q':['q2',0],'w':['q2',1],'e':['q2',2],'r':['q2',3]};
  if (map[e.key]){ document.querySelectorAll('#'+map[e.key][0]+' button')[map[e.key][1]].click(); }
  if (e.key === 'Enter'){ e.preventDefault(); save(); }
  if (e.key === 's'){ advance(); render(); }
});
init();
</script></body></html>"""


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _json(self, obj, code=200):
        b = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(PAGE.encode())
        elif self.path == '/api/state':
            sample, done = load()
            self._json({"sample": sample, "done": done})
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/api/save':
            rec = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
            done = json.load(open(OUT)) if OUT.exists() else []
            done = [d for d in done if d['gold_id'] != rec['gold_id']] + [rec]
            json.dump(sorted(done, key=lambda d: d['gold_id']), open(OUT, 'w'),
                      indent=1, ensure_ascii=False)
            self._json({"ok": True, "count": len(done)})
        else:
            self.send_response(404)
            self.end_headers()


class ReusableServer(HTTPServer):
    allow_reuse_address = True


if __name__ == '__main__':
    try:
        srv = ReusableServer(('127.0.0.1', PORT), H)
    except OSError:
        raise SystemExit(f"Port {PORT} is busy. Free it with:  lsof -ti :{PORT} | xargs kill")
    print(f"Gold-set review → http://127.0.0.1:{PORT}  (local only; corpus never leaves this machine)")
    srv.serve_forever()
