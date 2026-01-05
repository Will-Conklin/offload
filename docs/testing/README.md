<!-- Intent: Document testing status, coverage tracking, and how to run/extend tests. -->

# Testing and Coverage

Coverage reporting is not yet tracked in CI. Once coverage collection is enabled, this document will outline how to generate reports locally and where to find CI artifacts.

## Current Status

- Automated tests run through the iOS workflows (`ios-build.yml` and `ios-tests.yml`).
- Coverage tooling has not been wired up; tracking is planned.

## Next Steps for Coverage

1. Decide on a coverage tool (e.g., `xccov` via `xcodebuild` or a third-party reporter).
2. Update CI workflows to export coverage artifacts.
3. Publish a coverage badge pointing to generated reports.
