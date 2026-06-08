<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
if (!isNewFile) {
-%>---
type: Context
area:
aliases:
tags:
cover:
external:
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
cssclasses:
---

<%* } -%>
<%* if (isNewFile) { -%>
<%*
const contextName = await tp.system.prompt("Enter the context name.", "", false, false);
if (!contextName) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

const existingFile = tp.file.find_tfile(contextName);
if (existingFile) {
  new Notice("Context already exists: " + contextName, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Context\n';
frontmatter += 'area:\n';
frontmatter += 'aliases:\n';
frontmatter += '  - "' + contextName + '"\n';
frontmatter += 'tags:\n';
frontmatter += 'cover:\n';
frontmatter += 'external:\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += 'cssclasses:\n';
frontmatter += '---';

tR = frontmatter;
%>

<%*
await tp.file.move("/Contexts/" + contextName);
} // Close if (isNewFile)
%>
