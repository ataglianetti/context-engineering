<%*
const isNewFile = tp.config.run_mode === 0;

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

// Step 2: Find and select context dynamically
const allFiles = app.vault.getMarkdownFiles();
const contexts = [];

for (const file of allFiles) {
  if (!file.path.startsWith("Contexts/")) continue;
  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter && cache.frontmatter.type === "Context") {
    contexts.push(file.basename);
  }
}

let selectedContext;
if (contexts.length === 0) {
  new Notice("No contexts found. Run /setup first.", 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
} else if (contexts.length === 1) {
  selectedContext = contexts[0];
} else {
  selectedContext = await tp.system.suggester(contexts, contexts);
  if (!selectedContext) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }
}

// Step 3: Select Parent Project (filtered by context)
const projectTypes = ["Product", "Platform", "Initiative", "Feature"];
const projectOptions = [];
const projectValues = [];

for (const file of allFiles) {
  if (!file.path.includes(`Contexts/${selectedContext}/`)) continue;

  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const isProjectType = type && projectTypes.includes(type);
    const isNotArchived = cache.frontmatter.archive !== true;

    if (isProjectType && isNotArchived) {
      projectOptions.push(file.basename);
      projectValues.push(file.basename);
    }
  }
}

projectOptions.sort();
projectValues.sort();
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
  if (!file.path.includes(`Contexts/${selectedContext}/People/`)) continue;

  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const isPerson = type && (
      type.toLowerCase() === "person" ||
      (Array.isArray(type) && type.some(t => t.toLowerCase() === "person"))
    );
    const isNotArchived = cache.frontmatter.archive !== true;

    if (isPerson && isNotArchived) {
      people.push(file.basename);
    }
  }
}

people.sort();

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
