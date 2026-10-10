[CmdletBinding()]
param(
  [ValidateSet('debug', 'release')]
  [string]$BuildMode = 'debug'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$hvigor = Get-Command 'hvigorw.bat' -ErrorAction SilentlyContinue
if ($null -eq $hvigor) {
  throw 'hvigorw.bat was not found. Install DevEco Studio or add its Hvigor bin directory to PATH.'
}

Push-Location $projectRoot
try {
  & $hvigor.Source assembleHap
  if ($LASTEXITCODE -ne 0) {
    throw "HarmonyOS build failed with exit code $LASTEXITCODE"
  }

  $artifact = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'entry\build') -Recurse -File -Filter '*.hap' |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
  if ($null -eq $artifact) {
    throw 'Build succeeded, but no HAP was found below entry\build.'
  }

  Write-Host 'HarmonyOS build passed.'
  Write-Host "Artifact: $($artifact.FullName)"
  Write-Host "Size: $($artifact.Length) bytes"
}
finally {
  Pop-Location
}

