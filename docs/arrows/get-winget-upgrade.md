# Arrow: Windows Package Maintenance

Lists (and, via winget's own interactive UI, offers to upgrade) all winget packages with available updates.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/get-winget-upgrade/get-winget-upgrade-design.md

### EARS
- docs/intent/get-winget-upgrade/get-winget-upgrade-specs.md (WINGET-*)

### Tests
- (none currently — not exercised by `tests/`)

### Code
- helpers/Get-WingetUpgrade.ps1

## Architecture

**Purpose:** Convenience profile alias for a common Windows package-maintenance command.

**Key Components:**
1. `Get-WingetUpgrade` — single-line wrapper around `winget upgrade --all`.

## Spec Coverage

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap.

## Key Findings

1. **Simplest segment in the repo** — no parameters, no error handling, no structured output; all behavior is delegated entirely to `winget upgrade --all` (`helpers/Get-WingetUpgrade.ps1`).
2. **`.SYNOPSIS` describes winget's own UX, not anything this wrapper adds** — flagged during sweep as a description-vs-implementation note, not independently re-verified against winget's actual behavior in this mapping pass.

## Work Required

### Must Fix
None identified.

### Should Fix
None identified — segment is intentionally thin.

### Nice to Have
1. None identified.
