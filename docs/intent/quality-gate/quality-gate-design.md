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

- **`DefaultJson.Tests.ps1`** — validates `default.json`'s top-level shape (`.install[]`/`.profile[]` presence), that every install entry's `source` is one of five known values (a hardcoded, manually-maintained duplicate of the source vocabulary also described in AGENTS.md), and that every `profile[]` entry whose `value` URL points under `/helpers/` resolves to an actual file in `helpers/` containing a `function <sectionName>` declaration. This is the primary automated check on the AGENTS.md-documented "two-file change" contract for adding a helper — but it only verifies the `default.json → helpers/` direction (a registered link must resolve to a real function); nothing checks the reverse.
- **`Helpers.Tests.ps1`** — parameterized (Pester `-ForEach`, discovered via `BeforeDiscovery`) over every file in `helpers/`: confirms each parses with zero errors (`[Parser]::ParseFile`) and, after dot-sourcing the file into the live test process, that a function matching the filename-derived name exists and is callable. Dot-sourcing means any accidental top-level (non-function-body) statement in a helper would actually execute during `Invoke-Pester` — a latent risk, not evidenced by any current helper's content.
- **`InstallScript.Tests.ps1`** — the thinnest spec: confirms `install.ps1` parses without syntax errors via the same `[Parser]::ParseFile` mechanism. Does not exercise any of `install.ps1`'s actual logic (package dispatch, profile splice, idempotency).

## Coverage Gaps (Observed)

None of the current tests check:
- That every file in `helpers/` has a corresponding registration in `default.json`'s `profile[]` array (only the reverse direction is checked).
- The AGENTS.md-mandated `.SYNOPSIS` comment-based help block's presence on each helper — the exact thing `show-duke-commands` depends on for its "no description available" fallback.
- `install.ps1`'s actual dispatch/splice/idempotency behavior beyond parse-validity.
- Well-formedness of `adminCommandLine`/`commandLine` script text in `default.json`.
- Schema validation for `optional`/`buckets` properties in `default.json`.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| `install.ps1` never runs in CI | Parse-check only; no actual execution | Run `install.ps1` against a disposable CI VM | Explicitly documented in AGENTS.md: real package installs/profile writes aren't safe in CI. Confirmed consistent with `.github/workflows/ci.yml`'s actual job list (no install step present). |
| Helper verification via dot-sourcing | Load each helper into the live test process and check for a matching function | Parse to AST and inspect `FunctionDefinitionAst` without executing | [inferred] Simpler to implement and directly tests "is this callable," at the cost of actually executing any top-level code in the file — a trade-off not discussed in-repo. |
| Lint rule exclusions | Three targeted `ExcludeRules` with inline rationale | Suppress at the call site (`[Diagnostics.CodeAnalysis.SuppressMessageAttribute]`) or accept the lint failures | [inferred] Central exclusion file keeps the rationale in one place rather than scattered per-file; evidenced by the settings file's own self-documenting comment block. |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Should a reverse-direction test be added: every `helpers/*.ps1` file has a matching `default.json` profile registration?
2. Should a `.SYNOPSIS` presence check be added to `Helpers.Tests.ps1`?
3. Should `InstallScript.Tests.ps1` grow beyond parse-checking (e.g. mocked coverage of the splice/idempotency behavior)?

## References

- Code: `PSScriptAnalyzerSettings.psd1`, `.github/workflows/ci.yml`
- Tests: `tests/DefaultJson.Tests.ps1`, `tests/Helpers.Tests.ps1`, `tests/InstallScript.Tests.ps1`
- Arrow doc: `docs/arrows/quality-gate.md`
- Targets: `bootstrap` (install.ps1, default.json), all helper segments (via `helpers/*.ps1` glob)
