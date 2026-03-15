# Crear carpeta docs/
New-Item -ItemType Directory -Path 'C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\docs' -Force | Out-Null

# Mover archivos de referencia a docs/
$refs = @(
  'app_colors_reference.dart',
  'app_router_reference.dart',
  'app_strings_reference.dart',
  'exceptions_reference.dart',
  'failures_reference.dart',
  'injection_container_reference.dart',
  'lib_main_reference.dart',
  'usecase_reference.dart',
  'pubspec_reference.yaml',
  'android_build_gradle_reference.txt'
)
foreach ($f in $refs) {
  $src = "C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\$f"
  if (Test-Path $src) {
    Move-Item $src 'C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\docs\'
    Write-Host "Movido a docs/: $f"
  }
}

# Eliminar carpeta referencias/ si quedó vacía o tiene duplicados
$refDir = 'C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\referencias'
if (Test-Path $refDir) {
  Get-ChildItem $refDir | ForEach-Object {
    $dest = "C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\docs\$($_.Name)"
    if (-not (Test-Path $dest)) { Move-Item $_.FullName 'C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\docs\' }
    else { Remove-Item $_.FullName }
  }
  Remove-Item $refDir -ErrorAction SilentlyContinue
  Write-Host "Carpeta referencias/ eliminada"
}

# Mover script de limpieza a docs/
Move-Item 'C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\mover_referencias.ps1' 'C:\Users\luism\Documents\Universidad\Gerencia\SafeDrive\docs\' -ErrorAction SilentlyContinue

Write-Host "Listo"
