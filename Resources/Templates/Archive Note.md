---
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

// Build archive path dynamically from context name
const archivePath = "Contexts/" + contextName + "/Archive";

// Verify the archive folder exists (or could exist)
const archiveFolder = app.vault.getAbstractFileByPath(archivePath);
if (!archiveFolder) {
  // Create the archive folder if it doesn't exist
  await app.vault.createFolder(archivePath);
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
