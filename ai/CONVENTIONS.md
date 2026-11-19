# Code Conventions

Load this before editing Swift, schema, or styling code.

## Dates

`DateFormatter.setLocalizedDateFormatFromTemplate()`: set `formatter.locale` **before** the template call. Template parsing is locale-sensitive and determines component order ("May 15" vs "15 May"); setting locale afterward only changes names.

## Colors

- Only semantic tokens from `TaskFlow/DesignSystem/Colors.swift` (`primaryAction`, `appBackground`, `surface`, `textPrimary`, `textSecondary`, `textDisabled`, `border`, ...).
- No raw hex values in views. No opacity-based text coloring.
- Assets live in `TaskFlow/Assets.xcassets`.

## SwiftData schema changes

1. Preferred for simple additions: add the property to the latest schema version and remove `migrationPlan:` from `ModelContainer` — implicit lightweight migration, no checksum validation.
2. Full versioned schema: new version (e.g. `TaskFlowSchemaV10`), update typealiases and `Schema(versionedSchema:)` in `TaskFlowApp.swift` and `TaskPreviewData.swift`. **Never add `migrationPlan:`** — it triggers checksum collisions.

## CloudKit immutability

Model is mirrored to CloudKit via `ModelConfiguration(cloudKitDatabase:)`. Production record types are sealed by `CURRENT_PROJECT_VERSION` (`CFBundleVersion`).

- Any new field, relationship, or rename on an existing `@Model` **requires a strictly higher `CURRENT_PROJECT_VERSION`**.
- Without the bump, export/import fails silently with `Cannot create or modify field '<name>' in record '<type>' in production schema`; users see local-only saves and data loss after reinstall.
- `MARKETING_VERSION` bumps do not help.
- New entities alone need no bump; changing deployed entities does.
- If a bump is unavailable, derive the value at runtime instead of adding the field.
- Recovery: ship a higher build number so the delegate deploys a new generation and re-imports records. Resetting the CloudKit production environment is a last resort.

## Testing pattern

Xcode targets `TaskFlowTests` and `TaskFlowUITests` exist in the project but contain no sources. There is no app test suite, lint config, or formatter. Do not claim tests ran unless you add and run them.

## Naming

`TaskFlow` is internal (code, folders, internal docs). Customer-facing copy is **Wednesday Calendar**; download CTA: `https://apps.apple.com/us/app/wednesday/id1455779789`.
