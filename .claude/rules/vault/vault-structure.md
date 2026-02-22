# Vault Structure

## Hierarchy
```
Contexts/
├── [Organization Name]/
│   ├── Portfolio/        (Projects, products, initiatives)
│   ├── People/           (Colleagues, contacts)
│   └── Documents/        (Context-level documents)
└── Personal/             (Optional personal context)

Calendar/                 (Daily notes, meetings, threads)
Resources/
├── Frameworks/           (Operational tools, decision models)
├── Reference/            (External articles, resources)
├── Definitions/          (Standard terms)
├── Templates/            (Note templates)
└── Meta/                 (Claude rules, scripts)
```

## Portfolio Folder Pattern
```
[Item Name]/
├── [Item Name].md   (folder note)
└── Documents/       (PRDs, specs, tickets, analysis)
```

## Note Types
- **Portfolio:** Context, Product, Platform, Initiative, Feature
- **Navigation:** MOC (Map of Content — hub/index notes linking related items)
- **Support:** Document, Definition, Application, Framework, Reference
- **Calendar:** Journal, Meeting, Meeting Series, Thread
- **People:** Person
- **Content:** Post

## Templates
When creating new notes, read the corresponding template from `Resources/Templates/` first. Templates define required frontmatter and structure for each note type.
