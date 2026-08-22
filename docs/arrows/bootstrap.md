# Arrow: Bootstrap & Self-Update

Installs winget/msstore/scoop packages and post-install command snippets, splices helper functions into the user's PowerShell profile, and can re-download and re-run itself on demand.

## Status

**MAPPED** — sampled 2026-08-22, gap specs BOOT-013/BOOT-014 closed with tests 2026-08-22 (git SHA `efd29bf`). The 12 pre-existing `[x]` specs are reconstructed from source and still lack dedicated tests (deliberately out of scope for this pass — see this segment's `next` note); the 2 gap specs closed in this pass have real, passing tests.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/bootstrap/bootstrap-design.md

### EARS
- docs/intent/bootstrap/bootstrap-specs.md (BOOT-*)

### Tests
- tests/DefaultJson.Tests.ps1
- tests/InstallScript.Tests.ps1
- tests/GetProfileUpdate.Tests.ps1

### Code
- install.ps1
- default.json
- helpers/Get-ProfileUpdate.ps1

## Architecture

**Purpose:** One-shot machine bootstrap, re-runnable idempotently, with a self-update entry point that pulls the latest bootstrap definition from GitHub.

**Key Components:**
1. `install.ps1` — orchestrator: downloads/reads `default.json`, dispatches package installs across five sources, splices profile sections between `#---Begin/End Section---` markers.
2. `default.json` — declarative manifest: `install[]` (package groups) and `profile[]` (helper registrations).
3. `helpers/Get-ProfileUpdate.ps1` — re-downloads `install.ps1`/`default.json` and re-invokes the installer in-session, entirely delegating to `install.ps1`'s own logic.

## Spec Coverage

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| Package installation | BOOT-001 to BOOT-007 | 7 | 0 | 0 |
| Profile splicing | BOOT-008 to BOOT-011 | 4 | 0 | 0 |
| Self-update | BOOT-012 | 1 | 1 | 0 |
| Failure reporting | BOOT-013, BOOT-014 | 2 | 2 | 0 |

**Summary:** 14 of 14 specs implemented; 3 of 14 have dedicated tests (BOOT-012, BOOT-013, BOOT-014 — all touched in this pass). The remaining 11 pre-existing specs are implemented but untested, by deliberate scope decision (see Status).

## Key Findings

1. **Two-array manifest drives two independent dispatch paths** — `default.json`'s `install[]` and `profile[]` arrays are consumed by separate loops in `install.ps1`; nothing in code enforces they stay in sync with each other or with `helpers/*.ps1`'s actual contents (`install.ps1:1-`, `default.json:1-`).
2. **Re-run idempotency is real and verified in code** — `install.ps1` strips any existing profile section matching `sectionName` before rewriting it (confirms AGENTS.md's documented claim).
3. **`default.json`'s `adminCommandLine` and `msstore` required `items[]` arrays are currently empty** — `commandLine` carries two post-install snippets: the MiKTeX/LyX config block, and (added 2026-08-22, cross-segment cascade from `dev-workflow-toggles`) `uv tool install "headroom-ai[all]"` to provision the `headroom` CLI that `Start-ClaudeHeadroom` depends on. `astral-sh.uv` was added as a required winget item to guarantee `uv` is present first.
4. **`install.ps1` is deliberately never dot-sourced by tests** — it has real top-level side effects (network, package installs, profile writes). `BOOT-013`'s test isolates just the new `Test-InstallExitCode` function via AST extraction rather than executing the script, preserving that convention.

## Work Required

### Must Fix
None identified as broken.

### Should Fix
1. Reconcile the README/AGENTS.md entry-point inconsistency — either add usage instructions to README.md or correct AGENTS.md's claim. (Deferred — not tied to a gap spec.)
2. Investigate the profile-file encoding mismatch flagged during sweep (`Get-Content` default read vs. `-Encoding Default` write vs. `>>` append) — not confirmed as a bug from static reading alone. (Deferred — not tied to a gap spec.)
3. Decide whether failure-reporting should extend to scoop bucket adds and `adminCommandLine`/`commandLine` snippets (currently still silent on failure).

### Nice to Have
1. Clean up `install.ps1`'s dead/no-op statements (line ~12's unreachable catch message with a typo; line ~192's bare no-op `$profileValues` statement).
2. Backfill tests for the 11 pre-existing `[x]` specs if/when full behavioral coverage of `install.ps1` becomes a priority — a separate, larger initiative than this pass, not currently scheduled.
