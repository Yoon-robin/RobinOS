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
