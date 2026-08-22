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
- `adminCommandLine`/`commandLine` entries are raw PowerShell snippets run via `Invoke-Expression` (`sudo Invoke-Expression` for admin) — the escape hatch for post-install configuration that isn't expressible as a package install (currently used for the MiKTeX/LyX headless-config block).

`Test-PackageInstalled` checks whether a given source/item pair is already installed before attempting install, building a `$plan` of `{Source, Item, Required, AlreadyInstalled}` records. There is no error handling around install failures — the loop continues unconditionally through failures.

## Profile Splicing

`default.json`'s `profile[]` array is a list of `{sectionName, type, value}` entries. `type: "link"` fetches `value` (a raw GitHub URL) via `Invoke-WebRequest` and inlines its content; `type: "content"` inlines `value` literally. Each entry is written into `$Profile.CurrentUserAllHosts` delimited by `#---Begin Section: <name>---` / `#---End Section: <name>---` markers.

On every run, `install.ps1` first strips any existing section whose marker matches `sectionName` before rewriting it — this is what makes re-running the installer idempotent for profile updates, confirmed directly in code (not just documented). The `profileWriter()` function that performs this write reads from an outer-scope `$profileValues` variable rather than taking parameters — a tight coupling to its single call site's loop.

## Self-Update Path

`Get-ProfileUpdate` downloads `install.ps1`'s source as a string via `System.Net.WebClient`, turns it into a script block via `[ScriptBlock]::Create()`, and invokes it with the same `-resourceUri`/`-installUri` parameter contract `install.ps1` itself accepts. This means a signature change to `install.ps1`'s parameters would silently break `Get-ProfileUpdate` with no shared reference or test tying the two together.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Manifest format | Single `default.json` with two arrays (`install[]`, `profile[]`) | Separate files per concern | [inferred] Keeps one source of truth per AGENTS.md's explicit framing; not evidenced beyond the doc's own claim. |
| Post-install escape hatch | `adminCommandLine`/`commandLine` raw PowerShell snippets via `Invoke-Expression` | A more structured post-install step DSL | [inferred] `PSScriptAnalyzerSettings.psd1`'s inline comment explicitly justifies suppressing `PSAvoidUsingInvokeExpression` for this pattern — an intentional, acknowledged trade-off, not an oversight. |
| Idempotency mechanism | Strip-then-rewrite by `sectionName` marker on every run | Diff-and-patch, or skip-if-exists | [inferred] Observed directly in code (`install.ps1`); simplest approach that guarantees profile content always matches the current `default.json`, at the cost of losing any manual edits inside a managed section. |
| Self-update mechanism | Re-download `install.ps1` as text and invoke as a dynamic script block | Reference a version-pinned release artifact; require manual re-download | [inferred] Keeps the user always on `main`; trades off reproducibility and offline resilience for always-latest convenience. |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Should package-install failures halt the run or continue past them? Currently continues unconditionally with no error surfaced.
2. Should `Get-ProfileUpdate`'s download/invoke path get error handling, and if so, what's the desired failure mode (retry? fail loud?)?
3. Is the README/AGENTS.md inconsistency (AGENTS.md claims README documents "the intended entry point"; README's actual content doesn't) a doc bug to fix, or does README need the missing usage snippet added?
4. Confirm whether the profile file's read encoding (`Get-Content` default) vs. write encoding (`-Encoding Default` for full rewrites, default `>>` redirection encoding for appends) is a real inconsistency or a non-issue in practice.

## References

- Code: `install.ps1`, `default.json`, `helpers/Get-ProfileUpdate.ps1`
- Tests: `tests/DefaultJson.Tests.ps1`, `tests/InstallScript.Tests.ps1`
- Arrow doc: `docs/arrows/bootstrap.md`
- Depended on by: `show-duke-commands` (profile section-marker convention), `quality-gate` (tests target this segment's files)
