# Gets a change ready to commit in one step (docs/loop.md "7. 커밋"):
#   1. syncs the ISO overlay (scripts/sync-archiso-files.ps1)
#   2. puts back the SDDM config line endings the sync rewrites when nothing changed
#   3. runs the static checks (scripts/validate-project.ps1)
#   4. with -Check, also the desktop checks and tests in WSL (scripts/wsl-build.ps1 check)
# Exits non-zero when a step fails, so "ready.ps1 && git commit" never commits a failure.
#
#   powershell -ExecutionPolicy Bypass -File scripts/ready.ps1 [-Check]

param([switch]$Check)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Step([string]$name, [scriptblock]$body) {
    Write-Host "== $name"
    & $body
    if ($LASTEXITCODE -ne 0) {
        Write-Host "실패: $name" -ForegroundColor Red
        exit 1
    }
}

Step "ISO 오버레이 동기화" { powershell -NoProfile -ExecutionPolicy Bypass -File "$root\scripts\sync-archiso-files.ps1" | Out-Null }

$sddm = "archiso/airootfs/etc/sddm.conf.d/10-robinos-theme.conf"
git -C $root diff --ignore-cr-at-eol --quiet -- $sddm
if ($LASTEXITCODE -eq 0) {
    git -C $root checkout -q -- $sddm
} else {
    Write-Host "  $sddm 내용이 바뀌었어요(그대로 둬요)"
}

Step "정적 검증" { powershell -NoProfile -ExecutionPolicy Bypass -File "$root\scripts\validate-project.ps1" }

if ($Check) {
    Step "데스크톱 검사와 테스트" { powershell -NoProfile -ExecutionPolicy Bypass -File "$root\scripts\wsl-build.ps1" check }
}

Write-Host "커밋할 준비가 됐어요." -ForegroundColor Green
