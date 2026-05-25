<# check-gh.ps1 - GH CLI health check (clean) #>

param(
  [string] $Repo
)

function Write-OK($msg){ Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Host "=== GH CLI health check ===`n"


# check-gh.ps1 - GH CLI health check (minimal, parse-safe)
param(
  [string] $Repo
)

function Write-OK($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

Write-Host "=== GH CLI health check ===`n"

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) { Write-Err "gh not found on PATH"; exit 2 }
$ghPath = $gh.Path
Write-OK "gh found: $ghPath"

# Version
$ver = (& "$ghPath" --version) 2>&1
if ($LASTEXITCODE -ne 0) { Write-Err "gh --version failed: $ver"; exit 3 }
Write-Host "gh --version:`n$ver`n"

# Auth
$auth = (& "$ghPath" auth status) 2>&1
if ($LASTEXITCODE -eq 0) { Write-OK "gh is authenticated"; Write-Host $auth } else { Write-Warn "gh not authenticated"; Write-Host $auth }

if ($Repo) {
  Write-Host "`nTesting repo secrets for: $Repo"
  $out = (& "$ghPath" secret list --repo $Repo) 2>&1
  if ($LASTEXITCODE -eq 0) { Write-OK "Able to list secrets"; Write-Host $out } else { Write-Warn "Cannot list secrets"; Write-Host $out }
}

Write-Host "`n=== done ==="

    Non-destructive: checks gh on PATH, prints version, auth status, and optionally
    attempts to list repo secrets to validate permissions.
  #>

  param(
    [string] $Repo
  )

  function Write-OK($msg){ Write-Host "[OK] $msg" -ForegroundColor Green }
  function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
  function Write-Err($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

  Write-Host "=== GH CLI health check ===`n"

  # Locate gh
  $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
  if (-not $ghCmd) {
    Write-Err "gh not found on PATH (Get-Command failed)."
    Write-Host "Install: winget install --id GitHub.cli -e --source winget or visit https://cli.github.com"
    exit 2
  }
  $ghPath = $ghCmd.Path
  Write-OK "gh found at: $ghPath"

  # PATH sanity
  $pathEntries = ($env:PATH -split ';') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
  $dir = Split-Path $ghPath
  if ($pathEntries -contains $dir) { Write-OK "gh directory is on PATH: $dir" } else { Write-Warn "gh directory ($dir) is NOT on PATH for other shells. Consider adding it to your user PATH." }

  # Version
  $versionRaw = (& "$ghPath" --version) 2>&1
  if ($LASTEXITCODE -ne 0) { Write-Err "Failed running 'gh --version'. Output: $versionRaw"; exit 3 }
  Write-Host "gh --version output:`n$versionRaw`n"
  if ($versionRaw -match 'gh version\s+([0-9]+)\.([0-9]+)\.([0-9]+)') {
    $major = [int]$matches[1]
    if ($major -lt 2) { Write-Warn "gh major version is $major - consider upgrading to gh 2.x+." } else { Write-OK "gh major version is $major." }
  } else { Write-Warn "Could not parse gh version; output above." }

  # Auth status
  Write-Host "Checking auth status..."
  $authOut = (& "$ghPath" auth status) 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-OK "gh reports an authenticated session."
    Write-Host $authOut
    $apiOut = (& "$ghPath" api user --jq '.login' 2>$null) 2>&1
    if ($LASTEXITCODE -eq 0 -and $apiOut) { Write-OK "Authenticated GitHub username: $apiOut" } else { Write-Warn "Could not query /user. gh may have limited scopes." }
  } else {
    Write-Warn "gh auth status failed or not logged in. Output:"; Write-Host $authOut; Write-Host "Run: gh auth login"
  }

  # Optional repo-level check
  if ($Repo) {
    Write-Host "`nTesting repo-level access for: $Repo"
    $listOut = (& "$ghPath" secret list --repo $Repo) 2>&1
    if ($LASTEXITCODE -eq 0) { Write-OK "Able to list secrets in $Repo."; Write-Host $listOut } else { Write-Warn "Failed to list secrets in $Repo. Output:"; Write-Host $listOut }
  } else { Write-Host "`nPass -Repo 'owner/repo' to test repo-level permissions." }

  Write-Host "`n=== done ==="