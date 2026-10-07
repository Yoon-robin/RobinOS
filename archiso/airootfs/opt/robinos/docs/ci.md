# RobinOS CI

RobinOS can use GitHub Actions for early project health checks, but Actions is optional. The project also supports local validation and Git hooks.

## Recommended Without Actions

Use local validation:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-local-checks.ps1
```

Install a pre-push hook:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-git-hooks.ps1
```

Then every `git push` runs local validation first.

## Validate

Workflow:

```text
.github/workflows/validate.yml
```

Runs on:

- Push to `main`
- Pull requests
- Manual dispatch

Checks:

- Windows static validation through `scripts/validate-project.ps1`
- Bash syntax validation for scripts and installed command prototypes

If GitHub Actions is unavailable because of billing, spending limits, or account settings, run the local equivalent:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ci-local.ps1
```

## Build RobinOS ISO

Workflow:

```text
.github/workflows/build-iso.yml
```

Runs on:

- Push to `main` that touches the ISO, desktop, packages, scripts or themes
- Manual dispatch

Builds the ISO with `scripts/build-iso.sh` inside a privileged `archlinux:latest` container, so no Arch VM is needed. The ISO and `SHA256SUMS` are kept as the `robinos-iso` artifact for 7 days. If the build fails, the mkarchiso log is uploaded as `robinos-build-log`.

## Boot-test RobinOS ISO

Workflow:

```text
.github/workflows/boot-test.yml
```

Runs on:

- Every successful `Build RobinOS ISO` run
- Manual dispatch, optionally with the build run ID to test

`scripts/boot-test.sh` boots the ISO in QEMU (KVM when available) with a plain VGA display, like Hyper-V, so the desktop starts in software rendering. `scripts/boot-test-qmp.py` then opens the launcher, quick settings, a terminal with a Windows command, and the lock screen, and takes a screenshot at each step.

Results:

- Screenshots and `serial.log` as the `robinos-boot-test` artifact
- The same screenshots on the `boot-test` pre-release, shown in the job summary
- Key serial log lines (`robinos-session`, SDDM, failed units) in the job summary

The test boots with `robinos.debug`, which makes `robinos-session` copy Hyprland and shell output into the journal so it shows up in `serial.log`.

Run it locally on Linux after a build:

```bash
scripts/boot-test.sh out/robinos-*.iso
```

## Arch Package Check

Workflow:

```text
.github/workflows/arch-package-check.yml
```

Runs on:

- Manual dispatch
- Weekly schedule

Checks:

- Package names against current Arch repositories using `pacman -Si`

This workflow can fail when package names move between repositories or when a tool needs AUR/manual installation. If that happens, move the tool to `packages/security-optional.txt` or update its package name.

## Current Limitation

GitHub Actions requires the account to be allowed to run workflows. If a run fails before jobs start with a billing or spending-limit message, fix the GitHub account billing/settings first, then re-run the workflow.
