# Vault Structure

## Hierarchy
```
Contexts/
├── [Organization A]/Portfolio/      (Products, Initiatives)
├── [Organization B]/Portfolio/      (Products, Initiatives)
├── Personal/
│   └── ...                          (Customize: side projects, creative work, etc.)

Calendar/                            (Daily notes, meetings)
Resources/
├── Frameworks/                      (Operational tools)
├── Reference/                       (External articles)
├── Definitions/                     (Standard terms)
├── Templates/                       (Note templates)
│   ├── Agents/                      (Agent prompt templates for coding projects)
│   └── Commands/                    (Command templates deployed to projects)
└── Meta/                            (Claude rules, scripts)
```

## Portfolio Folder Pattern
```
[Item Name]/
├── [Item Name].md   (folder note)
└── Documents/       (PRDs, specs, tickets)
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
