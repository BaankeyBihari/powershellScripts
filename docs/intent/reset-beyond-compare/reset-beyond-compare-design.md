---
parent: high-level-design
prefix: BCOMPARE
---

# BeyondCompare Trial Reset

## Context and Current State

A one-off personal maintenance utility, unrelated to the repo's install/package-management machinery: resets Beyond Compare 4's trial-period tracking by clearing a registry value.

## Mechanism

`Reset-BeyondCompare` reads `HKCU:\Software\Scooter Software\Beyond Compare 4` via `Get-ItemProperty` (printing its current values to the console), removes the `CacheID` value via `Remove-ItemProperty`, then reads the key again to print the resulting state. No parameters, no confirmation prompt. Two guards run first: `Test-Path` confirms the key itself exists (if not, `Write-Warning` and return — Beyond Compare likely isn't installed); then the read `$before` object is checked for a `CacheID` property (if absent, `Write-Warning` and return — trial tracking already looks reset). Both guarded messages replace what were previously raw registry exceptions — confirmed directly by reproducing them against a throwaway registry key before fixing: a missing key raised `ItemNotFoundException`, a missing value raised `PSArgumentException` (`BCOMPARE-004`).

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Scope | Hardcoded to "Beyond Compare 4"'s specific registry path | Detect installed version and target dynamically | [inferred] Simplest implementation for a single-user, single-version personal utility; trades off portability across BC versions for directness. |
| `-WhatIf` support | None — `PSScriptAnalyzerSettings.psd1` explicitly excludes `PSUseShouldProcessForStateChangingFunctions` | Add `SupportsShouldProcess` | Consistent deliberate simplicity trade-off across the repo's helpers (one-shot personal utilities), not specific to this file. |
| Missing key/value handling (`BCOMPARE-004`) | `Test-Path` + property-existence guard, `Write-Warning` + return on either miss | Let the raw registry exceptions propagate (prior behavior); wrap in try/catch instead of pre-checking | Pre-checking with `Test-Path`/property inspection gives a specific, correctly-worded message per failure mode (missing key vs. missing value), which a generic catch-and-rewrap would blur together. |

## Open Questions & Future Decisions

### Resolved
1. ✅ The function now guards against a missing key/value and reports a clear message instead of a raw error — `BCOMPARE-004`.

### Deferred
1. Should the hardcoded "Beyond Compare 4" path be generalized to detect the installed version?

## References

- Code: `helpers/Reset-BeyondCompare.ps1`
- Tests: `tests/ResetBeyondCompare.Tests.ps1`
- Arrow doc: `docs/arrows/reset-beyond-compare.md`
