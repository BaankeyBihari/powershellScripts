# BeyondCompare Trial Reset — EARS Specs

- [x] **BCOMPARE-001**: When `Reset-BeyondCompare` is invoked, the system shall print the current value of `HKCU:\Software\Scooter Software\Beyond Compare 4` before making any change.
- [x] **BCOMPARE-002**: When `Reset-BeyondCompare` is invoked, the system shall remove the `CacheID` value under that registry key.
- [x] **BCOMPARE-003**: After removing `CacheID`, the system shall print the registry key's resulting value.
- [x] **BCOMPARE-004**: If the registry key or its `CacheID` value does not exist, then the system shall report a clear, guarded message rather than a raw non-terminating error.
