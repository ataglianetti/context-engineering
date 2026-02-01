<%*
const isNewFile = tp.config.run_mode === 0;

if (!isNewFile) {
-%>---
type: Thread
context:
about:
with:
one-liner:
aliases:
created: <% tp.date.now("YYYY-MM-DD") %>
tags:
modified:
---

<%* } -%>
<%* if (isNewFile) { -%>
<%*
const threadName = await tp.system.prompt("Enter the thread subject.", "", false, false);
if (!threadName) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

const existingFile = tp.file.find_tfile(threadName);
if (existingFile) {
  new Notice("Thread already exists: " + threadName, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Thread\n';
frontmatter += 'context:\n';
frontmatter += 'about:\n';
frontmatter += 'with:\n';
frontmatter += 'one-liner:\n';
frontmatter += 'aliases:\n';
frontmatter += '  - "' + threadName + '"\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'tags:\n';
frontmatter += 'modified:\n';
frontmatter += '---';

tR = frontmatter + '\n\n# ' + threadName;
%>

<%*
await tp.file.move("/Calendar/" + threadName);
} // Close if (isNewFile)
%>
