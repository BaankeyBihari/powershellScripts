---
parent: high-level-design
prefix: TOGGLE
---

# Dev Workflow Toggles

## Context and Current State

Three profile helpers grouped by a shared shape — each starts, stops, or launches-with-precondition a background dev service — but each targets a fully independent external tool with no shared code between them: `Start-ADBDaemon` (Android Debug Bridge), `Switch-Kubernetes` (Rancher Desktop's Kubernetes backend), and `Start-ClaudeHeadroom` (a `claude` CLI session proxied through a local Headroom instance). This grouping was confirmed during brownfield reconciliation as a real shared concept, not directory proximity.

## Start-ADBDaemon

Restarts the Android Debug Bridge server as a background job: `Start-Job` runs `adb kill-server` followed by `adb -a -P 5037 nodaemon server`. No parameters, no error handling, assumes `adb` is on `PATH`. The job's output and errors are never surfaced back to the caller — no `Receive-Job`, no `-Wait` — so the function returns immediately after starting the job and any failure inside it is invisible. The specific meaning of the `-a -P 5037 nodaemon server` flags isn't documented in-file.

## Switch-Kubernetes

Toggles Rancher Desktop's Kubernetes backend via `rdctl`: reads current state with `rdctl list-settings` (parsed as JSON, expecting a `.kubernetes.enabled` boolean), flips it with `rdctl set --kubernetes.enabled=<bool>`, then polls `docker info` every 2 seconds in an **unbounded `while ($true)` loop** until Docker reports success (`$LASTEXITCODE -eq 0`) — no timeout or max-retry guard. A failed Docker restart hangs the function indefinitely with only the initial "Waiting for Docker to become available..." message and no further feedback. Carries two explicit `PSScriptAnalyzer` suppressions (`PSUseSingularNouns`, `PSAvoidUsingWriteHost`) with inline justification.

## Start-ClaudeHeadroom

Health-checks a hardcoded local endpoint (`http://127.0.0.1:8787/health`, 2-second timeout) before launching a nested `pwsh -NoProfile -Command` session that sets `$env:ANTHROPIC_BASE_URL` and runs `claude`. On health-check failure, prints a remediation message referencing an external `headroom` CLI (`headroom install apply --preset persistent-docker`, `headroom proxy`) that is not otherwise visible anywhere else in this repo — not confirmed whether it's expected to be installed via `default.json`. Uses `-NoProfile` for the nested session deliberately (though unstated why), meaning none of the other spliced helpers — including its two siblings in this segment — are available inside the launched `claude` session. No cleanup of the env var is needed since it's scoped to the child process only, by construction.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Grouping these three together | One LLD, one EARS namespace, for three independently-targeted toggles | Split into three separate LLDs (matches original fine-grained lens) | User-confirmed during Phase 4 reconciliation: shared "toggle a background dev service" shape justifies one LLD over three near-empty ones, at the cost of the LLD covering three unrelated external systems. |
| `Switch-Kubernetes` polling | Unbounded `while ($true)` with fixed 2s sleep | Bounded retry count with a timeout error | [inferred] No evidence of a deliberate choice beyond simplicity — flagged as a gap below rather than a confirmed rationale. |
| `Start-ClaudeHeadroom`'s `-NoProfile` | Launch nested session without the user's profile | Launch with profile (inheriting other spliced helpers) | [inferred] Isolating the nested session avoids potential interference from other profile customizations when talking to the Headroom proxy — not confirmed by any in-file comment. |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Should `Switch-Kubernetes`'s polling loop get a timeout/max-retry bound?
2. Should `Start-ADBDaemon` surface its background job's output/errors to the caller?
3. Is `headroom` expected to be installed via `default.json`, and if so, should it be added there?
4. Should all three add a `PATH`/executable-presence check with a clear error message before invoking their external tool?

## References

- Code: `helpers/Start-ADBDaemon.ps1`, `helpers/Switch-Kubernetes.ps1`, `helpers/Start-ClaudeHeadroom.ps1`
- Tests: none currently
- Arrow doc: `docs/arrows/dev-workflow-toggles.md`
