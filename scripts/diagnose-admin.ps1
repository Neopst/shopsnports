# Diagnostic script for Shopsnports admin UI
# Writes output to scripts/diagnostics-admin-latest.txt and a timestamped copy

$now = Get-Date -Format "yyyyMMdd-HHmmss"
$outdir = Join-Path $PSScriptRoot ""
$report = Join-Path $PSScriptRoot "diagnostics-admin-latest.txt"
$reportTs = Join-Path $PSScriptRoot "diagnostics-admin-$now.txt"

function Write-Report {
    param($s)
    $s | Out-File -FilePath $report -Append -Encoding utf8
    $s | Out-File -FilePath $reportTs -Append -Encoding utf8
}

# start fresh
if (Test-Path $report) { Remove-Item $report -Force }

"Shopsnports Admin Diagnostics - $now" | Out-File $report -Encoding utf8
"" | Out-File $report -Append -Encoding utf8

Write-Report "Environment"
Write-Report "PWD: $PWD"
Write-Report "Node version: $(node --version 2>$null)"
Write-Report "NPM version: $(npm --version 2>$null)"
Write-Report "PowerShell: $($PSVersionTable.PSVersion)"
Write-Report ""

Write-Report "Listening ports (netstat)"
try {
    $net = netstat -ano | Select-String ":3000|:3001" -SimpleMatch
    if ($net) { $net | ForEach-Object { Write-Report $_.ToString() } } else { Write-Report "No listeners found on :3000 or :3001" }
} catch { Write-Report "netstat failed: $($_.Exception.Message)" }
Write-Report ""

Write-Report "Node processes (node.exe)"
try { Get-Process node -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, StartTime | ForEach-Object { Write-Report ("PID: {0}  Name: {1}  Start: {2}" -f $_.Id, $_.ProcessName, $_.StartTime) } } catch { Write-Report "Get-Process failed: $($_.Exception.Message)" }
Write-Report ""

# HTTP checks
$hosts = @("http://localhost:3000","http://localhost:3001")
foreach ($h in $hosts) {
    Write-Report "Checking $h/admin and assets"
    try {
        $resp = Invoke-WebRequest -Uri "$h/admin" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Report "$h/admin -> Status: $($resp.StatusCode)"
        Write-Report "Headers:"; $resp.Headers.GetEnumerator() | ForEach-Object { Write-Report "  $($_.Key): $($_.Value)" }
    } catch { Write-Report "$h/admin -> request failed: $($_.Exception.Message)" }

    $assets = @("/admin/ui/build/index.html","/admin/ui/build/main.dart.js","/admin/ui/build/main.dart.v20251021.js","/admin/ui/build/flutter_service_worker.js","/admin/ui/build/version.json")
    foreach ($a in $assets) {
        $url = $h + $a
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            Write-Report "$url -> $($r.StatusCode)  Length: $($r.Headers['Content-Length'])"
        } catch { Write-Report "$url -> failed: $($_.Exception.Message)" }
    }
    Write-Report ""
}

# local file checks
$buildDir = Join-Path $PSScriptRoot "..\server\public\admin\build"
Write-Report "Build dir: $buildDir"
if (Test-Path $buildDir) {
    Get-ChildItem -Path $buildDir -File -Recurse | Sort-Object Length -Descending | Select-Object FullName, Length, LastWriteTime | ForEach-Object { Write-Report ("{0}  {1} bytes  modified: {2}" -f $_.FullName, $_.Length, $_.LastWriteTime) }

    # grep for localhost occurrences in main.dart.js
    $main = Join-Path $buildDir "main.dart.js"
    if (Test-Path $main) {
        Write-Report "\nSearching main.dart.js for 'localhost' occurrences (first 20 lines):"
        Select-String -Path $main -Pattern "localhost|http://|https://" -AllMatches | Select-Object -First 20 | ForEach-Object { Write-Report $_.Line }
    } else { Write-Report "main.dart.js not found" }

    $sw = Join-Path $buildDir "flutter_service_worker.js"
    if (Test-Path $sw) { Write-Report "\nService worker contents (first 200 lines):"; Get-Content $sw -TotalCount 200 | ForEach-Object { Write-Report $_ } } else { Write-Report "flutter_service_worker.js not found" }

    $index = Join-Path $buildDir "index.html"
    if (Test-Path $index) { Write-Report "\nindex.html contents (first 200 lines):"; Get-Content $index -TotalCount 200 | ForEach-Object { Write-Report $_ } } else { Write-Report "index.html not found" }
} else { Write-Report "Build dir not found on disk" }

# Check server logs file (if exists)
$logFile = Join-Path $PSScriptRoot "..\server\server.log"
if (Test-Path $logFile) { Write-Report "\nLast 200 lines of server.log:"; Get-Content $logFile -Tail 200 | ForEach-Object { Write-Report $_ } } else { Write-Report "server.log not present" }

Write-Report "\nDiagnostics complete."

Write-Output "Wrote diagnostics to: $report and $reportTs"
