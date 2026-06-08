<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter
if (!isNewFile) {
  tR += `---
type: Person
context:
pronouns:
company:
teams:
discipline:
title:
cadence:
email:
birthday:
hire-date:
website:
aliases:
tags:
created: ${tp.date.now("YYYY-MM-DD")}
modified:
---

`;
} else {
  // For new files, continue with full prompts
  // Prompt for person's name
  const personName = await tp.system.prompt("Enter the person's name.", "", false, false);
  if (!personName) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Prompt for context
  const contextOptions = ["Yamaha Guitar Group", "APM Music", "Personal"];
  const contextValue = await tp.system.suggester(
    contextOptions,
    contextOptions,
    false,
    "Select context (work area this person is associated with)"
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

  // Parse name parts NOW before building frontmatter
  const nameParts = personName.trim().split(' ').filter(part => part.length > 0);
  const firstName = nameParts[0];
  const lastInitial = nameParts.length > 1 ? nameParts[nameParts.length - 1][0] : '';
  const firstNameLastInitial = lastInitial ? `${firstName} ${lastInitial}.` : firstName;

  // Build frontmatter based on context
  let frontmatter = '---\n';
  frontmatter += 'type: Person\n';

  // Format context as wikilink for all contexts
  frontmatter += 'context: "[[' + contextValue + ']]"\n';
  frontmatter += 'pronouns:\n';

  // Add context-specific fields
  if (contextValue === "Personal") {
    // Personal context fields
    frontmatter += 'relationship:\n';
    frontmatter += 'related:\n';
    frontmatter += 'birthday:\n';
    frontmatter += 'location:\n';
    frontmatter += 'phone:\n';
    frontmatter += 'email:\n';
  } else {
    // Work context fields
    frontmatter += 'company:\n';
    frontmatter += 'teams:\n';
    frontmatter += 'discipline:\n';
    frontmatter += 'title:\n';
    frontmatter += 'cadence:\n';
    frontmatter += 'email:\n';
    frontmatter += 'birthday:\n';
    frontmatter += 'hire-date:\n';
    frontmatter += 'website:\n';
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

  const peopleFolderPath = "Contexts/" + resolvedContext + "/People";
  const targetPath = peopleFolderPath + "/" + personNameTrimmed;
  await tp.file.move(targetPath);
}
-%>
