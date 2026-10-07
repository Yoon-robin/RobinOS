param(
    [string]$VMName = "RobinOS-Builder",
    [int]$MemoryGB = 8,
    [int]$CpuCount = 4,
    [int]$DiskGB = 60,
    [string]$VMRoot = "$env:USERPROFILE\VMs",
    [string]$IsoDir = "$env:USERPROFILE\Downloads\RobinOS-Builder",
    [string]$ArchIsoUrl = "https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-FeatureIfNeeded {
    param([string]$FeatureName)

    $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
    if ($feature.State -ne "Enabled") {
        Write-Host "Enabling Windows feature: $FeatureName"
        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All -NoRestart
        return $true
    }

    Write-Host "Feature already enabled: $FeatureName"
    return $false
}

Write-Host "RobinOS Hyper-V Arch VM setup"
Write-Host ""

if (-not (Test-IsAdmin)) {
    Write-Host "This script must run in Administrator PowerShell." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Open PowerShell as Administrator, then run:"
    Write-Host "  cd `"$PWD`""
    Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/setup-hyperv-arch-vm.ps1"
    exit 1
}

$needsReboot = $false
$needsReboot = (Enable-FeatureIfNeeded -FeatureName "Microsoft-Hyper-V-All") -or $needsReboot

if ($needsReboot) {
    Write-Host ""
    Write-Host "Hyper-V was enabled. Reboot Windows, then run this script again." -ForegroundColor Yellow
    exit 0
}

if (-not (Get-Command New-VM -ErrorAction SilentlyContinue)) {
    throw "Hyper-V PowerShell cmdlets are not available. Reboot and run this script again."
}

New-Item -ItemType Directory -Force -Path $VMRoot | Out-Null
New-Item -ItemType Directory -Force -Path $IsoDir | Out-Null

$isoPath = Join-Path $IsoDir "archlinux-x86_64.iso"

if (-not (Test-Path $isoPath)) {
    Write-Host "Downloading Arch Linux ISO..."
    Write-Host $ArchIsoUrl
    Invoke-WebRequest -Uri $ArchIsoUrl -OutFile $isoPath
} else {
    Write-Host "Arch ISO already exists: $isoPath"
}

$existing = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "VM already exists: $VMName"
} else {
    $vmPath = Join-Path $VMRoot $VMName
    $vhdPath = Join-Path $vmPath "$VMName.vhdx"
    $memoryBytes = [int64]$MemoryGB * 1GB
    $diskBytes = [int64]$DiskGB * 1GB

    New-Item -ItemType Directory -Force -Path $vmPath | Out-Null

    Write-Host "Creating VM: $VMName"
    New-VM `
        -Name $VMName `
        -Generation 2 `
        -MemoryStartupBytes $memoryBytes `
        -NewVHDPath $vhdPath `
        -NewVHDSizeBytes $diskBytes `
        -Path $vmPath `
        -SwitchName "Default Switch" | Out-Null

    Set-VM -Name $VMName -ProcessorCount $CpuCount -AutomaticCheckpointsEnabled $false
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes $memoryBytes -MaximumBytes $memoryBytes
    Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
}

$dvd = Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue
if ($dvd) {
    Set-VMDvdDrive -VMName $VMName -Path $isoPath
} else {
    Add-VMDvdDrive -VMName $VMName -Path $isoPath
}

$dvdDrive = Get-VMDvdDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -FirstBootDevice $dvdDrive

Write-Host ""
Write-Host "VM is ready." -ForegroundColor Green
Write-Host "Name: $VMName"
Write-Host "ISO:  $isoPath"
Write-Host ""
Write-Host "Start it with:"
Write-Host "  Start-VM -Name `"$VMName`""
Write-Host "  vmconnect.exe localhost `"$VMName`""
Write-Host ""
Write-Host "Inside Arch, install the OS or use the live session, then run:"
Write-Host "  sudo pacman -Syu"
Write-Host "  sudo pacman -S --needed git archiso qemu-full edk2-ovmf"
Write-Host "  git clone https://github.com/Yoon-robin/RobinOS.git"
Write-Host "  cd RobinOS"
Write-Host "  scripts/doctor-build.sh"
Write-Host "  scripts/build-iso.sh"
