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
  $buildArgs = @('assembleHap', '--no-daemon', '-p', "buildMode=$BuildMode")
  & $hvigor.Source @buildArgs
  if ($LASTEXITCODE -ne 0) {
    throw "HarmonyOS build failed with exit code $LASTEXITCODE"
  }

  $artifact = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'entry\build') -Recurse -File -Filter '*.hap' |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
  if ($null -eq $artifact) {
    throw 'Build succeeded, but no HAP was found below entry\build.'
  }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [System.IO.Compression.ZipFile]::OpenRead($artifact.FullName)
  try {
    $moduleEntry = $archive.GetEntry('module.json')
    if ($null -eq $moduleEntry) {
      throw 'Built HAP does not contain module.json.'
    }
    $reader = New-Object System.IO.StreamReader($moduleEntry.Open())
    try {
      $moduleMetadata = $reader.ReadToEnd() | ConvertFrom-Json
    }
    finally {
      $reader.Dispose()
    }
  }
  finally {
    $archive.Dispose()
  }

  $actualBuildMode = [string]$moduleMetadata.app.buildMode
  $actualDebug = [bool]$moduleMetadata.app.debug
  if ($actualBuildMode -ne $BuildMode -or (($BuildMode -eq 'release') -and $actualDebug) -or (($BuildMode -eq 'debug') -and -not $actualDebug)) {
    throw "HAP build mode mismatch. Expected $BuildMode, got buildMode=$actualBuildMode, debug=$actualDebug."
  }

  Write-Host 'HarmonyOS build passed.'
  Write-Host "BuildMode: $actualBuildMode (debug=$actualDebug)"
  Write-Host "Artifact: $($artifact.FullName)"
  Write-Host "Size: $($artifact.Length) bytes"
}
finally {
  Pop-Location
}

