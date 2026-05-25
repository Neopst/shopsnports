# Affiliate shipment request workflow (overview)

This document explains the end-to-end flow and how to run the Cloud Functions + client locally using the Firebase emulator.

Flow summary:
- Affiliate generates a shipment link (callable function `createShipmentLink`) -> server stores token in `shipment_tokens/{token}` and returns URL.
- Affiliate shares URL with client (SMS/WhatsApp/Email/QR).
- Client opens public form and submits -> client calls callable function `submitRequest(token, client)` which creates `shipment_requests/{requestId}` attaching `affiliateId` server-side.
- Firestore trigger `shipmentRequestCreated` runs -> creates notification docs and (optionally) sends FCM pushes to admin & affiliate.
- Admin marks request complete in admin UI -> sets `status=completed` and optionally triggers payout.

Local dev steps (quick):
1. Install dependencies in `functions/`: `cd functions && npm install`
2. Start emulator: `firebase emulators:start --only functions,firestore`
3. Run app in debug (`flutter run`) — `AffiliateApi` will attempt to call emulator endpoints at `http://localhost:5001/{project}/us-central1/...` in debug mode.

Notes:
- Configure FCM tokens and admin claims on users before sending push notifications in production.
- Review `functions/README.md` for deeper notes.
