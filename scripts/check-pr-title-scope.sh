#!/usr/bin/env bash
# Release Please attributes a commit to a chart by its conventional-commit
# scope. This repository squash-merges, so the PR *title* becomes that commit
# message — a title without the chart's scope releases nothing, and the fix
# sits on main unreleased and unpinnable. That happened on 2026-08-21 with
# #169 and cost two follow-up PRs to repair.
#
# Usage: check-pr-title-scope.sh "<pr title>" <changed chart>...
set -euo pipefail

title=${1-}
shift || true
charts=("$@")

if [ ${#charts[@]} -eq 0 ]; then
  echo "No chart changed; the title scope does not matter here."
  exit 0
fi

# Release Please's own pull requests are scoped to `main` by design and carry
# the chart in the subject instead.
if [[ $title =~ ^chore\(main\):\ release\  ]]; then
  echo "Release Please pull request; leaving its title alone."
  exit 0
fi

if [ ${#charts[@]} -gt 1 ]; then
  echo "::error::This pull request changes ${#charts[@]} charts (${charts[*]}), and a squash merge carries exactly one scope. Split it: one pull request per chart, or Release Please releases at most one of them."
  exit 1
fi

chart=${charts[0]}

if [[ ! $title =~ ^[a-z]+\(([^\)]+)\)!?:\  ]]; then
  echo "::error::The title must carry the chart scope, because the squash merge makes it the commit message: \"fix(${chart}): …\". Got: \"${title}\""
  exit 1
fi

scope=${BASH_REMATCH[1]}
if [ "$scope" != "$chart" ]; then
  echo "::error::The title is scoped to \"${scope}\" but the pull request changes charts/${chart}. Release Please would attribute the commit to neither. Use \"fix(${chart}): …\"."
  exit 1
fi

echo "Title scope \"${scope}\" matches the changed chart."
