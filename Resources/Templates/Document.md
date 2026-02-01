<%*
const isNewFile = tp.config.run_mode === 0;

if (!isNewFile) {
-%>---
type: Document
document-type:
document-status: Draft
context:
project:
parent:
aliases:
related:
archive: false
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
---

<%* } -%>
<%* if (isNewFile) { -%>
<%*

// Step 1: Find and select context dynamically
const allFiles = app.vault.getMarkdownFiles();
const contexts = [];

for (const file of allFiles) {
  if (!file.path.startsWith("Contexts/")) continue;
  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter && cache.frontmatter.type === "Context") {
    contexts.push(file.basename);
  }
}

let contextValue;
if (contexts.length === 0) {
  new Notice("No contexts found. Run /setup first.", 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
} else if (contexts.length === 1) {
  contextValue = contexts[0];
} else {
  contextValue = await tp.system.suggester(
    contexts,
    contexts,
    false,
    "Select context"
  );
  if (!contextValue) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }
}

// Step 2: Get potential parent notes from selected context
const parentTypes = ["Product", "Platform", "Initiative", "Feature"];
const potentialParents = [];

for (const file of allFiles) {
  const cache = app.metadataCache.getFileCache(file);
  if (cache?.frontmatter?.type && parentTypes.includes(cache.frontmatter.type)) {
    let parentContext = cache.frontmatter.context;
    if (typeof parentContext === 'string') {
      parentContext = parentContext.replace(/^["'\s]+|["'\s]+$/g, '').replace(/^\[\[|\]\]$/g, '');
    }

    if (parentContext === contextValue) {
      potentialParents.push({
        file: file,
        displayName: file.basename,
        type: cache.frontmatter.type
      });
    }
  }
}

potentialParents.sort((a, b) => a.displayName.localeCompare(b.displayName));

const parentOptions = ["No Parent", ...potentialParents.map(p => p.displayName)];
const parentValues = [null, ...potentialParents];

const selectedParent = await tp.system.suggester(
  parentOptions,
  parentValues,
  false,
  "Select parent"
);

if (selectedParent === undefined) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 3: Prompt for document title
const docTitle = await tp.system.prompt("Enter the document title.", "", false, false);
if (!docTitle) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 4: Prompt for document type
const docType = await tp.system.suggester(
  ["Product Requirements", "Specification", "Research", "Design Doc", "Ticket", "Reference", "Other"],
  ["Product Requirements", "Specification", "Research", "Design Doc", "Ticket", "Reference", "Other"],
  false,
  "Document type"
);

if (!docType) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Handle parent and find project
let parentLink = "";
let projectFile = null;

if (selectedParent) {
  parentLink = `"[[${selectedParent.file.basename}]]"`;

  async function findProject(parentFile) {
    const cache = app.metadataCache.getFileCache(parentFile);
    const projectTypes = ["Product", "Platform", "Initiative", "Feature"];

    if (cache?.frontmatter?.type && projectTypes.includes(cache.frontmatter.type)) {
      return parentFile;
    }

    if (cache?.frontmatter?.parent) {
      let parentName = cache.frontmatter.parent;
      parentName = parentName.replace(/^["'\s]+|["'\s]+$/g, '').replace(/^\[\[|\]\]$/g, '');
      const parentFile = app.vault.getMarkdownFiles().find(f => f.basename === parentName);
      if (parentFile) {
        return await findProject(parentFile);
      }
    }

    return null;
  }

  projectFile = await findProject(selectedParent.file);
}

let filename = docTitle;

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Document\n';
frontmatter += 'document-type: ' + (docType || '') + '\n';
frontmatter += 'document-status: Draft\n';
frontmatter += 'context: "[[' + contextValue + ']]"\n';

if (projectFile) {
  frontmatter += 'project: "[[' + projectFile.basename + ']]"\n';
} else {
  frontmatter += 'project:\n';
}

if (parentLink) {
  frontmatter += 'parent: ' + parentLink + '\n';
} else {
  frontmatter += 'parent:\n';
}

frontmatter += 'aliases:\n';
frontmatter += '  - "' + docTitle + '"\n';
frontmatter += 'related:\n';
frontmatter += 'archive: false\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += '---';

tR = frontmatter;
%>

<% tp.file.cursor(1) %>

<%*
const existingFile = tp.file.find_tfile(filename);
if (existingFile) {
  new Notice("Document already exists: " + filename, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

let targetPath;
if (projectFile) {
  const projectFolderPath = "Contexts/" + contextValue + "/Portfolio/" + projectFile.basename + "/Documents";
  targetPath = projectFolderPath + "/" + filename;
} else {
  const docsFolderPath = "Contexts/" + contextValue + "/Documents";
  targetPath = docsFolderPath + "/" + filename;
}
await tp.file.move(targetPath);

} // Close if (isNewFile)
%>
