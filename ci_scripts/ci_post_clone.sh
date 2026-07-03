#!/bin/bash

# Only run during the weekly release workflow on main
if [ "$CI_BRANCH" != "main" ] || [ "$CI_WORKFLOW" != "Weekly Release" ]; then
  exit 0
fi

# Days from today until the next Wednesday
DOW=$(date +%u)
if [ "$DOW" -le 3 ]; then
  BASE_OFFSET=$((3 - DOW))
else
  BASE_OFFSET=$((10 - DOW))
fi

# Advance week by week until we find a version/tag that hasn't been used
WEEKS=0
while true; do
  OFFSET=$((BASE_OFFSET + WEEKS * 7))
  VERSION=$(date -v +"${OFFSET}"d '+%y.%-m.%-d')
  TAG="v$VERSION"
  if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    break
  fi
  WEEKS=$((WEEKS + 1))
done

# Check if already on this version
CURRENT=$(grep -m1 "MARKETING_VERSION" TaskFlow.xcodeproj/project.pbxproj | grep -oE '\d+\.\d+\.\d+')
if [ "$CURRENT" = "$VERSION" ]; then
  echo "Already at $VERSION — nothing to bump"
  exit 0
fi

# Set git config for Xcode Cloud environment
git config user.name "TaskFlow CI"
git config user.email "ci@taskflow.app"

# Update MARKETING_VERSION in Xcode project
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/" \
  TaskFlow.xcodeproj/project.pbxproj

# Commit the bump, tag, and push
git add TaskFlow.xcodeproj/project.pbxproj
git commit -m "Bump version to $VERSION"
git tag "$TAG"
git push origin main --tags

echo "Bumped to $VERSION, tagged $TAG"
