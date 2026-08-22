# Session Logging — EARS Specs

- [x] **TEE-001**: The system shall accept the wrapped command as bare words or a script block via `$args`, without `CmdletBinding`-based parameter binding, so that flag/value pairs intended for the wrapped command are preserved as-is.
- [x] **TEE-002**: When `-LogPath` is supplied as the first argument, the system shall use it as the log file destination.
- [x] **TEE-003**: When `-LogPath` is not supplied, the system shall generate a default log path under the system temp directory named `<prefix>-<timestamp>-<random>.log`, where `<prefix>` is derived from the invoked command's first word.
- [x] **TEE-004**: When the wrapped command runs, the system shall pipe its combined `2>&1` stream through `Tee-Object` so output is written to both the console and the log file.
- [ ] **TEE-005**: If `Invoke-TeeCommand` is invoked with zero arguments, then the system shall report a clear error rather than failing on an unguarded null index.
