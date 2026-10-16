# RobinOS 검증 올인원: RobinOS를 빌드해 본 적 없는 윈도우 PC에서 한 번 실행하면
# 이 PC가 할 수 있는 만큼 준비하고, 브랜치를 받아 검사·ISO 빌드·부팅·설치 테스트를
# 돌린 뒤 결과를 zip 하나로 모아요. 그 zip을 Claude 대화창에 올리면 돼요.
#
# PowerShell에서 (관리자가 아니어도 돼요):
#   [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iwr -UseBasicParsing https://raw.githubusercontent.com/Yoon-robin/RobinOS/main/scripts/verify-all-in-one.ps1 -OutFile $env:TEMP\rv.ps1; powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\rv.ps1
#
# - Tools go to %USERPROFILE%\RobinOS-tools, downloaded from their official sources and
#   checked against the published checksums: QEMU for Windows (qemu.weilnetz.de, SHA-512),
#   7-Zip to unpack it (GitHub release digest), Python (python.org, SHA-256) and Git
#   (Git for Windows' MinGit, GitHub release digest) only when the PC lacks them.
# - WSL 2 and the Windows Hypervisor Platform need an administrator once (and a restart).
#   Without them it stops and says what is missing; run it again after the restart.
# - Safe to run again: it picks up where it stopped.

param(
    [string]$Branch = "main",
    [string]$Repo = "https://github.com/Yoon-robin/RobinOS.git",
    [string]$Work = "",
    [ValidateSet("robinos", "windows", "archinstall")]
    [string]$Installer = "robinos",
    # Only the checks, the ISO and the boot test (the install test takes the longest)
    [switch]$SkipInstallTest
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # Invoke-WebRequest is many times slower with the bar
# Python writes through a pipe in blocks; line by line, so the tests' progress shows as it happens
$env:PYTHONUNBUFFERED = "1"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# An ASCII path: QEMU for Windows breaks paths with Korean letters (docs/build-environment.md)
if (-not $Work) {
    $Work = Join-Path $env:SystemDrive "RobinOS-verify"
    try { New-Item -ItemType Directory -Force $Work | Out-Null } catch { $Work = Join-Path $env:USERPROFILE "RobinOS-verify" }
}
New-Item -ItemType Directory -Force $Work | Out-Null
$tools = Join-Path $env:USERPROFILE "RobinOS-tools"
New-Item -ItemType Directory -Force $tools | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmm"
$results = Join-Path $Work "results-$stamp"
New-Item -ItemType Directory -Force $results | Out-Null
$summary = New-Object System.Collections.Generic.List[string]
$started = Get-Date
try { Start-Transcript -Path (Join-Path $results "log.txt") | Out-Null } catch { }

function Say([string]$text, [string]$color = "White") { Write-Host $text -ForegroundColor $color }
function Note([string]$text) { $summary.Add($text); Say "  $text" }
function Step([string]$text) { Say "`n== $text" "Cyan" }

function Finish([int]$code) {
    $summary.Add("")
    $summary.Add(("걸린 시간: {0:N0}분" -f ((Get-Date) - $started).TotalMinutes))
    $summary | Set-Content -Encoding UTF8 (Join-Path $results "summary.txt")
    try { Stop-Transcript | Out-Null } catch { }
    $zip = "$results.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path (Join-Path $results "*") -DestinationPath $zip
    Say "`n결과를 모았어요: $zip" "Green"
    Say "이 zip 파일을 Claude 대화창에 올려 주세요. 요약은 summary.txt예요."
    exit $code
}

function Get-File([string]$url, [string]$path) {
    if (-not (Test-Path $path)) {
        Say "  내려받기: $url"
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile "$path.part"
        Move-Item "$path.part" $path -Force
    }
}

function Assert-Hash([string]$path, [string]$algorithm, [string]$expected) {
    $got = (Get-FileHash -Algorithm $algorithm $path).Hash
    if ($got -ne $expected.Trim().ToUpper()) {
        Remove-Item $path -Force
        throw "체크섬이 맞지 않아 지웠어요: $path ($algorithm)"
    }
}

# A file from a GitHub release, checked against the digest GitHub publishes for it
function Get-GitHubAsset([string]$repo, [string]$pattern, [string]$dir) {
    $release = Invoke-RestMethod -UseBasicParsing "https://api.github.com/repos/$repo/releases/latest"
    $asset = $release.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
    if (-not $asset) { throw "$repo 릴리스에서 $pattern 파일을 찾지 못했어요" }
    if (-not $asset.digest -or $asset.digest -notmatch '^sha256:') { throw "$repo 릴리스가 $($asset.name)의 체크섬을 알려 주지 않아요" }
    $path = Join-Path $dir $asset.name
    Get-File $asset.browser_download_url $path
    Assert-Hash $path "SHA256" ($asset.digest -replace '^sha256:', '')
    return $path
}

# Windows PowerShell 5.1 turns a native command's redirected stderr into errors, and
# with "Stop" the first such line ends the whole script: native calls whose output is
# captured run with "Continue"
function Test-Python {
    $ErrorActionPreference = "Continue"
    try {
        $out = & python -c "import sys; print(sys.version_info[0])" 2>$null
        return ($LASTEXITCODE -eq 0 -and "$out".Trim() -eq "3")
    } catch { return $false }
}

Say "RobinOS 검증 올인원 ($Branch)" "Cyan"
Say "작업 폴더: $Work, 도구: $tools, 결과: $results"
$summary.Add("RobinOS 검증 결과 ($stamp, 브랜치 $Branch)")
$summary.Add("")

# ---- 1. What this PC allows ----
Step "1. 이 PC 확인"
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ramGb = [math]::Round($cs.TotalPhysicalMemory / 1GB)
$freeGb = [math]::Round((Get-PSDrive ($env:SystemDrive.TrimEnd(':'))).Free / 1GB)
$identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$winBuild = [int]$os.BuildNumber
$virt = $cs.HypervisorPresent -or $cpu.VirtualizationFirmwareEnabled
Note "윈도우: $($os.Caption) (빌드 $winBuild)"
Note "CPU: $($cpu.Name.Trim()), 논리 코어 $($cs.NumberOfLogicalProcessors)개"
Note "메모리: ${ramGb}GB, $($env:SystemDrive) 남은 공간: ${freeGb}GB"
Note ("관리자 권한: {0}, 가상화: {1}" -f $(if ($isAdmin) { "있어요" } else { "없어요" }), $(if ($virt) { "켜져 있어요" } else { "꺼져 있거나 알 수 없어요" }))

$blocked = @()
if ($winBuild -lt 19041) { $blocked += "윈도우 10 2004(빌드 19041) 이상이 필요해요" }
if ($freeGb -lt 40) { $blocked += "$($env:SystemDrive)에 40GB 이상 비어 있어야 해요(지금 ${freeGb}GB)" }
if ($ramGb -lt 8) { $blocked += "메모리가 8GB 이상이어야 해요(지금 ${ramGb}GB)" }
if ($blocked) {
    foreach ($b in $blocked) { Note "막힘: $b" }
    Finish 1
}

# ---- 2. WSL 2 and the Arch Linux distro ----
Step "2. WSL 2와 Arch Linux"
$wslReady = $false
$ErrorActionPreference = "Continue"
try { wsl.exe --status *> $null; $wslReady = ($LASTEXITCODE -eq 0) } catch { }
$ErrorActionPreference = "Stop"
if (-not $wslReady) {
    if (-not $isAdmin) {
        Note "막힘: WSL 2가 켜져 있지 않아요. 켜려면 관리자 권한이 한 번 필요해요."
        Note "관리자 PowerShell에서: wsl --install --no-distribution ; dism /online /enable-feature /featurename:HypervisorPlatform /all /norestart"
        Note "그다음 컴퓨터를 다시 켜고 이 스크립트를 다시 실행해요. 학교 PC라 관리자 권한이 없으면 이 PC에서는 검증할 수 없어요."
        Finish 2
    }
    Say "  WSL 2와 하이퍼바이저 플랫폼을 켜요(관리자)"
    wsl.exe --install --no-distribution
    dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart | Out-Null
    Note "WSL 2와 하이퍼바이저 플랫폼을 켰어요. 컴퓨터를 다시 켠 뒤 이 스크립트를 다시 실행해요."
    Finish 3
}
$distros = (wsl.exe -l -q) -replace "`0", "" | Where-Object { $_.Trim() -ne "" }
if ($distros -notcontains "archlinux") {
    Say "  Arch Linux를 설치해요(공식 WSL 배포판)"
    wsl.exe --install archlinux --no-launch
    if ($LASTEXITCODE -ne 0) { Note "막힘: Arch Linux를 설치하지 못했어요(wsl --install archlinux). 학교 네트워크가 막았을 수 있어요."; Finish 1 }
    wsl.exe -d archlinux -u root -e true
}
Note "WSL 2와 Arch Linux: 준비됨"

# An earlier run still going (a window left open, or one stuck on a step) would share
# the checkout and the WSL clone with this one: end it, and what it started in WSL
$leftover = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessId -ne $PID -and $_.CommandLine -and
    ($_.CommandLine -match 'verify-all-in-one\.ps1|\\rv\.ps1|wsl-build\.ps1' -or
     ($_.Name -eq "qemu-system-x86_64.exe" -and $_.CommandLine -match 'robinos'))
})
if ($leftover.Count -gt 0) {
    Note "이전 실행에서 남은 것을 끝냈어요 (프로세스 $($leftover.Count)개)"
    foreach ($p in $leftover) { taskkill.exe /T /F /PID $p.ProcessId 2>&1 | Out-Null }
    $term = Start-Process wsl.exe -ArgumentList "--terminate archlinux" -WindowStyle Hidden -PassThru
    $null = $term.WaitForExit(60000)
}

# ---- 3. Tools on the Windows side ----
Step "3. 도구 (Git, Python, QEMU)"
$downloads = Join-Path $tools "downloads"
New-Item -ItemType Directory -Force $downloads | Out-Null
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $gitDir = Join-Path $tools "git"
        if (-not (Test-Path "$gitDir\cmd\git.exe")) {
            $zip = Get-GitHubAsset "git-for-windows/git" '^MinGit-[\d.]+-64-bit\.zip$' $downloads
            Expand-Archive $zip $gitDir -Force
        }
        $env:PATH = "$gitDir\cmd;$env:PATH"
    }
    Note "Git: $((& git --version) -join ' ')"

    if (-not (Test-Python)) {
        $pyDir = Join-Path $tools "python"
        if (-not (Test-Path "$pyDir\python.exe")) {
            # The newest stable 3.x, with the SHA-256 python.org lists for its embeddable zip
            $releases = Invoke-RestMethod -UseBasicParsing "https://www.python.org/api/v2/downloads/release/?is_published=true&pre_release=false&version=3"
            $newest = $releases | Where-Object { $_.name -match '^Python 3\.\d+\.\d+$' } |
                Sort-Object { [version]($_.name -replace '^Python ', '') } | Select-Object -Last 1
            $id = ($newest.resource_uri.TrimEnd('/') -split '/')[-1]
            $files = Invoke-RestMethod -UseBasicParsing "https://www.python.org/api/v2/downloads/release_file/?release=$id"
            $embed = $files | Where-Object { $_.url -match 'embed-amd64\.zip$' } | Select-Object -First 1
            if (-not $embed.sha256_sum) { throw "python.org가 $($embed.url)의 SHA-256을 알려 주지 않아요" }
            $zip = Join-Path $downloads (Split-Path -Leaf $embed.url)
            Get-File $embed.url $zip
            Assert-Hash $zip "SHA256" $embed.sha256_sum
            Expand-Archive $zip $pyDir -Force
        }
        $env:PATH = "$pyDir;$env:PATH"
    }
    Note "Python: $((& python --version) -join ' ')"

    $qemuDir = Join-Path $tools "qemu"
    $qemu = Join-Path $qemuDir "qemu-system-x86_64.exe"
    if (-not (Test-Path $qemu)) {
        $sevenZip = Join-Path $tools "7zip\7z.exe"
        if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") { $sevenZip = "$env:ProgramFiles\7-Zip\7z.exe" }
        if (-not (Test-Path $sevenZip)) {
            $sevenZr = Get-GitHubAsset "ip7z/7zip" '^7zr\.exe$' $downloads
            $setup = Get-GitHubAsset "ip7z/7zip" '^7z\d+-x64\.exe$' $downloads
            & $sevenZr x $setup "-o$(Join-Path $tools '7zip')" -y | Out-Null
        }
        $listing = (Invoke-WebRequest -UseBasicParsing "https://qemu.weilnetz.de/w64/").Content
        $name = [regex]::Matches($listing, 'qemu-w64-setup-(\d{8})\.exe') | ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique | Select-Object -Last 1
        if (-not $name) { throw "qemu.weilnetz.de에서 QEMU 설치 파일을 찾지 못했어요" }
        $exe = Join-Path $downloads "qemu-w64-setup-$name.exe"
        Get-File "https://qemu.weilnetz.de/w64/qemu-w64-setup-$name.exe" $exe
        # The .sha512 comes as bytes, not text: read it from a file
        $shaFile = Join-Path $downloads "qemu-w64-setup-$name.sha512"
        Get-File "https://qemu.weilnetz.de/w64/qemu-w64-setup-$name.sha512" $shaFile
        $sha = ((Get-Content $shaFile -Raw).Trim() -split '\s+')[0]
        Assert-Hash $exe "SHA512" $sha
        & $sevenZip x $exe "-o$qemuDir" -y | Out-Null
    }
    Note "QEMU: $qemu"
} catch {
    Note "막힘: 도구를 준비하지 못했어요: $($_.Exception.Message)"
    Finish 1
}

# Does the Windows Hypervisor Platform work? QEMU tells at once when it doesn't
$whpx = $false
$probe = Start-Process -FilePath $qemu -ArgumentList "-accel whpx -machine q35 -m 128 -display none -nodefaults -S" `
    -PassThru -WindowStyle Hidden -RedirectStandardError (Join-Path $results "whpx-probe.txt")
if (-not $probe.WaitForExit(6000)) { $whpx = $true; $probe.Kill() }
if ($whpx) {
    Note "가속(WHPX): 돼요. 빠른 묶음 검증(verify)을 써요"
} else {
    Note "가속(WHPX): 안 돼요. 느린 방식(TCG)으로 ISO와 부팅 테스트만 해요. 켜려면 관리자 PowerShell에서 dism /online /enable-feature /featurename:HypervisorPlatform /all /norestart 뒤 다시 켜요"
}

# ---- 4. The branch ----
Step "4. 저장소 받기 ($Branch)"
$repoDir = Join-Path $Work "RobinOS"
try {
    if (Test-Path (Join-Path $repoDir ".git")) {
        git -C $repoDir fetch -q origin $Branch
        git -C $repoDir checkout -q -B verify FETCH_HEAD
        git -C $repoDir reset -q --hard FETCH_HEAD
    } else {
        git clone -q --branch $Branch --single-branch $Repo $repoDir
    }
    if ($LASTEXITCODE -ne 0) { throw "git이 실패했어요" }
    # git writes UTF-8; Windows PowerShell would read it in the console's code page
    $consoleEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    $commit = (git -C $repoDir log -1 --format="%h %s")
    [Console]::OutputEncoding = $consoleEncoding
    Note "커밋: $commit"
} catch {
    Note "막힘: 저장소를 받지 못했어요: $($_.Exception.Message)"
    Finish 1
}
$wslBuild = Join-Path $repoDir "scripts\wsl-build.ps1"

# Ends a task that runs far past its usual time, so a run never sits on one step for
# hours (2026-10-15: a test waited for a key nobody saw). Runs as a background job: it
# notes what was running in <task>-stuck.txt, then ends the task's PowerShell with
# everything it started (wsl.exe, Python, QEMU) and what is left in WSL.
$watchdog = {
    param([int]$parentId, [int]$minutes, [string]$stuck)
    Start-Sleep -Seconds ($minutes * 60)
    $tasks = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$parentId" | Where-Object { $_.CommandLine -match 'wsl-build\.ps1' })
    if ($tasks.Count -eq 0) { return }
    $windows = Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(powershell|wsl|python|qemu)' } |
        Select-Object ProcessId, ParentProcessId, CommandLine | Format-Table -AutoSize -Wrap | Out-String -Width 300
    $wslList = "$stuck.wsl"
    $ps = Start-Process wsl.exe -ArgumentList "-d archlinux -u root -e ps -eo pid,etime,args --forest" `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput $wslList
    $null = $ps.WaitForExit(30000)
    $text = @("제한 시간 ${minutes}분을 넘겨서 멈췄어요. 그때 돌던 프로세스:", "", "== 윈도우", $windows, "== WSL")
    if (Test-Path $wslList) { $text += Get-Content $wslList }
    $text | Set-Content -Encoding UTF8 $stuck
    foreach ($t in $tasks) { taskkill.exe /T /F /PID $t.ProcessId 2>&1 | Out-Null }
    $term = Start-Process wsl.exe -ArgumentList "--terminate archlinux" -WindowStyle Hidden -PassThru
    $null = $term.WaitForExit(60000)
}

function Invoke-Task([string]$title, [string[]]$taskArgs, [int]$limit, [string]$usual) {
    $ErrorActionPreference = "Continue"
    Step $title
    Say "  보통 $usual 걸려요. ${limit}분이 넘으면 멈추고 다음으로 넘어가요." "DarkGray"
    $t0 = Get-Date
    $log = Join-Path $results (($taskArgs[0]) + ".txt")
    $stuck = Join-Path $results (($taskArgs[0]) + "-stuck.txt")
    $job = Start-Job -ScriptBlock $watchdog -ArgumentList $PID, $limit, $stuck
    # Every line on the screen as it comes, with the time, and in the step's log. Out-Host:
    # what a function outputs is its return value, so `$ok = Invoke-Task` used to swallow
    # it all and the window showed nothing for hours (2026-10-15). "$_" also turns
    # PowerShell's stderr records back into plain lines.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wslBuild @taskArgs 2>&1 |
        ForEach-Object { "[{0:HH:mm:ss}] {1}" -f (Get-Date), "$_" } |
        Tee-Object -FilePath $log -Append | Out-Host
    $code = $LASTEXITCODE
    $minutes = ((Get-Date) - $t0).TotalMinutes
    # The job may still be ending what the task left in WSL
    if (Test-Path $stuck) { $null = Wait-Job $job -Timeout 120 }
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    if ($code -eq 0) {
        Note ("{0}: 통과 ({1:N1}분)" -f $title, $minutes)
    } else {
        $why = "종료 코드 $code"
        if (Test-Path $stuck) { $why = "제한 시간 ${limit}분을 넘겨서 멈췄어요, 그때 돌던 것은 $(Split-Path -Leaf $stuck)" }
        Note ("{0}: 실패 ({1}, {2:N1}분, 기록 {3})" -f $title, $why, $minutes, (Split-Path -Leaf $log))
        # Why, in the summary itself: the lines the tests mark as failed
        # (the boot test inside verify writes to build\verify-boot.log)
        $logs = @($log, (Join-Path $repoDir "build\verify-boot.log")) | Where-Object { Test-Path $_ }
        Get-Content $logs -ErrorAction SilentlyContinue |
            ForEach-Object { $_ -replace '^\[\d\d:\d\d:\d\d\] ', '' } |
            Where-Object { $_ -match '^\s*FAILED |\[install-test\] FAILED|: missing \(|: FAIL |scenario stopped|Desktop check failed|Quick checks FAILED' -and $_ -notmatch '^\s*\+' } |
            Select-Object -First 12 | ForEach-Object {
                $line = ($_ -replace "\x1b\[[0-9;]*m", "").Trim()
                if ($line.Length -gt 220) { $line = $line.Substring(0, 220) + "..." }
                Note "    - $line"
            }
    }
    return ($code -eq 0)
}

# ---- 5. Build environment, checks, ISO and tests ----
# Each test VM takes 6 GB; on a PC with less than 12 GB they get 4 GB
$vmArgs = @("-Qemu", $qemu)
if ($ramGb -lt 12) { $vmArgs += @("-MemoryMB", "4096"); Note "메모리가 적어서 테스트 VM을 4GB로 띄워요" }
# Time limits (minutes) well past the usual times
$ok = Invoke-Task "5. WSL 빌드 도구 준비" @("setup") 60 "처음에는 10~20분, 그다음부터는 1분"
if ($ok) {
    $null = Invoke-Task "6. 빠른 검사 (설정 검사, qmllint, robinctl·설치기 시험)" @("check") 60 "5분 안쪽"
    if ($whpx -and $ramGb -ge 16 -and -not $SkipInstallTest) {
        $null = Invoke-Task "7. 묶음 검증 (ISO + 부팅·설치 테스트 동시)" (@("verify", "-Installer", $Installer) + $vmArgs) 180 "30~40분"
    } elseif ($whpx) {
        # Two VMs of 6 GB at once need 16 GB; one after the other is fine with less
        if (Invoke-Task "7. ISO 빌드" @("build") 120 "15~25분") {
            $null = Invoke-Task "8. 부팅 테스트" (@("boot-test", "-Accel", "whpx") + $vmArgs) 90 "10~15분"
            if (-not $SkipInstallTest) { $null = Invoke-Task "9. 설치 테스트 ($Installer)" (@("install-test", "-Installer", $Installer, "-Accel", "whpx") + $vmArgs) 180 "20~40분" }
        }
    } else {
        if (Invoke-Task "7. ISO 빌드" @("build") 120 "15~25분") {
            $null = Invoke-Task "8. 부팅 테스트 (TCG, 오래 걸려요)" @("boot-test", "-Accel", "tcg") 480 "1~3시간"
            Note "설치 테스트: 건너뜀 (가속 없이는 몇 시간 걸려요)"
        }
    }
}

# ---- Results ----
Step "결과 모으기"
$buildDir = Join-Path $repoDir "build"
foreach ($pair in @(@("boot-test", "*.png"), @("boot-test", "*.log"), @("install-test", "*.png"), @("install-test", "*.log"))) {
    $src = Join-Path $buildDir $pair[0]
    if (Test-Path $src) {
        $dest = Join-Path $results $pair[0]
        New-Item -ItemType Directory -Force $dest | Out-Null
        Get-ChildItem $src -Filter $pair[1] -File | Copy-Item -Destination $dest
    }
}
foreach ($f in "verify-boot.log", "verify-boot.log.err") {
    if (Test-Path (Join-Path $buildDir $f)) { Copy-Item (Join-Path $buildDir $f) $results }
}
$failed = $summary | Where-Object { $_ -match ': 실패|^막힘' }
Finish $(if ($failed) { 1 } else { 0 })
