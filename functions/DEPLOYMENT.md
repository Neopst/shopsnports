# Production Deployment Checklist

## Pre-Deployment Checklist

### Environment Configuration
- [ ] Configure Firebase project for production
- [ ] Set up SMTP credentials in Firebase Functions config
- [ ] Configure FCM credentials
- [ ] Set up custom domain (if applicable)
- [ ] Configure SSL/TLS certificates

### Security Configuration
- [ ] Review and update Firestore security rules
- [ ] Review and update Storage security rules
- [ ] Configure CORS to allow only production domains
- [ ] Enable Firebase App Check
- [ ] Set up 2FA for admin accounts
- [ ] Configure session timeout (recommended: 30 minutes)

### Database Configuration
- [ ] Deploy Firestore indexes (`firestore.indexes.json`)
- [ ] Set up data retention policies
- [ ] Configure backup strategy
- [ ] Test database performance

### Monitoring Setup
- [ ] Configure Firebase Crashlytics
- [ ] Set up Firebase Performance Monitoring
- [ ] Configure logging aggregation
- [ ] Set up alerting thresholds
- [ ] Test health check endpoint

### Email Configuration
- [ ] Verify SMTP settings in production
- [ ] Test all email templates
- [ ] Configure SPF, DKIM, DMARC records
- [ ] Set up email delivery monitoring

## Deployment Steps

### 1. Build and Test
```bash
cd functions
npm install
npm run build
npm test
```

### 2. Deploy to Firebase
```bash
# Deploy functions
firebase deploy --only functions

# Deploy firestore rules
firebase deploy --only firestore

# Deploy storage rules
firebase deploy --only storage

# Deploy indexes
firebase deploy --only firestore:indexes
```

### 3. Verify Deployment
- [ ] Check Firebase Console for deployed functions
- [ ] Test health check endpoint
- [ ] Verify all triggers are active
- [ ] Check function logs for errors

### 4. Post-Deployment
- [ ] Monitor error reporting for 24 hours
- [ ] Verify email delivery
- [ ] Test notification delivery
- [ ] Check audit trail entries
- [ ] Validate rate limiting

## Rollback Plan

If issues occur:
1. Identify the problematic function version
2. Roll back to previous version:
   ```bash
   firebase functions:rollback
   ```
3. Investigate issue in staging environment
4. Fix and redeploy

## Post-Production Monitoring

### First 24 Hours
- Monitor function invocations
- Check error rates
- Verify email delivery success
- Monitor FCM delivery rates
- Check database query performance

### First Week
- Review usage analytics
- Monitor security alerts
- Check audit trail for anomalies
- Review system metrics
- Gather user feedback

### Ongoing
- Weekly security review
- Monthly performance review
- Quarterly infrastructure audit
- Annual security assessment