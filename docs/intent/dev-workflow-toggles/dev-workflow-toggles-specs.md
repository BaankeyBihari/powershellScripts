# Dev Workflow Toggles — EARS Specs

Facets: `TOGGLE-ADB-*` (Android Debug Bridge), `TOGGLE-K8S-*` (Rancher Desktop Kubernetes backend), `TOGGLE-CLAUDE-*` (Claude CLI via local Headroom proxy).

## Start-ADBDaemon

- [x] **TOGGLE-ADB-001**: When `Start-ADBDaemon` is invoked, the system shall kill any running `adb` server (`adb kill-server`) then start a new one as a background job (`adb -a -P 5037 nodaemon server`).
- [x] **TOGGLE-ADB-002**: If the background ADB job ends (any state other than still-`Running`) within a short grace period after starting, then the system shall surface the job's output/errors to the caller instead of returning silently.

## Switch-Kubernetes

- [x] **TOGGLE-K8S-001**: When `Switch-Kubernetes` is invoked, the system shall read the current Kubernetes-backend enabled state via `rdctl list-settings`.
- [x] **TOGGLE-K8S-002**: When `Switch-Kubernetes` is invoked, the system shall toggle the Kubernetes backend via `rdctl set --kubernetes.enabled=<bool>` to the opposite of its current state.
- [x] **TOGGLE-K8S-003**: While waiting for Docker to become available after the toggle (Rancher Desktop's Kubernetes backend restart), the system shall poll `docker info` every 2 seconds until it exits successfully.
- [x] **TOGGLE-K8S-004**: If Docker does not become available within `-TimeoutSeconds` (default 120) after the toggle, then the system shall stop polling and report a timeout rather than looping indefinitely.

## Start-ClaudeHeadroom

- [x] **TOGGLE-CLAUDE-001**: When `Start-ClaudeHeadroom` is invoked, the system shall check `http://127.0.0.1:8787/health` with a 2-second timeout before proceeding.
- [x] **TOGGLE-CLAUDE-002**: If the Headroom health check (the local token-compression proxy at `127.0.0.1:8787`) fails, then the system shall print a remediation message referencing the `headroom` CLI's install/proxy commands and stop without launching `claude`.
- [x] **TOGGLE-CLAUDE-003**: When the Headroom health check succeeds, the system shall launch a nested `pwsh -NoProfile` session with `$env:ANTHROPIC_BASE_URL` set to the local Headroom proxy and run `claude` inside it.
