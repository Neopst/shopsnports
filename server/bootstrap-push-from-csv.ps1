<#
bootstrap-push-from-csv.ps1

Moves the downloaded AWS credentials CSV into a secure folder, reads the Access Key ID and Secret Access Key,
sets them as environment variables for the current script session, runs the prepared push-secrets-to-aws.ps1
in dry-run mode, and optionally executes the real push.

Usage (from project root):
  cd C:\projects\shopsnports\server
  .\bootstrap-push-from-csv.ps1 -CsvPath "$env:USERPROFILE\Downloads\shopsnports-deployer_accessKeys.csv"

Options:
  -CsvPath    Path to the downloaded CSV (defaults to Downloads/shopsnports-deployer_accessKeys.csv)
  -DestDir    Destination secure directory (defaults to %USERPROFILE%\secure-keys\shopsnports)
  -Stage      Secrets stage prefix (default: production)
  -NoDelete   Do not delete the CSV after a successful push
  -Verbose
#>
param(
  [string]$CsvPath = "$env:USERPROFILE\Downloads\shopsnports-deployer_accessKeys.csv",
  [string]$DestDir = "$env:USERPROFILE\secure-keys\shopsnports",
  [string]$Stage = "production",
  [switch]$NoDelete
)

Set-StrictMode -Version Latest

function Fail([string]$msg){ Write-Error $msg; exit 2 }

Write-Host "Bootstrap script started"
Write-Host "CsvPath: $CsvPath"
Write-Host "DestDir: $DestDir"

if (-not (Test-Path $CsvPath)) { Fail "CSV not found at path: $CsvPath" }

# Ensure dest dir exists
if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Force -Path $DestDir | Out-Null; Write-Host "Created dest dir: $DestDir" }

# Move the file into the dest dir (do not overwrite without prompt)
$destFile = Join-Path $DestDir ([IO.Path]::GetFileName($CsvPath))
try {
  Move-Item -Path $CsvPath -Destination $destFile -Force
  Write-Host "Moved CSV to: $destFile"
} catch {
  Fail "Failed to move CSV: $_"
}

# Import CSV and extract keys. AWS CSV header typically contains: "Access key ID","Secret access key"
try {
  # Force array context so single-row CSVs still have a Count property
  $rows = @(Import-Csv -Path $destFile -ErrorAction Stop)
} catch {
  Fail "Failed to parse CSV file as CSV: $_"
}

if ($rows.Count -lt 1) { Fail "CSV appeared empty or had no rows" }

# Look for common header names (case-insensitive)
$first = $rows[0]
$props = $first.psobject.Properties.Name | ForEach-Object { $_.ToString() }

# helper to find prop by name variants
function Get-PropValue([psobject]$row, [string[]]$candidates){
  foreach ($c in $candidates) {
    $match = $props | Where-Object { $_.ToLower() -eq $c.ToLower() }
    if ($match) { return $row."$match" }
  }
  return $null
}

$ak = Get-PropValue $first @('Access key ID','AccessKeyId','Access Key ID','Access key id','access key id')
$sk = Get-PropValue $first @('Secret access key','SecretAccessKey','Secret Access Key','secret access key')

# Fallback: try first two columns
if (-not $ak -or -not $sk) {
  $vals = $first.psobject.Properties | Select-Object -First 2 | ForEach-Object { $_.Value }
  if ($vals.Count -ge 2) {
    if (-not $ak) { $ak = $vals[0] }
    if (-not $sk) { $sk = $vals[1] }
  }
}

if (-not $ak -or -not $sk) {
  Fail "Could not locate Access Key ID and Secret Access Key in CSV. Found columns: $($props -join ', ')"
}

# Set env vars for this process (do not print values)
$env:AWS_ACCESS_KEY_ID = $ak
$env:AWS_SECRET_ACCESS_KEY = $sk
if (-not $env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION = 'us-east-1' }

Write-Host "AWS env vars set in this script session (values not displayed)."

# Run the dry-run of the push script (must exist next to this script)
$pushScript = Join-Path $PSScriptRoot 'push-secrets-to-aws.ps1'
if (-not (Test-Path $pushScript)) { Fail "Missing push script at $pushScript" }

Write-Host "Running dry-run of push script..."

# Capture output and check success via $?
try {
  $dryRunResult = & $pushScript -Stage $Stage -DryRun 2>&1
  if (-not $?) {
    Write-Host $dryRunResult
    Fail "Dry-run failed. See output above."
  }
} catch {
  Fail "Dry-run encountered an error: $_"
}

# Show dry-run output (it should list the secrets). Do NOT echo secret values because push script does not print them.
Write-Host "---- Dry-run output (below) ----"
Write-Host $dryRunResult
Write-Host "---- end dry-run ----"

# Ask for confirmation
$confirm = Read-Host "Proceed to create/update these secrets in AWS Secrets Manager? Type Y to proceed"
if ($confirm.Trim().ToUpper() -ne 'Y') {
  Write-Host "Operation cancelled by user. The CSV remains at: $destFile"
  Write-Host "Remember to rotate/delete the access key after use if you will not reuse it."
  exit 0
}

# Execute the real push
Write-Host "Running real push... (this will create or update secrets in AWS Secrets Manager)"
try {
  $pushResult = & $pushScript -Stage $Stage 2>&1
  if (-not $?) {
    Write-Host $pushResult
    Fail "Push failed. See output above."
  }
} catch {
  Fail "Push encountered an error: $_"
}

Write-Host "Push completed successfully. Output:" 
Write-Host $pushResult

if (-not $NoDelete) {
  try {
    Remove-Item -Path $destFile -Force
    Write-Host "Removed CSV from disk: $destFile"
  } catch {
    Write-Warning "Failed to delete CSV: $_"
  }
} else {
  Write-Host "CSV preserved at: $destFile (NoDelete set)"
}

Write-Host "IMPORTANT: Rotate or delete the bootstrap access key now in IAM to avoid leaving long-lived credentials."
Write-Host "Done."
