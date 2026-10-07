# Builds and tests RobinOS on this Windows PC through WSL 2 (Arch Linux).
#
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 setup
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
#
# The WSL side keeps its own clone in /root/RobinOS (building on /mnt/c is slow
# and loses file modes). Each task first resets that clone to this checkout's
# HEAD, so commit before running; uncommitted changes don't reach WSL.
# Test results (screenshots, serial logs) are copied back to build\ here.
# Needs WSL 2 and the archlinux distro: wsl --install archlinux

param(
    [Parameter(Position = 0)]
    [ValidateSet("setup", "build", "boot-test", "install-test", "shell")]
    [string]$Task = "build",
    [string]$Distro = "archlinux"
)

$ErrorActionPreference = "Stop"
$env:WSL_UTF8 = "1"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Invoke-Wsl([string]$script) {
    wsl.exe -d $Distro -u root -- bash -lc $script
    if ($LASTEXITCODE -ne 0) {
        throw "WSL 명령이 실패했어요 (종료 코드 $LASTEXITCODE)"
    }
}

$distros = (wsl.exe -l -q) -replace "`0", "" | Where-Object { $_.Trim() -ne "" }
if ($distros -notcontains $Distro) {
    Write-Host "WSL에 $Distro 배포판이 없어요. 먼저 설치하세요: wsl --install archlinux" -ForegroundColor Yellow
    exit 1
}

$wslRoot = (wsl.exe -d $Distro -u root -- wslpath -a ($root -replace "\\", "/")).Trim()

if ($Task -eq "setup") {
    Invoke-Wsl @"
set -e
pacman-key --init >/dev/null 2>&1 || true
pacman-key --populate archlinux >/dev/null 2>&1 || true
pacman -Syu --noconfirm --needed archiso git grub sudo qemu-full edk2-ovmf libarchive python openssl rsync
echo 'WSL 빌드 환경이 준비됐어요.'
"@
    exit 0
}

if (git -C $root status --porcelain) {
    Write-Host "알림: 커밋하지 않은 변경은 WSL로 넘어가지 않아요. HEAD 기준으로 진행해요." -ForegroundColor Yellow
}

Write-Host "WSL의 /root/RobinOS를 $(git -C $root rev-parse --short HEAD)로 맞춰요"
Invoke-Wsl @"
set -e
[ -d /root/RobinOS/.git ] || git clone -q '$wslRoot' /root/RobinOS
cd /root/RobinOS
git fetch -q '$wslRoot' HEAD
git reset -q --hard FETCH_HEAD
git clean -qfd
"@

switch ($Task) {
    "build" {
        Invoke-Wsl "cd /root/RobinOS && scripts/build-iso.sh"
    }
    "boot-test" {
        Invoke-Wsl "cd /root/RobinOS && scripts/boot-test.sh; rc=`$?; mkdir -p '$wslRoot/build' && rm -rf '$wslRoot/build/boot-test' && cp -r build/boot-test '$wslRoot/build/'; exit `$rc"
        Write-Host "결과: $root\build\boot-test"
    }
    "install-test" {
        Invoke-Wsl "cd /root/RobinOS && scripts/install-test.sh; rc=`$?; mkdir -p '$wslRoot/build/install-test' && cp build/install-test/*.png build/install-test/*.log '$wslRoot/build/install-test/' 2>/dev/null; exit `$rc"
        Write-Host "결과: $root\build\install-test"
    }
    "shell" {
        wsl.exe -d $Distro -u root --cd /root/RobinOS
    }
}
