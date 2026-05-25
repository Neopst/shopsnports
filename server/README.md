ShopsNports example payments server
==================================

This small Node/Express example demonstrates how to create a PaymentIntent
for use with a client-side Flutter PaymentSheet integration. It is intended
for local testing and as a reference. Do NOT use this exact code in
production without adding proper authentication, rate-limiting, error
handling, and secret management.

Setup
-----

1. Create a copy of the example .env file and insert your Stripe secret key:

```text
STRIPE_SECRET_KEY=sk_test_...   # your Stripe secret key (test)
STRIPE_WEBHOOK_SECRET=whsec_... # optional, for webhook signature verification
PORT=3000
```

2. Install dependencies and run the server:

```bash
cd server
npm install
npm run start
```

Endpoints
---------
- POST /create-payment-intent
  - Body: { amount: <integer cents>, currency?: 'usd' }
  - Returns: { clientSecret: '<client_secret>' }

- POST /webhook
  - Accepts Stripe webhook events. Configure Stripe dashboard to point
    to http://localhost:3000/webhook for local testing (use the Stripe CLI
    or ngrok when testing externally).

Notes
-----
- Use the Stripe CLI to forward events to your local webhook for testing:

  stripe listen --forward-to localhost:3000/webhook

- The server returns clientSecret only. The Flutter app will call
  `stripe.Stripe.instance.initPaymentSheet(...)` then `presentPaymentSheet()`.

Database TLS / SSL
-------------------

If you connect to a managed Postgres instance or a database that requires TLS,
the server supports enabling SSL for the Postgres client and loading optional
certificate files.

Environment variables:

- `DATABASE_URL` - your Postgres connection string (required for Postgres mode)
- `DB_SSL` - set to `true` to enable TLS for the Postgres client. When omitted
  TLS is also enabled automatically when `NODE_ENV=production`.
- `DB_SSL_REJECT_UNAUTHORIZED` - `true|false` (default: `true`). Set to `false`
  if you're using self-signed certs and explicitly accept the risk.
- `DB_SSL_CA_PATH` - optional path to a CA certificate file (PEM) to trust a
  private CA or self-signed server cert.
- `DB_SSL_CERT_PATH` and `DB_SSL_KEY_PATH` - optional client certificate and key
  files for mutual TLS connections.

Example (using a CA file):

```
DATABASE_URL=postgres://user:pass@db.example:5432/shopsnports
DB_SSL=true
DB_SSL_CA_PATH=C:\path\to\ca.pem
DB_SSL_REJECT_UNAUTHORIZED=true
```

If the server is unable to read the certificate files it will log a warning and
fall back to the default SSL configuration. Be sure to protect any certificate
files and never commit them to source control.
