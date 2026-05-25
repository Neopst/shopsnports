This folder contains example Firebase Cloud Functions (TypeScript) for the
affiliate shipment-request workflow. These are templates intended to run in
the Firebase emulator during local development. Do not deploy to production
without configuring IAM, secrets, and verifying security rules.

Files:
- src/generateShipmentLink.ts - HTTPS callable function for affiliates to create links
- src/submitShipmentRequest.ts - HTTPS callable function to create a shipment request server-side
- src/onShipmentRequestCreated.ts - Firestore trigger to notify admin and affiliate

To run locally with the Firebase emulator:
1. Install Firebase tools and dependencies in this folder.
2. Set up .env or use environment config for admin notification endpoints.
3. Run `firebase emulators:start --only functions,firestore`.
