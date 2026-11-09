const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', '..', 'data', 'levels');
fs.readdirSync(dir).forEach(file => {
  if (!file.endsWith('.json')) return;
  const p = path.join(dir, file);
  let content = fs.readFileSync(p, 'utf8');
  let data = JSON.parse(content);
  let modified = false;

  if (data.goals) {
    if (data.goals.flower_bell !== undefined) {
      data.goals.flower_tulip = (data.goals.flower_tulip || 0) + data.goals.flower_bell;
      delete data.goals.flower_bell;
      modified = true;
    }
    if (data.goals.flower_corolla !== undefined) {
      data.goals.flower_rose = (data.goals.flower_rose || 0) + data.goals.flower_corolla;
      delete data.goals.flower_corolla;
      modified = true;
    }
  }

  let text = JSON.stringify(data, null, 2);
  if (text.includes('flower_bell')) {
    text = text.replace(/"flower_bell"/g, '"flower_tulip"');
    modified = true;
  }
  if (text.includes('flower_corolla')) {
    text = text.replace(/"flower_corolla"/g, '"flower_rose"');
    modified = true;
  }

  if (modified) {
    fs.writeFileSync(p, text, 'utf8');
    console.log(`Updated ${file}`);
  }
});

console.log('Complete check & clean done.');
