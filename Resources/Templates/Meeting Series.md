<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
if (!isNewFile) {
-%>---
type: Meeting Series
context:
about:
with:
cadence:
aliases:
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
---

## Purpose

## Standing Agenda
-

## Occurrences
<%* } -%>
<%* if (isNewFile) { -%>
<%*

// Step 1: Enter Meeting Name
const meetingName = await tp.system.prompt("Enter the meeting name.", "", false, false);
if (!meetingName) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 2: Select Context
const contextOptions = ["APM Music", "Yamaha Guitar Group"];
const selectedContext = await tp.system.suggester(contextOptions, contextOptions);
if (!selectedContext) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 3: Select Parent Project (filtered by context)
const projectTypes = ["Product", "Platform", "Initiative", "Feature"];
const allFiles = app.vault.getMarkdownFiles();
const projectOptions = [];
const projectValues = [];

for (const file of allFiles) {
  // Filter by context folder path
  if (!file.path.includes(`Contexts/${selectedContext}/`)) continue;

  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const aliases = cache.frontmatter.aliases;

    // Check if type matches project types
    const isProjectType = type && projectTypes.includes(type);

    // Check if file is not archived
    const isNotArchived = cache.frontmatter.archive !== true;

    if (isProjectType && isNotArchived) {
      const displayName = aliases && aliases.length > 0
        ? `${aliases[0]} - ${file.basename}`
        : file.basename;
      projectOptions.push(displayName);
      projectValues.push(file.basename);
    }
  }
}

// Sort alphabetically
const sortedProjects = projectOptions.map((opt, i) => ({opt, val: projectValues[i]}))
  .sort((a, b) => a.opt.localeCompare(b.opt));
projectOptions.length = 0;
projectValues.length = 0;
sortedProjects.forEach(({opt, val}) => {
  projectOptions.push(opt);
  projectValues.push(val);
});

// Add "None" option
projectOptions.unshift("(No parent project)");
projectValues.unshift("");

const selectedProject = await tp.system.suggester(projectOptions, projectValues);
if (selectedProject === undefined) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 4: Multi-select Attendees (filtered by context)
const people = [];

for (const file of allFiles) {
  // Filter by context folder path
  if (!file.path.includes(`Contexts/${selectedContext}/People/`)) continue;

  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;

    // Check for "Person" or "person", handle both string and array
    const isPerson = type && (
      type.toLowerCase() === "person" ||
      (Array.isArray(type) && type.some(t => t.toLowerCase() === "person"))
    );

    // Check if file is not archived
    const isNotArchived = cache.frontmatter.archive !== true;

    if (isPerson && isNotArchived) {
      people.push(file.basename);
    }
  }
}

// Sort alphabetically
people.sort();

// Multi-select attendees loop
const selectedWith = [];
let selecting = true;

while (selecting && people.length > 0) {
  const remaining = people.filter(p => !selectedWith.includes(p));
  if (remaining.length === 0) break;

  const options = ["(Done selecting)", ...remaining];
  const selected = await tp.system.suggester(options, options);

  if (!selected || selected === "(Done selecting)") {
    selecting = false;
  } else {
    selectedWith.push(selected);
  }
}

// Step 5: Select Cadence
const cadenceOptions = ["Daily", "Twice Weekly", "Weekly", "Biweekly", "Monthly"];
const selectedCadence = await tp.system.suggester(cadenceOptions, cadenceOptions);
if (!selectedCadence) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Meeting Series\n';
frontmatter += 'context: "[[' + selectedContext + ']]"\n';

if (selectedProject) {
  frontmatter += 'about: "[[' + selectedProject + ']]"\n';
} else {
  frontmatter += 'about:\n';
}

frontmatter += 'with:';
if (selectedWith.length > 0) {
  frontmatter += '\n';
  for (const person of selectedWith) {
    frontmatter += '  - "[[' + person + ']]"\n';
  }
} else {
  frontmatter += '\n';
}

frontmatter += 'cadence: ' + selectedCadence + '\n';
frontmatter += 'aliases:\n';
frontmatter += '  - "' + meetingName + '"\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += '---';

// Output the frontmatter
tR = frontmatter + '\n\n# ' + meetingName;
%>

## Purpose

<% tp.file.cursor(1) %>

## Standing Agenda
-

## Occurrences

```dataview
TABLE WITHOUT ID
  link(file.link, dateformat(file.day, "MMM d")) as "Date",
  one-liner as "Summary"
FROM "Calendar"
WHERE contains(aliases, "<% meetingName %>") AND type != "Meeting Series"
SORT file.day DESC
LIMIT 20
```

<%*
// Rename and move file to Calendar folder
const targetFileName = meetingName;
const existingFile = tp.file.find_tfile(targetFileName);

if (existingFile) {
  new Notice("Meeting Series already exists: " + targetFileName, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

await tp.file.move('Calendar/' + targetFileName);

} // Close if (isNewFile)
%>
