Local emulator setup (quick):

1. cd functions
2. npm install
3. firebase emulators:start --only functions,firestore

Ensure you have a `firebase.json` at repo root pointing to an emulator config or run `firebase init` in the functions folder and configure Firestore + Functions.

Security rules (example) - put into Firestore rules:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /shipment_tokens/{token} {
      allow read: if false; // tokens are not readable by clients
      allow create: if request.auth != null && request.auth.uid == request.resource.data.affiliateId;
      allow delete: if request.auth != null && request.auth.uid == resource.data.affiliateId;
    }

    match /shipment_requests/{requestId} {
      // creation should be done only via callable function (server-side)
      allow read: if request.auth != null && request.auth.uid == resource.data.affiliateId; // affiliate can read their requests
      allow read: if request.auth != null && request.auth.token.hasAny(['admin']); // simplistic admin check - replace with proper claims
      allow create: if false; // disallow direct client writes, use callable function
    }
  }
}
