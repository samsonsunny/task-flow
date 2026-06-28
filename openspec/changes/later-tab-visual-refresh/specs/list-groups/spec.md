## ADDED Requirements

### Requirement: Thin divider between ungrouped and grouped sections

When both an ungrouped section and grouped sections are visible, a thin visual divider SHALL appear between the last ungrouped list and the first group. The divider SHALL use `AppTheme.colors.divider` and SHALL span the full width of the list.

#### Scenario: Divider appears between ungrouped and grouped sections
- **WHEN** the Later tab displays both ungrouped lists and grouped sections
- **THEN** a thin divider SHALL separate the two regions

#### Scenario: No divider when only one section type
- **WHEN** the Later tab displays only ungrouped lists or only groups (not both)
- **THEN** no thin divider SHALL be shown
