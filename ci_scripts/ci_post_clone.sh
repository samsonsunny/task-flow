#!/bin/bash

if [ "$CI_BRANCH" != "main" ] || [ "$CI_WORKFLOW" != "Weekly Release" ]; then
  exit 0
fi

git config user.name "TaskFlow CI"
git config user.email "ci@taskflow.app"

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
if git rev-parse "v$RELEASE" >/dev/null 2>&1; then
  echo "Tag v$RELEASE already exists (retry) — skipping tag"
  git push origin main
else
  git tag "v$RELEASE"
  git push origin main --tags
  echo "Tagged v$RELEASE"
fi
