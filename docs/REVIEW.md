# The Symbolic World — Standing Review

**Date:** 2026-07-27 · **State:** v1.0-cw14 + breadth (CW12) + assurance experiments
**Live:** [symbolicworld.observer](https://symbolicworld.observer) · Ledger: `pipeline/state.json`

## 0. Snapshot

| | |
|---|---|
| Graph | **227 nodes · 610 edges · 634 references**, 461 distinct CW paragraphs, 9 volumes |
| Verification | **634/634 (100%)** gate-verified with model+date provenance |
| Claim provenance | 423 jung-asserts · 151 jung-reports-parallel · 60 jung-quotes-source (74 named sources) |
| Coverage | CW14 complete end-to-end (396 refs); CW12 at 87 and growing; 7 further volumes sampled |
| Cost to date | ≈ $60–90 total model spend; ≈ **$0.09–0.12 per fully verified citation** |

## 1. Methodology

Every batch follows one pipeline, recorded in a committed transaction ledger
(`pipeline/state.json`; statuses `input-built → mined → pre-checked → gated → merged`,
one commit per transition — git history *is* the audit log):

1. **Mine** (Claude Opus 4.8): propose 12–22 edges from a contiguous paragraph
   window, verbatim quotes ≤25 words, node-vocabulary reuse, claim-typing rules.
2. **Mechanical pre-check** (deterministic): every quote must be an in-order
   letter-normalized substring of its cited paragraph; node existence; no duplicate
   triples. Eliminates fabricated quotes entirely.
3. **Independent gate** (Claude Fable 5 — different model family by design): full-paragraph
   review per edge → SUPPORTED / PARTIAL (with concrete correction) / WRONG.
4. **Adjudicated merge**: corrections applied, WRONG dropped (logged in commit
   messages), provenance stamped (`verified_by`, `verified_date`).
5. **Integrity tests → deploy → commit.** Tests re-validate every quote, anchor,
   claim type, and provenance field; since 2026-07-26 they also run **5 corruption
   canaries that must fail** (self-testing validators).

**Claim-type provenance** is first-class: every citation is typed by *whose claim
it is* (Jung's own voice / reported doctrine / quoted named source) — the graph
never silently converts Jung's reportage of alchemists into Jung's endorsement.

## 2. Architecture

```
epub ──extract.py──▶ data/paragraphs.jsonl (local only, never published)
                          │
     miners (Opus) ─▶ candidates ─▶ mechanical pre-check ─▶ Fable gate ─▶ seed.json
                          ▲                 (pipeline/ ledger, committed)     │
                          └──────────── corrections loop ◀───────────────────┘
seed.json ──build-atlas.mjs──▶ atlas.json ──vite──▶ single-file Atlas
   │                                                    │
tests/test_graph.py (validators + canaries)     launchd service :8788 (~/Library,
                                                 TCC-safe) ─▶ Cloudflare tunnel
                                                 ─▶ symbolicworld.observer
```

- **Corpus:** paragraph records extracted mechanically from epub markup (§ numbers
  never inferred); Bollingen page concordance carried per §; copyrighted text stays
  local — only ≤25-word verified quotes ship.
- **Data:** `seed.json` — nodes {id,type,label}, edges {subject,relation,object,
  references[{volume,¶,quote,claim_type,source,confidence,verified,verified_by,
  verified_date}]}.
- **Atlas UI:** deterministic phyllotaxis layout in six typed regions; search;
  click-to-walk; volume/layer filters; **evidence view** — every citation expands
  to its full verification record; About panel documents the trust model and the
  standing falsification offer.
- **Ops:** `manage.sh` (build/deploy/service/health), launchd auto-start/restart,
  remote-managed Cloudflare tunnel; all recovery procedures documented.

## 3. Findings (all experiments, real numbers)

| Experiment | n / seed | Result |
|---|---|---|
| **Retro-verification sweep** (all pre-gate edges) | 238 refs | 178 confirmed · 54 corrected · 6 edges deleted → **~25% flaw rate in ungated LLM extraction** |
| **Adversarial audit** (break-each-edge prompt) | 30 refs, seed 20260725 | **0 content/direction/fabrication errors**; 4 modality refinements (13.3%), applied |
| **Exp 1 — Gate calibration** (seeded corruption, blind) | 40 items, seed 20260726 | **Specificity 100%** (20/20 clean passed). **Sensitivity 75%**: reversals **5/5**, object swaps **5/5**, overreach 3/5, voice flips **2/5** |
| **Exp 2 — Modality sweep** (narrow claim-type/hedge audit) | 381/634 refs (3 of 5 batches; 2 held on spend limit) | **45 flagged (11.8%)** — 36 claim-type demotions, 9 source fixes, 9 hedge downgrades — all applied. Rate by graph age: oldest edges 19% → newest 5.5% |
| **Exp 3 — Stability probe** (blind re-mine, no prior triples) | staged; window A attempted | pending (spend limit); inputs + reference sets committed |
| **Recent pipeline precision** | last 3 batches | **60/60 SUPPORTED (three consecutive perfect batches)** |

**Discoveries worth publishing:**

1. **Unverified LLM extraction runs ~25% flawed on this corpus** — consistent with
   public benchmarks (KGGen 66%, GraphRAG 48% fact accuracy). Verification is not
   optional polish; it is where most of the value is created.
2. **Error classes are sharply asymmetric.** Structural errors (direction, referent)
   are caught at ceiling (10/10 in calibration; 0 in audits post-gate). The residual
   axis is *attribution modality* — whose claim is it, how hedged — now measured
   three independent ways (audit 13.3%, calibration voice-flip detection 40%,
   sweep flag rate 11.8%).
3. **The gate teaches the miner.** Modality flag rate falls from 19% (oldest edges)
   to ~5% (newest); the last three batches passed 20/20. Feedback from verifier
   corrections, folded into miner instructions, compounds.
4. **Fabrication is the easiest problem.** The mechanical verbatim-substring check
   eliminated fabricated quotes entirely; every surviving error class is semantic.
5. **Voice is the genuinely hard problem** — "sympathetic reportage" (doctrine Jung
   reports *and* partially adopts) resists binary classification by models and
   likely by humans; this is a scholarly judgment call, which motivates the human tier.

## 4. Mitigations in force → remaining risks

| Risk | Mitigation in force | Residual / next |
|---|---|---|
| Fabricated citations | Mechanical verbatim check + gate | Eliminated (measured) |
| Reversed/wrong-referent edges | Gate (calibrated 100% on these classes) | Negligible post-gate |
| Voice/modality drift | Claim-type taxonomy; sweep (381/634 done); hedge→confidence rule | Finish sweep batches 4–5 (**held**, ~$2); sympathetic-reportage ambiguity → human tier |
| Validator regression | 5 corruption canaries (must-fail) in test suite | — |
| Shared-substrate blind spots (same-vendor miner+gate) | Cross-family separation; assumptions register | **Cross-vendor tier (§5)** + community verification |
| Selection subjectivity | Stability probe designed, reference sets committed | Run when budget returns (~$2) |
| Reader trust | Evidence view (per-citation verification record); standing falsification offer; published error rates | Public dispute channel needs a decision (repo has no public remote yet) |
| Session/budget interruptions | Transaction ledger; held-not-merged rule (exercised 3× without data loss) | — |
| Translation dependence | Documented (assumption #1) | German GW cross-check — deferred |

## 5. Cross-vendor verification tier (GPT-5-class) — ready-to-run spec

**Purpose:** measure and mitigate the one structural weakness of the current trust
chain — proposer and verifier share a vendor (assumption #10).

- **Design:** stratified sample of 100 verified edges (strata: volume × claim-type
  × edge age), run through a GPT-5-class model with the *same* gate prompt, blind
  to Fable's verdicts. Output: SUPPORTED/PARTIAL/WRONG + corrections.
- **Analysis:** 3×3 disagreement matrix (Fable × GPT verdicts), per-class agreement,
  Cohen's κ; every disagreement re-adjudicated with the paragraph as ground truth
  and published (agree-with-Fable / agree-with-GPT / both-defensible).
- **Also worth running:** the same 40-item seeded-corruption set from Exp 1 —
  yields directly comparable cross-vendor sensitivity/specificity for ~$1.
- **Needs from you:** an OpenAI (or equivalent) API key with ~$5–10 of headroom.
  Everything else (sampler, prompt, scorer) already exists in the pipeline.
- **Publishable claim if agreement is high:** "two adversarial verifiers from
  different vendors agree on X% of edges; all disagreements published." That is a
  materially stronger claim than any single-vendor pipeline can make.

## 6. Immediate queue

1. Finish modality sweep batches 4–5 (held; ~$2 when budget returns).
2. Run stability probe A/B + scoring (~$2–3) — completes Experiment 3.
3. Cross-vendor tier on your go + API key (~$5–10).
4. Community verification pilot per `docs/ASSUMPTIONS.md` §E (50-edge stratified
   sample, 2–3 Jungian reviewers, κ vs machine gate).
5. Decide the public dispute channel (publish repo / issue tracker vs email alias).
