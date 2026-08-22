# Arrow: Command Discovery

Lists every function this repo has spliced into the current user's PowerShell profile, printing each one's synopsis and usage syntax.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/show-duke-commands/show-duke-commands-design.md

### EARS
- docs/intent/show-duke-commands/show-duke-commands-specs.md (DUKE-*)

### Tests
- (none currently — not exercised by `tests/`)

### Code
- helpers/Show-DukeCommands.ps1

## Architecture

**Purpose:** Give an end user, once `install.ps1` has spliced helpers into their profile, a way to enumerate what's installed and how to call each one.

**Key Components:**
1. `Show-DukeCommands` — reads the profile file, regex-matches `#---Begin Section: (.+)---` markers to recover section names, resolves each to a live function via `Get-Command`, and prints its `Get-Help`-derived synopsis and syntax.

## Spec Coverage

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap.

## Key Findings

1. **Tight coupling to a convention owned by a different segment** — this helper's entire mechanism depends on the `#---Begin/End Section---` marker format written by `install.ps1` (Bootstrap segment); a format change there would silently break discovery here with no shared constant or test tying the two together (`helpers/Show-DukeCommands.ps1`).
2. **"No description available" detection is a heuristic** — treats a synopsis equal to the bare function name as "no help block present" (the fallback `Get-Help` produces for undocumented functions); would misfire if a real function's synopsis text happened to equal its own name, though this isn't observed elsewhere in the repo.
3. **Silent skip on unresolvable sections** — `-ErrorAction SilentlyContinue` on `Get-Command`/`Get-Help` means a profile section that isn't a function (e.g. a "content"-type section) is skipped with no diagnostic.

## Work Required

### Must Fix
None identified.

### Should Fix
1. Document (in the LLD, and cross-reference from the Bootstrap segment's LLD) that the section-marker format is a cross-segment contract this helper depends on.

### Nice to Have
1. Consider a shared regex/constant for the section-marker format so both segments stay in sync automatically rather than by convention.
