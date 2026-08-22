---
parent: high-level-design
prefix: TEE
---

# Session Logging

## Context and Current State

A general-purpose observability helper: wraps any command so its combined stdout+stderr is captured to both the console and a log file, similar to Unix `tee`. This is the most recently and actively developed helper in the repo — git history shows three consecutive commits refining how the auto-generated log filename is derived (add the helper, prefix temp logs, then derive the prefix from the actual invoked command word).

## Mechanism

`Invoke-TeeCommand` accepts the invoked command either as bare words (`Invoke-TeeCommand docker ps -a`) or as a script block, with an optional `-LogPath` supplied as the first argument. It is deliberately declared without `[CmdletBinding()]` or typed `[Parameter()]` attributes — an inline comment in the file states this is intentional, so that PowerShell's automatic `$args` array preserves flag/value pairs like `-a` as-is rather than PowerShell's parameter binding collapsing them into positional values.

Because of this, `-LogPath` detection is manual: the function inspects `$args[0]` positionally rather than using named parameter binding. When no `-LogPath` is supplied, a default path is built under the system temp directory from a sanitized prefix (derived from the invoked command's first word), a timestamp (`yyyyMMdd-HHmmss`), and a random 4-digit suffix. The command (or script block) is then invoked with its `2>&1` stream piped through `Tee-Object` to write both to console and the log file.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|--------------------------|-----------|
| Parameter handling | Undeclared `$args`, manual positional parsing | `[CmdletBinding()]` with typed `[Parameter()]`s | Documented in-file: preserves flag/value splatting (e.g. `-a`) for the wrapped command, which PowerShell's parameter binder would otherwise collapse to positional args. |
| Default log naming | `<prefix>-<timestamp>-<random>.log` under system temp, prefix derived from the actual invoked command word | Fixed/generic log filename; require `-LogPath` always | [inferred] Evidenced by the 3-commit refinement history — the project iterated toward filenames that are identifiable per-command rather than opaque, while still working without requiring the caller to specify a path every time. |

## Open Questions & Future Decisions

### Resolved
(none yet — this LLD is freshly reconstructed from code)

### Deferred
1. Should calling with zero arguments (empty `$args`) fail with a clear error instead of the current unguarded `$rest[0]` access?
2. Is the auto-generated log file ever cleaned up, or is unbounded accumulation under the temp directory acceptable?

## References

- Code: `helpers/Invoke-TeeCommand.ps1`
- Tests: none currently
- Arrow doc: `docs/arrows/invoke-tee-command.md`
