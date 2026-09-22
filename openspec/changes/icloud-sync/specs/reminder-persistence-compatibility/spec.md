## MODIFIED Requirements

### Requirement: Reminder persistence evolution uses non-destructive schema migration
The system SHALL evolve reminder persistence through a non-destructive migration path that supports additive schema growth and future reminder requirements. Once CloudKit sync is enabled and the production schema is promoted, evolution becomes additive-only: model types cannot be removed and existing attributes cannot change type, because CloudKit schemas are immutable after deployment to production.

#### Scenario: App upgrades to expanded schema
- **WHEN** the app upgrades from the legacy reminder schema to the expanded reminder schema
- **THEN** the migration completes without deleting the existing reminder store

#### Scenario: Future fields can be added without redefining legacy reminders
- **WHEN** additional reminder metadata is introduced in later versions
- **THEN** the persistence design supports adding those fields through further versioned evolution rather than a one-time destructive reset

#### Scenario: CloudKit production schema constrains future evolution
- **WHEN** a schema version is promoted to the CloudKit production environment
- **THEN** subsequent releases SHALL evolve the model only by adding optional-or-default attributes and optional relationships, and SHALL NOT delete model types or change existing attribute types

## ADDED Requirements

### Requirement: Model schema satisfies CloudKit mirroring constraints
The system SHALL keep all persisted model types compatible with SwiftData's CloudKit mirroring: every attribute SHALL be optional or have a property-level default value, every relationship SHALL be optional, no `@Attribute(.unique)` constraints SHALL be used, and no `.deny` delete rule SHALL be used.

#### Scenario: Attributes are CloudKit-compatible
- **WHEN** the CloudKit-backed container initializes against the schema
- **THEN** no attribute triggers the "must be optional, or have a default value" CloudKit error

#### Scenario: Relationships are CloudKit-compatible
- **WHEN** the CloudKit-backed container initializes against the schema
- **THEN** no relationship, including to-many array relationships, triggers the "all relationships must be optional" CloudKit error

### Requirement: Previews and tests stay on local stores
The system SHALL keep preview and test model containers on in-memory stores with `cloudKitDatabase: .none` so that development tooling never touches a CloudKit container or requires an iCloud account.

#### Scenario: Preview container is local
- **WHEN** a SwiftUI preview builds a `TaskPreviewData.container()`
- **THEN** the container is in-memory and local-only with no CloudKit dependency

#### Scenario: Test container is local
- **WHEN** the unit/UI test suites build their model container
- **THEN** the container is in-memory and local-only with no CloudKit dependency