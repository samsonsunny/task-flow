#!/bin/bash

# Only run during the weekly release workflow on main
if [ "$CI_BRANCH" != "main" ] || [ "$CI_WORKFLOW" != "Weekly Release" ]; then
  exit 0
fi

set -euo pipefail

cd "${CI_WORKSPACE:-$(cd "$(dirname "$0")" && pwd)/..}"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "error: GITHUB_TOKEN is not set. Add it to Xcode Cloud environment variables."
  exit 1
fi

git config user.name "TaskFlow CI"
git config user.email "ci@taskflow.app"

# Switch to HTTPS with PAT for push access (set GITHUB_TOKEN in Xcode Cloud env vars)
git remote set-url origin "https://samsonsunny:${GITHUB_TOKEN}@github.com/samsonsunny/task-flow.git"

# Next Wednesday = release version (e.g. July 15 → 26.7.15)
RELEASE=$(date -v +1d -v +Wed '+%y.%-m.%-d')

# Set project to release version
CURRENT=$(grep -m1 "MARKETING_VERSION" TaskFlow.xcodeproj/project.pbxproj | grep -oE '\d+\.\d+\.\d+')
if [ "$CURRENT" != "$RELEASE" ]; then
  sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $RELEASE;/" \
    TaskFlow.xcodeproj/project.pbxproj
  git add TaskFlow.xcodeproj/project.pbxproj
  git commit -m "Set version to $RELEASE"
fi

git pull --rebase origin main

# Push main first as its own step — never block it on the tag.
git push origin main

# Check the REMOTE, not the local clone (Xcode Cloud clones often have no tags).
if git ls-remote --tags origin "refs/tags/v$RELEASE" 2>/dev/null | grep -q "refs/tags/v$RELEASE"; then
  echo "Tag v$RELEASE already exists on origin (retry) — skipping tag"
else
  git tag "v$RELEASE" 2>/dev/null || true
  # Push only this tag ref; a pre-existing conflicting tag must not fail the build.
  if git push origin "refs/tags/v$RELEASE:refs/tags/v$RELEASE" 2>/dev/null; then
    echo "Tagged v$RELEASE"
  else
    echo "Warn: tag v$RELEASE already exists on origin — skipping tag"
  fi
fi
