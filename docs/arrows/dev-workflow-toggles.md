# Arrow: Dev Workflow Toggles

Three independent profile helpers that each start, stop, or launch-with-precondition a background dev service: the ADB daemon, Rancher Desktop's Kubernetes backend, and a `claude` CLI session proxied through a local Headroom instance.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/dev-workflow-toggles/dev-workflow-toggles-design.md

### EARS
- docs/intent/dev-workflow-toggles/dev-workflow-toggles-specs.md (TOGGLE-*)

### Tests
- (none currently — not exercised by `tests/`)

### Code
- helpers/Start-ADBDaemon.ps1
- helpers/Switch-Kubernetes.ps1
- helpers/Start-ClaudeHeadroom.ps1

## Architecture

**Purpose:** Developer convenience toggles for local dev-tool state — each function owns a different external service's on/off state and has no shared code or cross-reference with the other two.

**Key Components:**
1. `Start-ADBDaemon` — kills and restarts the Android Debug Bridge server as a background job.
2. `Switch-Kubernetes` — toggles Rancher Desktop's Kubernetes backend via `rdctl`, then polls `docker info` until Docker reports available again.
3. `Start-ClaudeHeadroom` — health-checks a local Headroom proxy (`http://127.0.0.1:8787/health`), then launches a nested `pwsh -NoProfile` session running `claude` with `$env:ANTHROPIC_BASE_URL` pointed at the proxy.

## Spec Coverage

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap.

## Key Findings

1. **Grouped by shared shape, not proximity** — flagged during reconciliation and confirmed: all three share the "toggle an external dev service on/off" purpose, but each targets a fully independent tool (ADB, Rancher/Docker, Headroom) with zero shared code.
2. **`Switch-Kubernetes` has an unbounded polling loop** — `while ($true)` with a 2-second sleep against `docker info`, no timeout or max-retry guard; a failed Docker restart hangs the function indefinitely with only the initial status message (`helpers/Switch-Kubernetes.ps1`).
3. **`Start-ClaudeHeadroom` depends on an external `headroom` CLI** not otherwise visible anywhere in the repo (not confirmed as a `default.json` package entry) — its error-remediation message references `headroom install apply --preset persistent-docker` and `headroom proxy`.
4. **`Start-ClaudeHeadroom` launches its nested session with `-NoProfile`** — a deliberate-looking but unstated design choice, meaning none of the other spliced helpers (including its two siblings in this segment) are available inside the launched `claude` session.
5. **`Start-ADBDaemon` surfaces no job output or errors** — no `Receive-Job`/`-Wait`; the function returns immediately after starting the background job, so failures are invisible to the caller.
6. **No error handling in any of the three** if the underlying external executable (`adb`, `rdctl`, `docker`) isn't on `PATH`.

## Work Required

### Must Fix
None identified as currently broken.

### Should Fix
1. Add a timeout/max-retry bound to `Switch-Kubernetes`'s polling loop.
2. Surface `Start-ADBDaemon`'s background job output/errors to the caller.
3. Confirm whether `headroom` is expected to be installed via `default.json` and either add it there or document the external prerequisite explicitly.

### Nice to Have
1. Add basic PATH/executable-presence checks with a clear error message for all three.
