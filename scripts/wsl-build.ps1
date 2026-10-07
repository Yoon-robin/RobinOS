# Builds and tests RobinOS on this Windows PC through WSL 2 (Arch Linux).
#
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 setup
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 check
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 status
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
#   powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test -Installer robinos
#
# The WSL side keeps its own clone in /root/RobinOS (building on /mnt/c is slow
# and loses file modes). build, boot-test and install-test first reset that
# clone to this checkout's HEAD, so commit before running; uncommitted changes
# don't reach WSL. They refuse to start while another build or VM is running,
# because the reset would pull files out from under it. check (desktop config
# and qmllint) and status read this checkout directly and are always safe.
# Test results (screenshots, serial logs) are copied back to build\ here.
# Needs WSL 2 and the archlinux distro: wsl --install archlinux

param(
    [Parameter(Position = 0)]
    [ValidateSet("setup", "check", "status", "build", "boot-test", "install-test", "shell")]
    [string]$Task = "build",
    # install-test: archinstall (docs/install.md option A) or robinos (installer/robin-install)
    [ValidateSet("archinstall", "robinos")]
    [string]$Installer = "archinstall",
    # boot-test: whpx runs QEMU for Windows with the Windows Hypervisor Platform,
    # several times faster than TCG in WSL (no KVM on Windows 10). auto = whpx
    # when QEMU for Windows is at -Qemu, otherwise tcg.
    [ValidateSet("auto", "whpx", "tcg")]
    [string]$Accel = "auto",
    [string]$Qemu = "$env:USERPROFILE\RobinOS-tools\qemu\qemu-system-x86_64.exe",
    # install-test (WHPX): reuse the installed disk a failed run left behind
    [switch]$ReuseDisk,
    [string]$Distro = "archlinux"
)

$ErrorActionPreference = "Stop"
$env:WSL_UTF8 = "1"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Invoke-Wsl([string]$script) {
    # A Windows checkout of this file has CRLF line endings; bash would keep the \r
    $script = $script -replace "`r", ""
    # -e: run bash directly; without it wsl.exe passes the line through a shell first
    wsl.exe -d $Distro -u root -e bash -lc $script
    if ($LASTEXITCODE -ne 0) {
        throw "WSL 명령이 실패했어요 (종료 코드 $LASTEXITCODE)"
    }
}

# Boot test with QEMU for Windows (WHPX). WSL prepares the ISO (scripts/vm-prepare.sh),
# QEMU runs here, and scripts/boot-test-qmp.py drives it over QMP on TCP.
function Invoke-WhpxBootTest {
    $out = Join-Path $root "build\boot-test"
    $vm = Join-Path $root "build\vm"
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    New-Item -ItemType Directory -Force $out, $vm | Out-Null
    $wslVm = (wsl.exe -d $Distro -u root -e wslpath -a ($vm -replace "\\", "/")).Trim()

    $prepared = wsl.exe -d $Distro -u root -e bash "$wslRoot/scripts/vm-prepare.sh" $wslVm
    if ($LASTEXITCODE -ne 0) { throw "ISO를 준비하지 못했어요" }
    $base, $label, $isoName = (($prepared | Select-Object -Last 1) -split " ")
    Write-Host "ISO: $isoName (WHPX)"

    # A blank disk, so the installer's disk step has something to show
    & (Join-Path (Split-Path -Parent $Qemu) "qemu-img.exe") create -q -f qcow2 "$out\disk.qcow2" 64G

    $port = 47011
    $kernelArgs = "archisobasedir=$base archisolabel=$label console=tty0 console=ttyS0,115200 systemd.journald.forward_to_console=1 robinos.debug"
    # Start-Process joins the arguments with spaces, so quote the ones that have them
    $qemuArgs = @(
        "-machine", "q35", "-accel", "whpx", "-m", "6144", "-smp", "4",
        "-kernel", "`"$vm\$base\boot\x86_64\vmlinuz-linux`"",
        "-initrd", "`"$vm\$base\boot\x86_64\initramfs-linux.img`"",
        "-append", "`"$kernelArgs`"",
        "-cdrom", "`"$vm\robinos.iso`"",
        "-drive", "`"file=$out\disk.qcow2,format=qcow2,if=virtio`"",
        "-vga", "none", "-device", "VGA,edid=on,xres=1600,yres=900", "-display", "none",
        "-netdev", "user,id=net0", "-device", "virtio-net-pci,netdev=net0",
        "-qmp", "tcp:127.0.0.1:$port,server,nowait",
        "-serial", "`"file:$out\serial.log`""
    )
    $proc = Start-Process -FilePath $Qemu -ArgumentList $qemuArgs -PassThru -WindowStyle Hidden `
        -RedirectStandardError "$out\qemu-stderr.log" -RedirectStandardOutput "$out\qemu-stdout.log"

    python "$root\scripts\boot-test-qmp.py" "tcp:127.0.0.1:$port" $out 1
    if (-not $proc.WaitForExit(30000)) { $proc.Kill() }

    Write-Host "`n시리얼 로그의 주요 줄:"
    Select-String -Path "$out\serial.log" -Pattern "robinos-session|Reached target .*Graphical|Failed to start|hyprland.*(ERR|error|CRIT)" |
        Select-Object -Last 20 | ForEach-Object { $_.Line -replace "\x1b\[[0-9;]*m", "" }
    Write-Host "`n스크린샷:"
    Get-ChildItem "$out\*.png" | ForEach-Object { "  $($_.Name)" }
}

# Install test with QEMU for Windows (WHPX), the same phases as scripts/install-test.sh:
# live ISO (direct kernel boot) installs to a blank disk, then the installed system boots
# from it. scripts/install-test.py drives both over TCP (serial console and QMP).
function Invoke-WhpxInstallTest {
    $out = Join-Path $root "build\install-test"
    $vm = Join-Path $root "build\vm"
    $qemuDir = Split-Path -Parent $Qemu
    # -ReuseDisk: start from the disk a failed run left behind and skip the live phase
    $reuse = $ReuseDisk -and (Test-Path "$out\disk.qcow2") -and (Test-Path "$out\OVMF_VARS.fd")
    if ($reuse) {
        Get-ChildItem $out -File | Where-Object { $_.Name -notin "disk.qcow2", "OVMF_VARS.fd" } | Remove-Item -Force
        if (Test-Path "$out\share") { Remove-Item "$out\share" -Recurse -Force }
        Write-Host "남아 있던 설치 디스크로 시작해요 (라이브 단계 건너뜀)"
    } elseif (Test-Path $out) {
        Remove-Item $out -Recurse -Force
    }
    New-Item -ItemType Directory -Force $out, $vm | Out-Null
    $wslVm = (wsl.exe -d $Distro -u root -e wslpath -a ($vm -replace "\\", "/")).Trim()

    $prepared = wsl.exe -d $Distro -u root -e bash "$wslRoot/scripts/vm-prepare.sh" $wslVm
    if ($LASTEXITCODE -ne 0) { throw "ISO를 준비하지 못했어요" }
    $base, $label, $isoName = (($prepared | Select-Object -Last 1) -split " ")
    Write-Host "ISO: $isoName (WHPX), 설치 방식: $Installer"

    # This checkout's files for the installed system, as a read-only FAT disk
    $share = Join-Path $out "share\robinos"
    New-Item -ItemType Directory -Force $share | Out-Null
    foreach ($dir in "assets", "bin", "config", "desktop", "docs", "installer", "labs", "packages", "scripts", "themes") {
        Copy-Item (Join-Path $root $dir) $share -Recurse
    }

    if (-not $reuse) {
        & (Join-Path $qemuDir "qemu-img.exe") create -q -f qcow2 "$out\disk.qcow2" 40G
        Copy-Item (Join-Path $qemuDir "share\edk2-i386-vars.fd") "$out\OVMF_VARS.fd"
    }

    $env:ROBINOS_INSTALLER = $Installer
    $env:ROBINOS_SERIAL = "tcp:127.0.0.1:47021"
    $env:ROBINOS_QMP = "tcp:127.0.0.1:47022"
    $shareFat = (Join-Path $out "share") -replace "\\", "/"
    $common = @(
        "-machine", "q35", "-accel", "whpx", "-m", "6144", "-smp", "4",
        "-drive", "`"if=pflash,format=raw,readonly=on,file=$qemuDir\share\edk2-x86_64-code.fd`"",
        "-drive", "`"if=pflash,format=raw,file=$out\OVMF_VARS.fd`"",
        "-drive", "`"file=$out\disk.qcow2,format=qcow2,if=virtio`"",
        "-drive", "`"file=fat:$shareFat,format=raw,if=virtio,readonly=on`"",
        "-vga", "none", "-device", "VGA,edid=on,xres=1600,yres=900", "-display", "none",
        "-netdev", "user,id=net0", "-device", "virtio-net-pci,netdev=net0",
        "-qmp", "tcp:127.0.0.1:47022,server,nowait"
    )
    $kernelArgs = "archisobasedir=$base archisolabel=$label console=tty0 console=ttyS0,115200"
    $phases = @(
        @{ name = "live"; extra = @(
            "-kernel", "`"$vm\$base\boot\x86_64\vmlinuz-linux`"",
            "-initrd", "`"$vm\$base\boot\x86_64\initramfs-linux.img`"",
            "-append", "`"$kernelArgs`"",
            "-cdrom", "`"$vm\robinos.iso`"") },
        @{ name = "installed"; extra = @() }
    )
    if ($reuse) { $phases = @($phases[1]) }

    $failed = $false
    foreach ($phase in $phases) {
        $name = $phase.name
        Write-Host "`n== 설치 테스트: $name"
        $serial = @("-chardev", "`"socket,id=ser0,host=127.0.0.1,port=47021,server=on,wait=off,logfile=$out\serial-$name.log`"", "-serial", "chardev:ser0")
        $proc = Start-Process -FilePath $Qemu -ArgumentList ($common + $serial + $phase.extra) -PassThru -WindowStyle Hidden `
            -RedirectStandardError "$out\qemu-$name-stderr.log" -RedirectStandardOutput "$out\qemu-$name-stdout.log"
        python "$root\scripts\install-test.py" $name $out 1
        $status = $LASTEXITCODE
        if (-not $proc.WaitForExit(60000)) { $proc.Kill() }
        if ($status -ne 0) { $failed = $true; break }
    }
    Remove-Item Env:ROBINOS_SERIAL, Env:ROBINOS_QMP, Env:ROBINOS_INSTALLER -ErrorAction SilentlyContinue
    Write-Host "`n스크린샷:"
    Get-ChildItem "$out\*.png" | ForEach-Object { "  $($_.Name)" }
    if ($failed) {
        throw "설치 테스트가 실패했어요. $out\serial-*.log를 보세요. 설치 디스크를 남겨 뒀으니 -ReuseDisk로 이어서 할 수 있어요"
    }
    Remove-Item "$out\disk.qcow2" -ErrorAction SilentlyContinue  # 10 GB or so once installed
}

$distros = (wsl.exe -l -q) -replace "`0", "" | Where-Object { $_.Trim() -ne "" }
if ($distros -notcontains $Distro) {
    Write-Host "WSL에 $Distro 배포판이 없어요. 먼저 설치하세요: wsl --install archlinux" -ForegroundColor Yellow
    exit 1
}

$wslRoot = (wsl.exe -d $Distro -u root -e wslpath -a ($root -replace "\\", "/")).Trim()

if ($Task -eq "setup") {
    Invoke-Wsl @"
set -e
pacman-key --init >/dev/null 2>&1 || true
pacman-key --populate archlinux >/dev/null 2>&1 || true
pacman -Syu --noconfirm --needed archiso git grub sudo qemu-full edk2-ovmf libarchive python openssl rsync quickshell qt6-declarative lua hyprland
echo 'WSL 빌드 환경이 준비됐어요.'
"@
    exit 0
}

if ($Task -eq "check") {
    Invoke-Wsl "cd '$wslRoot' && bash scripts/check-desktop.sh && bash scripts/qmllint.sh"
    exit 0
}

# What is running in WSL right now (ISO build, test VMs)
$busy = (wsl.exe -d $Distro -u root -e bash -c "pgrep -af 'mkarchiso|qemu-system|install-test|boot-test' | grep -v pgrep") -join "`n"

if ($Task -eq "status") {
    if ($busy) { Write-Host "WSL에서 돌고 있는 작업:"; Write-Host $busy } else { Write-Host "WSL에서 돌고 있는 빌드나 VM이 없어요." }
    Invoke-Wsl "ls -lh /root/RobinOS/out/*.iso 2>/dev/null; ls -ld --time-style=+'%F %T' /root/RobinOS/build/boot-test /root/RobinOS/build/install-test 2>/dev/null; true"
    exit 0
}

if ($busy -and $Task -ne "shell") {
    Write-Host "WSL에서 다른 빌드나 VM이 돌고 있어서 시작하지 않아요:" -ForegroundColor Yellow
    Write-Host $busy
    exit 3
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
        if ($Accel -eq "auto") { $Accel = if (Test-Path $Qemu) { "whpx" } else { "tcg" } }
        if ($Accel -eq "whpx") {
            Invoke-WhpxBootTest
        } else {
            Invoke-Wsl "cd /root/RobinOS && scripts/boot-test.sh; rc=`$?; mkdir -p '$wslRoot/build' && rm -rf '$wslRoot/build/boot-test' && cp -r build/boot-test '$wslRoot/build/'; exit `$rc"
        }
        Write-Host "결과: $root\build\boot-test"
    }
    "install-test" {
        if ($Accel -eq "auto") { $Accel = if (Test-Path $Qemu) { "whpx" } else { "tcg" } }
        if ($Accel -eq "whpx") {
            Invoke-WhpxInstallTest
            Write-Host "결과: $root\build\install-test"
            break
        }
        Invoke-Wsl "cd /root/RobinOS && scripts/install-test.sh --installer=$Installer; rc=`$?; mkdir -p '$wslRoot/build/install-test' && cp build/install-test/*.png build/install-test/*.log '$wslRoot/build/install-test/' 2>/dev/null; exit `$rc"
        Write-Host "결과: $root\build\install-test"
    }
    "shell" {
        wsl.exe -d $Distro -u root --cd /root/RobinOS
    }
}
