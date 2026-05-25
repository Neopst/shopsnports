#!/usr/bin/env pwsh
# Quick start script for ShopsNSports server
Set-Location $PSScriptRoot
Write-Host "Starting server from: $(Get-Location)" -ForegroundColor Cyan
node index.js
