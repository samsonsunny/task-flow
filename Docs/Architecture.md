# TaskFlow Architecture (Context-Friendly)

## Goals
- Keep source files small and focused (target: **200–400 lines per file**).
- Organize by **feature**, so context is local and dependencies are obvious.
- Prefer **composition at the edges** (`App/`) and pure-ish logic in feature folders.

## Folder Map

### `TaskFlow/App/`
App entry points and composition root.
- Owns global navigation/shell decisions.
- Wires feature views together.

### `TaskFlow/Features/<Feature>/`
Feature-first organization. Each feature should be understandable in isolation.

Recommended subfolders (use what fits; don’t force all of them):
- `UI/` SwiftUI views (screens + UI-only helpers)
- `Model/` feature domain models/value types (if not shared)
- `State/` view state, reducers/stores, policies
- `Data/` persistence adapters / repositories

### `TaskFlow/Shared/`
Cross-feature code that is intentionally reusable.
- `Shared/UI/` common components
- `Shared/Extensions/` small standard-library extensions

### `TaskFlow/DesignSystem/`
Design tokens and shared styling primitives (colors, spacing, typography).

## Dependency Direction
- `App` → `Features` → `Shared` / `DesignSystem`
- `Shared` should not depend on specific features.
- `DesignSystem` should be dependency-light and stable.

## File Size Rule (Context)
If a file grows beyond ~400 lines:
1. Extract subviews into `UI/` siblings.
2. Move grouping/sorting/date logic into `State/` (or a small helper type).
3. Prefer **standalone `View` types** + small pure helpers over large view files.
