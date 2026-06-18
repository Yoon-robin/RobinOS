$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$gitDir = Join-Path $root ".git"
$hooksDir = Join-Path $gitDir "hooks"
$hookPath = Join-Path $hooksDir "pre-push"

if (-not (Test-Path $gitDir)) {
    throw "This directory is not a Git repository: $root"
}

New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

$hook = @'
#!/usr/bin/env sh
set -eu

echo "RobinOS pre-push checks"

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -ExecutionPolicy Bypass -File scripts/ci-local.ps1
elif command -v powershell >/dev/null 2>&1; then
  powershell -ExecutionPolicy Bypass -File scripts/ci-local.ps1
elif command -v pwsh >/dev/null 2>&1; then
  pwsh -ExecutionPolicy Bypass -File scripts/ci-local.ps1
else
  echo "PowerShell is required for scripts/ci-local.ps1" >&2
  exit 1
fi
'@

Set-Content -Encoding ASCII -Path $hookPath -Value $hook

try {
    $null = Get-Command bash -ErrorAction Stop
    bash -lc "chmod +x .git/hooks/pre-push"
} catch {
    Write-Host "Bash/chmod is not available; Git for Windows can still run the hook from this path." -ForegroundColor Yellow
}

Write-Host "Installed RobinOS pre-push hook at $hookPath" -ForegroundColor Green

