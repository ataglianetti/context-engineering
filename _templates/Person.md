<%*
const isNewFile = tp.config.run_mode === 0;

if (!isNewFile) {
  tR += `---
type: Person
context:
company:
teams:
discipline:
title:
cadence:
email:
aliases:
tags:
created: ${tp.date.now("YYYY-MM-DD")}
modified:
---

`;
} else {
  // Prompt for person's name
  const personName = await tp.system.prompt("Enter the person's name.", "", false, false);
  if (!personName) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Find and select context dynamically
  const allFiles = app.vault.getMarkdownFiles();
  const contexts = [];

  for (const file of allFiles) {
    if (!file.path.startsWith("Contexts/")) continue;
    const cache = app.metadataCache.getFileCache(file);
    if (cache && cache.frontmatter && cache.frontmatter.type === "Context") {
      contexts.push(file.basename);
    }
  }

  // Add Personal as an option
  if (!contexts.includes("Personal")) {
    contexts.push("Personal");
  }

  let contextValue;
  if (contexts.length === 1) {
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

  // Parse name parts
  const nameParts = personName.trim().split(' ').filter(part => part.length > 0);
  const firstName = nameParts[0];
  const lastInitial = nameParts.length > 1 ? nameParts[nameParts.length - 1][0] : '';
  const firstNameLastInitial = lastInitial ? `${firstName} ${lastInitial}.` : firstName;

  // Build frontmatter based on context
  let frontmatter = '---\n';
  frontmatter += 'type: Person\n';
  frontmatter += 'context: "[[' + contextValue + ']]"\n';

  if (contextValue === "Personal") {
    frontmatter += 'relationship:\n';
    frontmatter += 'related:\n';
    frontmatter += 'birthday:\n';
    frontmatter += 'location:\n';
    frontmatter += 'phone:\n';
    frontmatter += 'email:\n';
  } else {
    frontmatter += 'company:\n';
    frontmatter += 'teams:\n';
    frontmatter += 'discipline:\n';
    frontmatter += 'title:\n';
    frontmatter += 'cadence:\n';
    frontmatter += 'email:\n';
  }

  frontmatter += 'aliases:\n';
  frontmatter += '  - "' + firstName + '"\n';
  frontmatter += '  - "' + firstNameLastInitial + '"\n';
  frontmatter += 'tags:\n';
  frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
  frontmatter += 'modified:\n';
  frontmatter += '---';

  tR += frontmatter + '\n\n# ' + personName.trim();

  // Move file to context-specific People folder
  const personNameTrimmed = personName.trim();

  const existingFile = tp.file.find_tfile(personNameTrimmed);
  if (existingFile) {
    new Notice("Person already exists: " + personNameTrimmed, 5000);
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  const peopleFolderPath = "Contexts/" + contextValue + "/People";
  const targetPath = peopleFolderPath + "/" + personNameTrimmed;
  await tp.file.move(targetPath);
}
-%>
