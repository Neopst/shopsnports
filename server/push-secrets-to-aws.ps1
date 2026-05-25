# Push secrets from .env into AWS Secrets Manager
# Safe: this script does not print secret values. It creates/updates named secrets.
param(
  [string]$Stage = "production",
  [switch]$DryRun
)

$envPath = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envPath)) { Write-Error ".env not found at $envPath"; exit 2 }

Write-Host "Loading $envPath"
$lines = Get-Content $envPath | Where-Object { $_ -match '=' }
$kv = @{}
foreach ($l in $lines) {
  $parts = $l -split '=',2
  $k = $parts[0].Trim(); $v = $parts[1].Trim()
  $kv[$k] = $v
}

# Gather secrets to push
$secretsToPush = @{}
function AddSecret($name, $value) {
  if (-not $value) { return }
  if ($value -match '^Enter') { return } # skip placeholders
  $secretsToPush[$name] = $value
}

AddSecret "stripe/secret_key" $kv['STRIPE_SECRET_KEY']
AddSecret "stripe/publishable_key" $kv['STRIPE_PUBLISHABLE_KEY']
AddSecret "stripe/webhook_secret" $kv['STRIPE_WEBHOOK_SECRET']
AddSecret "paystack/secret_key" $kv['PAYSTACK_SECRET_KEY']
AddSecret "paystack/public_key" $kv['PAYSTACK_PUBLIC_KEY']
AddSecret "flutterwave/secret_key" $kv['FLUTTERWAVE_SECRET_KEY']
AddSecret "flutterwave/public_key" $kv['FLUTTERWAVE_PUBLIC_KEY']

# DB password (read from file if set)
if ($kv['APP_DB_PASSWORD_FILE']) {
  $dbpwpath = Join-Path $PSScriptRoot $kv['APP_DB_PASSWORD_FILE']
  if (Test-Path $dbpwpath) {
    $dbpw = (Get-Content $dbpwpath -ErrorAction Stop) -join "`n"
    AddSecret "db/app_user_password" $dbpw
  } else {
    Write-Warning "APP_DB_PASSWORD_FILE set but file not found: $dbpwpath"
  }
}

if ($secretsToPush.Count -eq 0) { Write-Host "No secrets to push (placeholders skipped)."; exit 0 }

# Check AWS CLI
try { $awsVer = & aws --version 2>&1; Write-Host "AWS CLI: $awsVer" } catch { Write-Error "AWS CLI not available in PATH"; exit 4 }

foreach ($k in $secretsToPush.Keys) {
  $fullName = "shopsnports/$Stage/$k"
  Write-Host "Processing: $fullName"
  if ($DryRun) { continue }

  # Use aws secretsmanager to create or update
  try {
    # Try to describe first
    & aws secretsmanager describe-secret --secret-id $fullName 2>$null
    if ($LASTEXITCODE -eq 0) {
      Write-Host "Updating secret: $fullName"
      $tmpFile = [System.IO.Path]::GetTempFileName()
      Set-Content -Path $tmpFile -Value $secretsToPush[$k] -NoNewline -Encoding UTF8
      & aws secretsmanager put-secret-value --secret-id $fullName --secret-binary fileb://$tmpFile | Out-Null
      Remove-Item $tmpFile -Force
    } else {
      Write-Host "Creating secret: $fullName"
      $tmpFile = [System.IO.Path]::GetTempFileName()
      Set-Content -Path $tmpFile -Value $secretsToPush[$k] -NoNewline -Encoding UTF8
      & aws secretsmanager create-secret --name $fullName --secret-binary fileb://$tmpFile | Out-Null
      Remove-Item $tmpFile -Force
    }
    Write-Host "OK: $fullName"
  } catch {
    $msg = $_.Exception.Message
    # Use ${} to avoid parser confusion with ':' in messages
    Write-Error ("Failed to create/update ${fullName}: {0}" -f $msg)
  }
}

Write-Host "Done."
