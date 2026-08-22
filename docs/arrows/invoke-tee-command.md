# Arrow: Session Logging

Runs an arbitrary command (bare words or a script block) and tees its combined stdout+stderr to both the console and an auto-named or user-supplied log file, mimicking Unix `tee`.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/invoke-tee-command/invoke-tee-command-design.md

### EARS
- docs/intent/invoke-tee-command/invoke-tee-command-specs.md (TEE-*)

### Tests
- (none currently — not exercised by `tests/`)

### Code
- helpers/Invoke-TeeCommand.ps1

## Architecture

**Purpose:** General-purpose logging/observability utility — wraps any command to capture a session transcript to both console and a log file.

**Key Components:**
1. `Invoke-TeeCommand` — manually parses `$args` (deliberately undeclared as `[CmdletBinding()]`/typed parameters to preserve flag-splatting), derives a default log path/filename from the invoked command's first word, timestamp, and a random suffix, then pipes the command's merged `2>&1` stream through `Tee-Object`.

## Spec Coverage

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap.

## Key Findings

1. **Deliberate parameter-binding tradeoff** — the file's own inline comment explains that avoiding `[CmdletBinding()]`/`[Parameter()]` is intentional, so `$args` splatting preserves flag/value pairs (e.g. `-a`) instead of collapsing them positionally. This is a documented design decision, not an oversight (`helpers/Invoke-TeeCommand.ps1:12-16`).
2. **Most recently actively developed helper** — git log shows 3 recent commits iteratively refining the auto-generated log-prefix logic (add → prefix temp logs → derive prefix from actual command word).
3. **No guard against being called with zero arguments** — if `$args` is empty, downstream indexing (`$rest[0]`) would hit `$null`; not exercised or tested, only observed from reading the code path.

## Work Required

### Must Fix
None identified.

### Should Fix
1. Add a guard/early-return for the zero-argument call case.

### Nice to Have
1. None identified.
