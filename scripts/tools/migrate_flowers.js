const fs = require('fs');
const path = require('path');

const replacements = {
  'level_11.json': { 'flower_bell': 'flower_tulip' },
  'level_12.json': { 'flower_bell': 'flower_tulip' },
  'level_19.json': { 'flower_corolla': 'flower_rose' },
  'level_20.json': { 'flower_corolla': 'flower_rose' },
  'level_21.json': { 'flower_bell': 'flower_tulip' },
  'level_25.json': { 'flower_corolla': 'flower_bed' },
  'level_28.json': { 'flower_bell': 'flower_tulip' },
  'level_29.json': { 'flower_corolla': 'flower_sunflower' },
  'level_31.json': { 'flower_bell': 'flower_tulip' },
  'level_34.json': { 'flower_corolla': 'flower_bed' },
  'level_37.json': { 'flower_bell': 'flower_tulip' },
  'level_38.json': { 'flower_corolla': 'flower_rose' }
};

const levelsDir = path.join(__dirname, '..', '..', 'data', 'levels');

for (const [file, mapping] of Object.entries(replacements)) {
  const filePath = path.join(levelsDir, file);
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    continue;
  }
  let content = fs.readFileSync(filePath, 'utf8');
  let data = JSON.parse(content);

  // Update goals
  if (data.goals) {
    for (const [oldKey, newKey] of Object.entries(mapping)) {
      if (data.goals[oldKey] !== undefined) {
        data.goals[newKey] = (data.goals[newKey] || 0) + data.goals[oldKey];
        delete data.goals[oldKey];
        console.log(`[${file}] Migrated goal ${oldKey} -> ${newKey} (${data.goals[newKey]})`);
      }
    }
  }

  // Update vegetation grid / tiles if any
  let strData = JSON.stringify(data, null, 2);
  for (const [oldKey, newKey] of Object.entries(mapping)) {
    const regex = new RegExp(`"${oldKey}"`, 'g');
    strData = strData.replace(regex, `"${newKey}"`);
  }

  fs.writeFileSync(filePath, strData, 'utf8');
  console.log(`[${file}] Saved successfully.`);
}

console.log('All 12 levels migrated.');
