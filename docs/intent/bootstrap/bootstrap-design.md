---
parent: high-level-design
prefix: BOOT
---

# Bootstrap & Self-Update

## Context and Current State

This is the repo's core system: a one-shot script that turns a fresh Windows machine into a configured one, and can be re-run — either manually or via `Get-ProfileUpdate` — to bring an already-bootstrapped machine back in sync with the latest `default.json`.

`install.ps1` reads a JSON manifest (`default.json`, downloaded from GitHub by default or supplied locally via `-resourceUri`/`-installUri`) and does two independent things with it: installs packages, and splices helper functions into the user's PowerShell profile. `Get-ProfileUpdate` is a thin re-entry point that re-downloads both files and re-invokes `install.ps1` in the current session — it has no independent logic of its own.

## Package Installation

`default.json`'s `install[]` array groups entries by `source`: `winget`, `msstore`, `scoop`, `adminCommandLine`, `commandLine`. `install.ps1` walks each group:
- `winget`/`msstore`/`scoop` groups carry `items` (always installed) and `optional` (user is prompted once, y/N, for the whole optional batch); `scoop` groups may also list `buckets` to add before installing.
- `adminCommandLine`/`commandLine` entries are raw PowerShell snippets run via `Invoke-Expression` (`sudo Invoke-Expression` for admin) — the escape hatch for post-install configuration that isn't expressible as a package install, or for installing a tool that has no winget/scoop/msstore package at all. Two `commandLine` entries currently exist: the MiKTeX/LyX headless-config block, and installing the `headroom` CLI (used by the `dev-workflow-toggles` segment's `Start-ClaudeHeadroom`) via `uv tool install "headroom-ai[all]"` — `uv` itself is a required winget item (`astral-sh.uv`) so it's guaranteed present by the time this snippet runs.

`Test-PackageInstalled` checks whether a given source/item pair is already installed before attempting install, building a `$plan` of `{Source, Item, Required, AlreadyInstalled}` records. The install loop wraps each entry's install command in a `try`/`catch` and, on success, checks `$LASTEXITCODE` via `Test-InstallExitCode`; a non-zero exit code or a thrown exception both add the entry to a `$failed` list, and a per-item warning plus a final summary line are printed once the loop completes. Installs are not halted on a single failure — the rest of the plan still runs — but every failure is surfaced (`BOOT-013`).

## Profile Splicing

`default.json`'s `profile[]` array is a list of `{sectionName, type, value}` entries. `type: "link"` fetches `value` (a raw GitHub URL) via `Invoke-WebRequest` and inlines its content; `type: "content"` inlines `value` literally. Each entry is written into `$Profile.CurrentUserAllHosts` delimited by `#---Begin Section: <name>---` / `#---End Section: <name>---` markers.

On every run, `install.ps1` first strips any existing section whose marker matches `sectionName` before rewriting it — this is what makes re-running the installer idempotent for profile updates, confirmed directly in code (not just documented). The `profileWriter()` function that performs this write reads from an outer-scope `$profileValues` variable rather than taking parameters — a tight coupling to its single call site's loop.

## Self-Update Path

`Get-ProfileUpdate` downloads `install.ps1`'s source via `Invoke-WebRequest` (switched from the original `System.Net.WebClient` call so the download step is mockable in tests, matching the rest of the codebase's convention), turns it into a script block via `[ScriptBlock]::Create()`, and invokes it with the same `-resourceUri`/`-installUri` parameter contract `install.ps1` itself accepts. Both the download and the invocation are wrapped in their own `try`/`catch`; on failure, `Write-Error` reports which step failed (download vs. re-run) and the function returns rather than letting a raw exception propagate (`BOOT-014`). This still means a signature change to `install.ps1`'s parameters would silently break `Get-ProfileUpdate` with no shared reference or test tying the two together — that risk is unchanged by this fix.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Manifest format | Single `default.json` with two arrays (`install[]`, `profile[]`) | Separate files per concern | Keeps one source of truth: one file to edit for either a new package or a new profile helper, matching AGENTS.md's explicit framing of `default.json` as "the single source of truth." |
| Post-install escape hatch | `adminCommandLine`/`commandLine` raw PowerShell snippets via `Invoke-Expression` | A more structured post-install step DSL | `PSScriptAnalyzerSettings.psd1`'s inline comment explicitly justifies suppressing `PSAvoidUsingInvokeExpression` for this pattern — an intentional, acknowledged trade-off: arbitrary post-install steps (like the MiKTeX/LyX config block) don't need a bespoke DSL when raw PowerShell already does the job. |
| Idempotency mechanism | Strip-then-rewrite by `sectionName` marker on every run | Diff-and-patch, or skip-if-exists | Guarantees profile content always matches the current `default.json` on every run, at the accepted cost of losing any manual edits made inside a managed section — simpler to reason about than a diff/patch approach. |
| Self-update mechanism | Re-download `install.ps1` as text and invoke as a dynamic script block | Reference a version-pinned release artifact; require manual re-download | Keeps the user always on `main`, trading reproducibility/offline resilience for always-latest convenience — consistent with this being a personal bootstrap tool re-run on demand, not a versioned release consumers pin to. |
| Install-failure handling | Report every failure (per-item warning + final summary), continue running the rest of the plan | Halt the whole run on first failure; silently continue with no reporting (prior behavior) | Applies the HLD's "blast radius" tenet: installs are high blast radius so failures must be visible, but one bad package shouldn't block installing the rest of an otherwise-good plan. |
| `Get-ProfileUpdate` failure handling | `try`/`catch` around both the download and the re-invocation, `Write-Error` naming which step failed, then return | Let the raw `.NET` exception propagate (prior behavior); retry automatically | Applies the same "fail loud" tenet — a self-update failure is high blast radius (it drives the whole install pipeline) — while retrying automatically was rejected as unnecessary complexity for a manually-invoked convenience command. |

## Open Questions & Future Decisions

### Resolved
1. ✅ Package-install failures are reported (per-item warning + final summary) and do not halt the rest of the run — see `BOOT-013` and the Decisions table.
2. ✅ `Get-ProfileUpdate`'s download/invoke path now fails loud via `try`/`catch` + `Write-Error`, no automatic retry — see `BOOT-014` and the Decisions table.

### Deferred
1. Is the README/AGENTS.md inconsistency (AGENTS.md claims README documents "the intended entry point"; README's actual content doesn't) a doc bug to fix, or does README need the missing usage snippet added? (Out of scope for this pass — not tied to a gap spec.)
2. Confirm whether the profile file's read encoding (`Get-Content` default) vs. write encoding (`-Encoding Default` for full rewrites, default `>>` redirection encoding for appends) is a real inconsistency or a non-issue in practice. (Out of scope for this pass — not tied to a gap spec.)
3. Failure-reporting (`BOOT-013`) currently covers only the winget/msstore/scoop install loop — scoop bucket adds and `adminCommandLine`/`commandLine` snippet execution still fail silently. Worth its own spec if this matters going forward.
4. Should `install.ps1` set a non-zero process exit code when `$failed` is non-empty, so calling automation (not just a human watching the console) can detect a partial failure?

## References

- Code: `install.ps1`, `default.json`, `helpers/Get-ProfileUpdate.ps1`
- Tests: `tests/DefaultJson.Tests.ps1`, `tests/InstallScript.Tests.ps1`, `tests/GetProfileUpdate.Tests.ps1`
- Arrow doc: `docs/arrows/bootstrap.md`
- Depended on by: `show-duke-commands` (profile section-marker convention), `quality-gate` (tests target this segment's files)
