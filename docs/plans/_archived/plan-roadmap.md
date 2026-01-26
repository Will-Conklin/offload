---
id: plan-roadmap
type: plan
status: archived
owners:
  - Will-Conklin
applies_to:
  - launch-release
last_updated: 2026-01-25
related:
  - plan-testing-polish
  - plan-release-prep
  - plan-tag-relationship-refactor
  - plan-view-decomposition
  - plan-visual-timeline
  - plan-celebration-animations
  - plan-advanced-accessibility
  - plan-ai-organization-flows
  - plan-ai-pricing-limits
  - plan-backend-api-privacy
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Archived launch roadmap snapshot"
  - "Supersedes plan-archived-master-plan.md"
priority: critical
---

# Offload Roadmap

## Executive Summary

This document was the **single source of truth** for launch planning. It is
now archived; execution planning is tracked in the standalone plan documents.
It supersedes the original master plan (now archived) which became out of date
after the January 13, 2026 UI overhaul.

**Last verified:** January 20, 2026

## Current Implementation Status

### ✅ COMPLETED

#### UI/UX Foundation

- Flat design system implemented (Elijah theme - lavender/cream palette)
- Bold borders instead of shadows
- Simplified spacing tokens (4, 8, 16, 24, 32, 48)
- Floating tab bar with center capture button
- Swipe actions for captures
- Inline tagging

#### Data Model Consolidation

- 4 core models: Item, Collection, CollectionItem, Tag
- Items with `type=nil` serve as captures
- Collections with `isStructured` distinguish plans vs lists
- Star system replaces priority system
- `completedAt` timestamp for lifecycle tracking

#### Repository Pattern (Jan 19, 2026)

- ✅ RepositoryEnvironment.swift with environment keys for all 4 repositories
- ✅ RepositoryBundle factory pattern for dependency injection
- ✅ AppRootView injects repositories into environment
- ✅ All views use `@Environment(\.itemRepository)` instead of modelContext
- ✅ Preview helpers for SwiftUI previews
- ✅ Comprehensive ItemRepositoryTests (45 tests)

#### Core Capture & Organize Behaviors

- Pagination implemented for Capture/Organize/Collection Detail lists
- Voice recording with on-device transcription and permission handling
- Capture list actions (complete, star, delete)
- Offline capture and persistence via local SwiftData store

### ⏳ IN PROGRESS

#### Error Handling (4 instances remaining)

Only 4 `try?` instances remain (down from 21):

- CollectionItem.swift:49 - children fetch fallback
- Item.swift:72,80 - JSON serialization for metadata
- TagRepository.swift:108 - items fetch fallback

**Assessment:** These are intentional fallbacks, not suppressions. The error
handling work is effectively complete.

## Architecture Patterns (Current State)

- ✅ Repository environment injection: IMPLEMENTED
- ✅ ErrorPresenter: Available (minimal remaining try?)
- ✅ ViewModels: Implemented for pagination in Capture/Organize flows
- ✅ SwiftData @Query: Used throughout for reactive data
- ✅ Repository mutations: All data changes go through repositories

## Remaining Work for Launch

### Active execution plans

- [Plan: Testing & Polish](../plan-testing-polish.md)
- [Plan: Release Prep](../plan-release-prep.md)

### Proposed scope (requires PRD/ADR confirmation)

- [Plan: Tag Relationship Refactor](../plan-tag-relationship-refactor.md)
- [Plan: View Decomposition](../plan-view-decomposition.md)
- [Plan: Visual Timeline](../plan-visual-timeline.md)
- [Plan: Celebration Animations](../plan-celebration-animations.md)
- [Plan: Advanced Accessibility Features](../plan-advanced-accessibility.md)
- [Plan: AI Organization Flows & Review Screen](../plan-ai-organization-flows.md)
- [Plan: AI Pricing & Limits](../plan-ai-pricing-limits.md)
- [Plan: Backend API + Privacy Constraints](../plan-backend-api-privacy.md)

## File Sizes Reference

- CollectionDetailView.swift: 778 lines (candidate for future decomposition)
- CaptureView.swift: ~450 lines
- CaptureComposeView.swift: 393 lines
- OrganizeView.swift: 328 lines
- SettingsView.swift: 208 lines

## Historical Context

### January 13, 2026 - UI Overhaul (PR #84)

- Implemented flat design with Elijah theme
- Removed CaptureEntry, consolidated data model
- Added floating tab bar with center capture button
- ~3000+ lines changed across 50+ files

### January 19, 2026 - Repository Pattern Complete

- Implemented RepositoryEnvironment.swift
- Updated all views to use repository injection
- Removed direct modelContext usage from views
- Fixed Swift concurrency errors

## Decision Log

| Decision     | Choice                                    | Date   |
| ------------ | ----------------------------------------- | ------ |
| UI Direction | Flat design (not glassmorphism)           | Jan 13 |
| Theme        | Single "Elijah" theme                     | Jan 13 |
| Launch scope | Manual app only (no AI)                   | Jan 19 |
| Pagination   | Defer to later release                    | Jan 19 |
| ViewModels   | Not needed for launch (@Query sufficient) | Jan 19 |

## User Verification

- [ ] User verification complete.
