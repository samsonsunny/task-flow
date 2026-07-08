#!/bin/bash

# Only run during the weekly release workflow on main
if [ "$CI_BRANCH" != "main" ] || [ "$CI_WORKFLOW" != "Weekly Release" ]; then
  exit 0
fi

set -euo pipefail

git config user.name "TaskFlow CI"
git config user.email "ci@taskflow.app"

# Switch to HTTPS with PAT for push access (set GITHUB_TOKEN in Xcode Cloud env vars)
git remote set-url origin "https://samsonsunny:${GITHUB_TOKEN}@github.com/samsonsunny/task-flow.git"

# Wednesday after release = dev version
DEV=$(date -v +1d -v +Wed -v +7d '+%y.%-m.%-d')

CURRENT=$(grep -m1 "MARKETING_VERSION" TaskFlow.xcodeproj/project.pbxproj | grep -oE '\d+\.\d+\.\d+')
if [ "$CURRENT" != "$DEV" ]; then
  sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $DEV;/" \
    TaskFlow.xcodeproj/project.pbxproj
  git add TaskFlow.xcodeproj/project.pbxproj
  git commit -m "Set dev version to $DEV"
  git pull --rebase origin main
  git push origin main
  echo "Set dev version to $DEV"
fi
