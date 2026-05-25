# shopsnports

A Flutter project (shopsnports) with example payment integration using
Stripe PaymentSheet (client) + Node/Express (server example).

## Getting Started

This project is a starting point for a Flutter application.

Useful resources:

- [Flutter docs](https://docs.flutter.dev/)
- [flutter_stripe package](https://pub.dev/packages/flutter_stripe)

## Payments (Stripe) — Server + Flutter PaymentSheet

This repository includes an example server under `server/` that creates
Stripe PaymentIntents for testing with `flutter_stripe` PaymentSheet.

Quick test guide
----------------

1. Start the example server:

```powershell
cd server
# create a .env file with STRIPE_SECRET_KEY and optionally STRIPE_WEBHOOK_SECRET
npm install
npm run start
```

2. Update server/.env with your Stripe test keys:

```
STRIPE_SECRET_KEY=sk_test_...          # Stripe secret key (test)
STRIPE_WEBHOOK_SECRET=whsec_...        # optional
PORT=3000
```

3. Configure the Flutter app to set the publishable key at startup.
Example (e.g., in `main()`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANT: load your publishable key securely (do NOT commit secrets)
  stripe.Stripe.publishableKey = 'pk_test_...';
  runApp(const MyApp());
}
```

4. Run the app and go to Checkout. The app will call the example server's
   `/create-payment-intent` endpoint, get a `clientSecret`, then initialize
   and present the PaymentSheet.

Native platform setup
---------------------

Follow the platform-specific setup in the `flutter_stripe` docs to enable
PaymentSheet, Apple Pay and Google Pay (if needed). Summary:

- Android
  - Add Internet permission to `AndroidManifest.xml`.
  - Follow the plugin's Gradle setup and proguard rules if using obfuscation.

- iOS
  - Add required permissions and URL schemes in `Info.plist`.
  - Enable Apple Pay capability if you plan to test Apple Pay.

See official docs: https://pub.dev/packages/flutter_stripe

Security note
-------------

Store `STRIPE_SECRET_KEY` and publishable keys securely. Never commit
secret keys into source control. The example server is for local testing
only; add authentication and secure secret management before using in
production.
# shopsnports

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
