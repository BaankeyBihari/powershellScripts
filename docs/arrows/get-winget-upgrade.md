# Arrow: Windows Package Maintenance

Lists (and, via winget's own interactive UI, offers to upgrade) all winget packages with available updates.

## Status

**MAPPED** — sampled 2026-08-22, decisions confirmed 2026-08-22 (git SHA `efd29bf`). Zero-gap segment: no code changed, no tests added; its one open question was resolved via the HLD's Tenet #3 rather than new code.

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

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| Wrapper behavior | WINGET-001, WINGET-002 | 2 | 0 | 0 |

**Summary:** 2 of 2 specs implemented; untested (deliberately out of scope — the segment is a bare `winget` passthrough with no logic of its own to unit test).

## Key Findings

1. **Simplest segment in the repo** — no parameters, no error handling, no structured output; all behavior is delegated entirely to `winget upgrade --all` (`helpers/Get-WingetUpgrade.ps1`).
2. **`.SYNOPSIS` describes winget's own UX, not anything this wrapper adds** — flagged during sweep as a description-vs-implementation note, not independently re-verified against winget's actual behavior in this mapping pass.
3. **Scope question resolved via tenet, not code** — whether to add a package-name filter parameter was answered by the HLD's Tenet #3 ("new capability is a new file, not a new parameter"): stays a bare `--all` wrapper; a filtered variant would be a new helper.

## Work Required

### Must Fix
None identified.

### Should Fix
None identified — segment is intentionally thin.

### Nice to Have
1. None identified.
