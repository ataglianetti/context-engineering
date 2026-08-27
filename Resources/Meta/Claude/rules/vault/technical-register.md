---
paths:
  - "Contexts/**/Documents/**"
---

# Technical Register

How to write the parts of a spec, ticket, or pull request that get **read repeatedly under time pressure** — as opposed to the parts that get read once, by a person deciding whether to care.

Borrowed from ASD-STE100 (the aerospace maintenance-manual standard: restricted vocabulary, one meaning per word, capped sentence length). The full standard is too sterile for anything a human reads for orientation. The subset below is the part that buys maintainability without killing the document.

**This never applies to published or interpersonal writing.** Blog posts, email, chat, meeting notes, and anything else in `core/writing-style.md`'s scope are out of scope — permanently. Uniform sentence length and restricted vocabulary are *exactly* what AI detectors key on, so applying this to prose works against you.

---

## The two layers

Every technical artifact has both. Don't pick one register for the whole document — pick per section.

| Layer | Purpose | Register |
|---|---|---|
| **Orientation** | Read once, by someone deciding whether this matters to them | Normal voice. `core/writing-style.md` applies in full. |
| **Reference** | Read repeatedly, mid-task, by someone who needs the exact answer fast | Technical register. Rules below. |

Per surface:

| Surface | Orientation (voiced) | Reference (technical register) |
|---|---|---|
| Requirements doc | TL;DR, problem, why now, tradeoffs | Requirements, guardrails, exit criteria, edge cases |
| Design doc | TL;DR, what this is, scope framing | Decision cascades, contracts, invariants, behavior tables |
| Bug report | Symptom + user impact | Steps to reproduce, expected, actual, environment |
| Story / work item | Problem statement | Acceptance criteria |
| Epic | The arc | (mostly orientation — little reference content) |
| Pull request | What changed and why, in the description's first paragraph | Behavior changes, test plan, migration steps, rollback |
| Repo issue | Symptom + context | Repro steps, environment, expected/actual |
| Handoff | Problem + why | Constraints stated as requirements |

---

## Reference-layer rules

1. **One name per thing.** Pick the term, then use that exact term every time. No elegant variation — four names for one operation is the single biggest maintainability leak, and it breaks grep. This rule does the most work of any on this list.
2. **One idea per sentence. One instruction per step.** Split anything carrying two.
3. **Active voice, explicit subject, present tense.** "The controller sends the query to the index" — not "the query is sent."
4. **Condition before action.** "If the cache is cold, fetch from origin." Never the payoff-first inversion.
5. **No cross-sentence pronouns.** "It," "this," "that" must not point back at the previous sentence's subject. Repeat the noun.
6. **~20 words per sentence, ceiling.** If it won't fit, it's two rules.
7. **No noun stacks over three words.** "search result cache key" is fine; "adaptive search gate threshold value" is not — break it with a preposition.
8. **Numbers and enums get a table or a numbered list, never a comma run.** A five-step cascade buried in a sentence is unmaintainable by construction.

---

## Before publishing

**Synonym sweep.** Read the reference sections and list every term used for each concept. More than one term for one thing → pick the winner, replace the others. Do this before opening a pull request or pushing a ticket.

**Layer check.** Is any reference content trapped inside a paragraph? Is any orientation content written in the flat register (a TL;DR nobody wants to read)? Fix in both directions.

## Escape hatch

For a one-off — a chat answer, a quick doc — the two-word prompt `Use ASD-STE100` invokes the full standard directly. It's the sledgehammer: maximum clarity, zero warmth, no judgment about which layer it's in. Fine for a procedure, wrong for anything with a reader to convince.

## Applying this outside the vault

The `paths:` glob above only reaches notes in this vault. Pull requests and repo issues get written from code repos, which never load these rules. To make it apply there, put a compressed version (the two layers plus the eight reference rules) in your global `~/.claude/CLAUDE.md`, which loads in every session regardless of directory — one file instead of one per repo.
