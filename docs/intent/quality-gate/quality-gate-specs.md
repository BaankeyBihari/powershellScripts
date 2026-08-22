# Repo Quality Gate — EARS Specs

- [x] **QUALITY-001**: When `default.json` is loaded by the test suite, the system shall verify every `install[]` entry's `source` is one of the five known values (`winget`, `msstore`, `scoop`, `adminCommandLine`, `commandLine`).
- [x] **QUALITY-002**: The system shall verify every `winget`/`msstore`/`scoop` install entry declares an `items` property (which may be empty).
- [x] **QUALITY-003**: The system shall verify every `profile[]` entry declares `sectionName`, `type` (`link`|`content`), and `value`.
- [x] **QUALITY-004**: When a `profile[]` entry's `type` is `"link"` and its `value` URL points under `/helpers/`, the system shall verify the referenced file exists in `helpers/` and contains a `function <sectionName>` declaration.
- [x] **QUALITY-005**: For every file in `helpers/`, the system shall verify it parses with zero PowerShell syntax errors.
- [x] **QUALITY-006**: For every file in `helpers/`, the system shall verify (after dot-sourcing the file) that a function exists whose name matches the file's name.
- [x] **QUALITY-007**: The system shall verify `install.ps1` parses with zero PowerShell syntax errors.
- [x] **QUALITY-008**: When the lint job runs, the system shall apply PSScriptAnalyzer to `install.ps1` and `helpers/` using the repo's rule-exclusion settings, and shall fail the build if any lint result is returned.
- [x] **QUALITY-009**: The CI pipeline shall not execute `install.ps1` itself.
- [x] **QUALITY-010**: The test suite shall verify that every file in `helpers/` has a corresponding `profile[]` registration in `default.json`.
- [x] **QUALITY-011**: The test suite shall verify every `helpers/*.ps1` file has a `.SYNOPSIS` comment-based help block, using the same "synopsis equals bare function name" fallback-detection heuristic `Show-DukeCommands` uses at runtime.
