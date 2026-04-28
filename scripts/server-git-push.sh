#!/usr/bin/env bash
# Run on the Cloudways server (after SSH). Pushes codebase to GitHub using the repo deploy key.
# Usage on server:
#   export APP_PATH="/home/master/applications/YOUR_APP_ID/public_html"
#   bash server-git-push.sh
#
# From Windows (PowerShell), pipe this file:
#   $env:APP_PATH="/home/master/applications/xxx/public_html"
#   Get-Content scripts\server-git-push.sh -Raw | ssh -p PORT master@HOST "export APP_PATH='$env:APP_PATH'; bash -s"

set -euo pipefail

REPO_SSH="${REPO_SSH:-git@github.com:tbsdigitallabs/TBS-Staging.git}"
BRANCH="${BRANCH:-main}"

if [[ -z "${APP_PATH:-}" ]]; then
  echo "ERROR: Set APP_PATH to your Cloudways web root, e.g. /home/master/applications/xxxxxx/public_html" >&2
  exit 1
fi

cd "$APP_PATH"

if [[ ! -d .git ]]; then
  git init
fi

if ! git config user.email >/dev/null 2>&1; then
  git config user.email "cloudways-git@localhost"
  git config user.name "Cloudways import"
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REPO_SSH"
else
  git remote add origin "$REPO_SSH"
fi

git add -A
if git diff --cached --quiet 2>/dev/null; then
  echo "No staged changes to commit."
else
  git commit -m "Import codebase from Cloudways" || true
fi

git branch -M "$BRANCH"

set +e
git fetch origin "$BRANCH"
FETCH_OK=$?
set -e

if [[ $FETCH_OK -eq 0 ]] && git show-ref --verify --quiet "refs/remotes/origin/$BRANCH" 2>/dev/null; then
  git merge "origin/$BRANCH" --allow-unrelated-histories --no-edit -m "Merge GitHub ${BRANCH} with Cloudways tree" || {
    echo "Merge failed — fix conflicts then: git merge --continue && git push -u origin $BRANCH" >&2
    exit 1
  }
fi

git push -u origin "$BRANCH"
echo "Done. Pushed to $BRANCH."
