#!/usr/bin/env pwsh
# Cleanup Script - Remove Temporary and Duplicate Files
# Run this from the project root: .\scripts\cleanup-temp-files.ps1

Write-Host "🧹 Starting cleanup of temporary files..." -ForegroundColor Cyan

$filesToDelete = @(
    "lib\screens\vendor_dashboard_screen.dart.new",
    "lib\screens\affiliate\profile_screen.dart.tmp",
    "lib\main.dart.bak.20251008-184337"
)

$deletedCount = 0
$notFoundCount = 0

foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $PSScriptRoot "..\$file"
    
    if (Test-Path $fullPath) {
        try {
            Remove-Item $fullPath -Force
            Write-Host "✅ Deleted: $file" -ForegroundColor Green
            $deletedCount++
        }
        catch {
            Write-Host "❌ Failed to delete: $file" -ForegroundColor Red
            Write-Host "   Error: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "⚠️  Not found: $file" -ForegroundColor Yellow
        $notFoundCount++
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "   Deleted: $deletedCount files" -ForegroundColor Green
Write-Host "   Not found: $notFoundCount files" -ForegroundColor Yellow

Write-Host "`n✨ Cleanup complete!" -ForegroundColor Cyan
