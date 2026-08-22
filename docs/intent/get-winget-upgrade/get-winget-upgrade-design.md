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
| Wrapper scope | Bare pass-through to `winget upgrade --all`, no flags/params | Add `-Silent`/`-Confirm` style parameters, filter output | Matches the repo-wide pattern of packaging one-liners as named functions rather than building richer wrappers — consistent with `PSScriptAnalyzerSettings.psd1`'s stated rationale that these are "thin CLI wrappers." Reinforced by the HLD's Tenet #3 ("new capability is a new file, not a new parameter"): per-package filtering, if ever wanted, becomes its own helper rather than a flag added here. |

## Open Questions & Future Decisions

### Resolved
1. ✅ `--all` stays the only mode. Per the HLD's Tenet #3, a package-name filter — if ever wanted — becomes a new helper (e.g. `Update-WingetPackage`), not a parameter added to this one.

### Deferred
(none)

## References

- Code: `helpers/Get-WingetUpgrade.ps1`
- Tests: none currently
- Arrow doc: `docs/arrows/get-winget-upgrade.md`
