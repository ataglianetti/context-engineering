# Entity Resolution

Shared resolution rules for any command that maps external-source names to vault entities — `/meeting-notes`, `/save-thread`, `/update-thread`, `/draft-reply`, and anything else that turns rough notes, emails, or chat pastes into vault notes. Referenced explicitly by those commands (like `confidence-convention.md`); not auto-loaded.

Source-specific caveats stay with their command. This file holds only the source-agnostic rules.

## Decision Flow (per entity: people, products, projects, bugs, features)

1. **Search** the vault for matching notes
2. **Not found** → plain text (no orphan wikilinks)
3. **Found, belongs in a frontmatter field** (`about:`, `with:`) → frontmatter wikilink, plain text in body
4. **Found, body-only entity** → `[[Name]]` on first body mention, plain text after
5. **Zero or multiple matches** → plain text + ask the user

Full discipline (frontmatter-vs-body, read-only fields): `rules/core/document-traversal.md` → Wikilink Discipline.

## Name Matching — Glob ALL Spelling Variants

When resolving a first name, glob every common spelling before accepting a match: Mark/Marc, Kris/Chris/Kristopher, Erik/Eric, Jenny/Jeni, Sean/Shawn, Steven/Stephen, Jon/John. A single match on one spelling is effectively a guess when the other spellings weren't checked. If multiple variants match, or context is ambiguous, ask. This is stricter than hard-walls' "zero/multiple → ask."

**Why:** globbing only `Mark *` returned exactly one hit — a different person entirely — for a meeting that was about someone spelled *Marc*. One match reads like certainty; it was an artifact of searching one spelling.

## Partial Identifiers — Never Invent the Missing Portion

When a source provides an incomplete name, code, or ID: search → exactly one match → wikilink; zero or multiple → plain text + ask. Never fabricate the missing part (a last name, a team attribution, a code suffix).

Hard wall: `rules/core/hard-walls.md` → Content Integrity.

**Why:** a first-name-only meeting title ("Dan 1:1") was written up with a surname and a team attached to it. Both were invented — a plausible last name for the wrong Dan, and an org he didn't work in. Nothing in the source supported either.

## Abbreviations — Check Definitions Before Guessing

For domain or business abbreviations, check the Definitions folders before expanding:
- Domain- or industry-specific terms → `Contexts/[Context]/Definitions/`
- General business terms → `Resources/Definitions/`

If the term exists, use the defined expansion and wikilink it; if it's missing, ask rather than guess.

**Why:** a three-letter manufacturing acronym was expanded to a confident, sensible-sounding phrase that was simply not what it stood for in that industry. The correct expansion was already defined in the vault. A plausible expansion is indistinguishable from a correct one to the reader.

## Canonical Spelling — Cross-Check the Vault's Own Authoritative Notes

An entity name captured from an external source (rough notes, email, auto-created note) can enshrine a misspelling. Before treating it as canonical, check the vault's own earlier authoritative notes (cost sheets, contracts, signed documents, email threads) — not just the web. On confirming the correct form: rename the note, and keep the old form as an alias so existing links resolve.

**Why:** an auto-created vendor note carried a misspelling from a transcript. The vault's own cost records had the correct spelling — including a country suffix that distinguished the entity — going back months, while a web search returned only unrelated companies with similar names. The vault knew; the web didn't.

## Shorthand Maps

Project and product notes carry `aliases:` that double as shorthand maps (spoken nicknames, internal codes, SKU numbers). During resolution, read the `about:` note's aliases plus the context's portfolio rules (`rules/[context]/portfolio.md`).

Path-scoped rules don't auto-load for `Calendar/` files, so read the relevant portfolio rule **explicitly** during the resolution step — otherwise the shorthand map exists but never reaches the model that needs it.
