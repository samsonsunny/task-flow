## ADDED Requirements

### Requirement: Codebase free of unreferenced source files

The project SHALL contain no Swift source files that have zero consumers (no other file references any type, extension, or symbol declared within them). Files whose only content is commented-out code SHALL be removed.

#### Scenario: Orphaned files are detected
- **WHEN** a Swift source file declares types, extensions, or functions
- **AND** no other file in the project imports or references any of those declarations
- **THEN** that file SHALL be removed from the repository

#### Scenario: Commented-out code is removed
- **WHEN** a Swift source file contains only commented-out code and non-functional imports
- **THEN** that file SHALL be removed from the repository

### Requirement: Empty directories removed

The project SHALL contain no empty directories under `TaskFlow/` that serve no organizational purpose.

#### Scenario: Empty directory is removed
- **WHEN** a directory under `TaskFlow/` contains no source files, resources, or other tracked content
- **THEN** that directory SHALL be removed from the repository

### Requirement: Build integrity after cleanup

The project SHALL compile and pass all existing tests after unused files are removed.

#### Scenario: Build succeeds after cleanup
- **WHEN** the Xcode project is built after all targeted files are deleted
- **THEN** the build SHALL succeed with no new errors or warnings

#### Scenario: Tests pass after cleanup
- **WHEN** all unit and UI tests are run after cleanup
- **THEN** all tests SHALL pass with the same results as before cleanup
