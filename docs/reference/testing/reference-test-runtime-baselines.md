---
id: reference-test-runtime-baselines
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - testing
last_updated: 2026-01-22
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Environment; Baselines."
  - "Keep top-level sections: Environment; Baselines."
---

# Test Runtime Baselines

Record wall-clock durations for key test commands to watch for regressions.

## Environment

- Xcode: 16.2
- CI pinned simulator: iPhone 16 (iOS 18.2)
- Baseline simulator (2026-01-03): iPhone 16 Pro (iOS 18.3.1)
- Scheme: `Offload`

Command:

```bash
xcodebuild test -project ios/Offload.xcodeproj -scheme Offload \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -derivedDataPath .derivedData \
  -resultBundlePath .xcresult-<timestamp>
```

## Baselines

| Date | Duration | Result Bundle | Notes |
| --- | --- | --- | --- |
| 2026-01-03 | 112.818s | `.xcresult-20260103093434` | Full suite on iPhone 16 Pro (iOS 18.3.1) |
| YYYY-MM-DD | ____s | CI artifact path | CI full suite |
