# ShopsNSports API Test Script
# Quick health check and API endpoint testing

param(
    [string]$BaseUrl = "http://localhost:3000"
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "ShopsNSports API Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host ""

$testResults = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [string]$Body = $null
    )
    
    Write-Host "Testing: $Name" -NoNewline
    
    try {
        $params = @{
            Uri = "$BaseUrl$Url"
            Method = $Method
            UseBasicParsing = $true
            TimeoutSec = 5
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params['Body'] = $Body
            $params['ContentType'] = 'application/json'
        }
        
        $response = Invoke-WebRequest @params
        
        if ($response.StatusCode -eq 200) {
            Write-Host " ✓ PASS (200 OK)" -ForegroundColor Green
            return $true
        } else {
            Write-Host " ⚠ WARNING (Status: $($response.StatusCode))" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host " ✗ FAIL" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "Running API Tests..." -ForegroundColor Cyan
Write-Host "-----------------------------------" -ForegroundColor Cyan
Write-Host ""

# Test endpoints
$tests = @(
    @{ Name = "News Ticker"; Url = "/api/v1/news-ticker" }
    @{ Name = "Affiliates"; Url = "/api/v1/affiliates" }
    @{ Name = "Categories"; Url = "/api/v1/categories" }
    @{ Name = "Users"; Url = "/api/v1/users" }
    @{ Name = "Vendors"; Url = "/api/v1/vendors" }
    @{ Name = "Shipping"; Url = "/api/v1/shipping" }
    @{ Name = "Reviews"; Url = "/api/v1/reviews" }
    @{ Name = "Analytics"; Url = "/api/v1/analytics" }
    @{ Name = "Notifications"; Url = "/api/v1/notifications" }
)

$passCount = 0
$failCount = 0

foreach ($test in $tests) {
    if (Test-Endpoint -Name $test.Name -Url $test.Url) {
        $passCount++
    } else {
        $failCount++
    }
    Start-Sleep -Milliseconds 200
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "Total:  $($passCount + $failCount)" -ForegroundColor Cyan
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
} else {
    Write-Host "⚠ Some tests failed. Check server logs." -ForegroundColor Yellow
}
