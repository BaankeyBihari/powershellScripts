---
parent: high-level-design
prefix: DUKE
---

# Command Discovery

## Context and Current State

Once `install.ps1` has spliced helper functions into a user's PowerShell profile (see the `bootstrap` segment), there's no built-in way to see what got installed short of opening the profile file. `Show-DukeCommands` closes that gap: it reads the profile, recovers the list of spliced sections, and prints each one's synopsis and call syntax.

## Mechanism

`Show-DukeCommands` reads `$Profile.CurrentUserAllHosts` (or a caller-supplied `-ProfilePath`) and runs `Select-String` with the regex `^#---Begin Section: (.+)---$` to recover every spliced section's name. For each recovered name, it calls `Get-Command -Name <name> -CommandType Function -Syntax` and `Get-Help -Name <name>`, printing the name, synopsis, and "Usage: <syntax>" line. Both lookups use `-ErrorAction SilentlyContinue`, so a section name that doesn't resolve to a live function (e.g. a `type: "content"` profile entry, which has no function) is silently skipped with no diagnostic.

A synopsis equal to the bare function name is treated as "no description available" — this is the fallback text `Get-Help` produces for a function with no comment-based help block, so the check is a heuristic for detecting that case rather than a literal string comparison against a known sentinel.

## Cross-Segment Dependency

This segment's entire mechanism depends on a convention it does not own: the `#---Begin Section: <name>---` / `#---End Section: <name>---` marker format written by `install.ps1` (the `bootstrap` segment). Nothing in the code shares a constant or regex between the two files — if `bootstrap`'s marker format changes, this segment breaks silently with no test catching it.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Section-list source | Regex-parse the profile file's own marker comments | Read `default.json`'s `profile[]` array directly | Regex-parsing the live profile file reflects what's *actually* installed on this machine, not what the manifest currently says — more accurate for a "what do I have" query, at the cost of the cross-segment coupling noted above. |
| Missing-help handling | Detect via synopsis-equals-name heuristic, print "no description available" | Require every helper to have a `.SYNOPSIS` and fail loudly if missing | Degrades gracefully rather than blocking discovery for an undocumented helper — consistent with this being a convenience/discovery tool, not a lint gate. |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Should the section-marker regex be shared (a constant or helper function) between this segment and `bootstrap` to remove the silent-breakage risk?
2. Should silently-skipped, unresolvable sections (`-ErrorAction SilentlyContinue`) instead surface a diagnostic, so a broken/renamed helper is visible rather than invisible?

## References

- Code: `helpers/Show-DukeCommands.ps1`
- Tests: none currently
- Arrow doc: `docs/arrows/show-duke-commands.md`
- Depends on: `bootstrap` (profile section-marker convention)
