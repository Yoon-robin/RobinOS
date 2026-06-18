# RobinOS Local Validation

GitHub Actions is optional. RobinOS can be validated locally before pushing or building.

## One-Time Hook Setup

Install the local pre-push hook:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-git-hooks.ps1
```

After this, `git push` runs:

```powershell
scripts/ci-local.ps1
```

If validation fails, the push is blocked.

## Manual Local Check

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-local-checks.ps1
```

This runs local CI and prints Git status.

## Arch VM Check

On Arch Linux:

```bash
scripts/check-arch-packages.sh
scripts/build-iso.sh
```

This is the real test for ISO readiness.

## Recommended Flow

Use this instead of GitHub Actions:

```text
Edit files
Run scripts/run-local-checks.ps1
Commit
Push
Build in Arch VM
Boot the ISO in a VM
```

