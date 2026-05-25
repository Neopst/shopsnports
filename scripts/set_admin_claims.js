// Usage: node set_admin_claims.js --key path/to/sa.json --uid <user_uid>
const admin = require('firebase-admin');
const fs = require('fs');
const argv = require('minimist')(process.argv.slice(2));

async function main() {
  const key = argv.key;
  const uid = argv.uid;
  const project = argv.project;
  if (!key || !uid) {
    console.error('Usage: node set_admin_claims.js --key path/to/sa.json --uid <user_uid> [--project <projectId>]');
    process.exit(1);
  }
  if (!fs.existsSync(key)) {
    console.error('Key file not found:', key);
    process.exit(1);
  }
  const keyJson = JSON.parse(fs.readFileSync(key, 'utf8'));
  admin.initializeApp({ credential: admin.credential.cert(keyJson), projectId: project });
  await admin.auth().setCustomUserClaims(uid, { admin: true });
  console.log('Set admin claim for', uid);
}

main().catch(e => { console.error(e); process.exit(1); });
