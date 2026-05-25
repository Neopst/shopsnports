param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectId
)

Write-Host "Deploying firestore indexes to project: $ProjectId"

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Error "Firebase CLI not found. Install from https://firebase.google.com/docs/cli"
  exit 2
}

$indexesFile = Join-Path (Get-Location) 'firestore.indexes.json'
if (-not (Test-Path $indexesFile)) {
  Write-Error "firestore.indexes.json not found in repository root."
  exit 2
}

& firebase deploy --only firestore:indexes --project $ProjectId; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Indexes deployed. Verify in Firebase Console."
