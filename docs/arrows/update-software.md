# Arrow: Software Update

A single-line convenience alias exposed in the user's profile that updates every package source this repo installs from — winget, scoop (apps and buckets), and uv-managed CLI tools — in one call.

## Status

**AUDITED** — implemented with full test coverage 2026-08-22.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/update-software/update-software-design.md

### EARS
- docs/intent/update-software/update-software-specs.md (SWUPDATE-*)

### Tests
- tests/UpdateSoftware.Tests.ps1

### Code
- helpers/Update-Software.ps1

## Architecture

**Purpose:** Convenience profile alias replacing the winget-only `Get-WingetUpgrade` with a full-stack updater across all three package sources this repo installs from.

**Key Components:**
1. `Update-Software` — runs `winget upgrade --all`, then (if present) `scoop update` + `scoop update --all`, then (if present) `uv tool upgrade --all`, each preceded by a status banner.

## Spec Coverage

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| Wrapper behavior | SWUPDATE-001 to SWUPDATE-009 | 9 | 9 | 0 |

**Summary:** 9 of 9 specs implemented and tested.

## Key Findings

1. **Replaces `Get-WingetUpgrade` outright** — old helper file, its `default.json` profile registration, and its `get-winget-upgrade` LLD/specs/arrow doc were all removed in the same change, per the HLD's Tenet #3 ("new capability is a new file, not a new parameter").
2. **winget is unguarded, scoop/uv are `Get-Command`-guarded** — a deliberate asymmetry: winget is a hard dependency of this repo's own install flow, while scoop/uv are optional.
3. **Non-fail-fast across all three steps** — no try/catch or exit-code gating between them, so a failure in one doesn't block the others.

## Work Required

### Must Fix
None identified.

### Should Fix
None identified.

### Nice to Have
1. None identified.
