import * as admin from 'firebase-admin';
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin

export async function createShipmentOnBehalf(data: any, context: any) {
  const { affiliateId: affiliateIdFromData, client } = data || {};
  if (!client) {
    throw new Error('client required');
  }

  // Prefer deriving affiliateId from auth context to prevent spoofing
  let affiliateId: string | undefined;
  const auth = context.auth;
  if (auth && auth.uid) {
    // Try to find an affiliate doc which lists this uid (simple mapping)
    const maybe = await admin.firestore().collection('affiliates').where('userId', '==', auth.uid).limit(1).get();
    if (!maybe.empty) {
      affiliateId = maybe.docs[0].id;
    }
    // If mapping not found, allow affiliateId to be stored on the affiliate doc keyed by uid
    if (!affiliateId) {
      // fallback: check a dedicated mapping doc
      const mapDoc = await admin.firestore().collection('affiliateMappings').doc(auth.uid).get();
      if (mapDoc.exists) {
        const m = mapDoc.data();
        affiliateId = m?.['affiliateId'];
      }
    }
  }

  // Emulator / fallback: allow passing affiliateId in data if auth is not present
  if (!affiliateId) affiliateId = affiliateIdFromData;

  if (!affiliateId) {
    throw new Error('affiliateId not available (authenticated caller required)');
  }

  // Create a shipment request doc with affiliateId attached server-side
  const docRef = await admin.firestore().collection('shippingRequests').add({
    affiliateId,
    client,
    status: 'submitted',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const shortLink = `https://example.com/shipment-request?id=${docRef.id}`;
  return { id: docRef.id, link: shortLink };
}
