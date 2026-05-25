<#
Create Docker Secrets for Postgres TLS files and app DB password.

Usage: from c:\projects\shopsnports\server
.\docker\create_docker_secrets.ps1 [-Force]

This script will create the following secrets (external names used by compose file):
- shopsnports_postgres_server_key
- shopsnports_postgres_server_crt
- shopsnports_postgres_ca_crt
- shopsnports_app_user_password

#>

param(
    [switch]$Force
)

function Initialize-Swarm {
    $swarm = docker info --format '{{json .Swarm}}' 2>$null | ConvertFrom-Json
    if (-not $swarm.LocalNodeState -or $swarm.LocalNodeState -eq 'inactive') {
        Write-Host "Docker Swarm not active. Initializing swarm..."
        docker swarm init | Write-Host
    } else {
        Write-Host "Docker Swarm already active: $($swarm.LocalNodeState)"
    }
}

function New-SecretIfMissing($name, $filePath) {
    if (-not (Test-Path $filePath)) {
        Write-Host "Skipping secret $name - file not found: $filePath"
        return
    }
    $exists = docker secret ls --format '{{.Name}}' | Where-Object { $_ -eq $name }
    if ($exists -and -not $Force) {
        Write-Host "Secret $name already exists. Use -Force to recreate."
        return
    }
    if ($exists -and $Force) {
        Write-Host "Removing existing secret $name"
        docker secret rm $name | Write-Host
    }
    Write-Host "Creating secret $name from $filePath"
    docker secret create $name $filePath | Write-Host
}

# Determine repository server directory robustly (script is in server\docker)
$scriptPath = $MyInvocation.MyCommand.Definition
$scriptDir = Split-Path -Parent $scriptPath
$serverDir = Split-Path -Parent $scriptDir
Set-Location $serverDir

Initialize-Swarm

New-SecretIfMissing -name 'shopsnports_postgres_server_key' -filePath '.\certs\server.key'
New-SecretIfMissing -name 'shopsnports_postgres_server_crt' -filePath '.\certs\server.crt'
New-SecretIfMissing -name 'shopsnports_postgres_ca_crt' -filePath '.\certs\ca.crt'
New-SecretIfMissing -name 'shopsnports_app_user_password' -filePath '.\secrets\app_user_password.txt'

# Ensure a superuser password exists for Postgres initialization (create if missing)
$superPwPath = '.\secrets\postgres_superuser_password.txt'
if (-not (Test-Path $superPwPath)) {
    Write-Host "Superuser password file not found at $superPwPath - generating a random password"
    $pw = [System.Web.Security.Membership]::GeneratePassword(20,4)
    Set-Content -Path $superPwPath -Value $pw
    icacls $superPwPath /inheritance:r /grant:r "$($env:USERNAME):(R)" /c | Out-Null
}
New-SecretIfMissing -name 'shopsnports_postgres_superuser_password' -filePath $superPwPath

Write-Host "Secrets creation complete. Use docker stack deploy -c .\docker\docker-compose.postgres.secrets.yml shopsnports to deploy the stack."
