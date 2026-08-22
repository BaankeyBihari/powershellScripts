# Command Discovery — EARS Specs

- [x] **DUKE-001**: The system shall read the profile file at `$Profile.CurrentUserAllHosts`, or a caller-supplied `-ProfilePath`, as its source of installed sections.
- [x] **DUKE-002**: When `Show-DukeCommands` is invoked, the system shall extract every spliced section name from the profile file by matching the `#---Begin Section: (.+)---` marker convention (owned by the `bootstrap` segment).
- [x] **DUKE-003**: When a recovered section name resolves to a live function, the system shall print that function's name, its `Get-Help`-derived synopsis, and its call syntax.
- [x] **DUKE-004**: While a resolved function's synopsis text equals its own function name, the system shall display "no description available" instead of the raw synopsis.
- [x] **DUKE-005**: If a recovered section name does not resolve to a live function, then the system shall skip it without printing a diagnostic.
