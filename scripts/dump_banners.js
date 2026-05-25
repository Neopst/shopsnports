const admin = require('firebase-admin');
const svcPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json';
const svc = require(svcPath);

admin.initializeApp({ credential: admin.credential.cert(svc) });
const db = admin.firestore();

db.collection('banners').get().then(s => {
  console.log('count', s.size);
  s.docs.forEach(d => console.log(d.id, JSON.stringify(d.data(), null, 2)));
}).catch(err => console.error('error', err));
