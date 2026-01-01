# iOS CI/CD Workflow Implementation Plan

## Executive Summary

**Root Cause of Previous Failures**: The Xcode project has an invalid iOS deployment target of `26.2` (iOS versions are 17.0, 18.0, etc., not 26.x). This likely caused Xcode to default to visionOS simulators as a fallback, resulting in all previous CI attempts failing.

**Solution**: Fix the deployment target, create shared schemes, and build a modern iOS CI/CD pipeline from scratch using 2026 best practices.

---

## Critical Issues Found

1. **Invalid iOS Deployment Target**: `IPHONEOS_DEPLOYMENT_TARGET = 26.2` in project.pbxproj (should be `17.0`)
2. **Missing Shared Schemes**: No version-controlled Xcode schemes (required for CI)
3. **No Working CI**: Previous attempts never succeeded due to simulator configuration issues

---

## Implementation Steps

### Phase 0: Auto-Fix Code Style (NEW)

**0.1 Run SwiftFormat Auto-Fix**
```bash
# Auto-fix all SwiftFormat violations (~50 violations)
swiftformat ios/Offload

# Verify all issues are resolved
swiftformat --lint ios/Offload
```

**Expected fixes**:
- Import sorting
- Consecutive spaces removal
- Redundant raw values in enums
- Redundant self removal
- Enum namespace conversions
- Unused argument marking

**Time**: ~5 minutes (automated)

**0.2 Commit Style Fixes**
```bash
git add ios/Offload
git commit -m "style: auto-fix SwiftFormat violations

- Sort imports alphabetically
- Remove consecutive spaces
- Clean up enum raw values
- Convert namespace structs to enums
- Mark unused arguments

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Phase 1: Fix Xcode Project Configuration

**1.1 Fix iOS Deployment Target**
- **File**: `ios/Offload.xcodeproj/project.pbxproj`
- **Change**: `IPHONEOS_DEPLOYMENT_TARGET = 26.2;` → `IPHONEOS_DEPLOYMENT_TARGET = 17.0;`
- **Locations**: Lines 325 (Debug), 383 (Release), and any other occurrences
- **Why**: 26.2 is not a valid iOS version, causing Xcode to select wrong platforms

**1.2 Create Shared Xcode Scheme**
- Open Xcode project
- Navigate to: **Product > Scheme > Manage Schemes**
- Check "**Shared**" for the "offload" scheme
- This creates: `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme`
- Verify scheme is configured for:
  - Test targets: `offloadTests` (unit tests)
  - Platform: iOS (not visionOS)
  - Code coverage: Enabled

**1.3 Local Validation**
```bash
# Test build locally with proper iOS simulator
xcodebuild build \
  -project ios/Offload.xcodeproj \
  -scheme offload \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'

# Test with coverage
xcodebuild test \
  -project ios/Offload.xcodeproj \
  -scheme offload \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -enableCodeCoverage YES
```

---

### Phase 2: Create Configuration Files

**2.1 SwiftFormat Configuration**
- **File**: `.swiftformat` (repository root)
- **Key Settings**:
  - Swift version: 5.9
  - Indent: 4 spaces
  - Max width: 120
  - **Minimal exceptions** (only if truly needed after auto-fix)
  - Exclude test directories and build artifacts

**2.2 SwiftLint Configuration**
- **File**: `.swiftlint.yml` (repository root)
- **Key Settings**:
  - GitHub Actions reporter for CI
  - **Standard rules** (no unnecessary exceptions)
  - Include only: `ios/Offload`
  - Exclude: test directories, build artifacts
  - Only disable rules if conflicts arise during testing

**2.3 Markdownlint Configuration**
- **File**: `.markdownlint.json` (repository root)
- **Settings**:
  - Disable MD013 (line length)
  - Disable MD033 (HTML allowed)
  - Disable MD041 (first line heading)

**2.4 Local Testing of Configs**
```bash
# Install tools
brew install swiftformat swiftlint
npm install -g markdownlint-cli

# Test configurations
swiftformat --lint ios/Offload
swiftlint lint --strict ios/Offload
markdownlint '**/*.md' --ignore node_modules
```

---

### Phase 3: Create Helper Scripts

Create in `scripts/ios/` directory (make executable with `chmod +x`):

**3.1 `setup-simulator.sh`**
- Validates iOS simulator availability
- Lists available devices
- Confirms target device exists (iPhone 16 Pro or fallback)

**3.2 `check-coverage.sh`**
- Extracts coverage percentage from `.xcresult` bundle
- Compares against 50% threshold using `bc`
- Exits with code 0 (pass) or 1 (fail)
- Uses: `xcrun xccov view --report`

**3.3 `lint-swift.sh`**
- Runs SwiftFormat in lint mode (no modifications)
- Runs SwiftLint in strict mode
- Provides clear pass/fail output

---

### Phase 4: GitHub Actions Workflow

**4.1 Create Workflow File**
- **File**: `.github/workflows/ios-ci.yml`

**4.2 Job Structure**
```
quality-checks (parallel)
  ├─ markdownlint
  ├─ swiftformat-check
  └─ swiftlint
        ↓
     build
        ↓
  test-unit (with coverage enforcement)
        ↓
   [test-ui - disabled initially]
```

**4.3 Key Configuration**
- **Runner**: `macos-15` (latest stable, Xcode 16+)
- **Xcode Version**: `/Applications/Xcode_16.0.app/Contents/Developer`
- **Destination**: `platform=iOS Simulator,name=iPhone 16 Pro,OS=latest`
- **Code Signing**: Disabled for CI (`CODE_SIGN_IDENTITY=""`)

**4.4 Caching Strategy**
- Cache DerivedData using `actions/cache@v4`
- Restore file timestamps with `chetan/git-restore-mtime-action@v2`
- Set Xcode flag: `IgnoreFileSystemDeviceInodeChanges = YES`
- Expected speedup: 50-70% (cached builds: 3-5min vs initial: 10-15min)

**4.5 Quality Gates**
- All linters must pass (fail-fast enabled)
- Unit tests must pass with 50% minimum coverage
- Test results uploaded as artifacts (30-day retention)
- Coverage report uploaded as artifact

**4.6 Timeouts**
- Quality checks: 10 minutes
- Build: 20 minutes
- Unit tests: 15 minutes
- UI tests: 20 minutes (disabled initially)

---

### Phase 5: Testing & Validation

**5.1 Local Script Testing**
```bash
bash scripts/ios/setup-simulator.sh
bash scripts/ios/lint-swift.sh ios/Offload
bash scripts/ios/check-coverage.sh ./build/test-results.xcresult
```

**5.2 Commit Strategy**
```bash
git add .
git commit -m "feat(ci): implement iOS CI/CD with modern best practices"
git push origin feature/ci-workflows
```

**5.3 Monitor First CI Run**
- Watch GitHub Actions execution
- Verify simulator selection succeeds
- Confirm test execution on iOS (not visionOS)
- Validate coverage calculation and threshold enforcement
- Review uploaded artifacts

**5.4 Iteration Plan**
- If iPhone 16 Pro unavailable, use iPhone 15 or other available device
- Adjust cache keys if hit rate is low
- Fine-tune timeouts based on actual run times
- Add UI tests once unit tests are stable

---

## Critical Files to Modify/Create

### Must Fix (Highest Priority)
1. `ios/Offload.xcodeproj/project.pbxproj` - Fix deployment target 26.2 → 17.0
2. `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme` - Create shared scheme

### Configuration Files
3. `.swiftformat` - SwiftFormat configuration
4. `.swiftlint.yml` - SwiftLint configuration with GitHub Actions reporter
5. `.markdownlint.json` - Markdownlint configuration

### Scripts
6. `scripts/ios/setup-simulator.sh` - Simulator validation
7. `scripts/ios/check-coverage.sh` - Coverage threshold enforcement (50%)
8. `scripts/ios/lint-swift.sh` - Combined SwiftFormat + SwiftLint check

### GitHub Actions
9. `.github/workflows/ios-ci.yml` - Main CI/CD workflow

---

## Why This Approach Works

**Root Cause Resolution**: Fixes the invalid 26.2 deployment target that caused visionOS fallback

**Modern Stack (2026)**:
- macOS 15 runners (latest)
- Xcode 16.0
- Actions cache v4
- GitHub Actions native logging

**Performance Optimized**:
- DerivedData caching (50-70% speedup)
- Parallel quality checks
- Strategic job dependencies

**Reliable Testing**:
- Proper iOS simulator selection
- No visionOS workarounds
- Coverage enforcement
- Artifact retention for debugging

**Maintainable**:
- Shared schemes in version control
- Helper scripts for reusability
- Clear configuration files
- Comprehensive troubleshooting guide

---

## Troubleshooting Guide

### Simulator Not Found
```bash
# Diagnosis
xcrun simctl list devices available | grep iPhone

# Solution: Update destination in workflow
# Change to any available iPhone (15, 15 Pro, etc.)
```

### Scheme Not Found in CI
```bash
# Cause: Scheme not shared
# Solution: Verify ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme exists
```

### Coverage Parsing Fails
```bash
# Cause: Invalid .xcresult path
# Solution: Verify -resultBundlePath is correct in xcodebuild test command
```

### Cache Not Working
```bash
# Solution: Ensure both steps are present:
# 1. git-restore-mtime-action@v2
# 2. defaults write IgnoreFileSystemDeviceInodeChanges
```

---

## Success Criteria

✅ CI workflow runs on iOS simulators (not visionOS)
✅ All quality checks pass (SwiftFormat, SwiftLint, markdownlint)
✅ Unit tests execute successfully
✅ Code coverage meets 50% minimum threshold
✅ Build completes in <5 minutes (cached) or <15 minutes (clean)
✅ Test results and coverage reports uploaded as artifacts
✅ No code signing errors

---

## Future Enhancements (Phase 2)

- **Fastlane**: Unified build/test/deploy automation
- **TestFlight**: Automated beta deployments
- **Codecov/Coveralls**: Historical coverage tracking with badges
- **Matrix Testing**: Multiple iOS versions and device types
- **Performance Testing**: Benchmark regression detection
- **PR Comments**: Automated coverage reports on pull requests

---

## Estimated Timeline

- **Phase 0** (Auto-fix Style): 5-10 minutes
- **Phase 1** (Fix Project): 15-30 minutes
- **Phase 2** (Configs): 15 minutes
- **Phase 3** (Scripts): 30 minutes
- **Phase 4** (Workflow): 30-45 minutes
- **Phase 5** (Testing): 30-60 minutes
- **Total**: ~2-3 hours including validation and iteration

---

## References

Research based on 2026 iOS CI/CD best practices:
- GitHub Actions iOS/Xcode optimization guides
- DerivedData caching strategies
- SwiftLint/SwiftFormat CI integration
- xcodebuild destination specifications
- Code coverage reporting with xccov/xcov
