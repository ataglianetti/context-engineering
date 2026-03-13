# Vault Structure

## Hierarchy
```
Contexts/
├── [Organization A]/Portfolio/     (Projects, products, initiatives)
├── [Organization B]/Portfolio/     (Projects, products, initiatives)
├── Personal/
│   └── ... (Customize: side projects, creative work, etc.)

Calendar/                            (Daily notes, weekly/monthly summaries, meetings)
Resources/
├── Frameworks/                      (Operational tools)
├── Reference/                       (External articles)
├── Definitions/                     (Standard terms)
├── Templates/                       (Note templates)
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

## Templates
When creating new notes, read the corresponding template from `Resources/Templates/` first. Templates define required frontmatter and structure for each note type.
