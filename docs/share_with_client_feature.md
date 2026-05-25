# Share Form with Client Feature

## Overview
Allows affiliates to share a tokenized shipping form link with their clients. Clients can fill the form themselves while the affiliate automatically receives commission credit.

## User Flow

### 1. Affiliate Shares Form
1. Open Affiliate Dashboard
2. Tap "Share Form with Client"
3. Enter client name (optional) and email (required)
4. Tap "Generate Secure Link"
5. Choose action:
   - **Copy Link**: Copy to clipboard and share manually
   - **Send Email**: Automatically email the link to client (requires email service)

### 2. Link Generation
- System generates unique token (UUID v4)
- Token stored in Firestore `shippingTokens` collection
- Token valid for 7 days
- Single-use only

### 3. Client Fills Form
- Client clicks link (e.g., `https://app.shopsnports.com/shipping/request?token=abc123`)
- Form loads with token validation
- Form appears identical to normal shipping form
- Client fills all required fields
- Submits request

### 4. Submission Processing
- System extracts affiliate ID from token
- Creates shipping request with:
  - `submittedBy: 'client'`
  - `shareToken: 'abc123'`
  - `affiliateId: 'aff_123'` (hidden from client)
- Marks token as used
- Redirects to success screen

### 5. Notifications (Future Enhancement)
- Admin receives: "New request from [Client] via Affiliate [Name]"
- Affiliate receives: "Your client [Name] submitted request REQ-12345"
- Client receives: "Request confirmed. Tracking: REQ-12345"

## Technical Implementation

### Files Created

1. **lib/services/shipping_token_service.dart**
   - `generateToken()`: Creates new token with affiliate ID, client email
   - `validateToken()`: Checks token validity (not expired, not used)
   - `markTokenAsUsed()`: Marks token as consumed after submission
   - `getPublicFormUrl()`: Generates shareable URL
   - `getAffiliateTokens()`: Lists all tokens created by affiliate
   - `deleteExpiredTokens()`: Cleanup utility

2. **lib/screens/affiliate/share_form_dialog.dart**
   - UI dialog for affiliate to enter client details
   - Token generation trigger
   - Copy to clipboard functionality
   - Email sending trigger (placeholder)
   - Visual confirmation of link generation

### Files Modified

1. **lib/screens/affiliate/affiliate_dashboard_screen.dart**
   - Added "Share Form with Client" quick action
   - Imported ShareFormDialog

2. **lib/screens/shipping/shipping_request_screen_new.dart**
   - Added `shareToken` parameter
   - Added `prefilledAffiliateId` parameter
   - Added token validation on init
   - Modified submission to include token metadata

3. **pubspec.yaml**
   - Added `uuid: ^4.5.1` dependency

## Firestore Structure

### Collection: `shippingTokens`
```json
{
  "token": "550e8400-e29b-41d4-a716-446655440000",
  "affiliateId": "aff_123",
  "clientEmail": "client@example.com",
  "clientName": "John Doe",
  "used": false,
  "createdAt": "2026-01-01T10:00:00Z",
  "expiresAt": "2026-01-08T10:00:00Z",
  "usedAt": null,
  "shippingRequestId": null
}
```

After client submits:
```json
{
  "used": true,
  "usedAt": "2026-01-01T15:30:00Z",
  "shippingRequestId": "REQ-12345"
}
```

## Security Features

1. **Token Expiration**: 7-day validity
2. **Single-Use**: Token invalidated after one submission
3. **Validation Check**: Token verified before form loads
4. **Affiliate Tracking**: Hidden affiliate ID prevents tampering
5. **Email Verification**: Token tied to specific client email

## Future Enhancements

### Email Service Integration
```dart
// Option 1: Cloud Function (Recommended)
// functions/src/index.ts
export const sendShareEmail = functions.https.onCall(async (data) => {
  const { clientEmail, clientName, link } = data;
  
  await sendEmail({
    to: clientEmail,
    subject: 'Complete Your Shipping Request',
    html: `
      <h2>Hi ${clientName || 'there'},</h2>
      <p>You've been invited to submit a shipping request through ShopsNSports.</p>
      <p><a href="${link}">Fill Shipping Form</a></p>
      <p>Link expires in 7 days.</p>
    `
  });
});

// Option 2: SendGrid API
// Option 3: Firebase Email Extension
```

### Notification System
```dart
// Cloud Function trigger on shipping request creation
export const onShippingRequestCreated = functions.firestore
  .document('shippingRequests/{requestId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    
    if (data.shareToken) {
      // Get token details
      const tokenDoc = await db.collection('shippingTokens').doc(data.shareToken).get();
      const token = tokenDoc.data();
      
      // Send notifications
      await Promise.all([
        notifyAdmin(data, token),
        notifyAffiliate(data, token),
        notifyClient(data)
      ]);
    }
  });
```

### SMS Integration
```dart
// Twilio integration for SMS sharing
Future<void> sendViaSMS(String phoneNumber, String link) async {
  final twilioService = TwilioService();
  await twilioService.sendSMS(
    to: phoneNumber,
    message: 'Complete your shipping request: $link (Expires in 7 days)',
  );
}
```

### Analytics Tracking
```dart
// Track share conversion rates
await FirebaseAnalytics.instance.logEvent(
  name: 'affiliate_share_form',
  parameters: {
    'affiliate_id': affiliateId,
    'client_email': clientEmail,
    'token': token,
  },
);

await FirebaseAnalytics.instance.logEvent(
  name: 'client_form_submit',
  parameters: {
    'token': shareToken,
    'affiliate_id': affiliateId,
  },
);
```

## Testing Checklist

- [x] Share button appears on affiliate dashboard
- [x] Dialog opens with proper UI
- [x] Email validation works
- [x] Token generates successfully
- [x] Link displays in dialog
- [x] Copy to clipboard works
- [ ] Email sends successfully (requires email service)
- [ ] Public URL route works
- [ ] Token validation prevents expired/used tokens
- [ ] Form submission includes affiliate ID
- [ ] Token marked as used after submission
- [ ] Notifications sent (requires Cloud Functions)

## Usage Statistics (Future)

Track in Firestore:
```json
{
  "shareStats": {
    "totalShares": 125,
    "successfulSubmissions": 87,
    "conversionRate": 0.696,
    "avgTimeToSubmit": "2.5 hours"
  }
}
```

## Admin Dashboard View

Future admin feature to see:
- Most active affiliates (by shares)
- Share conversion rates
- Expired vs used tokens
- Average client response time
- Popular share methods (email vs link)

## Support & Troubleshooting

**Token Expired Error:**
- Solution: Affiliate generates new link

**Token Already Used Error:**
- Solution: Contact affiliate for new link

**Email Not Received:**
- Check spam folder
- Use "Copy Link" as fallback
- Contact support

**Form Won't Load:**
- Verify link is complete
- Check token hasn't expired
- Try opening in different browser
