# A plain-language guide to the statistics in this project

No prior statistics knowledge assumed. Every number in the paper is one of the
kinds below, and every example uses our real results.

## Sensitivity — "how many of the planted errors did the checker catch?"

We deliberately corrupt real entries (swap a direction, change an object, misattribute
a voice) and slip them, unlabeled, in among clean ones. Sensitivity is the share of
corruptions the checker catches.

> Ours: **86/100 = 86%**. We planted 100 corruptions; the checker flagged 86.

A checker with low sensitivity is a guard who sleeps through break-ins.

## Specificity — "how often does it leave clean entries alone?"

The mirror image: of the *clean* entries, how many pass without a false alarm?

> Ours: **93/100 = 93%**. Of 100 clean entries, 93 passed; 7 were flagged.

A checker with low specificity is a smoke alarm that goes off when you make toast.
(Fine print: our 7 "false alarms" were real production entries, and on inspection
several flags were legitimate small nuances — so true specificity is at least 93%,
probably higher.)

Sensitivity and specificity trade off. A checker that flags *everything* has perfect
sensitivity and useless specificity. You need both numbers, always.

## Per-class rates — "which kinds of errors does it catch?"

We plant four kinds of corruption and score each separately:

> reversal (direction flipped): **23/25** · object-swap (wrong thing): **24/25**
> · overreach ("is identical to" where the text says "is like"): **21/25**
> · voice-flip (whose claim it is): **18/25**

Reading: structural errors are nearly always caught; voice errors are the weak spot.
That one line drives most of the paper's design decisions.

## Confidence intervals — "how sure can we be, given how few we tested?"

If you test 5 things and catch 4, is the true rate 80%? Not reliably — with so few
tests, luck dominates. A **95% confidence interval (CI)** is the range the true rate
is plausibly in, given the sample size. Bigger samples, tighter ranges.

> "86% sensitivity (95% CI 78–91%)" means: we measured 86%, and given that we tested
> 100 items, the true rate is plausibly anywhere from 78% to 91% — but not 60%, and
> not 99%.

(Why "Wilson"? There are several recipes for computing these ranges. The naive
schoolbook one misbehaves exactly where we need it most: with small samples and
rates near 0% or 100%, it can produce nonsense like "103% ± 5" or a zero-width
range around a perfect score. The Wilson recipe stays sensible at the extremes —
a 20/20 result gets an honest range like 84–100%, not a false "100% exactly."
That's the whole reason for the name-drop: it is the interval that doesn't
flatter perfect-looking small samples.)

Why it matters here: our first calibration tested only 5 items per error kind and
measured voice-flip detection at 2/5 = "40%". The expanded test (25 per kind) measured
72%. Neither test was wrong — the first was just too small to trust, and its interval
(roughly 12–77%) said so. **Whenever the paper reports a fraction like 5/6 instead of
a percentage, that's deliberate: the sample is too small for the percentage to be
taken seriously.**

## Flag rate — "what share of entries did an audit question?"

When an auditor reviews published entries, the flag rate is the share it raises any
issue about — before anyone decides whether the issue is real.

> The full-graph voice sweep flagged **65/634 = 10.3%**; the second vendor's
> full-volume audit flagged 51/407 (12.5%), of which only 10 were rated
> moderate-or-serious, of which **4 (1.0%) were upheld** after checking against
> the paragraphs.

The chain matters: *flagged* ≠ *wrong*. Flags get adjudicated; only upheld flags
are errors.

## Residual error rate — "after all the gates, how wrong is the published graph?"

The best estimate of what's still wrong in what we published, measured by
independent audit rather than self-assessment.

> **~1.0%** (4 upheld errors in a 407-reference full-volume audit by another
> vendor's model, judging in its own words) — and all four were nuances of
> reference (wrong specific figure, relation shading), not fabrications or
> reversed claims.

## Seeded corruption — "give the teacher wrong homework on purpose"

You can't measure a checker by only giving it good work. We deliberately break
known-good entries in specific ways, hide them among clean ones, and see what the
checker catches. This turns "we have a verifier" into "we have a verifier with a
measured catch rate per error type" — the difference between owning a smoke alarm
and having tested it with actual smoke.

## Rubric vs rubric-free — "did our grading scale bias the second opinion?"

When we ask another vendor's model to audit us, we can hand it our grading scale
(comparable results, but it inherits our thresholds) or let it judge in its own words
(fully independent, but needs translating). We did both:

> Same detection profile both ways (70%/95%), same items missed, and **95% of
> verdicts consistent** across the two modes on doubly-audited entries.

Meaning: the scale wasn't steering the verdicts — the paragraph evidence was.

## Cohen's kappa (κ) — mentioned but mostly not used, and why

κ measures how much two judges agree *beyond what chance would produce*. It needs
both judges to produce a mix of verdicts. Since every published edge already passed
our verifier (its verdicts are all "supported"), κ degenerates on that comparison —
so the paper uses plain agreement rates plus the calibration replays instead, and
reserves κ for the future human-annotator study, where it belongs.

## The honest-numbers rules used throughout

1. Raw fractions (5/6, 23/25) whenever samples are small — no percentage laundering.
2. Confidence intervals on any rate that carries an argument.
3. Flag → adjudicate → uphold: only the last of these counts as an error.
4. When a bigger sample contradicted an earlier claim (voice: "40%" → 72%),
   the claim was revised down in strength and the revision documented (E1b).
