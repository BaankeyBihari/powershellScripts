---
parent: high-level-design
prefix: WINGET
---

# Windows Package Maintenance

## Context and Current State

A single-line convenience alias exposed in the user's profile for a common maintenance task: checking for and upgrading outdated winget packages.

## Mechanism

`Get-WingetUpgrade` takes no parameters and runs `winget upgrade --all`, letting winget's own interactive UI list available upgrades and prompt for confirmation. All behavior — listing, prompting, upgrading — is delegated entirely to the external `winget` executable; the wrapper adds nothing beyond a memorable PowerShell verb-noun name.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Wrapper scope | Bare pass-through to `winget upgrade --all`, no flags/params | Add `-Silent`/`-Confirm` style parameters, filter output | [inferred] Matches the repo-wide pattern (see `Get-WingetUpgrade`, `Get-WingetUpgrade`-style siblings) of packaging one-liners as named functions rather than building richer wrappers — consistent with `PSScriptAnalyzerSettings.psd1`'s stated rationale that these are "thin CLI wrappers." |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Is `--all` (upgrade everything, no per-package selection) the intended default, or should the function accept a package-name filter?

## References

- Code: `helpers/Get-WingetUpgrade.ps1`
- Tests: none currently
- Arrow doc: `docs/arrows/get-winget-upgrade.md`
