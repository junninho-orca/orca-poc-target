#!/usr/bin/env bash
# Restores the vulnerable baseline: closes open PRs, deletes stale branches, and hard-resets
# main back to the `baseline` tag. Run this before every demo (§12 pre-demo checklist item 5).
set -euo pipefail

REPO="junninho-orca/orca-poc-target"

echo "==> Closing open PRs on $REPO"
gh pr list --repo "$REPO" --state open --json number --jq '.[].number' | while read -r pr; do
  echo "    closing PR #$pr"
  gh pr close "$pr" --repo "$REPO" --delete-branch || true
done

echo "==> Fetching and pruning remote branches"
git fetch origin --prune

echo "==> Deleting stale branches (everything except main)"
git branch -r | grep 'origin/' | grep -v 'origin/main' | grep -v 'HEAD ->' | sed 's#.*origin/##' | while read -r branch; do
  echo "    deleting branch $branch"
  git push origin --delete "$branch" || true
done

echo "==> Resetting main to the vulnerable baseline (tag: baseline)"
git checkout main
git fetch origin --tags
git reset --hard baseline
git push origin main --force-with-lease

echo "==> Target repo reset to baseline complete."
