# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this repo is

A one-shot Windows machine-bootstrap system: `install.ps1` reads `default.json` and (1) installs a list of winget/msstore/scoop packages, runs post-install commands, and (2) splices a set of standalone PowerShell functions (`helpers/*.ps1`) into the user's PowerShell profile. There is no build step — validate changes by reading/running the scripts directly with `pwsh`, and by lint/tests (see below).

## Commands

- Run the installer end-to-end: `pwsh -File install.ps1` (downloads `default.json`/`install.ps1` from GitHub by default; pass `-resourceUri`/`-installUri` to point at local copies instead, e.g. `pwsh -File install.ps1 -resourceUri ./default.json -installUri ./install.ps1`).
- Manually exercise a single helper without touching your profile: `. .\helpers\Start-ADBDaemon.ps1; Start-ADBDaemon` (dot-source the file, then call the function).
- Lint (`install.ps1` and `helpers/*.ps1` only, rules tuned via `PSScriptAnalyzerSettings.psd1`): `Install-Module PSScriptAnalyzer -Scope CurrentUser -Force` then `Invoke-ScriptAnalyzer -Path install.ps1,helpers -Recurse -Settings ./PSScriptAnalyzerSettings.psd1`.
- Tests (Pester specs in `tests/` cover `default.json` shape, that every `helpers/*.ps1` defines a function matching its filename, and that both `install.ps1` and each helper parse without syntax errors): `Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force` then `Invoke-Pester -Path ./tests`.
- CI (`.github/workflows/ci.yml`) runs both of the above on push/PR to `main`. It does not run `install.ps1` itself — that does real package installs and profile writes, which isn't safe in CI.

## Architecture

**`default.json`** is the single source of truth, with two top-level arrays:
- `install`: grouped by `source` (`winget`, `msstore`, `scoop`, `adminCommandLine`, `commandLine`). Each winget/msstore/scoop group has `items` (always installed) and `optional` (user is prompted once, y/N, for the whole optional batch). `scoop` groups can also list `buckets` to add. `adminCommandLine`/`commandLine` entries are raw PowerShell snippets run via `Invoke-Expression` (or `sudo Invoke-Expression` for admin) — used for post-install config that can't be expressed as a package install (see the MiKTeX/LyX config block).
- `profile`: a list of `{ sectionName, type, value }` entries that get written into `$Profile.CurrentUserAllHosts`, delimited by `#---Begin Section: <name>---` / `#---End Section: <name>---` markers. `type: "link"` fetches `value` (a raw GitHub URL) and inlines its content; `type: "content"` inlines `value` literally. On re-run, `install.ps1` first strips any existing section with a matching `sectionName` before rewriting it, so profile updates are idempotent.

**`install.ps1`** is fetched and executed by the user (see `README.md`'s intended entry point), and is also what `helpers/Get-ProfileUpdate.ps1` re-downloads and re-invokes on demand — so it must stay runnable both as a fresh download and as a re-run against an already-populated profile.

**`helpers/*.ps1`**: one PowerShell function per file, filename matches the function name (`Verb-Noun.ps1` → `function Verb-Noun { ... }`). These are never referenced directly by `install.ps1`'s package-install logic — the *only* thing that wires a helper into the user's profile is adding a matching `type: "link"` entry to `default.json`'s `profile` array pointing at its raw GitHub URL. Adding a new helper is therefore a two-file change: create `helpers/<Verb-Noun>.ps1`, then register it in `default.json`.

Note the bootstrapping dependency: `profile` link entries point at `raw.githubusercontent.com/.../main/...`, so a helper isn't actually pullable by end users until its commit is merged to `main`.

## Continuity across agent sessions

For non-trivial or likely-multi-session work (skip this for one-shot edits like a single typo fix or small helper tweak), use GitHub issues as the shared resumption point so another agent/session — possibly a different tool entirely — can pick up where you left off.

- **Session log issue**: a single persistent issue titled `Agent Session Log` is the index and discussion thread for ongoing AI-assisted work in this repo. Before starting non-trivial work, check whether it exists (`gh issue list --search "Agent Session Log" --state open`). If it doesn't, draft one and get the user's go-ahead before creating it — issue creation is a shared, visible action, not something to do silently.
- **Scoped work issues**: once a task's plan/scope is finalized, open a new issue for that specific piece of work, with `Parent: #<session-log-issue-number>` in the body. Keep discussion/decisions on the session log issue; use the scoped issue to record that task's plan, progress, and next steps, so a future session has enough context to resume without re-deriving it.
- Check `gh issue list` for open scoped issues linked to the session log before starting from scratch — you may be resuming existing work rather than starting new.
- Always confirm with the user before `gh issue create` or `gh issue close` — draft the content, get a go-ahead, then run it.
