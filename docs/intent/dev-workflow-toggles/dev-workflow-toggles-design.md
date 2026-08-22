---
parent: high-level-design
prefix: TOGGLE
---

# Dev Workflow Toggles

## Context and Current State

Three profile helpers grouped by a shared shape — each starts, stops, or launches-with-precondition a background dev service — but each targets a fully independent external tool with no shared code between them: `Start-ADBDaemon` (Android Debug Bridge), `Switch-Kubernetes` (Rancher Desktop's Kubernetes backend), and `Start-ClaudeHeadroom` (a `claude` CLI session proxied through a local Headroom instance). This grouping was confirmed during brownfield reconciliation as a real shared concept, not directory proximity.

## Start-ADBDaemon

Restarts the Android Debug Bridge server as a background job: `Start-Job` runs `adb kill-server` followed by `adb -a -P 5037 nodaemon server`. No parameters, no `PATH`-presence check, assumes `adb` is on `PATH`. The specific meaning of the `-a -P 5037 nodaemon server` flags isn't documented in-file.

Because `adb ... nodaemon server` runs indefinitely once started, the function can't simply wait for the job to finish (that would block forever on the success path). Instead, after starting the job it waits up to a 2-second grace period (`Wait-Job -Timeout 2`) and checks `$job.State`: if still `Running`, that's the expected steady state and the function returns quietly; for any other state (the job already ended — `adb` missing from `PATH`, a bad flag, etc.), it warns and calls `Receive-Job` to surface the job's recorded output/errors to the caller (`TOGGLE-ADB-002`).

## Switch-Kubernetes

Toggles Rancher Desktop's Kubernetes backend via `rdctl`: reads current state with `rdctl list-settings` (parsed as JSON, expecting a `.kubernetes.enabled` boolean), flips it with `rdctl set --kubernetes.enabled=<bool>`, then polls `docker info` every 2 seconds until Docker reports success (`$LASTEXITCODE -eq 0`) or a `-TimeoutSeconds` deadline (default 120, configurable) is reached, at which point it reports the timeout via `Write-Error` and returns rather than looping indefinitely (`TOGGLE-K8S-004`). Carries two explicit `PSScriptAnalyzer` suppressions (`PSUseSingularNouns`, `PSAvoidUsingWriteHost`) with inline justification.

## Start-ClaudeHeadroom

Health-checks a hardcoded local endpoint (`http://127.0.0.1:8787/health`, 2-second timeout) before launching a nested `pwsh -NoProfile -Command` session that sets `$env:ANTHROPIC_BASE_URL` and runs `claude`. On health-check failure, prints a remediation message referencing an external `headroom` CLI (`headroom install apply --preset persistent-docker`, `headroom proxy`). `headroom` is now a declared prerequisite: `default.json` installs it via `uv tool install "headroom-ai[all]"` (a `commandLine` entry in the `bootstrap` segment's manifest, since `headroom` has no winget/scoop/msstore package — confirmed via `Get-Command headroom` resolving to a `uv`-managed tool shim, not a package-manager install). Uses `-NoProfile` for the nested session deliberately (though unstated why), meaning none of the other spliced helpers — including its two siblings in this segment — are available inside the launched `claude` session. No cleanup of the env var is needed since it's scoped to the child process only, by construction.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Grouping these three together | One LLD, one EARS namespace, for three independently-targeted toggles | Split into three separate LLDs (matches original fine-grained lens) | User-confirmed during Phase 4 reconciliation: shared "toggle a background dev service" shape justifies one LLD over three near-empty ones, at the cost of the LLD covering three unrelated external systems. |
| `Start-ClaudeHeadroom`'s `-NoProfile` | Launch nested session without the user's profile | Launch with profile (inheriting other spliced helpers) | [inferred] Isolating the nested session avoids potential interference from other profile customizations when talking to the Headroom proxy — not confirmed by any in-file comment. |
| `Start-ADBDaemon` failure surfacing (`TOGGLE-ADB-002`) | Short `Wait-Job -Timeout 2` grace period, then branch on `$job.State` | Fully synchronous (`Wait-Job` with no timeout, i.e. block until done); fire-and-forget with a separate `Get-Job`-based status-check helper | A full wait would block forever on the success path since the daemon job never completes; a short grace period catches fast startup failures (bad flags, `adb` missing) while still returning promptly once the daemon is confirmed running. |
| `Switch-Kubernetes` timeout (`TOGGLE-K8S-004`) | `-TimeoutSeconds` parameter (default 120), deadline computed via `Get-Date`, `Write-Error` + return on expiry | Fixed hardcoded timeout with no override; max-retry count instead of wall-clock deadline | A parameter lets a slow machine or a deliberately long Docker restart be accommodated without editing the function; wall-clock deadline is simpler to reason about than counting retries against a variable sleep interval. |
| `headroom` install path | `uv tool install "headroom-ai[all]"` as a `default.json` `commandLine` entry, with `astral-sh.uv` as a required winget item | Leave undeclared as a manual prerequisite (prior state); add a scoop/winget package (none exists) | User-confirmed: this is how `headroom` is actually installed on the reference machine. No package-manager entry exists for it, so the `commandLine` escape hatch is the only option — same pattern the MiKTeX/LyX block already uses. |

## Open Questions & Future Decisions

### Resolved
1. ✅ `Switch-Kubernetes` now takes a `-TimeoutSeconds` parameter (default 120) and reports a timeout via `Write-Error` instead of polling forever — `TOGGLE-K8S-004`.
2. ✅ `Start-ADBDaemon` now surfaces its background job's output/errors after a short grace period — `TOGGLE-ADB-002`.
3. ✅ `headroom` is now installed via `default.json` (`uv tool install "headroom-ai[all]"`, non-admin `commandLine`, with `astral-sh.uv` as a required winget item) — see the Decisions table. No pre-check needed: `uv tool install` is already idempotent when the tool is present (confirmed by running it — prints "already installed", exits 0), matching the no-precheck pattern the MiKTeX/LyX `commandLine` entry already uses. This is a cross-segment cascade: the manifest entry itself lives in the `bootstrap` segment's `default.json`, not here.

### Deferred
1. Should all three add a `PATH`/executable-presence check with a clear error message before invoking their external tool? No gap spec covers this yet.

## References

- Code: `helpers/Start-ADBDaemon.ps1`, `helpers/Switch-Kubernetes.ps1`, `helpers/Start-ClaudeHeadroom.ps1`
- Tests: `tests/DevWorkflowToggles.Tests.ps1`
- Arrow doc: `docs/arrows/dev-workflow-toggles.md`
