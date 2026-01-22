---
id: plan-context-aware-ci-pipeline
type: plan
status: draft
owners:
  - Offload
applies_to:
  - Offload
last_updated: 2026-01-19
related:
  - plan-v1-roadmap
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; Progress."
---

# Plan: Context-Aware CI Pipeline (Proposed)

## Overview

Define a context-aware CI pipeline that runs the minimum required checks based on
changed files, with a docs-only path that performs fast, documentation-focused
validation. This plan focuses on sequencing and execution details for a CI
upgrade that is aligned to the Offload iOS app’s architecture and repo layout.

## Goals

- Introduce a docs-only check path that runs when changes are limited to
  documentation and related metadata.
- Separate iOS, backend, and script checks by path to keep feedback fast and
  targeted.
- Establish a discovery phase to evaluate CI tooling options and match them to
  the current repository structure and team workflows.
- Add guardrails for Swift, SwiftUI, and SwiftData changes (formatting, linting,
  and test lanes) while keeping local developer workflows lightweight.

## Phases

### Phase 1: Discovery & Recommendations

**Status:** Not Started

- [ ] Review existing CI configuration (if any) and catalog current checks and
      pain points.
- [ ] Evaluate CI tooling options for context-aware workflows (GitHub Actions
      path filters, reusable workflows, and concurrency controls).
- [ ] Identify recommended checks by area:
      - Docs: markdownlint, link checking, spell check (optional).
      - iOS: build + unit tests, SwiftFormat/SwiftLint, SwiftData migrations.
      - Backend: language-specific linting/tests if applicable.
      - Scripts: shellcheck or linting for automation scripts.
- [ ] Summarize recommended workflows, with triggers and minimum checks per
      change type.

### Phase 2: Docs-Only Workflow

**Status:** Not Started

- [ ] Implement a docs-only workflow that triggers when changes are limited to
      `docs/**`, `README.md`, or other documentation-only files.
- [ ] Run markdownlint and any doc-specific checks in this lane.
- [ ] Skip iOS builds/tests when docs-only changes are detected.

### Phase 3: Context-Aware Core Workflows

**Status:** Not Started

- [ ] Implement path-based workflows for iOS (`ios/**`), backend (`backend/**`),
      and shared automation (`scripts/**`).
- [ ] Add concurrency and caching strategies to keep CI responsive.
- [ ] Document workflow triggers and ownership for ongoing maintenance.

### Phase 4: Verification & Rollout

**Status:** Not Started

- [ ] Validate that each workflow runs the intended checks for representative
      PRs.
- [ ] Capture runtime baselines and adjust as needed.
- [ ] Announce changes and update contributor guidance.

## Dependencies

- CI provider decision and access (GitHub Actions or equivalent).
- Agreement on the minimal doc-only check set.
- Availability of lint/test tooling for Swift and backend languages.

## Risks

| Risk                                      | Impact | Mitigation                                    |
| ----------------------------------------- | ------ | --------------------------------------------- |
| Path filters miss a critical file change  | M      | Add a manual override and scheduled full run. |
| CI complexity increases maintenance       | M      | Use reusable workflows and clear ownership.   |
| Docs-only detection is too strict/lenient | L      | Review file patterns with the team.           |

## Progress

| Date       | Update                                 |
| ---------- | -------------------------------------- |
| 2026-01-19 | Draft plan created for review.          |
