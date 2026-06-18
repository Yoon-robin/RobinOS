$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "RobinOS local checks"
Write-Host ""

powershell -ExecutionPolicy Bypass -File (Join-Path $root "scripts/ci-local.ps1")

Write-Host ""
Write-Host "Git status"
git -C $root status -sb

