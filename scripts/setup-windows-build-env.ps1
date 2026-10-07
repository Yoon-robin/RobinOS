$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "RobinOS Windows build environment setup"
Write-Host ""

if (-not (Test-IsAdmin)) {
    Write-Host "This script must be run from an elevated Administrator PowerShell." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Open PowerShell as Administrator, then run:"
    Write-Host "  cd `"$PWD`""
    Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/setup-windows-build-env.ps1"
    exit 1
}

Write-Host "Step 1: Enable WSL and Virtual Machine Platform"
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host ""
Write-Host "Step 2: Set WSL 2 as default"
wsl --set-default-version 2

Write-Host ""
Write-Host "Step 3: Install an Arch-compatible path"
Write-Host "Windows does not reliably provide official Arch Linux WSL on every machine."
Write-Host "Recommended next step:"
Write-Host "  1. Reboot Windows if WSL features were newly enabled."
Write-Host "  2. Install an Arch Linux VM, or install Docker Desktop/WSL Arch manually."
Write-Host "  3. In that Arch environment, run:"
Write-Host ""
Write-Host "     git clone https://github.com/Yoon-robin/RobinOS.git"
Write-Host "     cd RobinOS"
Write-Host "     sudo pacman -Syu"
Write-Host "     sudo pacman -S --needed archiso git qemu-full edk2-ovmf"
Write-Host "     scripts/doctor-build.sh"
Write-Host "     scripts/build-iso.sh"
Write-Host "     scripts/run-vm.sh"
Write-Host ""
Write-Host "WSL base features are prepared. A reboot may be required." -ForegroundColor Green

