param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectId
)

Write-Host "Deploying firestore.rules to project: $ProjectId"

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Error "Firebase CLI not found. Install from https://firebase.google.com/docs/cli"
  exit 2
}

$rulesFile = Join-Path (Get-Location) 'firestore.rules'
if (-not (Test-Path $rulesFile)) {
  Write-Error "firestore.rules not found in repository root. Create it from firestore.rules.example first."
  exit 2
}

& firebase deploy --only firestore:rules --project $ProjectId; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deployment finished. Verify in Firebase Console."
