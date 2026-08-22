# Arrow: Bootstrap & Self-Update

Installs winget/msstore/scoop packages and post-install command snippets, splices helper functions into the user's PowerShell profile, and can re-download and re-run itself on demand.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

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

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap. Re-run an arrow-maintenance audit once `bootstrap-specs.md` exists to populate this table.

## Key Findings

1. **Two-array manifest drives two independent dispatch paths** — `default.json`'s `install[]` and `profile[]` arrays are consumed by separate loops in `install.ps1`; nothing in code enforces they stay in sync with each other or with `helpers/*.ps1`'s actual contents (`install.ps1:1-`, `default.json:1-`).
2. **Re-run idempotency is real and verified in code** — `install.ps1` strips any existing profile section matching `sectionName` before rewriting it (confirms AGENTS.md's documented claim).
3. **`Get-ProfileUpdate` has no error handling** around its network download or the dynamic script-block invocation of `install.ps1` — a network failure or malformed remote script surfaces as an unhandled exception (`helpers/Get-ProfileUpdate.ps1`).
4. **README/AGENTS.md inconsistency** — AGENTS.md claims README.md documents "the intended entry point" for `install.ps1`; README.md's actual 3-line content contains no such usage instructions.
5. **`default.json`'s `adminCommandLine` and `msstore` required `items[]` arrays are currently empty** — only `commandLine` currently carries real post-install work (the MiKTeX/LyX config snippet).

## Work Required

### Must Fix
1. None identified as broken — behavior matches documented intent.

### Should Fix
1. Add error handling around `Get-ProfileUpdate`'s download/invocation path (BOOT specs TBD).
2. Reconcile the README/AGENTS.md entry-point inconsistency — either add usage instructions to README.md or correct AGENTS.md's claim.
3. Investigate the profile-file encoding mismatch flagged during sweep (`Get-Content` default read vs. `-Encoding Default` write vs. `>>` append) — not confirmed as a bug from static reading alone.

### Nice to Have
1. Clean up `install.ps1`'s dead/no-op statements (line ~12's unreachable catch message with a typo; line ~192's bare no-op `$profileValues` statement).
