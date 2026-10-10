$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\usr\local\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\assets" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\config" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\docs" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\packages" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\keys" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\labs" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\opt\robinos\themes" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\usr\share\wallpapers\RobinOS" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\usr\share\sddm\themes\robinos" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\usr\share\grub\themes\robinos" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\usr\share\pixmaps" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\etc\sddm.conf.d" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\archiso\airootfs\etc\default\grub.d" | Out-Null

Copy-Item "$root\bin\robinctl" "$root\archiso\airootfs\usr\local\bin\robinctl" -Force
Copy-Item "$root\installer\robin-install" "$root\archiso\airootfs\usr\local\bin\robin-install" -Force
Copy-Item "$root\assets\*" "$root\archiso\airootfs\opt\robinos\assets" -Recurse -Force
Copy-Item "$root\bin\*" "$root\archiso\airootfs\opt\robinos\bin" -Force
Copy-Item "$root\config\*" "$root\archiso\airootfs\opt\robinos\config" -Recurse -Force
# Only the Markdown: docs\screenshots (README pictures) stays out of the ISO
Copy-Item "$root\docs\*.md" "$root\archiso\airootfs\opt\robinos\docs" -Force
Copy-Item "$root\packages\*.txt" "$root\archiso\airootfs\opt\robinos\packages" -Force
Copy-Item "$root\keys\robinos-release.asc" "$root\archiso\airootfs\opt\robinos\keys\robinos-release.asc" -Force
Copy-Item "$root\labs\*" "$root\archiso\airootfs\opt\robinos\labs" -Recurse -Force
if (Test-Path "$root\archiso\airootfs\opt\robinos\desktop") {
    Remove-Item "$root\archiso\airootfs\opt\robinos\desktop" -Recurse -Force
}
Copy-Item "$root\desktop" "$root\archiso\airootfs\opt\robinos\desktop" -Recurse -Force
Copy-Item "$root\scripts\*.sh" "$root\archiso\airootfs\opt\robinos\scripts" -Force
Copy-Item "$root\scripts\*.ps1" "$root\archiso\airootfs\opt\robinos\scripts" -Force
Copy-Item "$root\themes\*" "$root\archiso\airootfs\opt\robinos\themes" -Recurse -Force
Copy-Item "$root\assets\wallpapers\*.svg" "$root\archiso\airootfs\usr\share\wallpapers\RobinOS" -Force
Copy-Item "$root\assets\brand\robinos-mark.svg" "$root\archiso\airootfs\usr\share\pixmaps\robinos-mark.svg" -Force
Copy-Item "$root\themes\sddm\robinos\*" "$root\archiso\airootfs\usr\share\sddm\themes\robinos" -Recurse -Force
Copy-Item "$root\themes\grub\robinos\*" "$root\archiso\airootfs\usr\share\grub\themes\robinos" -Recurse -Force
Copy-Item "$root\config\grub\10-robinos-theme.cfg" "$root\archiso\airootfs\etc\default\grub.d\10-robinos-theme.cfg" -Force
Copy-Item "$root\assets\brand\robinos-mark.svg" "$root\archiso\airootfs\usr\share\sddm\themes\robinos\logo.svg" -Force
Copy-Item "$root\assets\wallpapers\robinos-lock.svg" "$root\archiso\airootfs\usr\share\sddm\themes\robinos\background.svg" -Force
Copy-Item "$root\assets\wallpapers\robinos-lock.svg" "$root\archiso\airootfs\usr\share\sddm\themes\robinos\preview.svg" -Force

@"
[Theme]
Current=robinos
"@ | Set-Content -Encoding ASCII "$root\archiso\airootfs\etc\sddm.conf.d\10-robinos-theme.conf"

# Desktop files: same mapping as scripts/install-desktop.sh
foreach ($line in Get-Content "$root\desktop\install-map.txt") {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith("#")) {
        continue
    }

    $source, $destination, $mode = $line -split "\s+"
    $sourcePath = Join-Path $root ($source.TrimEnd("/") -replace "/", "\")
    $target = Join-Path "$root\archiso\airootfs" ($destination.Trim("/") -replace "/", "\")

    if ($mode -eq "dir") {
        if (Test-Path $target) {
            Remove-Item $target -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Copy-Item "$sourcePath\*" $target -Recurse -Force
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item $sourcePath $target -Force
    }
}

Write-Host "Synced RobinOS files into archiso/airootfs"
