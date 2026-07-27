# Legal Statement

**The Symbolic World — a knowledge graph of C. G. Jung's Collected Works**
Date: 2026-07-27

This document sets out, in plain language, what this project contains, what it does not contain, and the legal basis on which it operates.

## 1. What the project contains — and what it does not

The Symbolic World is a scholarly knowledge graph of C. G. Jung's *Collected Works* (CW), built by Damian Spendel with AI collaborators. It is published as a public web application (symbolicworld.observer), a dataset (`seed.json`), and a research paper (`docs/PAPER.md`).

The dataset contains 653 references (count as of this statement's date; the dataset grows under the same rules). Each reference includes:

- a verbatim quotation of **at most 25 words** from a single CW paragraph;
- the CW volume and paragraph number (§);
- a Bollingen edition page number;
- scholarly metadata (claim type, verification provenance).

The project deliberately does **not** contain the text of the *Collected Works*. The full source texts were processed locally from lawfully obtained personal copies (epub). They are not distributed, not committed to this repository, and not served by the web application. Only the short quotations, § numbers, and page numbers described above are published.

The graph itself — its nodes, relations, and claim typing — is original analytical work. It describes and organizes claims *about* the CW; it does not reproduce the CW. Its closest analogues are an index, a concordance, or a scholarly apparatus.

## 2. Copyright status of the underlying works

The English translations of the *Collected Works* (translated by R.F.C. Hull, Bollingen Series XX, published by Princeton University Press and, in the UK, Routledge) are under copyright. This project treats them as such.

Jung's German originals have a separate status: Jung died in 1961, so in life-plus-70 jurisdictions the German originals begin entering the public domain from 2032. We do not rely on this and make no claim that any of the underlying material is currently in the public domain. The Hull translations are separately copyrighted works in their own right, and that copyright is current. All quotations in this dataset are taken from the copyrighted English translations.

## 3. Legal basis: quotation for scholarship

The project relies on the long-established quotation and fair-use/fair-dealing exceptions that permit short, attributed excerpts for scholarship, criticism, and review.

**United States — fair use (17 U.S.C. § 107).** The four factors, honestly assessed:

- *Purpose and character:* nonprofit scholarship and criticism. Each quotation anchors and verifies a specific analytical claim — the classic citation function.
- *Nature of the work:* the CW are published scholarly works; quotation for scholarly discussion of such works is at the core of what the exception protects.
- *Amount and substantiality:* each excerpt is at most 25 words, individually necessary to identify and verify the paragraph a claim rests on. No excerpt captures the "heart" of a volume.
- *Market effect:* none that we can identify, and plausibly complementary. The dataset cannot substitute for the books; every reference points the reader to a specific volume, paragraph, and page of the printed edition.

**United Kingdom and European Union.** UK law (CDPA s. 30) permits fair dealing with a work for quotation, criticism, and review; the EU InfoSoc Directive (art. 5(3)(d)) provides an equivalent quotation exception. Our quotations meet the usual conditions: the works are published; each quotation is attributed to its source (volume, paragraph, page); the extent is no more than the purpose requires; and the use is for a genuine scholarly purpose.

## 4. Aggregate use, stated honestly

Any single 25-word quotation is plainly within quotation norms. A dataset of 653 such quotations is an aggregation, and we address that directly rather than pretend each quote exists in isolation.

- **Scale.** 653 quotations of at most 25 words is under 17,000 words in total, drawn from a corpus of roughly twenty volumes running to several million words. The aggregate is a tiny fraction of the whole, spread thinly across it.
- **Non-substitutive.** The quotations are discontinuous fragments selected because they anchor citations, not because they represent the work's expressive interest. Read together they do not form readable text and could not serve anyone as a substitute for reading Jung.
- **Function.** The dataset operates as a concordance: a finding aid that tells a reader *where* in the CW a claim is grounded, and gives just enough verbatim text to verify the match. Paragraph (§) numbers and page numbers are facts, not protectable expression.

## 5. Takedown and contact

We are committed to acting in good faith toward the rights holders. If any rights holder — including Princeton University Press, Routledge, or the Jung estate — believes any quotation in this dataset exceeds what the quotation exceptions permit, we will review the concern promptly and, where warranted, further truncate or remove the contested quotations. Concerns may be raised via the project's repository issue tracker or its published contact address.

## 6. Licensing of the project's original content

- **Code:** MIT License.
- **Dataset (original content):** the graph structure, relations, claim typing, and scholarly metadata are licensed under **CC BY 4.0**.
- **Quotations:** the verbatim CW quotations are **excluded from both license grants**. They remain under the copyright of their respective rights holders and are included here in reliance on the quotation and fair-use exceptions described above. Reusers of the dataset must make their own assessment of the quotations for their own use.

## 7. AI disclosure

Extraction and verification were performed with AI models — Claude (Opus and Fable, Anthropic) and Gemini (Google) — under human direction. All quotations were mechanically verified verbatim against the source texts; the AI systems assisted the analysis but did not replace source verification.

## 8. Disclaimer

This statement is the project's good-faith position, prepared without legal counsel. It is not legal advice, and it does not bind anyone else's assessment: rights holders may take a different view, and the law of quotation varies by jurisdiction. We publish this statement so that our reasoning is open to scrutiny — and to correction.
