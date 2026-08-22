# Arrow: BeyondCompare Trial Reset

Clears the Beyond Compare 4 trial `CacheID` registry value under `HKCU` to reset its trial-period tracking.

## Status

**AUDITED** — sampled 2026-08-22, gap spec BCOMPARE-004 closed with tests 2026-08-22, audited 2026-08-22. All 4 specs now have direct assertions: BCOMPARE-001/BCOMPARE-003 (the before/after registry-value prints), found untested during audit, got dedicated tests asserting on `Reset-BeyondCompare`'s pipeline output (fixed 2026-08-22, `Invoke-Pester` green: 8/8 for this segment).

## References

### HLD
- docs/high-level-design.md (System Design)

### LLD
- docs/intent/reset-beyond-compare/reset-beyond-compare-design.md

### EARS
- docs/intent/reset-beyond-compare/reset-beyond-compare-specs.md (BCOMPARE-*)

### Tests
- tests/ResetBeyondCompare.Tests.ps1

### Code
- helpers/Reset-BeyondCompare.ps1

## Architecture

**Purpose:** One-off personal maintenance utility, unrelated to the install/package-management machinery — a registry tweak convenience function.

**Key Components:**
1. `Reset-BeyondCompare` — reads then removes the `CacheID` value under `HKCU:\Software\Scooter Software\Beyond Compare 4`, printing before/after state to the console.

## Spec Coverage

| Category | Spec IDs | Implemented | Tested | Gaps |
|----------|----------|-------------|--------|------|
| Reset behavior | BCOMPARE-001 to BCOMPARE-003 | 3 | 3 | 0 |
| Error handling | BCOMPARE-004 | 1 | 1 | 0 |

**Summary:** 4 of 4 specs implemented and tested — smallest segment in the repo, fully covered.

## Key Findings

1. **Sole owner of a specific registry key** — no other segment in the repo touches `HKCU:\Software\Scooter Software\Beyond Compare 4`; fully independent side effect.
2. **Hardcoded, version-specific registry path** — targets "Beyond Compare 4" specifically; will silently no-op or error against a different installed version with no version-detection logic (`helpers/Reset-BeyondCompare.ps1`). Not fixed this pass — no gap spec covers it.
3. **Missing-key/missing-value now guarded** — confirmed by reproducing both raw errors against a throwaway registry key before fixing (`ItemNotFoundException` for a missing key, `PSArgumentException` for a missing value); both now produce a specific `Write-Warning` instead (`BCOMPARE-004`).
4. **Trailing-semicolon style incidentally normalized** — the `BCOMPARE-004` rewrite dropped the semicolons that made this file a stylistic outlier among its siblings; not a deliberate cleanup pass, just a side effect of rewriting the function body.

## Work Required

### Must Fix
None identified.

### Should Fix
None outstanding.

### Nice to Have
1. Generalize the hardcoded "Beyond Compare 4" registry path to detect the installed version.
