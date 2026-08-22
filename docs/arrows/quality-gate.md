# Arrow: Repo Quality Gate

Lint (PSScriptAnalyzer) and test (Pester) verification of the repo's own source, run both manually and in CI — verifies the repo is internally correct, not end-user-facing behavior.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

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

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap.

## Key Findings

1. **Coupling is only verified in one direction** — `DefaultJson.Tests.ps1` checks that a registered profile "link" entry resolves to a real function, but nothing checks the reverse: that every file in `helpers/` has a corresponding registration in `default.json`'s `profile[]` array. A new unregistered helper would not be caught as a gap.
2. **No test enforces the AGENTS.md-mandated `.SYNOPSIS` comment-based help block** — `Helpers.Tests.ps1` checks parse-cleanliness and function-name match only; the help-block convention that `Show-DukeCommands` depends on for its "no description available" fallback is unverified anywhere in `tests/`.
3. **`InstallScript.Tests.ps1` is parse-only** — the shortest, least substantive spec file (13 lines, one `It` block); none of `install.ps1`'s actual dispatch/splice/idempotency logic is exercised by any test.
4. **Function-name-match regex is loose** — `DefaultJson.Tests.ps1`'s check for `function <Name>` in a helper file would still pass on a commented-out or string-literal occurrence; it doesn't verify a real top-level function declaration.
5. **Dot-sourcing as verification method** — `Helpers.Tests.ps1` dot-sources every helper file into the live test-runner process; any accidental top-level (non-function-body) statement in a helper would actually execute during `Invoke-Pester`, a latent risk flagged by inference from the test's mechanism, not from any current helper content.
6. **No schema validation** for `optional`/`buckets` properties in `default.json`, and no well-formedness check on `adminCommandLine`/`commandLine` script text.

## Work Required

### Must Fix
None identified — the gate does what it currently claims to do; the gaps below are coverage gaps, not defects.

### Should Fix
1. Add the reverse-direction check: every `helpers/*.ps1` file has a matching `default.json` profile registration.
2. Add a check for the `.SYNOPSIS` comment-based help block on every helper file.
3. Tighten the function-declaration match in `DefaultJson.Tests.ps1` to avoid false positives on comments/strings.

### Nice to Have
1. Expand `InstallScript.Tests.ps1` beyond parse-checking (e.g. mock-based coverage of the profile-splice idempotency behavior).
2. Add schema validation for `optional`/`buckets` in `DefaultJson.Tests.ps1`.
