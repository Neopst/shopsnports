#!/usr/bin/env node
/**
 * List all files in Firebase Storage to see what paths are available.
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '../shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function main() {
  try {
    const bucket = admin.storage().bucket('shopsnports.firebasestorage.app');

    console.log('📂 Firebase Storage Contents:\n');

    const [files] = await bucket.getFiles({ maxResults: 100 });

    if (files.length === 0) {
      console.log('❌ No files found in Storage.\n');
    } else {
      console.log(`✅ Found ${files.length} files:\n`);
      files.forEach((f) => {
        const size = f.metadata.size || '?';
        console.log(`  • ${f.name} (${size} bytes)`);
      });
    }

    console.log('\n✅ Done.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
