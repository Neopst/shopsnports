# Deploy Firestore Indexes
Write-Host "🔄 Deploying Firestore indexes..." -ForegroundColor Cyan
firebase deploy --only firestore:indexes
Write-Host "✅ Indexes deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Index creation may take a few minutes." -ForegroundColor Yellow
Write-Host "Check Firebase Console to monitor index build progress." -ForegroundColor Yellow
