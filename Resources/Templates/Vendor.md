<%*
// Check if this is a new file or inserting into existing file
const isNewFile = tp.config.run_mode === 0;

if (!isNewFile) {
  tR += `---
type: Vendor
context:
vendor-type:
status: Active
website:
aliases:
tags:
created: ${tp.date.now("YYYY-MM-DD")}
modified:
---

`;
} else {
  // Prompt for vendor name
  const vendorName = await tp.system.prompt("Enter the vendor/company name.", "", false, false);
  if (!vendorName) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Prompt for context (vendors are work entities only)
  const contextOptions = ["Yamaha Guitar Group", "APM Music"];
  const contextValue = await tp.system.suggester(
    contextOptions,
    contextOptions,
    false,
    "Select context"
  );

  if (!contextValue) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Prompt for vendor type
  const vendorTypeOptions = ["Contract Manufacturer", "Technology", "Service Provider"];
  const vendorType = await tp.system.suggester(
    vendorTypeOptions,
    vendorTypeOptions,
    false,
    "Select vendor type"
  );

  if (!vendorType) {
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Check for duplicate
  const vendorNameTrimmed = vendorName.trim();
  const existingFile = tp.file.find_tfile(vendorNameTrimmed);
  if (existingFile) {
    new Notice("Vendor already exists: " + vendorNameTrimmed, 5000);
    await app.vault.delete(tp.file.find_tfile(tp.file.title));
    return;
  }

  // Build frontmatter
  let frontmatter = '---\n';
  frontmatter += 'type: Vendor\n';
  frontmatter += 'context: "[[' + contextValue + ']]"\n';
  frontmatter += 'vendor-type: ' + vendorType + '\n';
  frontmatter += 'status: Active\n';
  frontmatter += 'website:\n';
  frontmatter += 'aliases:\n';
  frontmatter += 'tags:\n';
  frontmatter += 'created: ' + tp.date.now("YYYY-MM-DD") + '\n';
  frontmatter += 'modified:\n';
  frontmatter += '---';

  tR += frontmatter + '\n\n# ' + vendorNameTrimmed;

  // Move to context-specific Vendors folder
  const targetPath = "Contexts/" + contextValue + "/Vendors/" + vendorNameTrimmed;
  await tp.file.move(targetPath);
}
-%>
