$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "RobinOS local CI"
Write-Host "Repository: $root"
Write-Host ""

Write-Host "Step 1: Static validation"
powershell -ExecutionPolicy Bypass -File (Join-Path $root "scripts/validate-project.ps1")

Write-Host ""
Write-Host "Step 2: Bash syntax validation"
$bash = Get-Command bash -ErrorAction SilentlyContinue

if (-not $bash) {
    Write-Host "Skipped: bash is not available on this machine." -ForegroundColor Yellow
    Write-Host "Run this on Arch/Linux or install Git Bash/WSL to enable Bash syntax checks." -ForegroundColor Yellow
    exit 0
}

$scripts = @()
$scanRoots = @(
    "scripts",
    "bin",
    "installer",
    "archiso/airootfs/root",
    "archiso/airootfs/usr/local/bin"
)

foreach ($scanRoot in $scanRoots) {
    $fullRoot = Join-Path $root $scanRoot
    if (Test-Path $fullRoot) {
        $scripts += Get-ChildItem $fullRoot -Recurse -File |
            Where-Object {
                $_.Name.EndsWith(".sh") -or
                $_.Name -eq "robinctl" -or
                $_.Name -eq "robin-install"
            }
    }
}

foreach ($script in $scripts) {
    Write-Host "Checking $($script.FullName)"
    & $bash.Source -n $script.FullName
}

Write-Host ""
Write-Host "Local CI passed." -ForegroundColor Green

