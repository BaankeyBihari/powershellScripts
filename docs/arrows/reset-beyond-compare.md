# Arrow: BeyondCompare Trial Reset

Clears the Beyond Compare 4 trial `CacheID` registry value under `HKCU` to reset its trial-period tracking.

## Status

**MAPPED** — sampled 2026-08-22 (git SHA `efd29bf`). Reconstructed from source during initial brownfield mapping; specs and coverage below are not yet audited against a live test run.

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/reset-beyond-compare/reset-beyond-compare-design.md

### EARS
- docs/intent/reset-beyond-compare/reset-beyond-compare-specs.md (BCOMPARE-*)

### Tests
- (none currently — not exercised by `tests/`)

### Code
- helpers/Reset-BeyondCompare.ps1

## Architecture

**Purpose:** One-off personal maintenance utility, unrelated to the install/package-management machinery — a registry tweak convenience function.

**Key Components:**
1. `Reset-BeyondCompare` — reads then removes the `CacheID` value under `HKCU:\Software\Scooter Software\Beyond Compare 4`, printing before/after state to the console.

## Spec Coverage

Not yet written — EARS specs for this segment are generated in the next step of this bootstrap.

## Key Findings

1. **Sole owner of a specific registry key** — no other segment in the repo touches `HKCU:\Software\Scooter Software\Beyond Compare 4`; fully independent side effect.
2. **Hardcoded, version-specific registry path** — targets "Beyond Compare 4" specifically; will silently no-op or error against a different installed version with no version-detection logic (`helpers/Reset-BeyondCompare.ps1`).
3. **No error handling** — if the registry key or `CacheID` value doesn't exist (already reset, or app not installed), `Get-ItemProperty`/`Remove-ItemProperty` throw non-terminating errors rather than being guarded.
4. **Stylistic outlier** — every statement ends with a semicolon, unlike the sibling helper files read in the same sweep pass.

## Work Required

### Must Fix
None identified.

### Should Fix
1. Guard against the missing-key/missing-value case (existence check or `-ErrorAction`/try-catch).

### Nice to Have
1. Normalize trailing-semicolon style to match the rest of `helpers/`.
