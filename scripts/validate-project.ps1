$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error($message) {
    $errors.Add($message) | Out-Null
}

function Require-Path($path) {
    $fullPath = Join-Path $root $path
    if (-not (Test-Path $fullPath)) {
        Add-Error "Missing required path: $path"
    }
}

function Read-PackageList($path) {
    $fullPath = Join-Path $root $path
    if (-not (Test-Path $fullPath)) {
        Add-Error "Missing package list: $path"
        return @()
    }

    Get-Content $fullPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") }
}

function Validate-XmlFile($path) {
    $fullPath = Join-Path $root $path
    if (-not (Test-Path $fullPath)) {
        Add-Error "Missing XML/SVG file: $path"
        return
    }

    try {
        [xml](Get-Content $fullPath -Raw) | Out-Null
    } catch {
        Add-Error "Invalid XML/SVG: $path ($($_.Exception.Message))"
    }
}

function Validate-UniquePackages($path) {
    $packages = Read-PackageList $path
    $duplicates = $packages | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
    foreach ($pkg in $duplicates) {
        Add-Error "Duplicate package '$pkg' in $path"
    }
}

Write-Host "Validating RobinOS project..."

$requiredPaths = @(
    "README.md",
    ".github/workflows/validate.yml",
    ".github/workflows/arch-package-check.yml",
    "bin/robinctl",
    "installer/robin-install",
    "scripts/prepare-archiso.sh",
    "scripts/build-iso.sh",
    "scripts/doctor-build.sh",
    "scripts/run-vm.sh",
    "scripts/setup-windows-build-env.ps1",
    "scripts/setup-hyperv-arch-vm.ps1",
    "scripts/build-in-arch-container.sh",
    "scripts/clean-build.sh",
    "scripts/ci-local.ps1",
    "scripts/install-git-hooks.ps1",
    "scripts/run-local-checks.ps1",
    "scripts/customize-iso-boot.sh",
    "scripts/check-arch-packages.sh",
    "scripts/validate-project.ps1",
    "scripts/sync-archiso-files.sh",
    "scripts/sync-archiso-files.ps1",
    "scripts/post-install.sh",
    "scripts/install-branding.sh",
    "archiso/profiledef.sh",
    "archiso/packages.x86_64",
    "archiso/pacman.conf",
    "config/robinos.toml",
    "config/grub/10-robinos-theme.cfg",
    "packages/core.txt",
    "packages/security-baseline.txt",
    "packages/security-optional.txt",
    "labs/web/docker-compose.yml",
    "docs/build-iso.md",
    "docs/testing.md",
    "docs/release.md",
    "docs/boot-branding.md",
    "docs/ci.md",
    "docs/local-validation.md",
    "docs/vm-smoke-test.md",
    "docs/build-environment.md",
    "docs/hyperv-vm.md",
    "themes/sddm/robinos/Main.qml",
    "themes/grub/robinos/theme.txt",
    "themes/sddm/robinos/Glyph.qml",
    "packages/desktop.txt",
    "docs/design.md",
    "docs/desktop.md",
    "scripts/install-desktop.sh",
    "scripts/fetch-fonts.sh",
    "scripts/check-desktop.sh",
    "scripts/boot-test.sh",
    "scripts/boot-test-qmp.py",
    ".github/workflows/build-iso.yml",
    ".github/workflows/boot-test.yml",
    "desktop/install-map.txt",
    "desktop/shell/shell.qml",
    "desktop/shell/Theme.qml",
    "desktop/shell/ShellState.qml",
    "desktop/hypr/robinos.lua",
    "desktop/hypr/hyprland.lua",
    "desktop/bin/robinos-session",
    "desktop/session/robinos.desktop"
)

foreach ($path in $requiredPaths) {
    Require-Path $path
}

$svgFiles = @(
    "assets/brand/robinos-mark.svg",
    "assets/brand/robinos-logo.svg",
    "assets/brand/robinos-logo-horizontal.svg",
    "assets/wallpapers/robinos-default.svg",
    "assets/wallpapers/robinos-lock.svg",
    "themes/sddm/robinos/logo.svg",
    "themes/sddm/robinos/background.svg",
    "themes/sddm/robinos/preview.svg",
    "themes/grub/robinos/background.svg",
    "themes/grub/robinos/logo.svg",
    "themes/grub/robinos/select_c.svg",
    "themes/grub/robinos/select_e.svg",
    "themes/grub/robinos/select_w.svg"
)

foreach ($path in $svgFiles) {
    Validate-XmlFile $path
}

Validate-XmlFile "desktop/fontconfig/56-robinos-fonts.conf"

# Every source in the desktop install map must exist
foreach ($line in Get-Content (Join-Path $root "desktop/install-map.txt")) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith("#")) {
        continue
    }
    $fields = $line -split "\s+"
    if ($fields.Count -ne 3) {
        Add-Error "Malformed line in desktop/install-map.txt: $line"
        continue
    }
    Require-Path $fields[0].TrimEnd("/")
}

Validate-UniquePackages "packages/core.txt"
Validate-UniquePackages "packages/desktop.txt"
Validate-UniquePackages "packages/security-baseline.txt"
Validate-UniquePackages "packages/security-optional.txt"
Validate-UniquePackages "archiso/packages.x86_64"

$core = Read-PackageList "packages/core.txt"
$desktop = Read-PackageList "packages/desktop.txt"
$security = Read-PackageList "packages/security-baseline.txt"
$iso = Read-PackageList "archiso/packages.x86_64"

foreach ($pkg in $core) {
    if ($iso -notcontains $pkg) {
        Add-Error "Core package '$pkg' is missing from archiso/packages.x86_64"
    }
}

foreach ($pkg in $desktop) {
    if ($iso -notcontains $pkg) {
        Add-Error "Desktop package '$pkg' is missing from archiso/packages.x86_64"
    }
}

$expectedSecurityInIso = @(
    "nmap",
    "wireshark-qt",
    "tcpdump",
    "openbsd-netcat",
    "bind",
    "whois",
    "traceroute",
    "sqlmap",
    "nikto",
    "gobuster",
    "ffuf",
    "john",
    "hashcat",
    "hydra",
    "binwalk",
    "gdb",
    "strace",
    "ltrace",
    "testdisk",
    "perl-image-exiftool",
    "docker",
    "docker-compose",
    "virt-manager",
    "qemu-full"
)

foreach ($pkg in $expectedSecurityInIso) {
    if ($security -notcontains $pkg) {
        Add-Error "Expected ISO security package '$pkg' is missing from packages/security-baseline.txt"
    }
    if ($iso -notcontains $pkg) {
        Add-Error "Expected ISO security package '$pkg' is missing from archiso/packages.x86_64"
    }
}

$overlayPaths = @(
    "archiso/airootfs/usr/local/bin/robinctl",
    "archiso/airootfs/usr/local/bin/robin-install",
    "archiso/airootfs/opt/robinos/scripts/customize-iso-boot.sh",
    "archiso/airootfs/opt/robinos/scripts/build-iso.sh",
    "archiso/airootfs/opt/robinos/scripts/doctor-build.sh",
    "archiso/airootfs/opt/robinos/scripts/run-vm.sh",
    "archiso/airootfs/opt/robinos/docs/vm-smoke-test.md",
    "archiso/airootfs/opt/robinos/scripts/clean-build.sh",
    "archiso/airootfs/opt/robinos/docs/release.md",
    "archiso/airootfs/opt/robinos/themes/grub/robinos/theme.txt",
    "archiso/airootfs/usr/share/grub/themes/robinos/theme.txt",
    "archiso/airootfs/usr/share/sddm/themes/robinos/Main.qml",
    "archiso/airootfs/usr/share/wallpapers/RobinOS/robinos-default.svg",
    "archiso/airootfs/etc/sddm.conf.d/10-robinos-theme.conf",
    "archiso/airootfs/etc/default/grub.d/10-robinos-theme.cfg",
    "archiso/airootfs/etc/sddm.conf.d/20-robinos-live.conf",
    "archiso/airootfs/etc/xdg/hypr/hyprland.lua",
    "archiso/airootfs/usr/share/robinos/shell/shell.qml",
    "archiso/airootfs/usr/share/robinos/hypr/robinos.lua",
    "archiso/airootfs/usr/share/robinos/bin/robinos-session",
    "archiso/airootfs/usr/share/wayland-sessions/robinos.desktop",
    "archiso/airootfs/usr/share/sddm/themes/robinos/Glyph.qml"
)

foreach ($path in $overlayPaths) {
    Require-Path $path
}

# Scripts must be executable in git, or Linux checkouts cannot run them.
# Windows does not track the bit; fix with: git update-index --chmod=+x <file>
if (Get-Command git -ErrorAction SilentlyContinue) {
    Push-Location $root
    try {
        $entries = git ls-files -s -- "scripts/*.sh" "scripts/*.py" "bin/*" "installer/*" "desktop/bin/*" 2>$null
        foreach ($entry in $entries) {
            $mode, $rest = $entry -split "\s+", 2
            $path = ($entry -split "`t", 2)[1]
            if ($mode -ne "100755") {
                Add-Error "Script is not executable in git: $path (run: git update-index --chmod=+x $path)"
            }
        }
    } finally {
        Pop-Location
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Validation passed." -ForegroundColor Green
