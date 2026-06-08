<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
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
cover:
archive: false
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
cssclasses:
---

<%* } -%>
<%* if (isNewFile) { -%>
<%*

// For new files, continue with full prompts
const contextOptions = ["Yamaha Guitar Group", "APM Music", "Personal"];
const contextValue = await tp.system.suggester(
  contextOptions,
  contextOptions,
  false,
  "Select context (work area this document belongs to)"
);

if (!contextValue) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Map nested contexts to their parent folder paths
const nestedContexts = {
  "Songwriting": "Personal/Songwriting"
};
const resolvedContext = nestedContexts[contextValue] || contextValue;

// Get all potential parent notes (Documents can attach to any portfolio or work item) from the selected context
const parentTypes = ["Product", "Platform", "Initiative", "Feature"];
const allFiles = app.vault.getMarkdownFiles();

// Filter files by type AND context
const potentialParents = [];
for (const file of allFiles) {
  const cache = app.metadataCache.getFileCache(file);
  if (cache?.frontmatter?.type && parentTypes.includes(cache.frontmatter.type)) {
    // Only include parents that match the selected context
    let parentContext = cache.frontmatter.context;
    if (typeof parentContext === 'string') {
      parentContext = parentContext.replace(/^["'\s]+|["'\s]+$/g, '').replace(/^\[\[|\]\]$/g, '');
    }

    if (parentContext === contextValue) {
      potentialParents.push({
        file: file,
        displayName: file.basename,
        type: cache.frontmatter.type,
        context: cache.frontmatter.context,
        aliases: cache.frontmatter.aliases
      });
    }
  }
}

// Sort alphabetically
potentialParents.sort((a, b) => a.displayName.localeCompare(b.displayName));

// Show suggester - allow skipping with "No Parent"
const parentOptions = ["No Parent", ...potentialParents.map(p => p.displayName)];
const parentValues = [null, ...potentialParents];

const selectedParent = await tp.system.suggester(
  parentOptions,
  parentValues,
  false,
  "Select parent for this document (or choose 'No Parent')"
);

if (selectedParent === undefined) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for document title
const docTitle = await tp.system.prompt("Enter the document title.", "", false, false);
if (!docTitle) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for document type
const docType = await tp.system.suggester(
  ["Product Requirements", "Specification", "Research", "Analysis", "Design Doc", "Ticket", "Reference", "Marketing", "Presentation", "Release Notes", "Other"],
  ["Product Requirements", "Specification", "Research", "Analysis", "Design Doc", "Ticket", "Reference", "Marketing", "Presentation", "Release Notes", "Other"],
  false,
  "Document type (category of documentation)"
);

if (!docType) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Handle parent and find project
let parentLink = "";
let projectFile = null;

if (selectedParent) {
  // Format parent as wikilink
  parentLink = `"[[${selectedParent.file.basename}]]"`;

  // Function to find project by walking up the parent chain
  async function findProject(parentFile) {
    const cache = app.metadataCache.getFileCache(parentFile);
    const projectTypes = ["Product", "Platform", "Initiative", "Feature"];

    // If this file is a project-level type, return it
    if (cache?.frontmatter?.type && projectTypes.includes(cache.frontmatter.type)) {
      return parentFile;
    }

    // If this file has a parent, check the parent
    if (cache?.frontmatter?.parent) {
      let parentName = cache.frontmatter.parent;
      // Remove quotes and brackets from parent link
      parentName = parentName.replace(/^["'\s]+|["'\s]+$/g, '').replace(/^\[\[|\]\]$/g, '');

      // Find the parent file
      const parentFile = app.vault.getMarkdownFiles().find(f => f.basename === parentName);
      if (parentFile) {
        return await findProject(parentFile);
      }
    }

    return null;
  }

  // Try to find project from selected parent or its ancestors
  projectFile = await findProject(selectedParent.file);
}

// Build filename without project code (folder structure handles organization)
let filename = docTitle;

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Document\n';
frontmatter += 'document-type: ' + (docType || '') + '\n';
frontmatter += 'document-status: Draft\n';
frontmatter += 'context: "[[' + contextValue + ']]"\n';
// Add project field if found
if (projectFile) {
  frontmatter += 'project: "[[' + projectFile.basename + ']]"\n';
} else {
  frontmatter += 'project:\n';
}
// Add parent if exists
if (parentLink) {
  frontmatter += 'parent: ' + parentLink + '\n';
} else {
  frontmatter += 'parent:\n';
}
frontmatter += 'aliases:\n';
frontmatter += '  - "' + docTitle + '"\n';
frontmatter += 'related:\n';
frontmatter += 'cover:\n';
frontmatter += 'archive: false\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += 'cssclasses:\n';
frontmatter += '---';

tR = frontmatter;
%>

<% tp.file.cursor(1) %>

<%*
// Move file to project folder structure
const existingFile = tp.file.find_tfile(filename);
if (existingFile) {
  new Notice("Document already exists: " + filename, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

let targetPath;
if (projectFile) {
  // Move to project-specific Documents folder
  const projectFolderPath = "Contexts/" + resolvedContext + "/Portfolio/" + projectFile.basename + "/Documents";
  targetPath = projectFolderPath + "/" + filename;
} else {
  // No project found - move to context-level Documents folder
  const docsFolderPath = "Contexts/" + resolvedContext + "/Documents";
  targetPath = docsFolderPath + "/" + filename;
}
await tp.file.move(targetPath);

} // Close if (isNewFile)
%>
