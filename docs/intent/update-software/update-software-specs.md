# Software Update — EARS Specs

- [x] **SWUPDATE-001**: The system shall accept no parameters, delegating all upgrade selection and confirmation to each underlying CLI's own interactive UI.
- [x] **SWUPDATE-002**: The system shall run `winget upgrade --all` when `Update-Software` is invoked.
- [x] **SWUPDATE-003**: If `scoop` is found on `PATH`, the system shall run `scoop update` followed by `scoop update --all`.
- [x] **SWUPDATE-004**: If `scoop` is not found on `PATH`, the system shall write a warning and skip the scoop update step without stopping the remaining steps.
- [x] **SWUPDATE-005**: If `uv` is found on `PATH`, the system shall run `uv tool upgrade --all`.
- [x] **SWUPDATE-006**: If `uv` is not found on `PATH`, the system shall write a warning and skip the uv update step without stopping the remaining steps.
- [x] **SWUPDATE-007**: The system shall run the winget, scoop, and uv update steps in that fixed order.
- [x] **SWUPDATE-008**: The system shall write a banner identifying the source about to update immediately before each of the three steps.
- [x] **SWUPDATE-009**: The system shall proceed to the next step regardless of the exit code or failure of a preceding step.
