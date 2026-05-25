# Copy assets to web build
# This script copies all asset files needed for the web build

$sourceDir = ".\admin\admin\assets\icons"
$targetDir = ".\admin\admin\build\web\assets\icons"

# Create target directory if it doesn't exist
if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# Copy all icon files
Get-ChildItem $sourceDir | ForEach-Object {
    $targetPath = Join-Path $targetDir $_.Name
    Copy-Item $_.FullName $targetPath -Force
    Write-Host "Copied: $($_.Name)"
}

Write-Host "All assets copied successfully!"
