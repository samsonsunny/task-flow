#!/bin/sh
set -eu

WORKFLOW=$(printf '%s' "${CI_WORKFLOW:-}" | tr '[:upper:]' '[:lower:]')
if [ "${CI:-}" != "TRUE" ] || [ "$WORKFLOW" != "ci" ]; then
  exit 0
fi

if [ "${CI_START_CONDITION:-}" != "schedule" ]; then
  exit 0
fi

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ] || [ "${CI_XCODEBUILD_EXIT_CODE:-0}" != "0" ]; then
  exit 0
fi

for name in ASC_KEY_ID ASC_ISSUER_ID ASC_API_KEY_BASE64; do
  if [ -z "$(printenv "$name" || true)" ]; then
    echo "App Store submission failed: $name is not set on the CI workflow." >&2
    exit 1
  fi
done

INFO_PLIST="${CI_ARCHIVE_PATH:-}/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$INFO_PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")

python3 "${CI_PRIMARY_REPOSITORY_PATH}/ci_scripts/appstore_submit.py" \
  --bundle-id "${CI_BUNDLE_ID:-com.samson.wednesday}" \
  --version "$VERSION" \
  --build-number "$BUILD_NUMBER"
