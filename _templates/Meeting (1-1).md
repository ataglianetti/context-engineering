<%*
const isNewFile = tp.config.run_mode === 0;

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

// Step 2: Get people filtered by context, sorted by 1:1 meeting frequency
const personNames = [];

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
      personNames.push(file.basename);
    }
  }
}

// Count 1:1 meetings per person
const meetingCounts = {};
for (const name of personNames) {
  meetingCounts[name] = 0;
}

for (const file of allFiles) {
  if (!file.path.startsWith('Calendar/')) continue;

  const cache = app.metadataCache.getFileCache(file);
  if (cache && cache.frontmatter) {
    const type = cache.frontmatter.type;
    const withField = cache.frontmatter.with || [];
    const isMeeting = type === "Meeting";
    const is1on1 = isMeeting && withField.length === 1;

    if (is1on1) {
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

personNames.sort((a, b) => {
  const countDiff = meetingCounts[b] - meetingCounts[a];
  if (countDiff !== 0) return countDiff;
  return a.localeCompare(b);
});

const frequentPeople = personNames.filter(name => meetingCounts[name] > 0);
const otherPeople = personNames.filter(name => meetingCounts[name] === 0);

let displayList = [...frequentPeople];
if (otherPeople.length > 0) {
  displayList.push("Show all people...");
}
displayList.push("Other (enter manually)...");

let personName;
if (displayList.length > 1) {
  personName = await tp.system.suggester(displayList, displayList);
  if (!personName) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

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

// Step 3: Select Date
const todayDate = tp.date.now("YYYY-MM-DD");
const dateOptions = [];
const dateValues = [];

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

// Step 4: Get person's default cadence
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

const cadenceOptions = ["Weekly", "Biweekly", "Monthly", "Ad-hoc"];
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

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Meeting\n';
frontmatter += 'context: "[[' + selectedContext + ']]"\n';
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
frontmatter += '---';

const formattedDate = moment(finalDate).format("MMMM Do, YYYY");
tR = frontmatter + '\n\n# 1:1 with ' + personName + '\n[[' + finalDate + '|' + formattedDate + ']]';
%>

## Notes
- <% tp.file.cursor(1) %>

<%*
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
