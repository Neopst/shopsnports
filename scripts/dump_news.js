const admin = require('firebase-admin');
const svcPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json';
const svc = require(svcPath);
admin.initializeApp({ credential: admin.credential.cert(svc) });
const db = admin.firestore();
(async () => {
  const snap = await db.collection('news_items').get();
  console.log('news_items count', snap.size);
  snap.docs.forEach(d => console.log(d.id, JSON.stringify(d.data(), null, 2)));
})();
