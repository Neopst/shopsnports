# Interactive script to collect payment provider keys and write server/.env
# Usage: Open PowerShell, cd to the repo (optional), then run:
#   powershell -ExecutionPolicy Bypass -File .\server\setup-keys.ps1

# This script will:
# - Back up existing server/.env to server/.env.bak.TIMESTAMP if present
# - Prompt you to paste keys for Stripe, Paystack and Flutterwave
# - For each pasted key it asks whether it's a publishable/public key or a secret key
# - Update (or create) server/.env preserving other existing variables
# - Optionally start the Node example server (node index.js) after writing .env

Set-StrictMode -Version Latest

function MaskKey($k) {
    if ([string]::IsNullOrEmpty($k)) { return '<empty>' }
    if ($k.Length -le 12) { return $k }
    return $k.Substring(0,6) + '...' + $k.Substring($k.Length - 4)
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envPath = Join-Path $scriptDir '.env'

Write-Host "Setting up payment provider keys for the example server (path: $envPath)" -ForegroundColor Cyan

# Back up existing .env if present
if (Test-Path $envPath) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $bak = "$envPath.bak.$ts"
    Copy-Item -Path $envPath -Destination $bak -Force
    Write-Host "Backed up existing .env to: $bak" -ForegroundColor Yellow
}

# Read existing .env into a dictionary to preserve unrelated values
$existing = @{}
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^[ \t]*#') { return }
        if ($_ -match '^[ \t]*$') { return }
        if ($_ -match '^(?:\s*)([^=\s]+)=(.*)$') {
            $k = $matches[1]
            $v = $matches[2]
            $existing[$k] = $v
        }
    }
}

# Helper to ask for a key and type
function AskKey($providerFriendly, $envSecretName, $envPublishName) {
    Write-Host "\n--- $providerFriendly ---" -ForegroundColor Green
    $raw = Read-Host "Paste the key now (or press Enter to skip)"
    if ([string]::IsNullOrEmpty($raw)) {
        Write-Host "Skipping $providerFriendly (no key provided)." -ForegroundColor DarkYellow
        return
    }

    while ($true) {
        $type = Read-Host "Is this a 'publishable/public' key or a 'secret' key? Enter p for publishable/public or s for secret"
        switch ($type.ToLower()) {
            'p' { $existing[$envPublishName] = $raw; Write-Host "Set $envPublishName = $(MaskKey $raw)"; break }
            'publishable' { $existing[$envPublishName] = $raw; Write-Host "Set $envPublishName = $(MaskKey $raw)"; break }
            'public' { $existing[$envPublishName] = $raw; Write-Host "Set $envPublishName = $(MaskKey $raw)"; break }
            's' { $existing[$envSecretName] = $raw; Write-Host "Set $envSecretName = $(MaskKey $raw)"; break }
            'secret' { $existing[$envSecretName] = $raw; Write-Host "Set $envSecretName = $(MaskKey $raw)"; break }
            default { Write-Host "Please type 'p' (publishable/public) or 's' (secret)." -ForegroundColor Red }
        }
        if ($existing.ContainsKey($envSecretName) -or $existing.ContainsKey($envPublishName)) { break }
    }
}

# Collect provider keys
AskKey 'Stripe' 'STRIPE_SECRET_KEY' 'STRIPE_PUBLISHABLE_KEY'
AskKey 'Paystack' 'PAYSTACK_SECRET_KEY' 'PAYSTACK_PUBLIC_KEY'
AskKey 'Flutterwave' 'FLUTTERWAVE_SECRET_KEY' 'FLUTTERWAVE_PUBLIC_KEY'

# Ask about Paystack allow client secret flag (useful for local dev)
while ($true) {
    $ans = Read-Host "Allow Paystack client secret to be returned to client? (recommended: false). Enter y or n (press Enter for n)"
    if ([string]::IsNullOrEmpty($ans)) { $existing['PAYSTACK_ALLOW_CLIENT_SECRET'] = 'false'; break }
    $low = $ans.ToLower()
    if ($low -in @('y','yes')) {
        $existing['PAYSTACK_ALLOW_CLIENT_SECRET'] = 'true'
        break
    } elseif ($low -in @('n','no')) {
        $existing['PAYSTACK_ALLOW_CLIENT_SECRET'] = 'false'
        break
    } else {
        Write-Host "Please enter y or n." -ForegroundColor Red
    }
}

# Ensure PORT exists (default 3000)
if (-not $existing.ContainsKey('PORT')) { $existing['PORT'] = '3000' }

# Write the .env file
Write-Host "\nWriting .env to $envPath" -ForegroundColor Cyan
$lines = @()
# Maintain common ordering for readability
$orderedKeys = @('PORT','STRIPE_SECRET_KEY','STRIPE_PUBLISHABLE_KEY','PAYSTACK_SECRET_KEY','PAYSTACK_PUBLIC_KEY','PAYSTACK_ALLOW_CLIENT_SECRET','FLUTTERWAVE_SECRET_KEY','FLUTTERWAVE_PUBLIC_KEY')
foreach ($k in $orderedKeys) {
    if ($existing.ContainsKey($k)) { $lines += "$k=$($existing[$k])" }
}
# Add any other keys that weren't in the ordered list
foreach ($k in $existing.Keys | Sort-Object) {
    if ($orderedKeys -notcontains $k) { $lines += "$k=$($existing[$k])" }
}

Set-Content -Path $envPath -Value $lines -Encoding UTF8
Write-Host "Done. .env written. (Don't commit this file to source control)" -ForegroundColor Green

# Summary (masked)
Write-Host "\nSummary of keys saved (masked):" -ForegroundColor Cyan
foreach ($k in $orderedKeys) {
    if ($existing.ContainsKey($k)) { Write-Host "$k = $(MaskKey $existing[$k])" }
}

# Offer to start the server
$start = Read-Host "Would you like to start the Node example server now? (y/N)"
if ($start -and $start.ToLower() -in @('y','yes')) {
    # Check for node presence
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        Write-Host "Node.js not found in PATH. Please install Node or start the server manually: cd $scriptDir; node index.js" -ForegroundColor Red
    } else {
        Write-Host "Starting server in: $scriptDir" -ForegroundColor Cyan
        Push-Location $scriptDir
        try {
            # Run node index.js in the current console so the user can see logs
            & node index.js
        } catch {
            Write-Host "Server failed to start: $_" -ForegroundColor Red
        } finally {
            Pop-Location
        }
    }
} else {
    Write-Host "Skipping server start. To start later: cd $scriptDir; node index.js" -ForegroundColor Yellow
}

Write-Host "All done. If you need me to proceed to verifying endpoints (/create-payment-intent, /paystack/initialize etc.), say 'verify server' and I'll guide the next steps." -ForegroundColor Green
