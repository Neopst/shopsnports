Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Firestore Index Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Deploy indexes
Write-Host "📤 Deploying Firestore indexes..." -ForegroundColor Yellow
firebase deploy --only firestore:indexes

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ SUCCESS: Indexes deployed!" -ForegroundColor Green
    Write-Host "`n📋 Deployed indexes for shippingRequests:" -ForegroundColor Cyan
    Write-Host "   1. status + createdAt (for status filtering)" -ForegroundColor White
    Write-Host "   2. type + createdAt (for air/sea filtering)" -ForegroundColor White
    Write-Host "`n⏱️  Index Building:" -ForegroundColor Yellow
    Write-Host "   Firestore is building the indexes (1-3 minutes)" -ForegroundColor White
    Write-Host "   Check progress: https://console.firebase.google.com/project/_/firestore/indexes`n" -ForegroundColor White
    Write-Host "🔄 After indexes are ready, hot reload your dashboard!" -ForegroundColor Green
} else {
    Write-Host "`n❌ ERROR: Index deployment failed!" -ForegroundColor Red
    Write-Host "Check the error message above.`n" -ForegroundColor Yellow
}
