<%*
const isNewFile = tp.config.run_mode === 0;

if (!isNewFile) {
-%>---
type: Context
area:
aliases:
tags:
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
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
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += '---';

tR = frontmatter;
%>

<%*
await tp.file.move("/Contexts/" + contextName + "/" + contextName);
} // Close if (isNewFile)
%>
