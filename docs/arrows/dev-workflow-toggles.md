# Arrow: Dev Workflow Toggles

Three independent profile helpers that each start, stop, or launch-with-precondition a background dev service: the ADB daemon, Rancher Desktop's Kubernetes backend, and a `claude` CLI session proxied through a local Headroom instance.

## Status

**AUDITED** — sampled 2026-08-22, gap specs TOGGLE-ADB-002/TOGGLE-K8S-004 closed with tests 2026-08-22, audited 2026-08-22 (git SHA `5e75d0a`). The 4 pre-existing `[x]` specs still fully untested are ADB-001 and CLAUDE-001/002/003 — deliberately out of scope for this pass. K8S-001/002/003 turned out to already have dedicated `@spec`-annotated tests (corrected during audit; the prior count undercounted them).

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/dev-workflow-toggles/dev-workflow-toggles-design.md

### EARS
- docs/intent/dev-workflow-toggles/dev-workflow-toggles-specs.md (TOGGLE-*)

### Tests
- tests/DevWorkflowToggles.Tests.ps1

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

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| ADB | TOGGLE-ADB-001, TOGGLE-ADB-002 | 2 | 1 | 0 |
| Kubernetes | TOGGLE-K8S-001 to TOGGLE-K8S-004 | 4 | 4 | 0 |
| Claude+Headroom | TOGGLE-CLAUDE-001 to TOGGLE-CLAUDE-003 | 3 | 0 | 0 |

**Summary:** 9 of 9 specs implemented; 5 of 9 have dedicated tests (the two gap specs closed this pass, plus all four Kubernetes specs — `TOGGLE-K8S-001`/`002` via one `@spec`-annotated test, `003` and `004` each via their own). `TOGGLE-ADB-001` and `TOGGLE-CLAUDE-*` remain fully untested — deliberately out of scope for this pass.

## Key Findings

1. **Grouped by shared shape, not proximity** — flagged during reconciliation and confirmed: all three share the "toggle an external dev service on/off" purpose, but each targets a fully independent tool (ADB, Rancher/Docker, Headroom) with zero shared code.
2. **`Start-ClaudeHeadroom` depends on an external `headroom` CLI**, now declared as a prerequisite in `default.json` (`uv tool install "headroom-ai[all]"`, a `commandLine` entry in the `bootstrap` segment, since `headroom` has no winget/scoop/msstore package). Its error-remediation message still references `headroom install apply --preset persistent-docker`/`headroom proxy` as manual fallback instructions.
3. **`Start-ClaudeHeadroom` launches its nested session with `-NoProfile`** — a deliberate-looking but unstated design choice, meaning none of the other spliced helpers (including its two siblings in this segment) are available inside the launched `claude` session.
4. **No error handling in any of the three** if the underlying external executable (`adb`, `rdctl`, `docker`) isn't on `PATH` — flagged, not fixed this pass (no gap spec covers it).

## Work Required

### Must Fix
None identified as currently broken.

### Should Fix
None outstanding — the `headroom` install-path question is resolved.

### Nice to Have
1. Add basic PATH/executable-presence checks with a clear error message for all three.
2. Backfill tests for `TOGGLE-ADB-001` and `TOGGLE-CLAUDE-*` if/when full behavioral coverage becomes a priority.
