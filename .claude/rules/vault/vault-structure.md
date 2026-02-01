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
Resources/Templates/      (Note templates)
```

## Portfolio Folder Pattern
```
[Item Name]/
├── [Item Name].md   (folder note)
└── Documents/       (PRDs, specs, tickets)
```

## Note Types
- **Portfolio:** Context, Product, Platform, Initiative, Feature
- **Support:** Document, Definition
- **Calendar:** Journal, Meeting, Meeting Series, Thread
- **People:** Person

## Templates
When creating new notes, read the corresponding template from `Resources/Templates/` first. Templates define required frontmatter and structure for each note type.
