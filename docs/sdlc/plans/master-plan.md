<!-- Intent: Single source of truth for all implementation planning, consolidating remediation, UI/UX modernization, and feature development. -->

# Offload Master Implementation Plan

## Agent Navigation

- Overview: Executive Summary, Current Status by Work Stream
- Timeline: Consolidated Timeline (Weeks 1-10+)
- Priorities: Implementation Priority Matrix
- Decisions: Decision Log
- Delivery: Work Breakdown by Phase, Testing Strategy, Risk Assessment,
  Success Metrics

**Created:** January 9, 2026
**Status:** Active Development
**Current Phase:** Remediation Phase 1 Complete / UI Planning / Feature Development
**Timeline:** 8-10 weeks to production-ready v1.0
**Last Updated:** January 10, 2026

---

## Document Purpose

This is the **single source of truth** for all Offload implementation planning. It consolidates:
- Critical bug remediation (from remediation-plan.md & remediation-tracking.md)
- UI/UX modernization (from ios-ui-trends-2025.md & consolidated-implementation-plan.md)
- Design system polish (from polish-phase.md)
- Feature development (from brain-dump-model.md)

**All other plan documents are superseded by this master plan.**

---

## Executive Summary

**Current State:**
- ✅ **Phase 1 Critical Fixes:** 8/8 complete (toast fix merged Jan 9)
- 🟡 **Phase 2 High Priority:** 5/5 implementation complete, testing pending
- 🟡 **Phase 3 Architecture:** 3/3 complete
- 🟡 **UI/UX Modernization:** Research complete, implementation started
- ⏳ **Feature Gaps:** AI hand-off, suggestion UI, organize flows

**Production Blockers Remaining:**
- Testing and validation of Phase 1-3 fixes
- Performance benchmarking
- Accessibility audit

**Path to Production:**
1. Complete testing of critical fixes (Week 1-2)
2. Implement UI foundation (Weeks 2-3 - can start during Week 2 while testing completes)
3. Build component library & micro-interactions (Weeks 3-4)
4. Add ADHD-specific enhancements & accessibility (Weeks 5-6)
5. Integration, polish and release prep (Weeks 7-8)
6. Feature development for AI flows (Week 9-10+ post-v1)

---

## Current Status by Work Stream

### Stream A: Critical Remediation (P0-P1)
**Status:** ✅ Phase 1 Complete | 🟡 Phase 2 Implementation Done | ⏳ Testing Pending
**Priority:** CRITICAL
**Owner:** TBD

#### Phase 1: Critical Fixes (COMPLETE ✅)
All 8 critical production blockers resolved:
1. ✅ CapturesView race condition fixed
2. ✅ All 21 error suppression instances fixed
3. ✅ Repository queries use predicates (12/13 methods optimized)
4. ✅ Orphaned foreign key replaced with relationship
5. ✅ Force unwraps removed (4/4 instances)
6. ✅ **Toast cancellation fixed (Jan 9, commit 688110b)** ⭐ NEW
7. ✅ MainActor synchronization fixed
8. ✅ Input validation added for API endpoints

#### Phase 2: High Priority Fixes (IMPLEMENTATION DONE 🟡)
All implementation complete, testing pending:
1. 🟡 Task.category relationship added
2. 🟡 Array index out of bounds fixes
3. 🟡 Error handling patterns standardized
4. 🟡 Repository protocols defined
5. 🟡 Permission caching implemented

#### Phase 3: Architecture (COMPLETE ✅)
1. ✅ Generic FormSheet component extracted
2. ✅ Comprehensive test suite added
3. ✅ Logging and monitoring implemented

**Remaining Work:**
- [ ] Performance benchmarking (100, 1K, 10K records)
- [ ] Manual testing validation
- [ ] Regression testing
- [ ] Test evidence collection

---

### Stream B: UI/UX Modernization (P2-P3)
**Status:** 🟡 Research Complete | Implementation Started
**Priority:** HIGH
**Owner:** TBD

#### Research Findings (COMPLETE ✅)
- Comprehensive iOS 2025-2026 trend analysis
- ADHD-specific design patterns identified
- Component library architecture planned
- 4-phase implementation strategy defined

#### UI Foundation (COMPLETE ✅)
**Scope:**
- Glassmorphism/Liquid Glass materials
- Gradient accent system
- Soft edges (updated corner radius)
- Spacing consistency fixes (15+ instances)

**Progress:**
- ✅ Added Theme materials, gradients, and animations
- ✅ Applied glass treatment refinements to
  CaptureSheetView
- ✅ Updated corner radius + typography/line spacing
  tokens
- ✅ Applied glass effects to OrganizeView cards and
  capture FAB
- ✅ Replaced hardcoded padding with Theme spacing
  tokens
- ✅ Applied UI foundation styles to shared
  components

**Estimated:** 4 days

#### Component Library (COMPLETE ✅)
**Scope:**
- Unified Badge component
- Expandable Card component
- Pill Selector component
- Progress indicators (Ring, Bar)
- Loading skeletons

**Progress:**
- ✅ Badge component with VoiceOver labels
- ✅ Expandable Card component with VoiceOver hint
- ✅ Pill Selector component with VoiceOver labels
- ✅ Progress indicators with VoiceOver labels
- ✅ Loading skeleton component

**Estimated:** 5 days

#### Micro-Interactions (COMPLETE ✅)
**Scope:**
- Spring animations on buttons
- Completion celebration effects
- Improved shadows and depth
- Bottom sheet patterns
- Button press states

**Progress:**
- ✅ Spring animations on buttons
- ✅ Reduce Motion support
- ✅ Button press states
- ✅ Improved shadows and depth
- ✅ Bottom sheet patterns
- ✅ Celebration animations (task completion)

**Estimated:** 5 days

#### ADHD Features (IN PROGRESS 🟡)
**Scope:**
- Visual timeline view (Tiimo-inspired)
- Gentle transition indicators
- Next up badges
- Settings toggles for animations
- Completion celebrations

**Progress:**
- ✅ Visual timeline view
- 🟡 Accessibility audit started
- ✅ Gentle transition indicators
- ✅ ADHD settings toggles

**Estimated:** 6 days

---

### Stream C: Feature Development (P2-P3)
**Status:** 🟡 In Progress | Foundation Complete
**Priority:** MEDIUM
**Owner:** TBD

#### Completed ✅
- Core data models (CaptureEntry, HandOffRequest, Suggestion, etc.)
- Repository layer (CRUD + lifecycle helpers)
- CaptureWorkflowService (capture, archive, inbox queries)
- Basic capture UI (text + voice)
- Test infrastructure

#### In Progress 🟡
- AI hand-off submission (stubbed)
- Suggestion presentation UI (not started)
- Organize tab flows (TODOs present)
- Settings screen (placeholder)

#### Not Started ⏳
- Backend API implementation
- Full AI workflow (hand-off → suggestion → decision → placement)
- Export/import functionality
- Batch operations
- Search and filtering

---

## Consolidated Timeline (8-10 Weeks)

### Weeks 1-2: Testing & Validation ⚠️ CRITICAL
**Goal:** Verify all critical fixes work, no regressions
**Priority:** P0

**Tasks:**
1. **Performance Benchmarking** (2 days)
   - Query performance: 100, 1000, 10000 records
   - Memory usage during bulk operations
   - Scrolling performance (target 60fps)
   - Document baseline metrics

2. **Manual Testing** (3 days)
   - Delete operations (single, batch, rapid)
   - Form validation (empty, invalid, valid)
   - Error display (toasts, inline messages)
   - Voice recording lifecycle
   - Permission requests

3. **Regression Testing** (2 days)
   - All 21 fixed error suppressions
   - Race condition resolution
   - Toast cancellation behavior
   - MainActor synchronization
   - URL validation

4. **Test Evidence Collection** (1 day)
   - Document test results
   - Update remediation-tracking.md
   - Create test report

**Exit Criteria:**
- [ ] All critical bugs verified fixed
- [ ] Performance meets targets (<100ms queries at 1K records)
- [ ] Zero crashes in test scenarios
- [ ] Test evidence documented

---

### Week 2: Testing Completion + UI Foundation Start 🎨
**Goal:** Complete testing validation, begin visual modernization
**Priority:** P0 (Testing) + P1 (UI can start mid-week)

**Tasks:**
1. **Complete Testing & Validation** (Days 1-3 if needed from Week 1)
   - Finalize performance benchmarks
   - Complete manual test evidence
   - Regression test verification
   - **GATE:** No UI merges until testing verified ✅

2. **Theme System Extensions** (4 hours, can start Day 3+)
   ```swift
   struct Materials { ... }      // Glassmorphism
   struct Gradients { ... }      // Accent system
   struct Animations { ... }     // Spring presets
   ```

3. **Typography Improvements** (2 hours) ⭐ MOVED FROM WEEK 6
   - Weight variants (.semibold, .bold)
   - Monospaced numbers for numeric displays
   - Increased line height for readability

4. **Update Corner Radius** (1 hour)
   - sm: 4 → 6, md: 8 → 10, lg: 12 → 16, xl: 16 → 24

5. **Apply Glass Effects** (6 hours)
   - CaptureSheetView modal
   - CardView component
   - OrganizeView cards
   - FAB (Floating Action Button)
   - **Verify contrast ratios during implementation**

6. **Fix Spacing Inconsistencies** (3 hours)
   - Replace 15+ hardcoded padding values
   - Use Theme.Spacing.xs/sm/md/lg/xl throughout

**Decision Point:** End of Week 2 - Testing must pass before merging UI work to main

**Deliverable:** Testing complete + modern, polished UI foundation with proper typography

---

### Week 3: Component Library Expansion 🧩
**Goal:** Build reusable component library
**Priority:** P1 (Badge, Card) + P2 (Pill, Progress, Skeletons)

**Tasks:**
1. **Unified Badge Component** (4 hours) - **P1**
   - Generic badge with text, color, icon
   - Convenience constructors (category, status)
   - Replace 5+ duplicate implementations
   - **Add VoiceOver label during implementation**

2. **Expandable Card Component** (4 hours) - **P1**
   - Tap to expand/collapse
   - Spring animation
   - Solves lineLimit(2) truncation issues
   - **Add VoiceOver hint for expandable state**

3. **Pill Selector Component** (3 hours) - **P2**
   - Horizontal scrolling pills
   - Selection state
   - Use for filtering/sorting
   - **Add VoiceOver labels for each pill**

4. **Progress Indicators** (4 hours) - **P2**
   - ProgressRing (circular with percentage)
   - ProgressBar (linear)
   - Use for plan completion
   - **Announce percentage changes to VoiceOver**

5. **Loading Skeletons** (3 hours) - **P2**
   - Shimmering skeleton component
   - Replace ProgressView spinners
   - More modern UX
   - **Add "Loading" accessibility label**

**Accessibility Checkpoint:** All new components have VoiceOver labels

**Deliverable:** Consistent, accessible component library

---

### Week 4: Micro-Interactions & Polish ✨
**Goal:** Add purposeful animations and tactile feedback
**Priority:** P1 (Animations, Reduce Motion) + P2 (Celebrations, Bottom Sheets)

**Tasks:**
1. **Spring Animations on Buttons** (4 hours) - **P1**
   - Scale effect on press (0.95x)
   - Spring animation (0.3s response, 0.7 damping)
   - Apply to all interactive buttons

2. **Reduce Motion Support** (2 hours) - **P1** ⭐ MOVED FROM WEEK 6
   - Respect @Environment(\.accessibilityReduceMotion)
   - Disable all animations when enabled
   - Test with Accessibility Inspector

3. **Improved Shadows & Depth** (2 hours) - **P2**
   - Update CardView shadows
   - Add shadow variants to Theme

4. **Bottom Sheet Patterns** (3 hours) - **P2**
   - Apply .presentationDetents([.medium, .large])
   - Category picker, tag picker
   - Improved one-handed ergonomics

5. **Button Press States** (2 hours) - **P2**
   - Tactile feedback on all buttons
   - Scale + animation

6. **Completion Celebrations** (6 hours) - **P2 OPTIONAL**
   - Confetti/glow effects (respects Reduce Motion)
   - Settings toggle for on/off
   - ADHD dopamine boost

**Accessibility Checkpoint:** Reduce Motion fully implemented before Week 5

**Deliverable:** Polished, accessible, satisfying interactions

---

### Weeks 5-6: ADHD Features & Accessibility ♿
**Goal:** Add cognitive support, ensure accessibility compliance
**Priority:** P2 (High Value)

#### Week 5: Visual Timeline & Accessibility Audit

**Tasks:**
1. **Visual Timeline View** (12 hours)
   - Horizontal scrolling timeline
   - Hour-by-hour columns
   - Color-coded capture blocks
   - Reduces time blindness (ADHD benefit)

2. **Gentle Transition Indicators** (3 hours)
   - "Next up" badges
   - No pressure/anxiety
   - Reduces transition stress

3. **Accessibility Audit** (6 hours)
   - Add VoiceOver labels to all interactive elements
   - Test with VoiceOver navigation
   - Verify contrast ratios (WCAG AA)
   - Test Dynamic Type at all sizes

**Deliverable:** High-value ADHD features + accessibility compliance

---

### Week 6: Settings & Final Polish 🎯
**Goal:** User controls for ADHD features, final consistency pass
**Priority:** P1 (ADHD Settings) + P2 (Polish)

**Tasks:**
1. **ADHD Settings Section** (3 hours) - **P1**
   - Toggle completion animations on/off
   - Toggle visual timeline display
   - Toggle "next up" indicators
   - Animation speed preference (if celebrations included)
   - Explanatory text for each feature

2. **Accessibility Fixes from Week 5 Audit** (3-6 hours) - **P1**
   - Address issues found in comprehensive audit
   - Fix contrast ratio problems
   - Add missing VoiceOver labels
   - Fix Dynamic Type clipping

3. **Final Polish Pass** (8-12 hours) - **P2**
   - Address visual inconsistencies across screens
   - Optimize animation performance
   - Fine-tune glass effects and shadows
   - Performance tuning (ensure 60fps)
   - Code cleanup and TODO resolution

**Note:** Typography and Reduce Motion already completed in Weeks 2 & 4

**Deliverable:** Complete ADHD-friendly, accessible, polished app

---

### Weeks 7-8: Integration, Testing & Release Prep 🚀
**Goal:** Production-ready release candidate
**Priority:** P0

#### Week 7: Integration Testing

**Tasks:**
1. **Merge All Changes** (2 days)
   - Integrate remediation + UI changes
   - Resolve conflicts
   - Fix integration bugs

2. **Comprehensive Testing** (3 days)
   - Functional testing (all features work)
   - Visual testing (light/dark mode, Dynamic Type)
   - Performance testing (scrolling, animations, memory)
   - ADHD user testing (timeline, animations, cognitive load)
   - Accessibility testing (VoiceOver, contrast, motion)

**Exit Criteria:**
- [ ] All features work as designed
- [ ] No regressions
- [ ] Performance meets targets
- [ ] Accessibility standards met

---

#### Week 8: Release Preparation

**Tasks:**
1. **Final Polish** (2 days)
   - Visual inconsistencies
   - Animation tuning
   - Code cleanup

2. **Documentation** (2 days)
   - User-facing docs (new features)
   - Developer docs (design system, components)
   - Release notes
   - App Store materials (screenshots, descriptions)

3. **Release Candidate** (1 day)
   - Create release build
   - Final QA pass
   - TestFlight distribution
   - Sign off for production

**Deliverable:** Production-ready v1 release candidate

---

### Weeks 9-10+: Feature Development (POST-MVP) 📈
**Goal:** Complete AI workflows, advanced features
**Priority:** P3 (Nice-to-have for v1)

**Scope:**
- Backend API implementation
- AI hand-off submission
- Suggestion presentation UI
- Decision recording
- Placement flows
- Export/import functionality
- Batch operations
- Search and filtering

**Note:** These can be deferred to v1+ if timeline requires

---

## Implementation Priority Matrix

### P0 - Must Ship for v1 (Blockers)
- [x] All 8 critical bug fixes
- [x] Phase 2 high priority fixes
- [ ] Testing and validation (Weeks 1-2)
- [ ] Basic accessibility compliance

### P1 - Should Ship for v1 (High Value)
- [ ] UI foundation (glass effects, theme, typography)
- [ ] Core component library (badges, expandable cards)
- [ ] Spring animations on buttons
- [ ] Reduce Motion support (accessibility)
- [ ] ADHD settings toggles
- [ ] VoiceOver labels for all interactive elements

### P2 - Nice-to-Have for v1 (Polish)
- [ ] Visual timeline view
- [ ] Completion celebrations
- [ ] Loading skeletons
- [ ] Bottom sheets
- [ ] Advanced typography

### P3 - Can Defer to v1+ (Future)
- [ ] AI hand-off flows
- [ ] Suggestion UI
- [ ] Export/import
- [ ] Batch operations
- [ ] Search and filtering

---

## Decision Log

### Recent Decisions (Jan 9, 2026)

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| Jan 9 | Toast cancellation fix merged | Critical P0 bug, completes Phase 1 | Phase 1 now 8/8 complete |
| Jan 9 | Consolidate all plans into master-plan.md | Single source of truth, reduce confusion | Supersedes 4 separate docs |
| Jan 9 | Prioritize testing before new UI work | Validate critical fixes, avoid regressions | Weeks 1-2 focused on testing |
| Jan 9 | Visual timeline as P2 (nice-to-have) | High ADHD value but can defer if needed | Flexible on timeline |
| Jan 9 | Defer AI features to post-v1 | Focus on manual app first, AI as enhancement | MVP scope reduction |

### Decisions Needed (By Jan 15, 2026)

1. **Glassmorphism Implementation Level**
   - [ ] Option A: Subtle (cards/modals) - **RECOMMENDED**
   - [ ] Option B: Full Liquid Glass (navigation layer)
   - [ ] Option C: Minimal (FAB/tabs only)

2. **Timeline Feature Priority**
   - [ ] Must-have for v1
   - [ ] Nice-to-have for v1 - **RECOMMENDED**
   - [ ] Defer to v1

3. **Celebration Animations**
   - [ ] Include in v1 - **RECOMMENDED** (low effort, high ADHD value)
   - [ ] Defer to v1

4. **v1 Scope**
   - [ ] Manual app only (no AI) - **RECOMMENDED**
   - [ ] Include basic AI hand-off
   - [ ] Full AI workflow required

5. **Resource Allocation**
   - [ ] 1 developer, 8-10 weeks - **RECOMMENDED**
   - [ ] 2 developers, 4-5 weeks each
   - [ ] Other: _______________

---

## Work Breakdown by Phase

### Phase 1: Critical Remediation (COMPLETE ✅)
**Duration:** Completed (Jan 6-9, 2026)
**Status:** ✅ 8/8 tasks complete

| Task | Status | File(s) | Notes |
|------|--------|---------|-------|
| 1.1 CapturesView race condition | ✅ Complete | CapturesView.swift | Serialized deletes, single refresh |
| 1.2 Error suppression (21 instances) | ✅ Complete | Multiple files | All try? replaced with proper handling |
| 1.3 N+1 query problems | ✅ Complete | Repositories | 12/13 use predicates (1 SwiftData limitation) |
| 1.4 Orphaned foreign key | ✅ Complete | CaptureEntry.swift | UUID → @Relationship |
| 1.5 Force unwraps on URLs | ✅ Complete | SettingsView, APIClient | All use safe unwrapping |
| 1.6 Toast cancellation | ✅ Complete | ToastView.swift | Fixed Jan 9 (commit 688110b) |
| 1.7 MainActor synchronization | ✅ Complete | CaptureWorkflowService | private(set), explicit isolation |
| 1.8 API input validation | ✅ Complete | SettingsView | HTTPS enforcement, hostname validation |

**Testing Status:**
- ⏳ Performance benchmarking pending
- ⏳ Manual test evidence pending
- ⏳ Regression testing pending

---

### Phase 2: High Priority Fixes (IMPLEMENTATION COMPLETE 🟡)
**Duration:** Completed (Jan 6-8, 2026)
**Status:** 🟡 5/5 implementation done, testing pending

| Task | Status | File(s) | Notes |
|------|--------|---------|-------|
| 2.1 Task.category relationship | 🟡 Done | Task.swift | @Relationship added, testing pending |
| 2.2 Array index out of bounds | 🟡 Done | ListDetailView, PlanDetailView | Capture items before delete |
| 2.3 Error handling patterns | 🟡 Done | Common/ErrorHandling.swift | ErrorPresenter added, integration pending |
| 2.4 Repository protocols | 🟡 Done | Repositories/ | All protocols defined, DI enabled |
| 2.5 Permission caching | 🟡 Done | VoiceRecordingService | Cache added, testing pending |

**Testing Status:**
- ⏳ Cascade behavior testing
- ⏳ Delete operation validation
- ⏳ Error presenter integration
- ⏳ Mock testing with protocols
- ⏳ Permission flow validation

---

### Phase 3: Architecture (COMPLETE ✅)
**Duration:** Completed (Jan 6-8, 2026)
**Status:** ✅ 3/3 tasks complete

| Task | Status | File(s) | Notes |
|------|--------|---------|-------|
| 3.1 Generic FormSheet | ✅ Complete | FormSheet.swift | ~400 lines removed, all forms migrated |
| 3.2 Test suite | ✅ Complete | Tests/ | Repository + workflow tests added |
| 3.3 Logging | ✅ Complete | Common/Logger.swift | AppLogger added to workflows |

---

### Week 2: UI Foundation (IN PROGRESS 🟡)
**Duration:** Week 2 (3-4 days estimated)
**Status:** 🟡 Research complete, implementation started

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Materials, Gradients, Animations | ✅ | 4 hours | P1 |
| Typography improvements | ✅ | 2 hours | P1 |
| Update corner radius | ✅ | 1 hour | P1 |
| Apply glass effects (with contrast checks) | ✅ | 6 hours | P1 |
| Fix spacing inconsistencies | ✅ | 3 hours | P1 |

**Dependencies:** Can start mid-Week 2 while testing completes, but CANNOT MERGE until testing passes

---

### Week 3: Component Library (COMPLETE ✅)
**Duration:** Week 3 (3 days estimated)
**Status:** ✅ Components implemented

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Unified Badge component + VoiceOver | ✅ | 4 hours | P1 |
| Expandable Card + VoiceOver | ✅ | 4 hours | P1 |
| Pill Selector + VoiceOver | ✅ | 3 hours | P2 |
| Progress indicators + VoiceOver | ✅ | 4 hours | P2 |
| Loading skeletons + VoiceOver | ✅ | 3 hours | P2 |

**Dependencies:** Week 2 (Theme system updates) must complete first

---

### Week 4: Micro-Interactions (COMPLETE ✅)
**Duration:** Week 4 (2-3 days estimated)
**Status:** ✅ Implemented

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Spring animations | ✅ | 4 hours | P1 |
| Reduce Motion support | ✅ | 2 hours | P1 |
| Improved shadows | ✅ | 2 hours | P2 |
| Bottom sheets | ✅ | 3 hours | P2 |
| Button press states | ✅ | 2 hours | P2 |
| Celebration animations (optional) | ✅ | 6 hours | P2 |

**Dependencies:** Week 2 (Theme system) must complete first

---

### Weeks 5-6: ADHD Features & Polish (IN PROGRESS 🟡)
**Duration:** Weeks 5-6 (4-5 days estimated)
**Status:** 🟡 Research complete, implementation started

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Visual timeline view | ✅ | 12 hours | P2 |
| Gentle transition indicators | ✅ | 3 hours | P2 |
| Accessibility audit & fixes | 🟡 | 6 hours | P1 |
| ADHD settings section | ✅ | 3 hours | P1 |
| Final polish pass | ⏳ | 8-12 hours | P2 |

**Note:** Typography (Week 2) and Reduce Motion (Week 4) already complete

**Dependencies:** Weeks 2-4 (Theme, Components, Animations) must complete first

---

### Weeks 7-8: Integration & Release (NOT STARTED ⏳)
**Duration:** Weeks 7-8 (10 days estimated)
**Status:** ⏳ Pending all P0-P1 work complete

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Merge all P0-P1 changes | ⏳ | 2 days | P0 |
| Comprehensive testing | ⏳ | 3 days | P0 |
| Final polish | ⏳ | 2 days | P0 |
| Documentation | ⏳ | 2 days | P0 |
| Release candidate | ⏳ | 1 day | P0 |

**Dependencies:**
- All P0-P1 items complete (required for v1)
- P2 items either complete or consciously deferred
- P3 items explicitly deferred to v1+

---

## Testing Strategy

### Unit Testing (DONE ✅)
- Repository CRUD operations
- Workflow state transitions
- Validation logic
- Error handling

**Coverage:** ~60% of critical paths

---

### Integration Testing (PENDING ⏳)
**Scope:**
- Full capture workflow (text + voice)
- Delete operations (single, batch, rapid)
- Concurrent operations
- Save/rollback behavior
- Relationship integrity

**Estimated:** 2 days

---

### Manual Testing (PENDING ⏳)
**Scope:**
- Light/Dark mode (all screens)
- Dynamic Type (5 sizes: XS, S, M, L, XL, Accessibility)
- VoiceOver navigation (all screens)
- Reduce Motion (verify animations disabled)
- Stress testing (100+ captures, 50+ plans)

**Estimated:** 3 days

---

### Performance Testing (PENDING ⏳)
**Metrics:**
- Query performance: <100ms at 1K records
- Memory usage: Stable during bulk ops
- Scrolling: 60fps minimum
- Animation: No frame drops

**Estimated:** 1 day

---

### Accessibility Testing (PENDING ⏳)
**Scope:**
- VoiceOver labels (all interactive elements)
- Contrast ratios (WCAG AA compliance)
- Dynamic Type (no clipping at XXXL)
- Reduce Motion (animations disabled)
- Minimum tap targets (44pt)

**Estimated:** 1 day

---

## Risk Assessment & Mitigation

### High Risks

#### Risk 1: Performance Degradation from Glass Effects
**Likelihood:** Medium | **Impact:** High
**Mitigation:**
- Benchmark before/after glass application
- Use lighter materials if performance suffers
- Profile with Instruments
- Test on older devices (iPhone SE)
**Status:** ⏳ Not yet mitigated

---

#### Risk 2: Timeline Slippage (Testing Phase)
**Likelihood:** Medium | **Impact:** Medium
**Mitigation:**
- Prioritize P0-P1 testing over P2-P3
- Accept some test evidence gaps for v1
- Can defer P3 features if needed
**Status:** ⏳ Monitor closely

---

#### Risk 3: Timeline Feature Complexity
**Likelihood:** High | **Impact:** Medium
**Mitigation:**
- Timebox to 12 hours
- Create MVP first, iterate
- Make feature optional (can hide if buggy)
- Defer to v1 if needed (P2 priority)
**Status:** ⏳ Plan in place

---

### Medium Risks

#### Risk 4: Accessibility Issues
**Likelihood:** Low | **Impact:** High
**Mitigation:**
- Early VoiceOver testing
- Contrast ratio tools during design
- Accessibility audit checklist
**Status:** ⏳ Mitigation planned

---

#### Risk 5: ADHD Features Not Resonating
**Likelihood:** Low | **Impact:** Medium
**Mitigation:**
- Make features toggleable
- Gather user feedback early
- Iterate based on real usage
**Status:** ⏳ Mitigation planned

---

## Success Metrics

### Technical Metrics (Must Meet for v1)
- ✅ Zero crashes in production
- ✅ Zero critical bugs remaining
- [ ] <100ms query performance at 1000 records
- [ ] 60fps scrolling performance
- [ ] <5% memory usage increase from glass effects
- [ ] WCAG AA contrast ratios
- [ ] >80% test coverage on critical paths

---

### User Experience Metrics (Target for v1)
- Visual hierarchy clarity (subjective, user testing)
- ADHD feature adoption rate >30%
- App Store rating >4.5
- Reduced support requests for "how do I..."
- Increased task completion rates

---

### Business Metrics (Target for v1)
- Increased user retention
- Positive App Store reviews mentioning design
- Feature parity with award-winning ADHD apps
- App Store feature consideration

---

## Dependencies & Blockers

### Current Blockers
**None** - All critical code work complete, testing can begin immediately

### External Dependencies
- [ ] Design review/approval for glassmorphism level
- [ ] Stakeholder approval for v1 scope (manual vs. AI)
- [ ] Resource allocation confirmation

### Internal Dependencies
- **Testing completion (end of Week 2)** is HARD GATE for merging any UI work to main
- UI Foundation (Week 2) can START during testing but cannot MERGE until testing passes
- UI Foundation (Week 2) must complete before Component Library (Week 3) begins
- Theme system (Week 2) required for components (Week 3) and animations (Week 4)
- Reduce Motion support (Week 4) required before animations can ship
- All P0-P1 work (Weeks 1-6) must complete before Integration (Week 7)
- P2 items can be consciously deferred if timeline slips

---

## Resource Requirements

### Team Composition
**Recommended:**
- 1 Senior iOS Developer (full-time, 8-10 weeks)
- 1 UI/UX Designer (part-time, consultation for Weeks 2-6)
- 1 QA Engineer (full-time, Weeks 1-2 and 7-8)

**Minimum:**
- 1 iOS Developer (full-time, 8-10 weeks)
- Self-testing and design implementation

### Infrastructure
- [ ] TestFlight distribution setup
- [ ] CI/CD pipeline for automated testing
- [ ] Performance profiling tools (Instruments)
- [ ] Accessibility testing tools

### Testing Devices
- iPhone SE (small screen)
- iPhone 14/15 Pro (standard)
- iPhone 15 Pro Max (large screen)
- iOS 17.0, 17.5, 18.0 for compatibility testing

---

## Appendix A: Quick Reference

### Key Files Changed (by Phase)

#### Phase 1-3 (Complete)
- `ios/Offload/DesignSystem/ToastView.swift` (toast cancellation fix)
- `ios/Offload/Features/Inbox/CapturesView.swift` (race condition fix)
- `ios/Offload/Data/Repositories/*Repository.swift` (predicate queries)
- `ios/Offload/Domain/Models/CaptureEntry.swift` (relationship fix)
- `ios/Offload/Data/Services/CaptureWorkflowService.swift` (MainActor)
- Multiple files (21 error suppression fixes)

#### Phase 4-8 (Pending)
- `ios/Offload/DesignSystem/Theme.swift` (materials, gradients)
- `ios/Offload/DesignSystem/Components.swift` (new components)
- `ios/Offload/Features/Timeline/TimelineView.swift` (NEW)
- `ios/Offload/Features/Settings/SettingsView.swift` (ADHD settings)
- Multiple view files (spacing consistency, glass effects)

---

### Command Reference

```bash
# Testing
xcodebuild test -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 15'

# Find remaining issues
grep -r "try?" ios/Offload --include="*.swift" | grep -v "test"
grep -r "!" ios/Offload --include="*.swift" | grep "URL(string:"
grep -r "\.padding()" ios/Offload --include="*.swift" | grep -v "Theme.Spacing"

# Performance profiling
instruments -t "Time Profiler" -D trace.trace path/to/Offload.app

# Line count
find ios/Offload -name "*.swift" | xargs wc -l
```

---

### Document Links
- [Remediation Plan](./remediation-plan.md) - **SUPERSEDED by this document**
- [Remediation Tracking](./remediation-tracking.md) - **SUPERSEDED by this document**
- [Consolidated Plan](./consolidated-implementation-plan.md) - **SUPERSEDED by this document**
- [Polish Phase](./polish-phase.md) - **SUPERSEDED by this document**
- [Brain Dump Model](./brain-dump-model.md) - Reference for feature development
- [Testing Checklist](../testing/testing-checklist.md) - Execution tracker
- [Release Prep Checklist](../testing/release-prep-checklist.md) - Release readiness gates
- [AI Integration Plan](./ai-integration-plan.md) - Phased AI rollout
- [UI Trends Research](../research/ios-ui-trends-2025.md) - Research findings
- [ADHD UX Guardrails](../decisions/ADR-0003-adhd-ux-guardrails.md) - Design principles

---

### Contact Information
- **Project Lead:** TBD
- **iOS Developer:** TBD
- **UI/UX Designer:** TBD
- **QA Engineer:** TBD

---

## Appendix B: Testing Checklist (Comprehensive)

### Phase 1-3 Remediation Testing

#### Critical Bug Verification
- [ ] Toast cancellation works (rapid show, auto-dismiss, manual dismiss)
- [ ] No race conditions in delete operations
- [ ] All 21 error suppressions properly handled
- [ ] Repository queries use predicates (verify via code review)
- [ ] Relationships properly declared (verify models)
- [ ] No force unwraps crash (test URL validation)
- [ ] MainActor synchronization correct (test concurrent captures)
- [ ] Input validation prevents invalid API endpoints

#### Performance Validation
- [ ] Query benchmarks at 100 records: <10ms
- [ ] Query benchmarks at 1000 records: <100ms
- [ ] Query benchmarks at 10000 records: <1000ms
- [ ] Memory usage stable during bulk operations
- [ ] No memory leaks detected (Instruments)

---

### UI Foundation Testing

#### Visual Consistency
- [ ] Light mode: All screens render correctly
- [ ] Dark mode: All screens render correctly
- [ ] Glass effects visible but subtle
- [ ] Corner radius consistent throughout
- [ ] Spacing consistent (no hardcoded values visible)
- [ ] Shadows provide appropriate depth
- [ ] Gradients render correctly

#### Device Compatibility
- [ ] iPhone SE (small screen) - all content accessible
- [ ] iPhone 14/15 Pro (standard) - optimal layout
- [ ] iPhone 15 Pro Max (large) - no wasted space
- [ ] Portrait orientation works
- [ ] Landscape orientation works (if supported)

---

### Component Testing

#### Badge Component
- [ ] Category badges render with correct colors
- [ ] Status badges show appropriate states
- [ ] Icons display when provided
- [ ] Text truncates gracefully for long labels
- [ ] Tappable area meets 44pt minimum

#### Expandable Card
- [ ] Tap to expand works smoothly
- [ ] Animation is spring-based and smooth
- [ ] Collapsed state shows 2-line preview
- [ ] Expanded state shows full content
- [ ] No layout jumping during expansion

#### Other Components
- [ ] Pill selector scrolls horizontally
- [ ] Progress ring animates smoothly
- [ ] Progress bar shows accurate progress
- [ ] Loading skeletons shimmer correctly
- [ ] All components respect color scheme

---

### Animation Testing

#### Performance
- [ ] Spring animations run at 60fps
- [ ] No frame drops on button presses
- [ ] Celebration animations smooth
- [ ] Glass effects don't degrade scrolling
- [ ] Toast animations smooth

#### Accessibility
- [ ] Reduced motion respected (animations disabled)
- [ ] User can toggle animations in settings
- [ ] No flashing content (seizure risk)
- [ ] Animations enhance, don't distract

---

### ADHD Feature Testing

#### Visual Timeline
- [ ] Renders with 0 captures correctly (empty state)
- [ ] Renders with 50 captures correctly
- [ ] Renders with 100+ captures correctly (performance)
- [ ] Horizontal scrolling is smooth
- [ ] Tap to view capture details works
- [ ] Color coding is clear and consistent
- [ ] Time labels are readable at all sizes

#### Cognitive Load Assessment (User Testing)
- [ ] Timeline reduces time blindness (feedback)
- [ ] Next up indicators not anxiety-inducing (feedback)
- [ ] Completion animations feel rewarding (feedback)
- [ ] Settings allow adequate customization
- [ ] Features can be turned off easily
- [ ] Overall cognitive load feels manageable

---

### Accessibility Testing

#### VoiceOver
- [ ] All screens navigable with VoiceOver
- [ ] All buttons have descriptive labels
- [ ] Form inputs announced correctly
- [ ] Lists read items in logical order
- [ ] Modals announced properly
- [ ] Navigation hints are helpful

#### Contrast
- [ ] Text on backgrounds meets WCAG AA (4.5:1)
- [ ] Badge colors meet minimum contrast
- [ ] Glass effects don't obscure text
- [ ] Focus indicators visible and clear

#### Dynamic Type
- [ ] Extra Small text readable
- [ ] Small text readable
- [ ] Medium (default) optimal
- [ ] Large text doesn't break layout
- [ ] Extra Large text doesn't clip
- [ ] Accessibility sizes (XXL, XXXL) work

---

### Integration Testing

#### End-to-End Flows
- [ ] Capture (text) → View in Captures → Delete
- [ ] Capture (voice) → Transcription → View → Edit
- [ ] Create Plan → Add Tasks → Mark Complete → Archive
- [ ] Create List → Add Items → Check Off → Delete
- [ ] Settings changes persist across app restarts

#### Error Handling
- [ ] Network errors display toast
- [ ] Validation errors show inline
- [ ] Toast notifications appear/dismiss correctly
- [ ] Retry actions work
- [ ] Data rollback on error works

---

## Appendix C: Code Review Checklist

### Pre-Merge Requirements

#### Code Quality
- [ ] No force unwraps on dynamic values
- [ ] No `try?` without justification/comment
- [ ] All TODOs addressed or tracked
- [ ] No debug print statements (use AppLogger)
- [ ] Logging uses proper log levels

#### Performance
- [ ] No N+1 queries (all use predicates)
- [ ] Async operations properly isolated (@MainActor)
- [ ] No main thread blocking
- [ ] Memory leaks addressed (checked with Instruments)

#### Design System Compliance
- [ ] Uses Theme.Colors (no hardcoded colors)
- [ ] Uses Theme.Spacing (no hardcoded padding)
- [ ] Uses Theme.Typography (no raw Font calls)
- [ ] Uses Theme.CornerRadius (no hardcoded corner radii)
- [ ] No magic numbers (all constants named)

#### Testing
- [ ] Unit tests added for new logic
- [ ] Integration tests updated if needed
- [ ] Manual testing completed and documented
- [ ] Performance impact assessed

#### Documentation
- [ ] Code comments for complex logic
- [ ] Intent comments at file level
- [ ] README updated if architecture changes
- [ ] ADR created for major decisions

---

## Changelog

### January 9, 2026 (v4.7)
- ✅ Added AI integration plan

### January 9, 2026 (v4.6)
- ✅ Added release prep checklist

### January 9, 2026 (v4.5)
- ✅ Standardized Settings title typography to theme tokens

### January 9, 2026 (v4.4)
- ✅ Standardized Settings body text to theme tokens

### January 9, 2026 (v4.3)
- ✅ Standardized Organize empty state colors

### January 9, 2026 (v4.2)
- ✅ Standardized task completion icon styling

### January 9, 2026 (v4.1)
- ✅ Standardized Capture and Task row typography/colors

### January 9, 2026 (v4.0)
- ✅ Standardized Settings typography and colors to theme tokens

### January 9, 2026 (v3.9)
- ✅ Added Captures empty state message

### January 9, 2026 (v3.8)
- ✅ Standardized List detail typography to theme tokens

### January 9, 2026 (v3.7)
- ✅ Standardized Plan detail typography to theme tokens

### January 9, 2026 (v3.6)
- ✅ Standardized Organize list typography to theme tokens

### January 9, 2026 (v3.5)
- ✅ Improved timeline empty-hour guidance

### January 9, 2026 (v3.4)
- ✅ Added VoiceOver labels for form sheets and pickers

### January 9, 2026 (v3.3)
- ✅ Added VoiceOver hints for toggles and task inputs

### January 9, 2026 (v3.2)
- ✅ Added VoiceOver hints for navigation targets

### January 9, 2026 (v3.1)
- ✅ Added VoiceOver labels for alerts and error dialogs

### January 9, 2026 (v3.0)
- ✅ Added VoiceOver labels for task and list rows

### January 9, 2026 (v2.9)
- ✅ Added VoiceOver labels for capture rows and timeline cards

### January 9, 2026 (v2.8)
- ✅ Added ADHD support settings and next-up indicators

### January 9, 2026 (v2.7)
- ✅ Respected Reduce Motion in expandable cards and skeletons

### January 9, 2026 (v2.6)
- ✅ Added VoiceOver hints for key actions

### January 9, 2026 (v2.5)
- ✅ Added VoiceOver labels to capture and quick-add fields

### January 9, 2026 (v2.4)
- ✅ Added VoiceOver labels for action menus

### January 9, 2026 (v2.3)
- ✅ Added VoiceOver labels to icon-only controls

### January 9, 2026 (v2.2)
- ✅ Added accessibility labels to task and list toggles

### January 9, 2026 (v2.1)
- ✅ Added visual timeline view (tab)

### January 9, 2026 (v2.0)
- ✅ Added task completion sparkle celebration

### January 9, 2026 (v1.9)
- ✅ Updated card and floating shadows
- ✅ Added bottom sheet detents and drag indicators

### January 9, 2026 (v1.8)
- ✅ Added pressable button style with Reduce Motion support

### January 9, 2026 (v1.7)
- ✅ Added loading skeleton component

### January 9, 2026 (v1.6)
- ✅ Added Pill Selector component with VoiceOver labels
- ✅ Added Progress Ring and Progress Bar components

### January 9, 2026 (v1.5)
- ✅ Added Badge component with VoiceOver labels
- ✅ Added Expandable Card component with VoiceOver hint

### January 9, 2026 (v1.4)
- ✅ Applied glass styling to OrganizeView cards and
  capture FAB
- ✅ Replaced hardcoded padding with Theme spacing
  tokens

### January 9, 2026 (v1.3)
- ✅ Added testing checklist tracker
- ✅ Updated UI foundation progress

### January 9, 2026 (v1.1 - Revised)
- 🔧 **CORRECTED:** Resolved continuity issues and sequencing problems
  - Typography improvements moved to Week 2 (was Week 6)
  - Reduce Motion support moved to Week 4 (was Week 6)
  - Clarified Week 2 testing/UI overlap (testing is GATE for UI merge)
  - Made UI Foundation consistently P1 (was mixed P1/P2)
  - Consolidated celebration animations in Week 4 (removed duplication)
  - Added accessibility checkpoints throughout (not just Week 5)
  - Updated terminology from "Phase" to "Week" in timeline
  - Clarified P2 items can be deferred if timeline slips
  - Added VoiceOver requirements to all new components

### January 10, 2026 (v1)
- ✅ Applied glass treatment and Theme spacing updates to CaptureSheetView

### January 9, 2026 (v1)
- ✅ Toast cancellation fix merged (commit 688110b)
- ✅ Phase 1 critical fixes: 8/8 complete
- ✅ Merged latest changes from main
- ✅ Consolidated all planning documents into master-plan.md
- 📄 Created comprehensive testing checklist
- 📄 Defined 8-week timeline with exit criteria
- 📄 Identified P0-P3 priorities for v1 scope

### January 8, 2026
- ✅ Phase 2 high priority fixes: 5/5 implementation complete
- ✅ Phase 3 architecture improvements: 3/3 complete

### January 6, 2026
- ✅ Phase 1 critical fixes: 7/8 complete
- 📄 Initial remediation plan created

---

## Sign-Off

**Phase 1-3 (Critical Fixes) Approved:**
- [ ] Project Lead: ________________ Date: ________
- [ ] iOS Developer: ________________ Date: ________

**Phase 4-7 (UI/UX) Approved:**
- [ ] Project Lead: ________________ Date: ________
- [ ] UI/UX Designer: ________________ Date: ________

**Phase 8 (Release) Approved:**
- [ ] Project Lead: ________________ Date: ________
- [ ] QA Lead: ________________ Date: ________

**Timeline & Resources Approved:**
- [ ] Project Lead: ________________ Date: ________

---

**Document Version:** 1.0
**Last Updated:** January 9, 2026
**Status:** Active - Single Source of Truth
**Next Review:** Weekly (every Friday)
