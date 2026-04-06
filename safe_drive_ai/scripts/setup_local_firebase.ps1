$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $projectRoot
$source = Join-Path $workspaceRoot 'google-services.json'
$destinationDir = Join-Path $projectRoot 'android\app'
$destination = Join-Path $destinationDir 'google-services.json'

if (-not (Test-Path $source)) {
  Write-Error "No se encontro google-services.json en: $source"
}

if (-not (Test-Path $destinationDir)) {
  Write-Error "No se encontro android/app en: $destinationDir"
}

Copy-Item -Path $source -Destination $destination -Force
Write-Host "OK: Copiado a $destination"
Write-Host "Nota: Este archivo esta ignorado por git y no se sube al repo."
