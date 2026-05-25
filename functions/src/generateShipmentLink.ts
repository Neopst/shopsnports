import * as admin from 'firebase-admin';
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin

export async function generateShipmentLink(data: any, context: any) {
  // Expect affiliateId provided by authenticated affiliate
  if (!context.auth) {
    throw new Error('unauthenticated');
  }
  const affiliateId = context.auth.uid;
  // Create a random token (server-side)
  const token = Math.random().toString(36).substring(2, 12) + Date.now().toString(36);
  const tokenDoc = {
    affiliateId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 3600 * 1000)),
  };
  await admin.firestore().doc(`shipment_tokens/${token}`).set(tokenDoc);
  const url = `https://yourdomain.com/shipment-request?token=${token}`;
  return { url, token };
}
