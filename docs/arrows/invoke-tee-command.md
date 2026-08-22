# Arrow: Session Logging

Runs an arbitrary command (bare words or a script block) and tees its combined stdout+stderr to both the console and an auto-named or user-supplied log file, mimicking Unix `tee`.

## Status

**AUDITED** — sampled 2026-08-22, gap spec TEE-005 closed with tests 2026-08-22, audited 2026-08-22. The 4 pre-existing `[x]` specs (TEE-001 to TEE-004) still lack dedicated tests — deliberately out of scope for this pass, except incidental coverage from the happy-path regression test, now tagged `@spec TEE-002, TEE-004` (fixed 2026-08-22).

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/invoke-tee-command/invoke-tee-command-design.md

### EARS
- docs/intent/invoke-tee-command/invoke-tee-command-specs.md (TEE-*)

### Tests
- tests/InvokeTeeCommand.Tests.ps1

### Code
- helpers/Invoke-TeeCommand.ps1

## Architecture

**Purpose:** General-purpose logging/observability utility — wraps any command to capture a session transcript to both console and a log file.

**Key Components:**
1. `Invoke-TeeCommand` — manually parses `$args` (deliberately undeclared as `[CmdletBinding()]`/typed parameters to preserve flag-splatting), derives a default log path/filename from the invoked command's first word, timestamp, and a random suffix, then pipes the command's merged `2>&1` stream through `Tee-Object`.

## Spec Coverage

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| Command invocation | TEE-001 to TEE-004 | 4 | 1 (incidental, via the happy-path regression test) | 0 |
| Error handling | TEE-005 | 1 | 1 | 0 |

**Summary:** 5 of 5 specs implemented; the one gap spec closed this pass has direct tests, plus one happy-path regression test added alongside it.

## Key Findings

1. **Deliberate parameter-binding tradeoff** — the file's own inline comment explains that avoiding `[CmdletBinding()]`/`[Parameter()]` is intentional, so `$args` splatting preserves flag/value pairs (e.g. `-a`) instead of collapsing them positionally. This is a documented design decision, not an oversight (`helpers/Invoke-TeeCommand.ps1:12-16`). One consequence, confirmed while fixing `TEE-005`: no `[CmdletBinding()]` means no common parameters either, so tests must use stream redirection (`2>&1`/`3>&1`) rather than `-ErrorVariable`/`-WarningVariable` to inspect its output.
2. **Most recently actively developed helper** — git log shows 3 recent commits iteratively refining the auto-generated log-prefix logic (add → prefix temp logs → derive prefix from actual command word).
3. **Zero-argument crash reproduced and fixed** — confirmed by actually running it: calling with no arguments previously produced a confusing "expression after '&' produced an object that was not valid" error, after first printing a misleading "No -LogPath given" warning and creating a stray empty log file. Now guarded with a specific error before any of that setup runs (`TEE-005`).

## Work Required

### Must Fix
None identified.

### Should Fix
None outstanding.

### Nice to Have
1. Backfill tests for `TEE-001` through `TEE-004` if/when full behavioral coverage becomes a priority.
