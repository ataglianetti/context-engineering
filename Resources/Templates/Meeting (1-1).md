<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
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

// Step 2: Get people filtered by context folder path
const allFiles = app.vault.getMarkdownFiles();
const personNames = [];

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
      personNames.push(file.basename);
    }
  }
}

// Count 1:1 meetings per person to sort by frequency
const meetingCounts = {};
for (const name of personNames) {
  meetingCounts[name] = 0;
}

for (const file of allFiles) {
  // Only check Calendar files
  if (!file.path.startsWith('Calendar/')) continue;

  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const withField = cache.frontmatter.with || [];

    // Check if this is a 1:1 meeting (Meeting type with exactly one person in with)
    const isMeeting = type === "Meeting";
    const is1on1 = isMeeting && withField.length === 1;

    if (is1on1) {
      // Check which person this meeting is with
      for (const name of personNames) {
        const personLinked = withField.some(w =>
          w && (w.includes(`[[${name}]]`) || w === name)
        );
        if (personLinked) {
          meetingCounts[name]++;
        }
      }
    }
  }
}

// Sort by meeting count (descending), then alphabetically for ties
personNames.sort((a, b) => {
  const countDiff = meetingCounts[b] - meetingCounts[a];
  if (countDiff !== 0) return countDiff;
  return a.localeCompare(b);
});

// Split into frequent (1+ meetings) and others (0 meetings)
const frequentPeople = personNames.filter(name => meetingCounts[name] > 0);
const otherPeople = personNames.filter(name => meetingCounts[name] === 0);

// Build initial list: frequent people + Show all option + manual entry
let displayList = [...frequentPeople];
if (otherPeople.length > 0) {
  displayList.push("Show all people...");
}
displayList.push("Other (enter manually)...");

// Prompt for person using suggester
let personName;
if (displayList.length > 1) {
  personName = await tp.system.suggester(displayList, displayList);
  if (!personName) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Handle "Show all people..." selection
  if (personName === "Show all people...") {
    const fullList = [...frequentPeople, ...otherPeople, "Other (enter manually)..."];
    personName = await tp.system.suggester(fullList, fullList);
    if (!personName) {
      await app.vault.delete(tp.file.find_tfile(tp.file.title));
      return;
    }
  }

  if (personName === "Other (enter manually)...") {
    personName = await tp.system.prompt("Enter the person's name.", "", false, false);
    if (!personName) {
      await app.vault.delete(tp.file.find_tfile(tp.file.title));
      return;
    }
  }
} else {
  personName = await tp.system.prompt("Enter the person's name.", "", false, false);
  if (!personName) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }
}

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
    dateOptions.push("Today (" + dateStr + ")");
  } else if (i === 1) {
    dateOptions.push("Tomorrow (" + dateStr + ")");
  } else {
    dateOptions.push(dayName + ", " + dateStr);
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

// Step 4: Get person's default cadence from their note
let defaultCadence = "Ad-hoc";
if (personName) {
  const personFile = tp.file.find_tfile(personName);
  if (personFile) {
    const personCache = app.metadataCache.getFileCache(personFile);
    if (personCache && personCache.frontmatter && personCache.frontmatter.cadence) {
      defaultCadence = personCache.frontmatter.cadence;
    }
  }
}

// Build cadence options with person's default first
const cadenceOptions = ["Weekly", "Biweekly", "Monthly", "Ad-hoc"];

// Reorder so person's cadence is first, add "(from person)" label
const orderedOptions = [
  defaultCadence,
  ...cadenceOptions.filter(c => c !== defaultCadence)
];
const displayOptions = orderedOptions.map((c, i) =>
  i === 0 ? `${c} (default)` : c
);

const selectedCadence = await tp.system.suggester(displayOptions, orderedOptions);
if (!selectedCadence) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Build context wikilink
const personContext = `"[[${selectedContext}]]"`;

// Build the entire frontmatter as a string
let frontmatter = '---\n';
frontmatter += 'type: Meeting\n';
frontmatter += 'context: ' + personContext + '\n';
frontmatter += 'about:\n';
frontmatter += 'with:\n';

if (personName) {
  frontmatter += '  - "[[' + personName + ']]"\n';
}

frontmatter += 'aliases:\n';
frontmatter += '  - "' + selectedCadence + ' 1:1 with ' + personName + '"\n';
frontmatter += 'one-liner:\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += 'cssclasses:\n';
frontmatter += '---';

// Output the frontmatter
const formattedDate = moment(finalDate).format("MMMM Do, YYYY");
tR = frontmatter + '\n\n# 1:1 with ' + personName + '\n[[' + finalDate + '|' + formattedDate + ']]';
%>

## Notes
- <% tp.file.cursor(1) %>

<%*
// Rename and move file to Calendar folder with date prefix
if (personName) {
  const targetFileName = finalDate + " " + personName;
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
