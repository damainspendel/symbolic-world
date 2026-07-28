# Provenance policy

Adopted 2026-07-28, after a hostile review found (a) quote repairs applied without
re-verification, leaving stamps attesting to superseded text, and (b) verification
dates backfilled in bulk rather than recorded at operation time.

## Rules

1. **Stamps are written by the operation they describe, at the time it runs.**
   No retroactive backfilling. (Historical exception, disclosed: references verified
   before 2026-07-26 carry batch-backfilled dates; the underlying verification is
   real, the timestamps are reconstructions.)
2. **Any edit to a reference's quote, subject, relation, object, or claim_type
   invalidates its verification stamps.** The reference must be re-gated; the old
   stamps are replaced (with the edit noted in `quote_repaired` or equivalent), and
   any cross-vendor stamp is annotated as predating the edit until a re-audit covers it.
3. **`crossvendor_checked` names the audit and its date**, and is only attached to
   references the audit actually covered.
4. **Convention-dependent readings carry `vocabulary_note`**, so a reader can apply
   either the project's mapping or the strict single-paragraph reading.
5. CI runs structural checks on every push; the full quote validator (which needs the
   local corpus) gates every build and deploy via `manage.sh`.
