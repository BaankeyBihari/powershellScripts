# Bootstrap & Self-Update — EARS Specs

- [x] **BOOT-001**: The system shall accept `-resourceUri` and `-installUri` parameters, defaulting to the raw GitHub URLs for `default.json` and `install.ps1` on `main`.
- [x] **BOOT-002**: When `install.ps1` is invoked, the system shall parse the resource file at `-resourceUri` as JSON exposing top-level `.install[]` and `.profile[]` arrays.
- [x] **BOOT-003**: When `install.ps1` is invoked, the system shall install every required winget/msstore/scoop item that is not already installed.
- [x] **BOOT-004**: When an install group declares an `optional` list, the system shall prompt the user once (y/N) before installing that group's optional items.
- [x] **BOOT-005**: When a scoop install group declares `buckets`, the system shall add those buckets before installing that group's scoop items.
- [x] **BOOT-006**: When an `adminCommandLine` entry is present in `default.json`, the system shall execute it via elevated (`sudo`) `Invoke-Expression`.
- [x] **BOOT-007**: When a `commandLine` entry is present in `default.json`, the system shall execute it via non-elevated `Invoke-Expression`.
- [x] **BOOT-008**: When the system writes a profile section, it shall delimit the section with `#---Begin Section: <name>---` and `#---End Section: <name>---` markers keyed on the entry's `sectionName`.
- [x] **BOOT-009**: When `install.ps1` re-runs and a profile section with a matching `sectionName` already exists in `$Profile.CurrentUserAllHosts`, the system shall strip the existing section before rewriting it.
- [x] **BOOT-010**: When a `profile[]` entry's `type` is `"link"`, the system shall fetch `value` over HTTP and inline the downloaded content as the section body.
- [x] **BOOT-011**: When a `profile[]` entry's `type` is `"content"`, the system shall inline `value` literally as the section body.
- [x] **BOOT-012**: When `Get-ProfileUpdate` is invoked, the system shall download `install.ps1`'s current source from `-installUri` and invoke it with the caller's `-resourceUri`/`-installUri` values.
- [x] **BOOT-013**: If a package install (winget/msstore/scoop) fails — either by exiting non-zero or by throwing — then the system shall report the failure (per-item warning plus a final summary) rather than continuing the install loop silently.
- [x] **BOOT-014**: If `Get-ProfileUpdate`'s download or invocation of `install.ps1` fails, then the system shall surface a clear error identifying which step failed, rather than an unhandled exception.
