#!/usr/bin/env bash
# Restores the vulnerable baseline: closes open PRs, deletes stale branches, and hard-resets
# main back to the `baseline` tag. Run this before every demo (§12 pre-demo checklist item 5).
#
# Branch protection on main requires allow_force_pushes:false (§6 "no force push") — which
# means the hard reset this script exists to do is, by design, impossible without briefly
# lifting that one setting. This script does exactly that and nothing else: it never touches
# required_status_checks, enforce_admins, or allow_deletions, and it re-applies the full
# protected configuration (scripts/branch_protection.json) before exiting on any path,
# including failure. Verified live once: a bare `git push --force` to main was rejected while
# protection was in its normal (locked) state.
set -euo pipefail

REPO="junninho-orca/orca-poc-target"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTECTION_JSON="$SCRIPT_DIR/branch_protection.json"

restore_protection() {
  echo "==> Restoring branch protection (allow_force_pushes: false)"
  gh api "repos/$REPO/branches/main/protection" -X PUT --input "$PROTECTION_JSON" >/dev/null
}
trap restore_protection EXIT

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

echo "==> Temporarily allowing force-push to main (required_status_checks/enforce_admins/allow_deletions untouched)"
python3 -c "
import json
cfg = json.load(open('$PROTECTION_JSON'))
cfg['allow_force_pushes'] = True
print(json.dumps(cfg))
" | gh api "repos/$REPO/branches/main/protection" -X PUT --input - >/dev/null

echo "==> Resetting main to the vulnerable baseline (tag: baseline)"
git checkout main
git fetch origin --tags
git reset --hard baseline
git push origin main --force

echo "==> Target repo reset to baseline complete."
# restore_protection runs automatically via the EXIT trap, even if a step above failed.
