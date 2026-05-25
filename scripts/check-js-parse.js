const fs = require('fs');
const p = './server/public/admin/build/main.dart.v20251021.js';
try {
  const s = fs.readFileSync(p, 'utf8');
  new Function(s);
  console.log('PARSE_OK');
} catch (e) {
  console.error('PARSE_ERROR', e && e.message);
  if (e && e.stack) console.error(e.stack);
  process.exit(2);
}
