---
modified: 2026-02-11T20:44:36-08:00
---
<%*
// Get context from target file's frontmatter (not template's)
const cache = app.metadataCache.getFileCache(tp.config.target_file);
let context = cache?.frontmatter?.context;
if (!context) {
  new Notice("No context set - cannot archive");
  return;
}

// Extract context name from wikilink format "[[Context Name]]"
const contextName = context.replace(/\[\[|\]\]/g, '');

// Map contexts to archive paths (work contexts only)
const contextPaths = {
  "APM Music": "Contexts/APM Music/Archive",
  "Yamaha Guitar Group": "Contexts/Yamaha Guitar Group/Archive",
  "Personal": "Contexts/Personal/Archive"
};

const archivePath = contextPaths[contextName];
if (!archivePath) {
  new Notice("Context '" + contextName + "' does not have an archive");
  return;
}

// Set archive: true in frontmatter
const file = tp.config.target_file;
await app.fileManager.processFrontMatter(file, (fm) => {
  fm.archive = true;
});

// Move to archive folder
await tp.file.move(archivePath + "/" + tp.file.title);
new Notice("Archived to " + archivePath + "/");
%>