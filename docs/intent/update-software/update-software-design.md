---
parent: high-level-design
prefix: SWUPDATE
---

# Software Update

## Context and Current State

A single-line convenience alias exposed in the user's profile for a common maintenance task: bringing every package source this repo installs from — winget, scoop (apps and buckets), and uv-managed CLI tools — up to date in one call, rather than remembering and running three separate update commands.

## Mechanism

`Update-Software` takes no parameters and runs, in order, each preceded by a `Write-Host` banner announcing which source is about to update (so three tools' worth of output, run back-to-back, stays visually separable):

1. **winget** — `winget upgrade --all`, always run; winget is a hard dependency of this repo's install flow (`default.json`'s `winget.items` includes required packages), so it's assumed present.
2. **scoop** — `scoop update` followed by `scoop update --all`, but only if `scoop` is on `PATH` (checked via `Get-Command scoop -ErrorAction SilentlyContinue`, the same guard `install.ps1` uses before any scoop call). The first command refreshes Scoop itself and all added bucket manifests; the second upgrades every installed scoop app across those buckets. If `scoop` isn't found, a warning is written and the step is skipped rather than failing the whole call.
3. **uv** — `uv tool upgrade --all`, but only if `uv` is on `PATH` (same `Get-Command` guard). This upgrades every `uv tool`-installed CLI (e.g. `headroom-ai`, installed via `default.json`'s `commandLine` post-install step) without touching `uv` itself — `uv` is winget-managed in this repo (`default.json`'s `winget.items` includes `astral-sh.uv`), so its own version is already covered by step 1. If `uv` isn't found, a warning is written and the step is skipped.

None of the three steps are guarded by try/catch or exit-code checks against each other: a failure or non-zero exit from one external command does not block the next step from running, since the three sources are independent and a problem in one (e.g. a network blip during `scoop update`) shouldn't prevent the others from updating. All three steps delegate their actual update logic — what's outdated, what gets confirmed, what output is shown — entirely to the underlying CLI; the wrapper's own job is sequencing the three calls, announcing each with a banner, and guarding the two optional ones.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Scope | One wrapper covering winget + scoop (apps and buckets) + `uv tool` upgrades | Keep `Get-WingetUpgrade` as a winget-only wrapper and add separate `Update-Scoop`/`Update-UvTools` helpers | The user's own workflow treats "update my machine" as one action across all three sources this repo installs from; splitting it into three commands to run separately reintroduces the exact friction this helper exists to remove. |
| Missing-tool handling | Warn and skip the affected step, continue to the remaining sources | Fail the whole call (`Write-Error` + `return`) if scoop or uv is missing | Per the HLD's Tenet #1 ("blast radius decides how defensive to be"), missing an optional source shouldn't block updating the sources that *are* present — but staying silent would hide that a source was skipped, so a warning keeps the failure loud without aborting the rest of the run. |
| `uv` self-update | Not included — only `uv tool upgrade --all` | Also run `uv self update` | `uv` itself is winget-managed in this repo (`default.json`'s `winget.items`), so step 1's `winget upgrade --all` already covers it; running `uv self update` too would let `uv`'s own version drift ahead of what winget tracks. |
| Replacing vs. adding alongside `Get-WingetUpgrade` | Replace outright — old helper file and profile registration removed, new file added | Keep both, deprecate old one gradually | Per the HLD's Tenet #3 ("new capability is a new file, not a new parameter"), the old winget-only wrapper is fully superseded, not extended; keeping a redundant winget-only alias alongside the full-stack one would just be two ways to do a subset of the same thing. |
| Cross-step failure handling | Non-fail-fast — no try/catch or exit-code gating between the three steps | Fail-fast (stop the whole call if an earlier step errors) | The three sources are independent tool ecosystems; a transient failure in one (e.g. `scoop update`'s bucket refresh hitting a network error) has no bearing on whether winget or uv can still update successfully, so blocking them on an unrelated failure would only reduce how much actually gets updated per call. |
| Per-source output banners | A `Write-Host` banner before each of the three steps | Bare pass-through with zero added output (`Get-WingetUpgrade`'s prior behavior) | With three CLIs' output concatenated in one call, an undifferentiated wall of text makes it hard to tell which lines belong to which source; a one-line banner per step costs little and keeps the combined output scannable. |

## Open Questions & Future Decisions

### Resolved
1. ✅ No parameters — matches the bare pass-through pattern of the winget-only wrapper it replaces; a per-source filter, if ever wanted, becomes a new helper per Tenet #3, not a flag here.

### Deferred
(none)

## References

- Code: `helpers/Update-Software.ps1`
- Tests: `tests/Helpers.Tests.ps1` (generic parse/name/synopsis checks); no update-flow-specific tests (see EARS spec test coverage)
- Arrow doc: `docs/arrows/update-software.md`
