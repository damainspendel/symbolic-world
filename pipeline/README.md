# Pipeline transaction log

`state.json` is the ledger of every mining/verification batch. Statuses:
`input-built -> mined -> pre-checked -> gated -> merged` (terminal), or `held`.

**Recovery after session loss:** read `state.json`; for any batch not
`merged`, the listed files under `batches/` (candidates/verdicts, committed)
plus the local corpus `data/paragraphs.jsonl` are sufficient to resume:
- mined/pre-checked -> run the Fable gate on candidates (full paragraphs
  come from the corpus; gate inputs under work/ are disposable derivatives)
- gated -> apply verdicts to seed.json (SUPPORTED as-is; PARTIAL with the
  correction; WRONG dropped), set verified+verified_by+verified_date, run
  tests/test_graph.py, ./manage.sh deploy, commit, mark merged.
Nothing merged is ever only here: seed.json + git is the source of truth.

Invariant: miner (Opus family) and gate (Fable family) stay different
model families. Never merge unverified.
