# Payment Webhook Requirements

## Overview
Backend webhook handlers are required to receive real-time payment notifications from payment gateways. These ensure payment verification happens even if the user closes the app.

## Required Webhooks

### 1. Stripe Webhooks
**Endpoint**: `POST /webhooks/stripe`

**Events to Handle**:
- `payment_intent.succeeded` - Payment completed
- `payment_intent.payment_failed` - Payment failed
- `charge.refunded` - Refund processed

**Implementation**:
```javascript
// Verify webhook signature
const signature = req.headers['stripe-signature'];
const event = stripe.webhooks.constructEvent(req.body, signature, webhookSecret);

switch (event.type) {
  case 'payment_intent.succeeded':
    await updateOrderStatus(paymentIntent.id, 'completed');
    break;
  case 'payment_intent.payment_failed':
    await updateOrderStatus(paymentIntent.id, 'failed');
    break;
}
```

### 2. Paystack Webhooks
**Endpoint**: `POST /webhooks/paystack`

**Events to Handle**:
- `charge.success` - Payment completed
- `charge.failed` - Payment failed
- `refund.processed` - Refund completed

**Implementation**:
```javascript
// Verify webhook signature
const hash = crypto.createHmac('sha512', webhookSecret)
  .update(JSON.stringify(req.body))
  .digest('hex');

if (hash === req.headers['x-paystack-signature']) {
  const { event, data } = req.body;
  
  switch (event) {
    case 'charge.success':
      await updateOrderStatus(data.reference, 'completed');
      break;
  }
}
```

### 3. Flutterwave Webhooks
**Endpoint**: `POST /webhooks/flutterwave`

**Events to Handle**:
- `charge.completed` - Payment completed
- `refund.completed` - Refund processed

**Implementation**:
```javascript
// Verify webhook signature
const hash = req.headers['verif-hash'];
if (hash !== webhookSecret) {
  return res.status(401).send('Invalid signature');
}

const { event, data } = req.body;

switch (event) {
  case 'charge.completed':
    if (data.status === 'successful') {
      await updateOrderStatus(data.tx_ref, 'completed');
    }
    break;
}
```

## Security Requirements

1. **Signature Verification**: Always verify webhook signatures
2. **HTTPS Only**: Accept webhooks only over HTTPS
3. **Idempotency**: Handle duplicate webhook deliveries gracefully
4. **Rate Limiting**: Implement rate limiting to prevent abuse
5. **Secret Storage**: Store webhook secrets in environment variables

## Database Updates

When webhook received:
1. Update order status in Firestore
2. Send customer notification (email/push)
3. Update analytics/reporting
4. Trigger fulfillment process if applicable

## Webhook URLs (Production)

Configure these URLs in payment gateway dashboards:
- Stripe: `https://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/webhooks/stripe`
- Paystack: `https://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/webhooks/paystack`
- Flutterwave: `https://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/webhooks/flutterwave`

## Testing

Use webhook testing tools:
- **Stripe CLI**: `stripe listen --forward-to localhost:3000/webhooks/stripe`
- **Paystack**: Use test mode webhook simulator
- **Flutterwave**: Use sandbox environment webhook testing

## Mobile App Integration

The mobile app already handles:
1. Deep links for payment success (`myapp://payment-success`)
2. Payment verification screens (`payment_verifying_screen.dart`)
3. Success/failure UI (`successful_checkout_screen.dart`)

Webhooks provide redundant verification for reliability even if deep links fail.
