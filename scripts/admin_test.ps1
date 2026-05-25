# Headless admin test: login, fetch csrf, approve vendor
$ErrorActionPreference = 'Stop'
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$loginBody = @{ username='admin@example.com'; password='adminpass' } | ConvertTo-Json
try {
  $login = Invoke-WebRequest -Uri 'http://localhost:3000/admin/login' -Method Post -Body $loginBody -ContentType 'application/json' -WebSession $session -TimeoutSec 10
  Write-Host "LOGIN_STATUS: $($login.StatusCode)"
} catch {
  Write-Host "LOGIN FAILED: $($_.Exception.Message)"
  exit 2
}

try {
  $csrfResp = Invoke-WebRequest -Uri 'http://localhost:3000/admin/csrf-token' -Method Get -WebSession $session -TimeoutSec 10
  Write-Host "CSRF_BODY: $($csrfResp.Content)"
  $token = ($csrfResp.Content | ConvertFrom-Json).csrfToken
  Write-Host "TOKEN: $token"
} catch {
  Write-Host "CSRF FETCH FAILED: $($_.Exception.Message)"
  exit 3
}

try {
  $approve = Invoke-WebRequest -Uri 'http://localhost:3000/admin/vendors/11/approve' -Method Post -WebSession $session -Headers @{ 'X-CSRF-Token' = $token } -ContentType 'application/json' -TimeoutSec 10
  Write-Host "APPROVE_STATUS: $($approve.StatusCode)"
  Write-Host "APPROVE_BODY: $($approve.Content)"
} catch {
  Write-Host "APPROVE FAILED: $($_.Exception.Message)"
  try { $body = ($_.Exception.Response | Select-Object -ExpandProperty Content); Write-Host "RESPONSE_BODY: $body" } catch { }
  exit 4
}

# Tail server log
Write-Host "\n--- server.log tail ---"
try {
  Get-Content -Path 'C:\projects\shopsnports\server.log' -Tail 100 | ForEach-Object { Write-Host $_ }
} catch { Write-Host 'No server.log found or cannot read it' }

Write-Host "\nTest complete"
