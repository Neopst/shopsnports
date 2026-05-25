# Interactive key insertion helper
# Usage: powershell -ExecutionPolicy Bypass -File .\server\insert-key.ps1
# This script will prompt which key you want to paste, ask whether it's a secret or publishable/public
# and insert it into the appropriate file: server/.env or lib/main.dart (for Stripe publishable key).
# The script backs up any file it modifies before writing.

Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition | Split-Path -Parent
$envPath = Join-Path $repoRoot 'server\.env'
$mainPath = Join-Path $repoRoot 'lib\main.dart'

function Backup-File($path) {
    if (Test-Path $path) {
        $ts = Get-Date -Format "yyyyMMdd-HHmmss"
        $bak = "$path.bak.$ts"
        Copy-Item -Path $path -Destination $bak -Force
        Write-Host "Backed up $path -> $bak" -ForegroundColor Yellow
    }
}

function Write-EnvKey($keyName, $value) {
    Backup-File $envPath
    $lines = @()
    if (Test-Path $envPath) {
        $lines = Get-Content $envPath
        $found = $false
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match "^$keyName=") {
                $lines[$i] = "$keyName=$value"
                $found = $true
                break
            }
        }
        if (-not $found) { $lines += "$keyName=$value" }
    } else {
        $lines = ("$keyName=$value")
    }
    Set-Content -Path $envPath -Value $lines -Encoding UTF8
    Write-Host "Wrote $keyName to $envPath (masked): $(if ($value.Length -gt 12) { $value.Substring(0,6) + '...' + $value.Substring($value.Length-4) } else { $value })"
}

function Insert-StripePublishable($value) {
    # Insert stripe.Stripe.publishableKey = 'pk_...' at the top of main.dart after Firebase.init but before runApp
    if (-not (Test-Path $mainPath)) { Write-Host "$mainPath not found" -ForegroundColor Red; return }
    Backup-File $mainPath
    $content = Get-Content $mainPath -Raw
    # Look for a good insertion point: after Firebase.initializeApp();
    $pattern = "await Firebase.initializeApp\(\);"
    if ($content -match $pattern) {
        $replacement = "$&\n  // Stripe publishable key inserted by insert-key.ps1 for local testing\n  stripe.Stripe.publishableKey = '$value';"
        $new = $content -replace $pattern, $replacement
        Set-Content -Path $mainPath -Value $new -Encoding UTF8
        Write-Host "Inserted publishable key into $mainPath (masked): $($value.Substring(0,6) + '...' + $value.Substring($value.Length-4))"
    } else {
        Write-Host "Could not find Firebase.initializeApp() insertion point in $mainPath. Opening file for manual edit." -ForegroundColor Yellow
    }
}

Write-Host "Which provider key would you like to insert? (1) Stripe (publishable), (2) Stripe (secret -> server/.env), (3) Paystack public, (4) Paystack secret, (5) Flutterwave public, (6) Flutterwave secret" -ForegroundColor Cyan
$choice = Read-Host "Enter the number (1-6)"
switch ($choice) {
    '1' { $keyLabel='Stripe publishable (pk_)'; $target='stripe_pub'; break }
    '2' { $keyLabel='Stripe secret (sk_)'; $target='env'; $envKey='STRIPE_SECRET_KEY'; break }
    '3' { $keyLabel='Paystack public (pk_)'; $target='env'; $envKey='PAYSTACK_PUBLIC_KEY'; break }
    '4' { $keyLabel='Paystack secret (sk_)'; $target='env'; $envKey='PAYSTACK_SECRET_KEY'; break }
    '5' { $keyLabel='Flutterwave public (FLWPUBK_)'; $target='env'; $envKey='FLUTTERWAVE_PUBLIC_KEY'; break }
    '6' { $keyLabel='Flutterwave secret (FLWSEC_)'; $target='env'; $envKey='FLUTTERWAVE_SECRET_KEY'; break }
    default { Write-Host "Invalid choice" -ForegroundColor Red; exit 1 }
}

Write-Host "Paste the $keyLabel now and press Enter:" -ForegroundColor Green
$key = Read-Host
if ([string]::IsNullOrEmpty($key)) { Write-Host "No key provided, exiting."; exit 0 }

if ($target -eq 'env') {
    Write-EnvKey $envKey $key
} elseif ($target -eq 'stripe_pub') {
    # Ensure flutter_stripe import exists
    # Add import if missing: import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
    $main = Get-Content $mainPath -Raw
    if ($main -notmatch "package:flutter_stripe") {
        # Insert the import near other imports
        $main = $main -replace "(import .*;\n)(?=import )", "`$1"
        # naive append of import at top
        $main = $main -replace "(import .*;\n)(\n)", "`$1import 'package:flutter_stripe/flutter_stripe.dart' as stripe;`$2"
        Set-Content -Path $mainPath -Value $main -Encoding UTF8
        Write-Host "Added flutter_stripe import to $mainPath" -ForegroundColor Yellow
    }
    Insert-StripePublishable $key
}

Write-Host "Done. If you edited app code, run a full rebuild: flutter clean; flutter pub get; flutter run" -ForegroundColor Green
