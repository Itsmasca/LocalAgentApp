<#
.SYNOPSIS
  Simula la ubicacion GPS del emulador Android para probar la app.

.EXAMPLE
  .\tool\simular_ubicacion.ps1                 # menu interactivo
  .\tool\simular_ubicacion.ps1 zocalo          # fija un lugar por nombre
  .\tool\simular_ubicacion.ps1 -Lista          # muestra los lugares
  .\tool\simular_ubicacion.ps1 -Ruta           # camina desde el Zocalo hacia el norte
  .\tool\simular_ubicacion.ps1 -Lat 19.4 -Lng -99.1   # coordenada libre
#>
param(
  [string]$Lugar,
  [double]$Lat,
  [double]$Lng,
  [switch]$Ruta,
  [switch]$Lista,
  [string]$Dispositivo = 'emulator-5554',
  [int]$PausaSegundos = 3
)

$ErrorActionPreference = 'Stop'

# Radio por defecto de una Ubicacion: 75 m (lib/domain/entities/ubicacion.dart).
# 0.00027 grados de latitud son unos 30 m.
$lugares = [ordered]@{
  'zocalo'         = @{ Lat = 19.432600; Lng = -99.133200; Nota = 'Punto base A' }
  'zocalo-30m'     = @{ Lat = 19.432870; Lng = -99.133200; Nota = '30 m al norte de A: dentro del radio, deberia resolver a A' }
  'zocalo-150m'    = @{ Lat = 19.433950; Lng = -99.133200; Nota = '150 m al norte de A: fuera del radio, propone lugar nuevo' }
  'zocalo-sur'     = @{ Lat = 19.431700; Lng = -99.133200; Nota = 'Punto C, 100 m al sur de A (radios traslapados con A)' }
  'entre-a-y-c'    = @{ Lat = 19.432240; Lng = -99.133200; Nota = '40 m de A y 60 m de C: dentro de ambos, deberia ganar A (la mas cercana)' }
  'bellas-artes'   = @{ Lat = 19.435200; Lng = -99.141200; Nota = 'Unos 900 m de A' }
  'chapultepec'    = @{ Lat = 19.420400; Lng = -99.181900; Nota = 'Lejos' }
  'coyoacan'       = @{ Lat = 19.350000; Lng = -99.162400; Nota = 'Lejos' }
  'guadalajara'    = @{ Lat = 20.676700; Lng = -103.347500; Nota = 'Otra ciudad' }
  'mountain-view'  = @{ Lat = 37.421998; Lng = -122.084000; Nota = 'Ubicacion por defecto del emulador' }
}

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($null -eq $cmd) { throw 'No se encontro adb. Instala Android SDK platform-tools.' }
  $adb = $cmd.Source
}

function Set-Ubicacion([double]$latitud, [double]$longitud, [string]$etiqueta) {
  $ci = [System.Globalization.CultureInfo]::InvariantCulture
  $lngTxt = $longitud.ToString($ci)
  $latTxt = $latitud.ToString($ci)
  # geo fix recibe LONGITUD primero, luego latitud.
  $salida = & $adb -s $Dispositivo emu geo fix $lngTxt $latTxt 2>&1
  if ($LASTEXITCODE -ne 0 -or "$salida" -notmatch 'OK') {
    throw "Fallo geo fix en ${Dispositivo}: $salida"
  }
  Write-Host ("-> {0,-14} lat {1}, lng {2}" -f $etiqueta, $latTxt, $lngTxt) -ForegroundColor Green
}

function Show-Lugares {
  $i = 1
  foreach ($k in $lugares.Keys) {
    Write-Host ("{0,2}. {1,-14} {2}" -f $i, $k, $lugares[$k].Nota)
    $i++
  }
}

# Asegura que el GPS del emulador este encendido.
& $adb -s $Dispositivo shell cmd location set-location-enabled true 2>&1 | Out-Null

if ($Lista) { Show-Lugares; return }

if ($PSBoundParameters.ContainsKey('Lat') -and $PSBoundParameters.ContainsKey('Lng')) {
  Set-Ubicacion $Lat $Lng 'personalizada'
  return
}

if ($Ruta) {
  # Camina 10 m por paso hacia el norte desde A: cruza el radio de 75 m.
  $base = $lugares['zocalo']
  for ($m = 0; $m -le 150; $m += 10) {
    $lat = $base.Lat + ($m / 111320.0)
    Set-Ubicacion $lat $base.Lng "A + $m m"
    Start-Sleep -Seconds $PausaSegundos
  }
  return
}

if ($Lugar) {
  if (-not $lugares.Contains($Lugar)) {
    Write-Host "Lugar '$Lugar' desconocido. Opciones:" -ForegroundColor Yellow
    Show-Lugares
    exit 1
  }
  $p = $lugares[$Lugar]
  Set-Ubicacion $p.Lat $p.Lng $Lugar
  return
}

# Menu interactivo.
$claves = @($lugares.Keys)
while ($true) {
  Write-Host ''
  Show-Lugares
  $sel = Read-Host 'Numero o nombre (Enter para salir)'
  if ([string]::IsNullOrWhiteSpace($sel)) { break }
  $n = 0
  if ([int]::TryParse($sel, [ref]$n) -and $n -ge 1 -and $n -le $claves.Count) {
    $sel = $claves[$n - 1]
  }
  if ($lugares.Contains($sel)) {
    $p = $lugares[$sel]
    Set-Ubicacion $p.Lat $p.Lng $sel
  } else {
    Write-Host "No reconocido: $sel" -ForegroundColor Yellow
  }
}
