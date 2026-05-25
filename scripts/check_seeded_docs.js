#!/usr/bin/env node
/**
 * Quick Firestore seeded-docs checker
 * Usage:
 * 1. Ensure Node.js is installed
 * 2. Install deps: `npm install firebase-admin`
 * 3. Run:
 *    - Option A (env var): `export GOOGLE_APPLICATION_CREDENTIALS=./shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json` (Windows PowerShell: `$env:GOOGLE_APPLICATION_CREDENTIALS='shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'`)
 *    - Option B (explicit path): edit the `serviceAccountPath` variable below
 *    node scripts/check_seeded_docs.js
 *
 * The script prints document counts and a small sample for these collections:
 * - banners
 * - news_items
 * - news_ticker
 * - content_pages
 */

const admin = require('firebase-admin');
const path = require('path');

// If you want to hardcode a path to the service account JSON, update this variable.
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, '..', 'shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json');

if (!admin.apps.length) {
  try {
    const svc = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(svc),
      projectId: svc.project_id || 'shopsnports',
    });
  } catch (err) {
    console.error('Failed to initialize admin SDK. Set GOOGLE_APPLICATION_CREDENTIALS or update serviceAccountPath.');
    console.error(err.message || err);
    process.exit(1);
  }
}

const db = admin.firestore();

async function sampleCollection(name, limit = 5) {
  try {
    const snapshot = await db.collection(name).limit(limit).get();
    return snapshot.docs.map(d => ({ id: d.id, data: d.data() }));
  } catch (e) {
    return { error: e.message || String(e) };
  }
}

async function countCollection(name) {
  try {
    const snapshot = await db.collection(name).limit(1).get();
    // Firestore doesn't provide count without aggregation in old SDKs; use size on a full query when small
    // We'll attempt to get up to 1000 docs and report size (suitable for seeded sets)
    const full = await db.collection(name).limit(1000).get();
    return full.size;
  } catch (e) {
    return { error: e.message || String(e) };
  }
}

async function run() {
  const collections = ['banners', 'news_items', 'news_ticker', 'content_pages'];

  console.log('\n🔎 Checking seeded collections in Firestore for project:', admin.apps[0].options.projectId || 'unknown');

  for (const c of collections) {
    process.stdout.write(`\n• Collection: ${c} — `);
    const cnt = await countCollection(c);
    if (typeof cnt === 'number') {
      console.log(`${cnt} documents`);
      const sample = await sampleCollection(c, 5);
      if (Array.isArray(sample)) {
        console.log('  Sample doc ids:', sample.map(s => s.id).join(', ') || '(none)');
        // If we're looking at banners, dump the full docs too and save to file
        if (c === 'banners') {
          console.log('  Full banner docs:');
          const fs = require('fs');
          const dumpPath = 'scripts/banners_log.txt';
          const dumpLines = [];
          sample.forEach(s => {
            const line = `${s.id}: ${JSON.stringify(s.data, null, 2)}`;
            console.log('    ' + line);
            dumpLines.push(line);
          });
          try {
            fs.writeFileSync(dumpPath, dumpLines.join('\n'), 'utf8');
            console.log(`  Banner docs also written to ${dumpPath}`);
          } catch (e) {
            console.log('  Failed to write banner dump file:', e);
          }
        }
      } else {
        console.log('  Sample error:', sample.error);
      }
    } else {
      console.log('error:', cnt.error);
    }
  }

  console.log('\n✅ Check complete. Use Firebase Console for deeper inspection.');
  process.exit(0);
}

run();
