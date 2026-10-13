#!/usr/bin/env bash
set -euo pipefail

# Publishes the landing page (site/) to the gh-pages branch. GitHub Pages serves
# that branch at https://yoon-robin.github.io/RobinOS/ (repository Settings → Pages
# → Deploy from a branch: gh-pages, / (root)). No GitHub Actions involved.
#
# `git subtree split` gives the same commits for the same history, so each publish
# is a fast-forward of the last one.
#
#   bash scripts/publish-site.sh          # push what HEAD has in site/
#   bash scripts/publish-site.sh --dry-run

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -n "$(git status --porcelain -- site)" ]]; then
  printf 'site/에 커밋하지 않은 변경이 있어요. 커밋한 것만 올려요.\n' >&2
  exit 1
fi
for f in site/index.html site/.nojekyll; do
  git cat-file -e "HEAD:${f}" 2>/dev/null || { printf '%s가 커밋에 없어요\n' "${f}" >&2; exit 1; }
done

commit="$(git subtree split --prefix site HEAD)"
printf 'site/ → gh-pages: %s\n' "${commit}"
if [[ "${1:-}" == "--dry-run" ]]; then
  git ls-tree -r --name-only "${commit}" | sed 's/^/  /'
  exit 0
fi
git push origin "${commit}:refs/heads/gh-pages"
printf '올렸어요. 몇 분 뒤 https://yoon-robin.github.io/RobinOS/ 에 보여요.\n'
