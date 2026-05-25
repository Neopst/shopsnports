# News Ticker Admin Integration - Deployment Guide

## ✅ Completed Implementation

### Mobile App (Flutter)
- ✅ `NewsTickerService` - Firestore integration
- ✅ `NewsTickerWidget` - Real-time updates via StreamProvider
- ✅ News ticker visible on all major screens

### Admin Dashboard (Flutter Web)
- ✅ `NewsTickerPage` - Full CRUD UI
- ✅ Add/Edit/Delete news items
- ✅ Priority management
- ✅ Active/Inactive toggle
- ✅ Link support (optional)

### Backend API (Node.js/Express)
- ✅ `GET /admin/news-ticker` - List all items
- ✅ `POST /admin/news-ticker` - Create item
- ✅ `PUT /admin/news-ticker/:id` - Update item
- ✅ `DELETE /admin/news-ticker/:id` - Delete item
- ✅ Firebase Firestore integration
- ✅ Admin authentication required
- ✅ CSRF protection

---

## 🚀 Deployment Steps

### 1. Build Admin Dashboard

```powershell
cd admin_flutter

# Build for web deployment
flutter build web --release

# Output will be in: admin_flutter/build/web/
```

### 2. Deploy to Server

Copy the built admin dashboard to your server's public directory:

```powershell
# From project root
Copy-Item -Path "admin_flutter\build\web\*" -Destination "server\public\admin\build\" -Recurse -Force
```

### 3. Update Server on AWS ECS

If you're using Docker/ECS:

```powershell
# Navigate to server directory
cd server

# Build Docker image
docker build -t shopsnports-server:latest .

# Tag for AWS ECR
docker tag shopsnports-server:latest YOUR_AWS_ACCOUNT.dkr.ecr.REGION.amazonaws.com/shopsnports-server:latest

# Push to ECR
docker push YOUR_AWS_ACCOUNT.dkr.ecr.REGION.amazonaws.com/shopsnports-server:latest

# Update ECS service
aws ecs update-service --cluster shopsnports-cluster --service shopsnports-service --force-new-deployment
```

Or using your existing deployment script:

```powershell
cd server
.\push-secrets-to-aws.ps1
# OR
.\deploy-to-ecs.ps1
```

### 4. Verify Firebase Configuration

Ensure your server has Firebase Admin SDK credentials:

```javascript
// server/index.js or server/firebaseAuth.js should have:
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
```

### 5. Test the Integration

#### A. Test Admin Dashboard

1. Navigate to: `https://your-domain.com/admin/ui`
2. Login with admin credentials
3. Click "News Ticker" in navigation
4. Try adding a test news item:
   ```
   Text: 🎉 Welcome to ShopsNports!
   Priority: 10
   Active: ✓
   ```
5. Verify it appears in the list

#### B. Test Mobile App

1. Open the mobile app
2. Check home screen - news ticker should appear at top
3. Verify the test message scrolls
4. Navigate to other screens - ticker should persist

#### C. Test Real-time Updates

1. Keep mobile app open
2. In admin dashboard, add/update news item
3. Within 1-2 seconds, changes should appear in mobile app
4. No app refresh needed!

---

## 📋 Firestore Security Rules

Add these rules to your Firestore:

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // News ticker - public read, admin write
    match /news_ticker/{tickerId} {
      allow read: if true;  // Anyone can read
      allow create, update, delete: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

Deploy rules:

```powershell
firebase deploy --only firestore:rules
```

---

## 🧪 Testing Checklist

### Admin Dashboard
- [ ] Login works
- [ ] News Ticker page loads
- [ ] Can create news item
- [ ] Can edit news item
- [ ] Can toggle active/inactive
- [ ] Can delete news item
- [ ] Form validation works
- [ ] Error messages display
- [ ] List updates after operations

### Mobile App
- [ ] News ticker appears on Home
- [ ] News ticker appears on Products
- [ ] News ticker appears on Search
- [ ] News ticker appears on Orders
- [ ] News ticker appears on Cart
- [ ] News ticker appears on Profile
- [ ] Ticker scrolls smoothly
- [ ] Multiple items loop correctly
- [ ] Real-time updates work

### Backend API
- [ ] GET /admin/news-ticker returns items
- [ ] POST /admin/news-ticker creates item
- [ ] PUT /admin/news-ticker/:id updates item
- [ ] DELETE /admin/news-ticker/:id deletes item
- [ ] Requires authentication
- [ ] CSRF protection works
- [ ] Validation works

---

## 🔧 Troubleshooting

### Admin Dashboard Issues

**News Ticker page not loading:**
- Check browser console for errors
- Verify Firebase Admin SDK is initialized
- Check network tab for failed API calls

**API returns 401 Unauthorized:**
- Ensure you're logged in
- Check session cookies
- Verify ADMIN_API_KEY if using

**API returns 500 Error:**
- Check server logs
- Verify Firebase credentials
- Ensure Firestore is enabled

### Mobile App Issues

**News ticker not showing:**
- Check Firestore rules allow public read
- Verify at least one item has `isActive: true`
- Check app console for errors

**No real-time updates:**
- Verify internet connection
- Check Firebase configuration
- Restart the app

**Items not in correct order:**
- Check priority values (higher = first)
- Verify createdAt timestamps
- Ensure Firestore index is created

---

## 📊 Monitoring

### Check News Items Count

```javascript
// In Firestore Console
SELECT COUNT(*) FROM news_ticker WHERE isActive = true
```

### View Recent Changes

```javascript
// Query by creation date
SELECT * FROM news_ticker ORDER BY createdAt DESC LIMIT 10
```

### Analytics (Future Enhancement)

Track news ticker engagement:
- Click-through rate on links
- View duration
- User interactions

---

## 🎯 Quick Commands

### Build Admin Dashboard
```powershell
cd admin_flutter
flutter build web --release
```

### Deploy to Server (Local)
```powershell
Copy-Item -Path "admin_flutter\build\web\*" -Destination "server\public\admin\build\" -Recurse -Force
```

### Restart Server (Local)
```powershell
cd server
npm run dev
# OR
node index.js
```

### View Logs
```powershell
# AWS ECS
aws logs tail /ecs/shopsnports-server --follow

# Local
Get-Content server.log -Wait
```

---

## ✅ Deployment Complete!

Your news ticker is now:
- ✅ Manageable from admin dashboard
- ✅ Visible on mobile app
- ✅ Updated in real-time
- ✅ Deployed to AWS ECS

**Next Steps:**
1. Add initial news items
2. Test on production
3. Monitor engagement
4. Iterate based on feedback

---

**Created:** December 23, 2025  
**Status:** Ready for deployment 🚀
