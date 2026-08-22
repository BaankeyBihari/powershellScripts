# Arrow: Repo Quality Gate

Lint (PSScriptAnalyzer) and test (Pester) verification of the repo's own source, run both manually and in CI — verifies the repo is internally correct, not end-user-facing behavior.

## Status

**AUDITED** — sampled 2026-08-22, gap specs QUALITY-010/QUALITY-011 closed with tests 2026-08-22, audited 2026-08-22. All 11 specs have direct test coverage; QUALITY-001 through QUALITY-007's `It` blocks (pre-dating the `@spec` annotation convention) are now tagged (fixed 2026-08-22, `Invoke-Pester` still green: 54/54).

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/quality-gate/quality-gate-design.md

### EARS
- docs/intent/quality-gate/quality-gate-specs.md (QUALITY-*)

### Tests
- tests/DefaultJson.Tests.ps1
- tests/Helpers.Tests.ps1
- tests/InstallScript.Tests.ps1

### Code
- PSScriptAnalyzerSettings.psd1
- .github/workflows/ci.yml

## Architecture

**Purpose:** Automated correctness gate for the repo's own scripts and manifest, run on every push/PR to `main` and available as a manual local command.

**Key Components:**
1. `PSScriptAnalyzerSettings.psd1` — lint rule exclusions with inline rationale, tuned to the repo's intentional patterns (`Invoke-Expression` usage, no `-WhatIf`/`-Confirm` on one-shot utilities).
2. `.github/workflows/ci.yml` — two-job pipeline (`lint`, `test`) on `windows-latest`, gated on `.ps1`/`.json`/workflow-file path changes.
3. `tests/DefaultJson.Tests.ps1` — validates `default.json`'s shape and one direction of the helper↔manifest coupling (a registered profile link must resolve to a real function).
4. `tests/Helpers.Tests.ps1` — parameterized over every `helpers/*.ps1` file: parses cleanly, defines a function matching its filename.
5. `tests/InstallScript.Tests.ps1` — confirms `install.ps1` has no syntax/parse errors (does not exercise its logic).

## Spec Coverage

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| Manifest shape | QUALITY-001 to QUALITY-004 | 4 | 4 | 0 |
| Helper structure | QUALITY-005, QUALITY-006 | 2 | 2 | 0 |
| Script validity | QUALITY-007 | 1 | 1 | 0 |
| Lint/CI | QUALITY-008, QUALITY-009 | 2 | 2 (self-verifying: these describe the gate's own CI wiring) | 0 |
| Two-way helper registration | QUALITY-010, QUALITY-011 | 2 | 2 | 0 |

**Summary:** 11 of 11 specs implemented and tested — this segment's tests literally are the tests for its own specs (QUALITY-001 through QUALITY-011 are each directly backed by an `It` block).

## Key Findings

1. **Coupling is now verified in both directions** — `DefaultJson.Tests.ps1` checks both that a registered profile "link" entry resolves to a real function (`QUALITY-004`) and, as of this pass, that every file in `helpers/` has a corresponding `profile[]` registration (`QUALITY-010`).
2. **`.SYNOPSIS` presence is now enforced** — `Helpers.Tests.ps1` (`QUALITY-011`) reuses the same "synopsis equals bare function name" heuristic `Show-DukeCommands` uses at runtime (`DUKE-004`), so the test and the runtime fallback can't silently drift apart.
3. **`InstallScript.Tests.ps1` remains parse-only for `install.ps1`'s top-level logic** — the one addition (`Test-InstallExitCode`, extracted for `BOOT-013`) is unit-tested via AST extraction; the dispatch/splice/idempotency logic is still unexercised, by deliberate deferred scope (see `bootstrap`'s Open Questions).
4. **Function-name-match regex is loose** — `DefaultJson.Tests.ps1`'s check for `function <Name>` in a helper file would still pass on a commented-out or string-literal occurrence; it doesn't verify a real top-level function declaration. Not fixed in this pass — no gap spec covered it.
5. **Dot-sourcing as verification method** — `Helpers.Tests.ps1` dot-sources every helper file into the live test-runner process; any accidental top-level (non-function-body) statement in a helper would actually execute during `Invoke-Pester`, a latent risk flagged by inference from the test's mechanism, not from any current helper content.
6. **No schema validation** for `optional`/`buckets` properties in `default.json`, and no well-formedness check on `adminCommandLine`/`commandLine` script text.

## Work Required

### Must Fix
None identified — the gate does what it currently claims to do.

### Should Fix
1. Tighten the function-declaration match in `DefaultJson.Tests.ps1` to avoid false positives on comments/strings (not tied to a gap spec — raise explicitly if wanted).

### Nice to Have
1. Expand `InstallScript.Tests.ps1` beyond parse-checking + `Test-InstallExitCode` (e.g. mock-based coverage of the profile-splice idempotency behavior) — tied to `bootstrap`'s deferred backfill decision.
2. Add schema validation for `optional`/`buckets` in `DefaultJson.Tests.ps1`.
