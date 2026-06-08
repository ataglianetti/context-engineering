# Writing Style

## Scope
These rules apply to ALL prose Claude generates—drafts, plans, final output. Don't defer style checks to "later."

Applies to: vault notes (including speaker notes and presentation scripts), drafts, external replies, professional communication (email, Slack, Teams). If you have a separate style guide for social media or casual platforms, reference it here.

## First Principle

The user's voice must come through in everything we produce. AI is a speed tool, not a ghostwriter. If output reads as AI-generated, it undermines credibility and defeats the purpose.

Every draft should pass the "could a person tell?" test. If a colleague, Reddit commenter, or recipient would clock it as AI, rewrite.

## Rhythm & Pacing
- **Sentence fragments are a tool, not a default.** Use them for emphasis or punch. But back-to-back fragments read as choppy AI output. When two or three short fragments stack up, join some with dashes, commas, or conjunctions to create flow. Mix short and long.
- **Em-dashes are fine sparingly.** The tell is *density*, not presence. Max ~1 per paragraph. When overused, replace with periods (for punch) or commas (for flow).
- Never default to em-dashes as a connective crutch. If three sentences in a row use them, rewrite.
- **Always use real em-dashes (`—`), never double hyphens (`--`).** Applies everywhere: vault notes, thread headers, drafts, chat output. `copy-rich.sh` handles encoding normalization for clipboard — vault content stays typographically correct.

## Patterns to Avoid
- **Repetitive openers.** "Here's what...", "Here's how...", "Here's the thing..." — one per piece is fine. Multiple is a template tell. Vary your entry points.
- **Thesis-antithesis pairs.** "One is X. The other is Y." Use once for impact. Repeating the structure flattens it.
- Dialectical hedging, rhetorical equivocation
- Formal topic-announcing constructions ("On X, ...", "Regarding X, ...", "Let's explore...")
- **List-announcing fragments.** "Five principles. All role-agnostic." before a numbered list is the model organizing its output, not a writer making a point. Just start the list, or lead with the first item.
- **Essay-on-Slack.** In a Slack/Teams DM, a multi-paragraph constructed argument reads as "startupy/businessy" even with casual, lowercase wording and zero corporate slang. The tell is the *shape* — topic sentences, developed paragraphs, a closing/landing line — not the vocabulary. When a colleague asks your take, react first and riff in fragments across a few messages; save the constructed version for where it earns its keep (long-form, PRD, stakeholder memo). Scoped to chat; developed paragraphs are *correct* in long-form.

## Preferred Alternatives

| Instead of | Use |
|------------|-----|
| "On X, ..." / "Regarding X, ..." | State the point directly, or use a transitional sentence ("X works differently though.") |
| "Here's what/how/the thing..." | Vary openers—start with the subject, a question, or context |
| "One is X. The other is Y." (repeated) | Use once for contrast, then vary structure |

## Voice Calibration

| Context | Register | Sounds like |
|---|---|---|
| Reddit / casual | Blunt, sarcastic, humor from the situation | [fill in your casual voice] |
| Stakeholder email | Direct, opinionated, no corporate padding | States the recommendation, skips the preamble, doesn't over-hedge |
| Product docs / PRDs | Clean and precise, personality in framing not language | Structured but not sterile — reads like a person wrote it with intent |
| Blog / long-form | Essay voice, argument-driven, lopsided depth | Develops ideas unevenly — spends time on what's interesting, compresses the rest. Not documentation. |
| Speaker notes / read aloud | Spoken cadence, setup → payoff | Reads aloud cleanly. Qualifiers come before payoffs ("no matter how Y, X" not "X, no matter how Y"). Sentences flow forward to the ear. |
| Internal Teams/Slack — quick/transactional | Concise, action-oriented | Short messages. Lead with the ask or the update. Skip the preamble. |
| Internal Teams/Slack — riffing on an idea | Casual, spoken, think-aloud | Lead with the reaction, then riff. One thought per message; let it span a few sends. Drop the topic sentences and the closing/landing line. Say it how you'd say it at a desk, not how you'd draft it. Casual isn't all-lowercase: keep "I" and proper nouns (names, product names) capitalized. |
| Drafts for others | Match the recipient's expected register | Formal when needed, but never AI-formal |

- Lead with recommendations, then rationale
- Tables for structured comparisons

## Anti-AI Tells (Avoid in ALL Writing)

- **The diplomatic sandwich:** acknowledge → concede → correct → pivot. Real people don't structure disagreement this neatly.
- **Validating before disagreeing:** "Fair point, and..." / "Great question..." — just get to it.
- **Corporate hedging in casual clothes:** "meaningfully different," "worth being precise about," "exactly the kind of X this space needs" — this is LinkedIn voice leaking everywhere.
- **Symmetrical structure:** Real writing is lopsided. Spend time on what matters, skip what doesn't. Numbered lists where every item gets equal depth are a listicle tell — vary the weight based on what's actually interesting.
- **Right-branching qualifiers (payoff first, setup last):** Tacking conditions onto the end of a sentence after the conclusion — "X happens, no matter how Y" / "Take this away. If you remember anything, remember it." — reads backward, especially when spoken. The listener gets the payoff and then has to rebuild the setup as an afterthought. Default to **setup → payoff** order: condition first, conclusion last. Worst in speaker notes and anything read aloud; still applies to email and chat. Example: ❌ *"You'll get a generic email, no matter how cleverly you phrase it."* → ✓ *"No matter how cleverly you phrase it, you'll get a generic email."* Exception: imperative rules with conditions ("Build X when Y" / "Brush your teeth before bed") read naturally action-first.
- **Exhaustive politeness:** A full paragraph of acknowledgment before getting to the point is a tell.
- **Abstraction over specifics:** "I've taken steps to address this" vs "I updated the README" — always pick the concrete version.
- **Corporate slang:** "circle back," "leverage," "align on," "double-click on," "move the needle," "bandwidth" — never, in any register.
- **MBA-deck metaphors:** "moat," "flywheel," "wedge" and similar business-school shorthand — drop them in stakeholder writing. Describe durability concretely ("we own the inputs," "no vendor schema sits in the middle," "we control the speed"). The proof points carry the argument; the metaphor label is the tell. Internal audiences already share the strategic context — no need to declare the thing a moat.
- **Paragraph-ending thesis restatement:** Summarizing the point you just made in the last sentence. Fine once for emphasis. Back-to-back across paragraphs is a dead giveaway.
- **Negation-reversal pile-up:** "X, not Y" / "isn't X — it's Y" / "not A but B" used as the default sentence shape. One contrast lands; stacked, it's the loudest generated-prose tell. ❌ *"the infrastructure I think with, not a tool I open... The work wasn't extracting dollars. It was earning the renewal... renewed because they wanted to, not because canceling was hard"* (three in a row). Use the structure once per piece, then vary.
- **Colon-setup punches:** "The unusual part:", "Here's the thing:", "The best part:" — manufactured suspense before a short payoff. Cut the setup, state the thing. ❌ *"The unusual part: I build the AI products I manage."* → ✓ *"I also build the AI products I manage, which is less common for a PM."*
- **Every-paragraph mic-drop:** ending each paragraph on a short punchy fragment ("We grew by being worth it." / "It's the interesting part." / "I'd rather solve the first one."). One or two across a piece is fine; every paragraph is rhythm-by-template. Let some paragraphs end flat.
- **Product documentation register shift:** When describing features or tools, the voice can slide into README/landing page copy ("Run `/setup` and the system interviews you. Not a form. A conversation."). In essay or long-form context, describe from the inside (what you experienced, what it does for you) rather than from the outside (what the product offers).

## Tone Toward Readers
- **Never punch down.** When writing for an audience, assume readers are capable people who haven't encountered this information yet.
- Frame knowledge gaps as the information not having reached people yet, not people being behind. "That pattern hasn't made it to individual users yet" vs. "Individual users haven't caught on."
- Show what you built and why. Let the work speak. Avoid implying others are doing it wrong — show a better way and let them decide.

## Formatting
- Use Obsidian-flavored markdown (tabs for nested bullets, wikilinks, callouts)
