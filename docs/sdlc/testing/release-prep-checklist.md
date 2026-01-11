<!--
Intent: Release preparation checklist aligned to Week 7-8 scope, including QA
gates, documentation updates, and release candidate steps.
-->

# Release Prep Checklist

## Agent Navigation

- Overview: Scope + Gates
- QA: Release Gates
- Docs: Documentation Updates
- RC: Release Candidate Steps
- App Store: Materials List

## Scope

This checklist aligns to the Week 7-8 release prep tasks in
`docs/sdlc/plans/master-plan.md`. Complete items in order; do not ship without
all Release Gates passing.

## Release Gates

- [ ] Critical remediation tests complete (Phase 1-3 verification)
- [ ] Accessibility visual QA complete (contrast + Dynamic Type + VoiceOver)
- [ ] Performance benchmarks complete (100/1K/10K records)
- [ ] Integration tests complete (end-to-end flows)
- [ ] No known P0/P1 bugs

## Documentation Updates

- [ ] Update `docs/sdlc/plans/master-plan.md` with final status
- [ ] Update `docs/sdlc/testing/testing-checklist.md` with QA results
- [ ] Update `docs/sdlc/prd/v1.md` if scope changes
- [ ] Update `docs/sdlc/decisions/ADR-0001-stack.md` if stack changes

## Release Candidate Steps

- [ ] Build release candidate in Xcode (Release config)
- [ ] Run full regression pass on RC build
- [ ] Archive and export for TestFlight
- [ ] Upload to TestFlight
- [ ] Distribute to internal testers
- [ ] Collect sign-off from QA + Product

## App Store Materials

- [ ] App description (short + long)
- [ ] Screenshots (iPhone + iPad)
- [ ] Keywords list
- [ ] Support URL
- [ ] Privacy policy URL
