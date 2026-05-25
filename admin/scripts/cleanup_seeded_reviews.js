/*
Cleanup script to delete seeded review documents created by `seed_reviews.js`.

Usage:
- Set `GOOGLE_APPLICATION_CREDENTIALS` to point to a service account JSON with Firestore delete permissions.
- Run:
  node scripts/cleanup_seeded_reviews.js

This script deletes documents from the `reviews` collection where `seedTag == 'dev_seed_v1'` OR `seeded == true`.
It performs two queries (one for each condition) and deletes matching documents in batches.
*/

const admin = require('firebase-admin');
const readline = require('readline');
const { program } = require('commander');

program
  .option('--dry-run', 'Show how many documents would be deleted, do not delete')
  .option('--yes', 'Skip confirmation and delete')
  .parse(process.argv);

const opts = program.opts();
const DRY_RUN = !!opts.dryRun;
const SKIP_CONFIRM = !!opts.yes;

try {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    // Running against Firestore Emulator: no credentials required
    const projectId = process.env.GCLOUD_PROJECT || 'demo-project';
    admin.initializeApp({ projectId });
    console.log(`[cleanup_seeded_reviews] Initialized for emulator (projectId=${projectId}).`);
  } else {
    // Production/real Firestore: requires ADC/service account
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
    console.log('[cleanup_seeded_reviews] Initialized with application default credentials.');
  }
} catch (e) {
  console.error('Failed to initialize firebase-admin. For emulator set FIRESTORE_EMULATOR_HOST and GCLOUD_PROJECT. For prod set GOOGLE_APPLICATION_CREDENTIALS.');
  console.error(e);
  process.exit(1);
}

const db = admin.firestore();
const reviewsRef = db.collection('reviews');

async function deleteQueryBatch(query, batchSize = 100) {
  const snapshot = await query.limit(batchSize).get();
  if (snapshot.size === 0) return 0;

  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return snapshot.size;
}

async function countQuery(query) {
  const snapshot = await query.get();
  return snapshot.size;
}

async function promptYes(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase() === 'yes');
    });
  });
}

(async () => {
  console.log('Preparing cleanup for seeded review documents...');
  const queries = [
    { q: reviewsRef.where('seedTag', '==', 'dev_seed_v1'), label: "seedTag == 'dev_seed_v1'" },
    { q: reviewsRef.where('seeded', '==', true), label: 'seeded == true' },
  ];

  let totalMatched = 0;
  const counts = [];
  for (const item of queries) {
    const c = await countQuery(item.q);
    counts.push({ label: item.label, count: c });
    totalMatched += c;
  }

  console.log('Query counts:');
  counts.forEach((c) => console.log(`  ${c.label}: ${c.count}`));
  console.log(`Total matching documents (sum of queries): ${totalMatched}`);

  if (DRY_RUN) {
    console.log('Dry-run mode: no documents will be deleted. Exiting.');
    process.exit(0);
  }

  if (!SKIP_CONFIRM) {
    const ok = await promptYes('Proceed to delete the matching documents? Type YES to confirm: ');
    if (!ok) {
      console.log('Aborted by user. No documents deleted.');
      process.exit(0);
    }
  }

  console.log('Deleting matched documents...');
  let totalDeleted = 0;
  for (const item of queries) {
    const q = item.q;
    while (true) {
      const deleted = await deleteQueryBatch(q, 100);
      totalDeleted += deleted;
      console.log(`  Deleted ${deleted} documents in this batch for query ${item.label}.`);
      if (deleted < 100) break;
    }
  }

  console.log(`Cleanup complete. Total documents deleted: ${totalDeleted}`);
  process.exit(0);
})();
