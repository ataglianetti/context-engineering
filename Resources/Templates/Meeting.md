<%*
// Check if this is a new file or inserting into existing file
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
if (!isNewFile) {
-%>---
type: Meeting
context:
about:
with:
aliases:
one-liner:
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
---

## Notes
- <%* } -%>
<%* if (isNewFile) { -%>
<%*

// Step 1: Enter Meeting Title
const meetingTitle = await tp.system.prompt("Enter the meeting title.", "", false, false);
if (!meetingTitle) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 2: Select Date (Today first for quick selection)
const todayDate = tp.date.now("YYYY-MM-DD");
const dateOptions = [];
const dateValues = [];

for (let i = 0; i < 14; i++) {
  const date = moment().add(i, 'days');
  const dateStr = date.format("YYYY-MM-DD");
  const dayName = date.format("dddd");

  if (i === 0) {
    dateOptions.push(`Today (${dateStr})`);
  } else if (i === 1) {
    dateOptions.push(`Tomorrow (${dateStr})`);
  } else {
    dateOptions.push(`${dayName}, ${dateStr}`);
  }
  dateValues.push(dateStr);
}

dateOptions.push("Custom date...");
dateValues.push("custom");

const selectedDate = await tp.system.suggester(dateOptions, dateValues);
if (!selectedDate) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

let finalDate;
if (selectedDate === "custom") {
  finalDate = await tp.system.prompt("Enter custom date (YYYY-MM-DD)", todayDate);
  if (!finalDate) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }
} else {
  finalDate = selectedDate;
}

// Step 3: Find available contexts dynamically
const allFiles = app.vault.getMarkdownFiles();
const contexts = [];

for (const file of allFiles) {
  if (!file.path.startsWith("Contexts/")) continue;
  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter && cache.frontmatter.type === "Context") {
    contexts.push(file.basename);
  }
}

// Select context (or None if multiple contexts exist)
let selectedContext = null;
if (contexts.length === 0) {
  // No contexts defined yet
  selectedContext = null;
} else if (contexts.length === 1) {
  // Auto-select single context
  selectedContext = contexts[0];
} else {
  // Multiple contexts - let user choose
  const contextOptions = [...contexts, "None"];
  selectedContext = await tp.system.suggester(contextOptions, contextOptions);
  if (selectedContext === "None") selectedContext = null;
}

// Step 4: Multi-select Attendees (filtered by context if selected)
const people = [];

for (const file of allFiles) {
  if (selectedContext) {
    if (!file.path.includes(`Contexts/${selectedContext}/People/`)) continue;
  } else {
    if (!file.path.includes("/People/")) continue;
  }

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

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Meeting\n';

if (selectedContext) {
  frontmatter += 'context: "[[' + selectedContext + ']]"\n';
} else {
  frontmatter += 'context:\n';
}

frontmatter += 'about:\n';
frontmatter += 'with:';

if (selectedWith.length > 0) {
  frontmatter += '\n';
  for (const person of selectedWith) {
    frontmatter += '  - "[[' + person + ']]"\n';
  }
} else {
  frontmatter += '\n';
}

frontmatter += 'aliases:\n';
frontmatter += '  - "' + meetingTitle + '"\n';
frontmatter += 'one-liner:\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += '---';

const formattedDate = moment(finalDate).format("MMMM Do, YYYY");
tR = frontmatter + '\n\n# ' + meetingTitle + '\n[[' + finalDate + '|' + formattedDate + ']]';
%>

## Notes
- <% tp.file.cursor(1) %>

<%*
if (meetingTitle) {
  const targetFileName = finalDate + " " + meetingTitle;
  const existingFile = tp.file.find_tfile(targetFileName);

  if (existingFile) {
    new Notice("Meeting note already exists: " + targetFileName, 5000);
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  await tp.file.move("/Calendar/" + targetFileName);
}

} // Close if (isNewFile)
%>
