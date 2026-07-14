param(
  [int]$BridgePort = 8787
)

$ErrorActionPreference = 'Stop'
$bridgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgeScript = Join-Path $bridgeDir 'deveco-health-bridge.mjs'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'Node.js was not found. Install Node.js 22 or later.'
}
if (-not (Get-Command deveco -ErrorAction SilentlyContinue)) {
  throw 'DevEco Code CLI was not found. Install and sign in to deveco first.'
}

function Find-Hdc {
  $fromPath = Get-Command hdc -ErrorAction SilentlyContinue
  if ($fromPath) {
    return $fromPath.Source
  }

  $candidates = @()
  if ($env:DEVECO_HOME) {
    $candidates += (Join-Path $env:DEVECO_HOME 'sdk\default\openharmony\toolchains\hdc.exe')
  }
  $studioPath = [Environment]::GetEnvironmentVariable('DevEco Studio')
  if ($studioPath) {
    foreach ($item in ($studioPath -split ';')) {
      if ($item.Trim().Length -gt 0) {
        $studioRoot = Split-Path -Parent $item.TrimEnd('\')
        $candidates += (Join-Path $studioRoot 'sdk\default\openharmony\toolchains\hdc.exe')
      }
    }
  }
  $candidates += 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
  $candidates += 'D:\Program Files\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }
  return $null
}

$hdc = Find-Hdc
if (-not $hdc) {
  throw 'HDC was not found. Set DEVECO_HOME or add hdc to PATH.'
}

Write-Host "Configuring reverse port: device 127.0.0.1:$BridgePort -> host 127.0.0.1:$BridgePort"
& $hdc rport "tcp:$BridgePort" "tcp:$BridgePort"
if ($LASTEXITCODE -ne 0) {
  throw 'HDC reverse-port setup failed. Make sure a device or emulator is connected.'
}

$env:HEALTHLIFE_BRIDGE_PORT = [string]$BridgePort
Write-Host 'Starting the HealthLife DevEco GLM-5.1 bridge. Press Ctrl+C to stop.'
& node $bridgeScript
exit $LASTEXITCODE
