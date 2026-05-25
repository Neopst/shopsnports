#!/usr/bin/env pwsh

Write-Host "Starting Admin Dashboard Web Build..." -ForegroundColor Green

Set-Location .\admin\admin

Write-Host "Running flutter clean..." -ForegroundColor Yellow
flutter clean

Write-Host "Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host "Web build is at: admin\admin\build\web" -ForegroundColor Cyan
} else {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
}

Set-Location ..\..\
