# Task List Smart Order (Future Spec)

## Status
- Future feature spec only.
- Current production behavior remains: sort by `createdAt` (descending in iteration 1 plan).

## Goal
Provide a smart but predictable task ordering model that helps users see likely next actions quickly, without causing confusing list jumps.

## Non-Goals
- No ML ranking in v1.
- No hidden or continuously changing order.
- No decorative grouping that increases cognitive load.

## Product Principles
- Predictable first: users should understand why tasks move.
- Stable while scanning: avoid reorder churn during active reading.
- Fast interaction: updates only after meaningful events.
- Explainable ranking: every boost has a clear product reason.

## Phased Rollout
1. Phase 1 (Shipped baseline)
- Newest first (`createdAt` descending).

2. Phase 2 (Smart Order v1)
- Introduce `lastTouchedAt` and interaction boosts.
- Order by score, then stable tie-breakers.

3. Phase 3 (Optional)
- Add pinning and optional user-selected ordering mode.

## Data Model (Planned)
- `createdAt: Date` (existing)
- `lastTouchedAt: Date?` (new)
- `isPinned: Bool` (optional future)
- `manualRank: Int?` (optional future, if drag ordering is introduced)

## Ranking Model (Smart Order v1)
Order tasks by:
1. `isPinned` descending (if enabled)
2. `smartScore` descending
3. `createdAt` descending
4. `id` ascending (final stable tie-breaker)

### smartScore Inputs
- `recencyCreated`: newer tasks receive a moderate boost.
- `recencyTouched`: recently interacted tasks receive a stronger boost.
- `explicitBump`: optional small one-time boost when user marks task as “focus next.”

### Example Weights (Initial)
- `recencyTouched`: 0.60
- `recencyCreated`: 0.35
- `explicitBump`: 0.05

## Update Triggers
Recompute ordering only when:
- Task is created.
- Task is edited.
- User performs an explicit bump/focus action.
- App returns to foreground (single recompute pass).

Do not recompute continuously while user is scrolling.

## UX Rules
- Preserve scroll position when possible during reorder.
- Animate reorders subtly; no dramatic motion.
- Do not reorder while the user is actively dragging/scrolling.
- If keyboard is dismissed during capture, keep draft text intact.

## Explainability
- Optional v1.1: “Why this is near top” debug string for internal builds.
- Suggested reasons: “Recently edited”, “Recently added”, “Pinned”.

## Accessibility
- Ordering changes must not rely on color.
- VoiceOver order must follow visual order.
- Reorder announcements should be minimal and non-noisy.

## Telemetry (Future)
- Time to first task action from app open.
- Tasks acted on from top 5 list positions.
- Manual scroll depth before first action.
- Reopen rate after task creation.

## Risks and Mitigations
- Risk: list feels random.
  - Mitigation: stable tie-breakers + clear trigger rules.
- Risk: too much movement.
  - Mitigation: no continuous recompute; only event-driven updates.
- Risk: performance on larger lists.
  - Mitigation: precompute score fields where needed; avoid per-frame calculations.

## Open Questions
- Should Smart Order be default or opt-in under settings?
- Should pinned tasks be part of v1 or delayed to v1.1?
- Should explicit bump be swipe action or detail action?
