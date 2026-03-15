# Confidence Flagging Convention

Referenced explicitly by research skills and agent templates. Not auto-loaded.

## Levels

| Level | Criteria | Presentation |
|-------|----------|-------------|
| **HIGH** | Primary source verified (official docs, code inspection, API response, direct observation) | State as fact |
| **MEDIUM** | Multiple secondary sources agree, or reasonable inference from observed patterns | "Based on {source}..." |
| **LOW** | Single unverified source, training data only, extrapolation from partial evidence | Flag explicitly: "[LOW] — needs validation" |

## Inline Format

Use bracketed tags with evidence:

```
[HIGH] The auth middleware uses JWT with RS256 (verified in src/middleware/auth.ts:23)
[MEDIUM] Based on package.json and tsconfig, the project targets Node 20+ (no explicit engine field)
[LOW] The deployment likely uses AWS Lambda — needs validation against infra config
```

## Source Hierarchy

Highest confidence first:

1. **Codebase** — actual source files, configs, tests
2. **Official documentation** — framework/library docs, API references
3. **Multiple secondary sources** — blog posts, tutorials, Stack Overflow answers that agree
4. **Single secondary source** — one article or post
5. **Training data / general knowledge** — no specific source, pattern recognition only

## Aggregate Confidence

For research summaries covering multiple findings:

- **Overall confidence** = lowest-confidence finding that materially affects the conclusion
- If 8 HIGH findings and 1 LOW finding that doesn't change the recommendation: overall stays HIGH
- If 1 LOW finding undermines the core conclusion: overall drops to LOW
- Always note which specific findings are LOW when reporting aggregate

## Valid Result: "Couldn't Determine"

"Couldn't determine with confidence" is a legitimate research outcome. Better to report what you don't know than to guess. When reporting:

- What was searched / checked
- Why it was inconclusive
- What would resolve it (specific file to check, person to ask, test to run)
