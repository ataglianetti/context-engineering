<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
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
cssclasses:
---

## Notes
- <%* } -%>
<%* if (isNewFile) { -%>
<%*

// Step 1: Select Context
const contextOptions = ["APM Music", "Yamaha Guitar Group"];
const selectedContext = await tp.system.suggester(contextOptions, contextOptions);
if (!selectedContext) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Step 2: Get Meeting Series filtered by context
const allFiles = app.vault.getMarkdownFiles();
const mocOptions = [];
const mocValues = [];
const mocDataMap = {};

for (const file of allFiles) {
  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const context = cache.frontmatter.context;

    // Check if type is Meeting Series
    const isMeetingMoc = type === "Meeting Series";

    // Check if context matches (context can be a wikilink string)
    const contextMatches = context && (
      context.includes(selectedContext) ||
      context === selectedContext
    );

    // Check if file is not archived
    const isNotArchived = cache.frontmatter.archive !== true;

    if (isMeetingMoc && contextMatches && isNotArchived) {
      const displayName = file.basename;
      mocOptions.push(displayName);
      mocValues.push(file.basename);
      mocDataMap[file.basename] = {
        file: file,
        frontmatter: cache.frontmatter
      };
    }
  }
}

// Sort alphabetically
const sorted = mocOptions.map((opt, i) => ({opt, val: mocValues[i]}))
  .sort((a, b) => a.opt.localeCompare(b.opt));
mocOptions.length = 0;
mocValues.length = 0;
sorted.forEach(({opt, val}) => {
  mocOptions.push(opt);
  mocValues.push(val);
});

if (mocOptions.length === 0) {
  new Notice("No Meeting Series notes found for " + selectedContext + ". Create one first using the Meeting Series template.", 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for MOC using suggester
const selectedMoc = await tp.system.suggester(mocOptions, mocValues);
if (!selectedMoc) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

const mocData = mocDataMap[selectedMoc];

// Step 3: Select Date (Today first for quick selection)
const todayDate = tp.date.now("YYYY-MM-DD");
const dateOptions = [];
const dateValues = [];

// Generate date options for the next 14 days
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

// Add custom date option
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

// Get attendees from MOC's with: field
const mocWith = mocData.frontmatter.with || [];

// Get about (topic) from MOC
const mocAbout = mocData.frontmatter.about || '';

// Get alias from MOC (use first alias or basename)
const mocAliases = mocData.frontmatter.aliases || [];
const meetingAlias = mocAliases.length > 0 ? mocAliases[0] : selectedMoc;

// Build the frontmatter for the occurrence
let frontmatter = '---\n';
frontmatter += 'type: Meeting\n';
frontmatter += 'context: "[[' + selectedContext + ']]"\n';
frontmatter += 'series: "[[' + selectedMoc + ']]"\n';

// about: inherits topic from MOC (handle both string and array)
frontmatter += 'about:';
if (mocAbout) {
  const aboutItems = Array.isArray(mocAbout) ? mocAbout : [mocAbout];
  frontmatter += '\n';
  for (const item of aboutItems) {
    // Strip any existing wikilink syntax, then re-add it properly
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
    // Strip any existing wikilink syntax, then re-add it properly
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
frontmatter += 'cssclasses:\n';
frontmatter += '---';

// Output the frontmatter
const formattedDate = moment(finalDate).format("MMMM Do, YYYY");
tR = frontmatter + '\n\n# ' + meetingAlias + '\n[[' + finalDate + '|' + formattedDate + ']]';
%>

## Notes
- <% tp.file.cursor(1) %>

<%*
// Rename and move file to Calendar folder with date prefix
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
