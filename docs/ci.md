# RobinOS CI

RobinOS uses GitHub Actions for early project health checks.

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

