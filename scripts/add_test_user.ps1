# Get user UID and add to Firestore
Write-Host "Getting user UID from Firebase..." -ForegroundColor Cyan

# Export users to get UID
firebase auth:export users_temp.json --format=JSON 2>&1 | Out-Null

if (Test-Path users_temp.json) {
    $users = Get-Content users_temp.json | ConvertFrom-Json
    $testUser = $users.users | Where-Object { $_.email -eq "tester@shopsnports.com" } | Select-Object -First 1
    
    if ($testUser) {
        $uid = $testUser.localId
        Write-Host "Found user UID: $uid" -ForegroundColor Green
        
        # Create Firestore document using Firebase CLI
        $userData = @{
            id = $uid
            email = "tester@shopsnports.com"
            name = "Test User"
            roles = @("customer", "vendor", "affiliate", "shipper")
            activeRole = "vendor"
            isAdmin = $true
            affiliateApproved = $true
        } | ConvertTo-Json
        
        Write-Host "Adding user to Firestore..." -ForegroundColor Cyan
        Write-Host "Please manually add this to Firestore Console:" -ForegroundColor Yellow
        Write-Host "Collection: users" -ForegroundColor Yellow
        Write-Host "Document ID: $uid" -ForegroundColor Yellow
        Write-Host "Data:" -ForegroundColor Yellow
        Write-Host $userData -ForegroundColor White
        
    } else {
        Write-Host "User not found in Firebase Auth" -ForegroundColor Red
    }
    
    Remove-Item users_temp.json
} else {
    Write-Host "Could not export users from Firebase" -ForegroundColor Red
}
