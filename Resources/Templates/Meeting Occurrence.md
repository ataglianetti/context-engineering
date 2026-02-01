<%*
const isNewFile = tp.config.run_mode === 0;

if (!isNewFile) {
-%>---
type: Meeting
context:
series:
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

// Step 2: Get Meeting Series filtered by context
const mocOptions = [];
const mocValues = [];
const mocDataMap = {};

for (const file of allFiles) {
  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const context = cache.frontmatter.context;
    const isMeetingMoc = type === "Meeting Series";
    const contextMatches = context && (
      context.includes(selectedContext) || context === selectedContext
    );
    const isNotArchived = cache.frontmatter.archive !== true;

    if (isMeetingMoc && contextMatches && isNotArchived) {
      mocOptions.push(file.basename);
      mocValues.push(file.basename);
      mocDataMap[file.basename] = {
        file: file,
        frontmatter: cache.frontmatter
      };
    }
  }
}

mocOptions.sort();
mocValues.sort();

if (mocOptions.length === 0) {
  new Notice("No Meeting Series found for " + selectedContext + ". Create one first.", 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

const selectedMoc = await tp.system.suggester(mocOptions, mocValues);
if (!selectedMoc) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

const mocData = mocDataMap[selectedMoc];

// Step 3: Select Date
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

// Get data from MOC
const mocWith = mocData.frontmatter.with || [];
const mocAbout = mocData.frontmatter.about || '';
const mocAliases = mocData.frontmatter.aliases || [];
const meetingAlias = mocAliases.length > 0 ? mocAliases[0] : selectedMoc;

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Meeting\n';
frontmatter += 'context: "[[' + selectedContext + ']]"\n';
frontmatter += 'series: "[[' + selectedMoc + ']]"\n';

frontmatter += 'about:';
if (mocAbout) {
  const aboutItems = Array.isArray(mocAbout) ? mocAbout : [mocAbout];
  frontmatter += '\n';
  for (const item of aboutItems) {
    const cleanItem = item.replace(/^\[\[|\]\]$/g, '').replace(/^"|"$/g, '');
    frontmatter += '  - "[[' + cleanItem + ']]"\n';
  }
} else {
  frontmatter += '\n';
}

frontmatter += 'with:';
if (mocWith.length > 0) {
  frontmatter += '\n';
  for (const person of mocWith) {
    const cleanPerson = person.replace(/^\[\[|\]\]$/g, '').replace(/^"|"$/g, '');
    frontmatter += '  - "[[' + cleanPerson + ']]"\n';
  }
} else {
  frontmatter += '\n';
}

frontmatter += 'aliases:\n';
frontmatter += '  - "' + meetingAlias + '"\n';
frontmatter += 'one-liner:\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += '---';

const formattedDate = moment(finalDate).format("MMMM Do, YYYY");
tR = frontmatter + '\n\n# ' + meetingAlias + '\n[[' + finalDate + '|' + formattedDate + ']]';
%>

## Notes
- <% tp.file.cursor(1) %>

<%*
const targetFileName = finalDate + ' ' + selectedMoc;
const existingFile = tp.file.find_tfile(targetFileName);

if (existingFile) {
  new Notice("Meeting note already exists: " + targetFileName, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

await tp.file.move('Calendar/' + targetFileName);

} // Close if (isNewFile)
%>
