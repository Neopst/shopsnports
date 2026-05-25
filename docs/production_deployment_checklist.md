# Production Deployment Checklist

## Pre-Deployment Verification

### Code Quality
- [ ] All unit tests passing (`flutter test test/unit/`)
- [ ] All widget tests passing (`flutter test test/widgets/`)
- [ ] All integration tests passing (`flutter test integration_test/`)
- [ ] Flutter analyze shows no errors (`flutter analyze`)
- [ ] Code coverage > 70% for critical paths

### Security
- [ ] API keys moved to environment variables
- [ ] Firebase security rules reviewed and deployed
- [ ] Backend API endpoints use HTTPS only
- [ ] Rate limiting enabled on backend
- [ ] CSRF protection enabled for admin routes
- [ ] Session management secure (httpOnly, secure flags)
- [ ] Stripe webhook signature verification enabled
- [ ] No hardcoded credentials in code

### Performance
- [ ] Images optimized and compressed
- [ ] Lazy loading implemented for lists
- [ ] Network caching configured
- [ ] Bundle size analyzed (`flutter build apk --analyze-size`)
- [ ] Startup time < 3 seconds
- [ ] No memory leaks detected
- [ ] Offline mode tested

### Firebase Configuration
- [ ] Production Firebase project created
- [ ] Firestore indexes deployed
- [ ] Firestore security rules deployed
- [ ] Firebase Authentication configured
- [ ] Cloud Storage rules configured
- [ ] Firebase Analytics enabled
- [ ] Crashlytics integrated

### Payment Gateways
- [ ] Stripe production keys configured
- [ ] Stripe webhooks registered
- [ ] Paystack production keys configured
- [ ] Flutterwave production keys configured
- [ ] Test payment flows with real cards
- [ ] Refund process tested

### Backend Deployment
- [ ] AWS ECS service configured
- [ ] Load balancer health checks passing
- [ ] SSL certificate configured
- [ ] Environment variables set
- [ ] Database backups automated
- [ ] Monitoring and alerts configured
- [ ] Error tracking enabled (Sentry/Rollbar)
- [ ] Rate limiting configured
- [ ] CORS configured correctly

### Mobile App
- [ ] App version updated in pubspec.yaml
- [ ] Build number incremented
- [ ] App name and package name verified
- [ ] App icons updated
- [ ] Splash screen configured
- [ ] Deep linking tested
- [ ] Push notifications tested
- [ ] Google Sign-In configured for production
- [ ] Location permissions configured

### Admin Dashboard
- [ ] Admin dashboard built (`flutter build web`)
- [ ] Deployed to server/public/admin/build/
- [ ] Admin authentication working
- [ ] News ticker management tested
- [ ] User management tested
- [ ] Analytics dashboard accessible

### Testing
- [ ] End-to-end checkout tested
- [ ] Payment flows tested with test cards
- [ ] Order creation and fulfillment tested
- [ ] Email notifications tested
- [ ] Push notifications tested
- [ ] Deep links tested
- [ ] Offline mode tested
- [ ] Error recovery tested

### Documentation
- [ ] API documentation updated
- [ ] Deployment runbook created
- [ ] Environment variables documented
- [ ] Troubleshooting guide created
- [ ] Admin user guide created

## Deployment Steps

### 1. Prepare Backend
```bash
cd server
npm install --production
npm run build
# Deploy to AWS ECS
```

### 2. Deploy Firebase
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# Deploy storage rules
firebase deploy --only storage
```

### 3. Build Admin Dashboard
```bash
cd admin_flutter
flutter build web --release
# Copy build to server/public/admin/build/
```

### 4. Build Mobile App

#### Android
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

#### iOS
```bash
flutter build ipa --release
# Upload to App Store Connect
```

### 5. Configure Monitoring
- Set up Firebase Crashlytics
- Configure backend error tracking
- Set up uptime monitoring
- Configure performance monitoring

### 6. Post-Deployment Verification
- [ ] App launches successfully
- [ ] User registration works
- [ ] Login works
- [ ] Product browsing works
- [ ] Cart operations work
- [ ] Checkout completes successfully
- [ ] Payments process correctly
- [ ] Orders appear in admin dashboard
- [ ] Email notifications send
- [ ] Push notifications work
- [ ] News ticker updates in real-time

## Rollback Plan

If issues occur:
1. Revert to previous app version in stores
2. Restore database from backup
3. Revert backend deployment
4. Notify users of temporary issues

## Environment Variables

### Backend (.env)
```
NODE_ENV=production
PORT=3000
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
PAYSTACK_SECRET_KEY=sk_live_...
FLUTTERWAVE_SECRET_KEY=...
JWT_SECRET=...
SESSION_SECRET=...
FIREBASE_PROJECT_ID=...
DATABASE_URL=...
```

### Flutter (firebase_options_production.dart)
- Already configured via FlutterFire CLI

## Performance Targets

- App startup: < 3 seconds
- Page navigation: < 300ms
- API response: < 500ms
- Image load: < 2 seconds
- Checkout completion: < 10 seconds

## Monitoring Dashboards

- Firebase Console: Analytics, Crashlytics
- AWS CloudWatch: Backend metrics
- Stripe Dashboard: Payment analytics
- Google Play Console: App metrics
- App Store Connect: App metrics

## Support Contacts

- Backend issues: [Backend team]
- Payment issues: [Payment team]
- Firebase issues: [Firebase admin]
- App store issues: [Publishing team]
