<%*
// Check if this is a new file or inserting into existing file
// tp.config.run_mode: 0 = CreateNewFromTemplate, 1 = AppendActiveFile (insertion)
const isNewFile = tp.config.run_mode === 0;

// If inserting into existing file, just output basic frontmatter and exit
if (!isNewFile) {
-%>---
type: Application
application-type:
context: "[[Personal]]"
company:
role:
job-url:
date-applied:
application-status: Draft
location:
compensation:
job-level:
employment-type:
experience-required:
aliases:
archive: false
created: <% tp.date.now("YYYY-MM-DD") %>
modified:
cssclasses:
---

<%* } -%>
<%* if (isNewFile) { -%>
<%*

// For new files, continue with full prompts
// Prompt for company name
const company = await tp.system.prompt("Enter the company name.", "", false, false);
if (!company) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for role/position
const role = await tp.system.prompt("Enter the role/position title.", "", false, false);
if (!role) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for application type
const appType = await tp.system.suggester(
  ["Resume", "Cover Letter", "Essay Responses"],
  ["Resume", "Cover Letter", "Essay Responses"],
  false,
  "Application document type"
);

if (!appType) {
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Prompt for job URL (optional)
const jobUrl = await tp.system.prompt("Enter the job listing URL (optional).", "", false, false) || "";

// Build filename: YYYY-MM-DD Company Role Type
const dateStr = tp.date.now("YYYY-MM-DD");
const filename = `${dateStr} ${company} ${role} ${appType}`;

// Build frontmatter
let frontmatter = '---\n';
frontmatter += 'type: Application\n';
frontmatter += 'application-type: ' + appType + '\n';
frontmatter += 'context: "[[Personal]]"\n';
frontmatter += 'company: "' + company + '"\n';
frontmatter += 'role: "' + role + '"\n';
frontmatter += 'job-url: "' + jobUrl + '"\n';
frontmatter += 'date-applied:\n';
frontmatter += 'application-status: Draft\n';
frontmatter += 'location:\n';
frontmatter += 'compensation:\n';
frontmatter += 'job-level:\n';
frontmatter += 'employment-type:\n';
frontmatter += 'experience-required:\n';
frontmatter += 'aliases:\n';
frontmatter += '  - "' + company + ' ' + role + '"\n';
frontmatter += 'archive: false\n';
frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
frontmatter += 'modified:\n';
frontmatter += 'cssclasses:\n';
frontmatter += '---';

tR = frontmatter;
%>

<% tp.file.cursor(1) %>

<%*
// Move file to Job Applications folder under the company
const existingFile = tp.file.find_tfile(filename);
if (existingFile) {
  new Notice("Application already exists: " + filename, 5000);
  await app.vault.delete(tp.file.find_tfile(tp.file.title));
  return;
}

// Target path: Contexts/Personal/Job Search/Company/filename
const targetPath = "Contexts/Personal/Job Search/" + company + "/" + filename;
await tp.file.move(targetPath);

} // Close if (isNewFile)
%>
