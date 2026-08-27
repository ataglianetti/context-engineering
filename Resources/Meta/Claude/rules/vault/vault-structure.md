# Vault Structure

## Hierarchy
```
Contexts/
├── [Context 1]/Portfolio/      (Projects, products, initiatives)
├── [Context 2]/Portfolio/      (Projects, products, initiatives)
├── Personal/
│   └── ... (Customize: side projects, creative work, finances, etc.)

Calendar/                            (Daily notes, weekly/monthly summaries, meetings)
Resources/
├── Frameworks/                      (Operational tools)
├── Reference/                       (External articles)
├── Definitions/                     (Standard terms)
└── Meta/                            (System config)
```

## Portfolio Folder Pattern
```
[Item Name]/
├── [Item Name].md   (folder note)
└── Documents/       (PRDs, TRDs, specs, tickets)
```

## Note Types
- **Portfolio:** Context, Product, Platform, Initiative, Feature
- **Navigation:** MOC (Map of Content — hub/index notes linking related items)
- **Support:** Document, Definition, Application, Framework, Reference
- **Calendar:** Journal, Meeting, Meeting Series, Thread
- **People:** Person
- **Creative:** Song

## Frontmatter Contract
Every note carries `type:`, and context-linked types also carry `context:` as a wikilink. Both are enforced on write by `validate-frontmatter.sh` — a note missing either is blocked, not warned.

This kit does not ship note templates. If you keep templates in `Resources/Templates/`, the validation hooks skip that folder so template scaffolding with placeholder frontmatter doesn't trip the type check.
