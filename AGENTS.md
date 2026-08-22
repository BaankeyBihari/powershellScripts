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

Every helper function must start its body with a comment-based help block (`<# .SYNOPSIS ... .EXAMPLE ... #>`), e.g.:

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
    One-line description of what this does.
    .EXAMPLE
    Verb-Noun
    #>
    ...
}
```

`helpers/Show-DukeCommands.ps1` reads this via `Get-Help` to list every spliced-in function with its description and usage — a helper without a `.SYNOPSIS` shows as "(no description available)". When adding a new helper or editing an existing one, add or update its `.SYNOPSIS` (and `.EXAMPLE` if usage isn't obvious from the syntax alone) so it stays accurate.

Note the bootstrapping dependency: `profile` link entries point at `raw.githubusercontent.com/.../main/...`, so a helper isn't actually pullable by end users until its commit is merged to `main`.

## LID
- Mode: Full
- Version: 1.3.0

## Linked-Intent Development (MANDATORY)

**Consult the `linked-intent-dev` skill for ALL code changes.** All changes flow through the arrow of intent in one direction:

```
HLD → LLDs → EARS → Tests → Code
```

- **New features and refactors**: full six-phase workflow (HLD check → LLD check/draft → EARS → intent-narrowing edge audit → tests-first → code).
- **Bug fixes**: walk the arrow like any other change — find where behavior diverged from intent and cascade from there. No short-circuit.
- **If unsure**: use the full workflow.

Stop after each phase for user review. **Docs carry current intent, written to be read cold** — write each doc as if authored fresh today, from current intent alone: no narration of how it changed, no meaning that needs the conversation that produced it, no rebuttals to questions only a past discussion raised. Rationale, considered alternatives, and constraints a fresh author would independently write stay; record rejected alternatives and why in the LLD's Decisions & Alternatives table, not as asides in body prose.

**Memory vs. intent.** Before saving durable project knowledge to agent or tool memory, test whether it is project *intent* — would a fresh agent, in any tool, next session, need it to build this system correctly? If yes, record it in the arrow (HLD / LLD / EARS / decision doc), which travels and cascades — not in private, per-tool memory, where intent escapes the arrow. Knowledge about the user or how they like to work stays in memory.

### Navigation

| What you need | Where to look |
|---|---|
| High-level design | `docs/high-level-design.md` |
| Design tree (sub-HLDs, LLDs, their specs) | `docs/intent/` — one folder per node |
| EARS specs | beside each design doc as `{node}-specs.md` in the node's folder under `docs/intent/` |
| Decision docs | `docs/decisions/` (project-level) and `docs/intent/<segment>/decisions/` |
| Arrow of intent overlay | `docs/arrows/index.yaml` and per-segment docs in `docs/arrows/` |

### Terminology

- **HLD**: High-Level Design — single project-level doc at `docs/high-level-design.md`.
- **LLD**: Low-Level Design — detailed component design doc in `docs/intent/`. The design layer is a recursive tree: the root is the HLD, leaf LLDs own EARS, and a component deep enough to outgrow one doc becomes a sub-HLD (HLD-shaped, owns no EARS) with children beneath it. "HLD" and "LLD" are roles by position; depth-2 (one HLD over flat leaf LLDs) is the default.
- **EARS**: Easy Approach to Requirements Syntax — structured one-line requirements beside each design doc as `{node}-specs.md` in the node's folder under `docs/intent/`. IDs are path-concatenated — the root-to-leaf path of the owning segment plus a number — so a prefix grep gathers a subtree. Markers: `[x]` implemented, `[ ]` active gap, `[D]` deferred.
- **Arrow**: the unidirectional chain from vision to code (HLD → LLDs → EARS → Tests → Code). Strictly a DAG of intent.
- **Arrow segment**: the territory owned by one leaf LLD — the LLD itself plus the specs, tests, and code that cite its EARS IDs. The boundary is the leaf prefix. Within-segment cascade is free; across-segment cascade pauses.
- **Cascade**: propagating a change downstream through the arrow so adjacent levels stay coherent.

### Code annotations

Annotate code and tests with `@spec` comments citing EARS IDs:

```
// @spec AUTH-UI-001, AUTH-UI-002
```

Place the annotation at the *entry point of the behavior's implementation graph* — the topmost function or module owning the specified behavior, not every helper. When a behavior spans multiple subsystems (UI + API + database, for example), annotate at the entry point in each subsystem. Tests follow the same rule: annotate the test that directly exercises the spec, not every inner assertion.

## Continuity across agent sessions

For non-trivial or likely-multi-session work (skip this for one-shot edits like a single typo fix or small helper tweak), use GitHub issues as the shared resumption point so another agent/session — possibly a different tool entirely — can pick up where you left off.

- **Session log issue**: [#1 "Agent Session Log"](https://github.com/BaankeyBihari/powershellScripts/issues/1) is the persistent index and discussion thread for ongoing AI-assisted work in this repo. If it's ever missing/closed, draft a replacement and get the user's go-ahead before creating it — issue creation is a shared, visible action, not something to do silently.
- **Scoped work issues**: once a task's plan/scope is finalized, open a new issue for that specific piece of work, with `Parent: #1` in the body. Keep discussion/decisions on the session log issue; use the scoped issue to record that task's plan, progress, and next steps, so a future session has enough context to resume without re-deriving it.
- Check `gh issue list` for open scoped issues linked to [#1](https://github.com/BaankeyBihari/powershellScripts/issues/1) before starting from scratch — you may be resuming existing work rather than starting new.
- Always confirm with the user before `gh issue create` or `gh issue close` — draft the content, get a go-ahead, then run it.
