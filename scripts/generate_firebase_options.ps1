<#
Helper to generate firebase_options.dart for a given Firebase project using the FlutterFire CLI.

This script does not run FlutterFire CLI commands itself because the CLI may require interactive steps
and additional setup. Instead it prints the exact commands and checks you should run.

Usage:
  ./generate_firebase_options.ps1 -ProjectId "my-project-id" -OutputName "firebase_options_staging.dart"

Prerequisites:
  - Install FlutterFire CLI: dart pub global activate flutterfire_cli
  - Login: flutterfire configure --project <projectId>

#>

param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectId,
  [Parameter(Mandatory=$false)]
  [string]$OutputName = "firebase_options.dart"
)

Write-Host "To generate firebase options for project: $ProjectId"
Write-Host "Run the following commands in PowerShell (they require Flutter & FlutterFire CLI):`n"

Write-Host "dart pub global activate flutterfire_cli"
Write-Host "flutterfire configure --project $ProjectId --out=lib/$OutputName"

Write-Host "After that, verify the generated file at lib/$OutputName and then wire it into your app entrypoint."
