---
parent: high-level-design
prefix: BCOMPARE
---

# BeyondCompare Trial Reset

## Context and Current State

A one-off personal maintenance utility, unrelated to the repo's install/package-management machinery: resets Beyond Compare 4's trial-period tracking by clearing a registry value.

## Mechanism

`Reset-BeyondCompare` reads `HKCU:\Software\Scooter Software\Beyond Compare 4` via `Get-ItemProperty` (printing its current values to the console), removes the `CacheID` value via `Remove-ItemProperty`, then reads the key again to print the resulting state. No parameters, no confirmation prompt, no error handling — if the key or value doesn't exist (already reset, or Beyond Compare not installed), the cmdlets throw non-terminating errors rather than being guarded.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Scope | Hardcoded to "Beyond Compare 4"'s specific registry path | Detect installed version and target dynamically | [inferred] Simplest implementation for a single-user, single-version personal utility; trades off portability across BC versions for directness. |
| Safety | No existence check / no `-WhatIf` support | Add `SupportsShouldProcess`, guard against missing key | [inferred] `PSScriptAnalyzerSettings.psd1` explicitly excludes `PSUseShouldProcessForStateChangingFunctions` with a rationale citing "one-shot personal utilities" — consistent with this being a deliberate simplicity trade-off across the repo's helpers, not specific to this file. |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Should the function guard against a missing key/value (already reset, or app not installed) rather than surfacing a raw non-terminating error?
2. Should the hardcoded "Beyond Compare 4" path be generalized to detect the installed version?

## References

- Code: `helpers/Reset-BeyondCompare.ps1`
- Tests: none currently
- Arrow doc: `docs/arrows/reset-beyond-compare.md`
