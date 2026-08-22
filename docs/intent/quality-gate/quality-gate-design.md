---
parent: high-level-design
prefix: QUALITY
---

# Repo Quality Gate

## Context and Current State

Verifies the repo's own source is internally correct — not end-user-facing behavior. Runs as a manual command (documented in AGENTS.md) and as CI (`.github/workflows/ci.yml`) on every push/PR to `main`, scoped to `.ps1`/`.json`/workflow-file changes. CI does not run `install.ps1` itself, since that performs real package installs and profile writes that aren't safe to run unattended.

## Lint

`PSScriptAnalyzerSettings.psd1` excludes three rules — `PSAvoidUsingInvokeExpression`, `PSAvoidUsingPositionalParameters`, `PSUseShouldProcessForStateChangingFunctions` — each with an inline comment justifying it against a specific repo-wide pattern (post-install `Invoke-Expression` snippets, thin CLI wrappers, one-shot personal utilities with no need for `-WhatIf`/`-Confirm`). CI's `lint` job runs `Invoke-ScriptAnalyzer` against `install.ps1` and `helpers` with this settings file and throws (fails the build) if any result is returned.

## Tests

Three Pester v5 spec files under `tests/`, each independently deriving `$repoRoot` via `Split-Path -Parent $PSScriptRoot` (no shared setup file):

- **`DefaultJson.Tests.ps1`** — validates `default.json`'s top-level shape (`.install[]`/`.profile[]` presence), that every install entry's `source` is one of five known values (a hardcoded, manually-maintained duplicate of the source vocabulary also described in AGENTS.md), that every `profile[]` entry whose `value` URL points under `/helpers/` resolves to an actual file in `helpers/` containing a `function <sectionName>` declaration, and — as of `QUALITY-010` — the reverse direction: every file in `helpers/` has a matching `profile[]` link entry. Together these two checks fully close the AGENTS.md-documented "two-file change" contract for adding a helper in both directions. As of `QUALITY-012`, it also validates every `winget`/`msstore` `items`/`optional` entry is an `{id, name}` object with both fields non-empty — catching a future regression back to bare ID strings, the shape those two sources used before the `bootstrap` segment's `{id, name}` convention (`BOOT-015`).
- **`Helpers.Tests.ps1`** — parameterized (Pester `-ForEach`, discovered via `BeforeDiscovery`) over every file in `helpers/`: confirms each parses with zero errors (`[Parser]::ParseFile`), that a function matching the filename-derived name exists and is callable after dot-sourcing, and — as of `QUALITY-011` — that `Get-Help` on that function returns a `.SYNOPSIS` whose text isn't just the bare function name (the same "no real help block" heuristic `Show-DukeCommands` uses at runtime, per `DUKE-004`). Dot-sourcing means any accidental top-level (non-function-body) statement in a helper would actually execute during `Invoke-Pester` — a latent risk, not evidenced by any current helper's content.
- **`InstallScript.Tests.ps1`** — the thinnest spec: confirms `install.ps1` parses without syntax errors via the same `[Parser]::ParseFile` mechanism. Does not exercise any of `install.ps1`'s actual logic (package dispatch, profile splice, idempotency) beyond the `Test-InstallExitCode` function extracted and tested for `BOOT-013`.

## Coverage Gaps (Observed)

Still not checked by any current test (out of scope for this pass — no gap spec covers these):
- `install.ps1`'s actual dispatch/splice/idempotency behavior beyond parse-validity and the extracted `Test-InstallExitCode` function.
- Well-formedness of `adminCommandLine`/`commandLine` script text in `default.json`.
- Schema validation for `scoop`'s `buckets` property, and for `scoop`'s own `items`/`optional` string entries, in `default.json` (`winget`/`msstore` `items`/`optional` shape is covered by `QUALITY-012`).

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| `install.ps1` never runs in CI | Parse-check only; no actual execution | Run `install.ps1` against a disposable CI VM | Explicitly documented in AGENTS.md: real package installs/profile writes aren't safe in CI. Confirmed consistent with `.github/workflows/ci.yml`'s actual job list (no install step present). |
| Helper verification via dot-sourcing | Load each helper into the live test process and check for a matching function | Parse to AST and inspect `FunctionDefinitionAst` without executing | Simpler to implement and directly tests "is this callable," at the cost of actually executing any top-level code in the file — an accepted trade-off given every current helper is a pure function definition with no top-level side effects. |
| Lint rule exclusions | Three targeted `ExcludeRules` with inline rationale | Suppress at the call site (`[Diagnostics.CodeAnalysis.SuppressMessageAttribute]`) or accept the lint failures | Central exclusion file keeps the rationale in one place rather than scattered per-file, and documents each exclusion's justification inline for future reviewers. |
| Reverse helper-registration check (`QUALITY-010`) | Compare `Get-ChildItem helpers/*.ps1` filenames against `profile[]` link entries' URL-derived filenames | Require manual bookkeeping; add a build-time generator that writes `profile[]` from `helpers/` | A test is cheaper than a generator for a repo this size, and directly closes the gap the existing forward-direction test left open. |
| `.SYNOPSIS` presence check (`QUALITY-011`) | Reuse `Show-DukeCommands`' own "synopsis equals function name" heuristic in the test | Require an exact non-empty string; parse the comment block directly via AST | Keeping the test's definition of "has a real synopsis" identical to the runtime code that depends on it (`DUKE-004`) avoids the two silently drifting apart. |
| `winget`/`msstore` `{id, name}` shape check (`QUALITY-012`) | Verify `items`/`optional` entries are objects with non-empty `id` and `name` | Leave the shape unenforced (rely on the `bootstrap` segment's convention alone) | The `bootstrap` LLD's `{id, name}` convention (`BOOT-015`) has nothing stopping a future edit from reintroducing a bare ID string for `winget`/`msstore` if left unchecked; a schema-level test catches that at the same boundary `QUALITY-001`/`QUALITY-002` already check entry shape at. |

## Open Questions & Future Decisions

### Resolved
1. ✅ A reverse-direction test was added (`QUALITY-010`, in `DefaultJson.Tests.ps1`): every `helpers/*.ps1` file must have a matching `default.json` profile registration.
2. ✅ A `.SYNOPSIS` presence check was added to `Helpers.Tests.ps1` (`QUALITY-011`).
3. ✅ `winget`/`msstore` `items`/`optional` entries are now shape-checked as `{id, name}` objects with non-empty fields (`QUALITY-012`), cascaded from the `bootstrap` segment's `{id, name}` convention (`BOOT-015`).

### Deferred
1. Should `InstallScript.Tests.ps1` grow beyond parse-checking and the `Test-InstallExitCode` extraction (e.g. mocked coverage of the splice/idempotency behavior)? Tied to `bootstrap`'s own deferred decision to backfill tests for its pre-existing specs — not scheduled.
2. Should well-formedness of `adminCommandLine`/`commandLine` script text, or schema validation for `scoop`'s `buckets`/`items`/`optional` properties, be added to `DefaultJson.Tests.ps1`? No gap spec currently covers these.

## References

- Code: `PSScriptAnalyzerSettings.psd1`, `.github/workflows/ci.yml`
- Tests: `tests/DefaultJson.Tests.ps1`, `tests/Helpers.Tests.ps1`, `tests/InstallScript.Tests.ps1`
- Arrow doc: `docs/arrows/quality-gate.md`
- Targets: `bootstrap` (install.ps1, default.json), all helper segments (via `helpers/*.ps1` glob)
