# Deep Linking Guide - ShopsNSports

## Overview

ShopsNSports uses a custom URL scheme (`myapp://`) to handle deep links for payment redirects, affiliate invitations, and product sharing.

## Implementation

### Platform Setup

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Intent filters configured for `myapp://` scheme
- Supports `autoVerify` for seamless link handling
- MainActivity.kt implements MethodChannel bridge

**iOS** (Future):
- TODO: Configure URL schemes in Info.plist
- TODO: Implement AppDelegate handling

### Deep Link Handler

Location: `lib/utils/deep_link_handler.dart`

The `DeepLinkHandler` class provides:
- One-shot initial link retrieval
- Platform channel communication
- Error handling and logging
- URI parsing utilities

## Supported Deep Link Patterns

### 1. Payment Success Redirects

**Pattern**: `myapp://payment-success?provider=X&reference=Y`

**Providers**: Stripe, Paystack, Flutterwave

**Parameters**:
- `provider` - Payment gateway name (stripe/paystack/flutterwave)
- `reference` - Payment reference/transaction ID
- `tx_ref` - Flutterwave transaction reference
- `transaction_id` - Alternative transaction identifier

**Example**:
```
myapp://payment-success?provider=paystack&reference=T123456789
myapp://payment-success?provider=flutterwave&tx_ref=FLW123456
```

**Handler**: Navigates to `PaymentVerifyingScreen` to validate and complete payment

**Implementation**: `lib/main.dart` (lines 105-145)

### 2. Affiliate Invitation Links (Planned)

**Pattern**: `myapp://affiliate?code=AFFILIATE123`

**Parameters**:
- `code` - Affiliate referral code

**Example**:
```
myapp://affiliate?code=JOHN2024
```

**Handler**: TODO - Navigate to affiliate registration with pre-filled code

**Status**: ⚠️ Intent filter configured, handler not implemented

### 3. Product Detail Links (Planned)

**Pattern**: `myapp://product?id=PRODUCT_ID`

**Parameters**:
- `id` - Product ID

**Example**:
```
myapp://product?id=prod_abc123
```

**Handler**: TODO - Navigate to product detail screen

**Status**: ⚠️ Intent filter configured, handler not implemented

## Testing Deep Links

### Android (ADB)

Test payment success:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "myapp://payment-success?provider=stripe&reference=test123" com.example.shopsnports
```

Test affiliate link:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "myapp://affiliate?code=JOHN2024" com.example.shopsnports
```

Test product link:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "myapp://product?id=prod_123" com.example.shopsnports
```

### iOS (Future)

```bash
xcrun simctl openurl booted "myapp://payment-success?provider=stripe&reference=test123"
```

## Integration Points

### Payment Gateways

**Stripe**: Redirect URL configured in payment intent
**Paystack**: `callbackUrl` parameter in checkout
**Flutterwave**: `redirectUrl` parameter in transaction

See: `lib/screens/checkout_screen.dart`

### Checkout Screen

Lines 336, 581: Payment gateway callback URLs configured

```dart
// Paystack
final callbackUrl = 'myapp://payment-success?provider=paystack';

// Flutterwave
redirectUrl: 'myapp://payment-success?provider=flutterwave',
```

## Security Considerations

1. **URL Validation**: Always validate deep link parameters before navigation
2. **Authentication**: Verify user authentication for sensitive deep links
3. **Parameter Sanitization**: Sanitize all query parameters to prevent injection
4. **HTTPS Fallback**: Support universal links (https://) for better security
5. **Rate Limiting**: Consider rate limiting for affiliate link usage

## Logging

All deep link operations are logged via `AppLogger`:

- `AppLogger.debug()` - Link retrieval and parsing
- `AppLogger.info()` - Successful link processing
- `AppLogger.error()` - Link processing failures

Check logs for debugging:
```dart
// Example log output
DeepLinkHandler: Requesting initial link from platform
DeepLinkHandler: Initial link received: myapp://payment-success?provider=stripe&reference=test123
Processing deep link: payment-success with params: {provider: stripe, reference: test123}
Navigating to payment verification: provider=stripe, params={reference: test123}
```

## Future Enhancements

### Universal Links (iOS/Android App Links)

Replace custom scheme with HTTPS URLs:
- `https://shopsnports.com/payment-success?...`
- `https://shopsnports.com/affiliate?...`
- `https://shopsnports.com/product?...`

Benefits:
- Better security (HTTPS validation)
- Fallback to web if app not installed
- Improved SEO

### Dynamic Link Providers

Consider Firebase Dynamic Links or Branch.io for:
- Analytics and tracking
- Deferred deep linking (install attribution)
- Link shortening
- Cross-platform support

### Additional Patterns

Potential deep link patterns to implement:
- Order tracking: `myapp://order?id=ORDER123`
- Vendor profiles: `myapp://vendor?id=VENDOR_ID`
- Search results: `myapp://search?q=QUERY`
- Categories: `myapp://category?id=electronics`

## Troubleshooting

### Link Not Opening App

1. Verify intent filter in AndroidManifest.xml
2. Check `android:scheme` and `android:host` match exactly
3. Ensure app is installed on device
4. Test with ADB command

### Link Opens But Navigation Fails

1. Check `AppLogger` for error messages
2. Verify URI parsing in `main.dart`
3. Ensure `navigatorKey` is properly configured
4. Check route definitions in `AppRouter`

### Payment Redirect Not Working

1. Verify callback URL in payment gateway settings
2. Check network logs for redirect URL
3. Ensure payment provider uses exact URL format
4. Test with ADB simulation first

## Resources

- [Android Deep Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [Flutter Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)
- Stripe Documentation: Payment redirects
- Paystack Documentation: Callback URLs
- Flutterwave Documentation: Redirect URLs
