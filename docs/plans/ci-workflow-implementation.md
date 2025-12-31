# CI Workflow Implementation Plan

## Overview
Implement a comprehensive CI/CD pipeline for the Offload monorepo with strict quality enforcement, supporting both iOS development and future backend implementation.

## User Requirements
- **Scope**: Full stack (iOS + backend prep)
- **Triggers**: Pull requests to main, manual workflow dispatch
- **Quality Gates**: Strict enforcement (fail on linting/formatting/coverage failures)
- **Testing Strategy**: Unit tests only with 50% minimum coverage
- **Enforcement**: Block merges if quality checks fail

## Implementation Steps

### 1. Create GitHub Workflow Directory Structure
**Files to create:**
- `.github/workflows/ci.yml` - Main CI workflow
- `.github/workflows/ios-ci.yml` - iOS-specific workflow (optional, or combine into main)

**Decision**: Use a single unified workflow file (`.github/workflows/ci.yml`) with separate jobs for iOS and backend to simplify management.

### 2. iOS Workflow Job
**Job: `ios-build-and-test`**
- **Runner**: `macos-latest` (required for Xcode)
- **Steps**:
  1. Checkout code
  2. Setup Xcode (select Xcode 15.x)
  3. Cache derived data and SPM packages
  4. Install SwiftLint
  5. Install SwiftFormat
  6. Run SwiftFormat check (fail if formatting needed)
  7. Run SwiftLint (fail on warnings/errors)
  8. Build iOS app with xcodebuild
  9. Run unit tests with coverage enabled (uses Swift Testing framework with @Test attributes)
  10. Generate coverage report
  11. Enforce 50% minimum coverage (fail if below threshold)
  12. Upload test results and coverage artifacts

**xcodebuild commands**:
```bash
# Build
xcodebuild -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Test with coverage (Swift Testing framework)
xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -enableCodeCoverage YES -resultBundlePath TestResults.xcresult

# Extract coverage
xcrun xccov view --report TestResults.xcresult > coverage.txt
```

**Note**: Tests use Swift Testing framework (@Test attributes, #expect assertions), not XCTest.

### 3. Backend Workflow Job (Prep)
**Job: `backend-check`**
- **Runner**: `ubuntu-latest`
- **Conditional**: Skip if no Python files in backend/ (use path filters)
- **Steps**:
  1. Checkout code
  2. Setup Python 3.11+
  3. Install uv (package manager)
  4. Cache uv dependencies
  5. Install dependencies (when they exist)
  6. Run ruff format check
  7. Run ruff linting
  8. Run pytest with coverage
  9. Enforce 50% minimum coverage

**Note**: Most steps will be no-ops initially since backend is scaffolding only.

### 4. Documentation Workflow Job
**Job: `docs-lint`**
- **Runner**: `ubuntu-latest`
- **Steps**:
  1. Checkout code
  2. Setup Node.js
  3. Install markdownlint-cli
  4. Run markdownlint on all .md files
  5. Fail on any linting errors

**markdownlint command**:
```bash
npx markdownlint-cli '**/*.md' --ignore node_modules
```

### 5. Configuration Files

#### `.github/workflows/ci.yml`
- Define workflow triggers: `pull_request` (target: main), `workflow_dispatch`
- Set up matrix strategy for iOS (multiple simulators if desired)
- Configure proper caching strategies
- Set job dependencies (docs-lint can run parallel, but coverage must complete)
- Add status check requirements

#### `.swiftlint.yml` (create in `ios/` directory)
- Configure SwiftLint rules matching project style
- Enable/disable specific rules based on AGENTS.md preferences
- Set line length, file length limits
- Exclude generated code, build artifacts

#### `.swiftformat` (create in `ios/` directory)
- Configure SwiftFormat rules
- Set indentation (4 spaces per CLAUDE.md)
- Set quote style (single quotes per CLAUDE.md)
- Match existing code style

#### `.markdownlint.json` (create in root)
- Configure markdown linting rules
- Allow GitHub Flavored Markdown features
- Set line length limits for readability

#### `backend/pyproject.toml` (update or create)
- Configure ruff linting and formatting
- Set pytest configuration
- Configure coverage thresholds (50%)
- Define development dependencies

### 6. Coverage Enforcement Strategy

**iOS Coverage**:
- Use xcodebuild's built-in coverage (`-enableCodeCoverage YES`)
- Parse `.xcresult` bundle with `xcrun xccov`
- Extract total coverage percentage
- Compare against 50% threshold
- Fail workflow if below threshold

**Backend Coverage** (when implemented):
- Use pytest-cov plugin
- Configure in `pyproject.toml`: `--cov-fail-under=50`
- Generate HTML and XML reports
- Upload coverage artifacts

**Script approach**: Create `scripts/ios/check_coverage.sh` to parse coverage and enforce threshold.

### 7. Caching Strategy

**iOS**:
- Cache path: `~/Library/Developer/Xcode/DerivedData`
- Cache key: Based on `ios/Offload.xcodeproj/project.pbxproj` hash
- SPM cache: `~/.swiftpm` if using packages

**Backend**:
- Cache uv directory: `~/.cache/uv`
- Cache key: Based on `backend/pyproject.toml` and `uv.lock` (when created)

**Node.js** (for markdownlint):
- Cache npm: `~/.npm`
- Cache key: Based on package.json hash (if created) or static

### 8. Artifact Retention

**Artifacts to upload**:
- iOS test results (`.xcresult` bundle) - 7 days retention
- iOS coverage reports (HTML, text) - 30 days retention
- Backend test results (when applicable) - 7 days retention
- Backend coverage reports - 30 days retention
- Lint reports (if failures occur) - 7 days retention

### 9. Status Checks and Branch Protection

**After implementation**:
1. Configure branch protection on `main` branch
2. Require status checks to pass:
   - `ios-build-and-test`
   - `docs-lint`
   - `backend-check` (when applicable)
3. Require PR reviews: 1 approval (optional, user decision)
4. No force pushes to main
5. No deletions of main

## Files to Create/Modify

### New Files
1. `.github/workflows/ci.yml` - Main CI workflow
2. `ios/.swiftlint.yml` - SwiftLint configuration
3. `ios/.swiftformat` - SwiftFormat configuration
4. `.markdownlint.json` - Markdown linting rules
5. `scripts/ios/check_coverage.sh` - Coverage threshold enforcement script
6. `backend/pyproject.toml` - Python project configuration (if doesn't exist)

### Files to Modify
- None (all new infrastructure)

## Workflow Execution Flow

```
PR opened/updated → Trigger CI workflow
                    ↓
         ┌──────────┴──────────┐
         ↓                     ↓
    docs-lint            ios-build-and-test
         ↓                     ↓
    markdownlint          1. SwiftFormat check
         ↓                2. SwiftLint
    Pass/Fail            3. Build
         ↓                4. Unit tests
         └──────────→     5. Coverage check
                          6. Enforce 50% threshold
                          ↓
                     Pass/Fail
                          ↓
                 Merge allowed (if all pass)
```

## Testing the Workflow

1. Push to `feature/ci-workflows` branch
2. Open PR to `main` to trigger workflow
3. Verify all jobs run and report status
4. Test failure scenarios:
   - Intentionally break SwiftFormat
   - Add SwiftLint violation
   - Lower test coverage
   - Add markdown linting error
5. Verify workflow fails appropriately
6. Fix issues and verify workflow passes

## Future Extensibility

**When backend implementation begins**:
1. Update `backend-check` job path filters
2. Add Python dependencies to `pyproject.toml`
3. Enable pytest and coverage steps
4. Backend job will automatically activate

**Potential enhancements**:
1. Add UI test job (separate from unit tests)
2. Add nightly builds for regression testing
3. Add dependency vulnerability scanning
4. Add build time tracking
5. Add test flakiness detection
6. Add iOS app archiving/distribution

## Rollout Plan

1. **Phase 1**: Create workflow files and configurations on `feature/ci-workflows` branch
2. **Phase 2**: Test workflow execution via PR
3. **Phase 3**: Iterate on any failures or issues
4. **Phase 4**: Merge to `main` once stable
5. **Phase 5**: Enable branch protection rules

## Risk Mitigation

- **Risk**: macOS runners are expensive (10x Linux runners)
  - **Mitigation**: Use path filters to only run iOS job when iOS files change

- **Risk**: Xcode version mismatches
  - **Mitigation**: Pin to specific Xcode version (15.x) using `xcode-select`

- **Risk**: Flaky tests in CI
  - **Mitigation**: Only run unit tests initially; add UI tests later after stabilization

- **Risk**: Coverage threshold too strict
  - **Mitigation**: Start at 50% as requested, can adjust if needed

## Success Criteria

✅ CI workflow runs on every PR to main
✅ Manual workflow dispatch works
✅ SwiftFormat enforces code formatting
✅ SwiftLint enforces code quality
✅ iOS builds successfully on CI
✅ Unit tests run with coverage reporting
✅ Coverage enforcement blocks merges below 50%
✅ Markdown files are linted
✅ Backend pipeline structure ready for future use
✅ Workflow completes in reasonable time (<10 minutes for iOS)
✅ Clear failure messages when quality gates fail
