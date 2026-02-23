<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
if (!isNewFile) {
-%>---
type: Post
post-platform:
post-status: draft
post-community:
context:
project:
parent:
aliases:
related:
external:
target-date:
published-date:
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
const platformOptions = ["reddit", "substack", "twitter", "linkedin", "hackernews", "blog"];
const platformValue = await tp.system.suggester(
  ["Reddit", "Substack", "Twitter/X", "LinkedIn", "Hacker News", "Blog"],
  platformOptions,
  false,
  "Select platform"
);

if (!platformValue) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Community/subreddit prompt (conditional - only for reddit/substack)
let communityValue = "";
if (platformValue === "reddit") {
  communityValue = await tp.system.prompt("Subreddit (e.g., r-therapyGPT, r-ClaudeCode)", "", false, false);
  if (communityValue === null) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }
} else if (platformValue === "substack") {
  communityValue = await tp.system.prompt("Publication name (or leave blank for personal)", "", false, false);
  if (communityValue === null) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }
}

// Status prompt
const statusOptions = ["idea", "draft", "ready", "scheduled", "published", "archived"];
const statusValue = await tp.system.suggester(
  ["Idea", "Draft (Recommended)", "Ready to Publish", "Scheduled", "Published", "Archived"],
  statusOptions,
  false,
  "Select status"
);

if (!statusValue) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Context prompt (reuse existing pattern from Document.md)
// Dynamically discover contexts from vault notes
const contextFiles = app.vault.getMarkdownFiles().filter(f =>
  app.metadataCache.getFileCache(f)?.frontmatter?.type === "Context"
);
const contextOptions = contextFiles.map(f => f.basename);
if (contextOptions.length === 0) {
  new Notice("No contexts found. Run /setup first.");
  return;
}
contextOptions.push("Personal");
const contextValue = await tp.system.suggester(
  contextOptions,
  contextOptions,
  false,
  "Select context (work area this post belongs to)"
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

// Get all potential parent notes (Posts attach to portfolio items) from the selected context
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
  "Select project for this post (or choose 'No Parent')"
);

if (selectedParent === undefined) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for post title
const postTitle = await tp.system.prompt("Enter the post title", "", false, false);
if (!postTitle) {
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

// Build filename: just the title (platform is a subfolder, community is in frontmatter)
let filename = postTitle;
let platformFolder = platformValue.charAt(0).toUpperCase() + platformValue.slice(1);

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Post\n';
frontmatter += 'post-platform: ' + platformValue + '\n';
frontmatter += 'post-status: ' + statusValue + '\n';
frontmatter += 'post-community: ' + (communityValue || '') + '\n';
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
frontmatter += '  - "' + postTitle + '"\n';
frontmatter += 'related:\n';
frontmatter += 'external:\n';
frontmatter += 'target-date:\n';
frontmatter += 'published-date:\n';
frontmatter += 'cover:\n';
frontmatter += 'archive: false\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += 'cssclasses:\n';
frontmatter += '---';

tR = frontmatter;
%>

# <% postTitle %>

<% tp.file.cursor(1) %>

<%*
// Move file to project Posts folder
const existingFile = tp.file.find_tfile(filename);
if (existingFile) {
  new Notice("Post already exists: " + filename, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

let targetPath;
if (projectFile) {
  // Move to project-specific Posts folder with platform subfolder
  const projectFolderPath = "Contexts/" + resolvedContext + "/Portfolio/" + projectFile.basename + "/Posts/" + platformFolder;
  targetPath = projectFolderPath + "/" + filename;
} else {
  // No project found - move to context-level Posts folder with platform subfolder
  const postsFolderPath = "Contexts/" + resolvedContext + "/Posts/" + platformFolder;
  targetPath = postsFolderPath + "/" + filename;
}
await tp.file.move(targetPath);

} // Close if (isNewFile)
%>
