[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
  'README.md', 'AGENTS.md', 'tasks.md', 'changes.md', 'design.md', 'design-qa.md',
  'docs\qa\README.md', 'build-profile.json5', 'oh-package.json5', 'hvigorfile.ts',
  'entry\build-profile.json5', 'entry\oh-package.json5', 'entry\hvigorfile.ts',
  'entry\src\main\module.json5', 'entry\src\main\resources\base\profile\main_pages.json'
)

$missing = @($requiredFiles | Where-Object { -not (Test-Path (Join-Path $projectRoot $_) -PathType Leaf) })
if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Error "Missing required file: $_" }
  exit 1
}

$taskText = Get-Content -Raw -Encoding UTF8 (Join-Path $projectRoot 'tasks.md')
foreach ($status in @('pending', 'in_progress', 'done', 'blocked')) {
  if (-not $taskText.Contains($status)) {
    Write-Error "tasks.md is missing status: $status"
    exit 1
  }
}

Write-Host 'Standard project check passed.'
Write-Host "Project: $projectRoot"

