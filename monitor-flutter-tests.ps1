param(
  [string]$FlutterArgs = "test",
  [int]$PollSeconds = 5
)

$root = Get-Location
$log = Join-Path $root "test.log"
$err = Join-Path $root "test.err"

# clean previous logs
If (Test-Path $log) { Remove-Item $log -Force }
If (Test-Path $err) { Remove-Item $err -Force }

Write-Host "Resolving flutter executable..."
$flutterCmd = $null
try {
  $flutterCmd = (Get-Command flutter -ErrorAction Stop).Source
} catch {
  # ignore
}
if (-not $flutterCmd) {
  try {
    $whereOut = & where.exe flutter 2>$null
    if ($whereOut) { $flutterCmd = $whereOut -split "\r?\n" | Select-Object -First 1 }
  } catch {
    # ignore
  }
}

if (-not $flutterCmd) {
  Write-Error "flutter executable not found in PATH. Please ensure Flutter SDK is installed and 'flutter' is available from your shell."
  exit 1
}

Write-Host "Starting: $flutterCmd $FlutterArgs"

# Start flutter in a PowerShell child process and pipe output to Tee-Object so the log file
# can be read while flutter writes to it. We redirect stderr into stdout inside the child.
$psCommand = "& `$flutterCmd $FlutterArgs 2>&1 | Tee-Object -FilePath '`"$log`"'"
$proc = Start-Process -FilePath "powershell" -ArgumentList '-NoProfile','-Command',$psCommand -WindowStyle Hidden -PassThru


# small spinner state
$spinner = @("|","/","-","\\")
$spinIdx = 0

# Poll loop until process exits
$lastSize = 0
while (-not $proc.HasExited) {
  Start-Sleep -Seconds $PollSeconds

  if (Test-Path $log) {
    try {
      $info = Get-Item $log -ErrorAction Stop
      $size = $info.Length
      $mtime = $info.LastWriteTime
    } catch {
      $size = 0
      $mtime = Get-Date
    }

    if ($size -gt $lastSize) {
      $status = "active"
    } elseif ($size -eq $lastSize -and $size -gt 0) {
      $status = "idle"
    } else {
      $status = "no-output-yet"
    }

    # show last 8 lines for quick context
    $tail = ""
    try {
      $tailLines = Get-Content $log -Tail 8 -ErrorAction Stop
      $tail = ($tailLines -join "`n")
    } catch { $tail = "[no log content yet]" }

    $spin = $spinner[$spinIdx % $spinner.Length]; $spinIdx++
    Clear-Host
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] flutter test PID=$($proc.Id)  status=$status  size=${size}B  mtime=$mtime  $spin"
    Write-Host "---- last log lines ----"
    Write-Host $tail
    Write-Host "---- end ----"
    $lastSize = $size
  } else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] log file not created yet..."
  }
}

# Process exited — print final status and tail of logs
$proc.WaitForExit()
$exitCode = $proc.ExitCode
Write-Host "`nProcess finished. Exit code: $exitCode"

if (Test-Path $err) {
  $errText = Get-Content $err -Raw
  if ($errText.Trim().Length -gt 0) {
    Write-Host "`nStderr (first 2000 chars):"
    Write-Host $errText.Substring(0,[Math]::Min(2000,$errText.Length))
  }
}

if (Test-Path $log) {
  Write-Host "`nFinal tail of test.log:"
  Get-Content $log -Tail 50 | ForEach-Object { Write-Host $_ }
}
