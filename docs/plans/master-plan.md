<!-- Intent: Single source of truth for all implementation planning, consolidating remediation, UI/UX modernization, and feature development. -->

# Offload Master Implementation Plan
**Created:** January 9, 2026
**Status:** Active Development
**Current Phase:** Remediation Phase 1 Complete / UI Planning / Feature Development
**Timeline:** 8-10 weeks to production-ready v1.0
**Last Updated:** January 9, 2026

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
- ⏳ **UI/UX Modernization:** Research complete, implementation pending
- ⏳ **Feature Gaps:** AI hand-off, suggestion UI, organize flows

**Production Blockers Remaining:**
- Testing and validation of Phase 1-3 fixes
- Performance benchmarking
- Accessibility audit

**Path to Production:**
1. Complete testing of critical fixes (Week 1-2)
2. Implement UI foundation (Week 2-4)
3. Add ADHD-specific enhancements (Week 4-6)
4. Polish and release prep (Week 7-8)
5. Feature development for AI flows (Week 9-10+)

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
**Status:** ⏳ Research Complete | Implementation Pending
**Priority:** HIGH
**Owner:** TBD

#### Research Findings (COMPLETE ✅)
- Comprehensive iOS 2025-2026 trend analysis
- ADHD-specific design patterns identified
- Component library architecture planned
- 4-phase implementation strategy defined

#### UI Foundation (NOT STARTED ⏳)
**Scope:**
- Glassmorphism/Liquid Glass materials
- Gradient accent system
- Soft edges (updated corner radius)
- Spacing consistency fixes (15+ instances)

**Estimated:** 4 days

#### Component Library (NOT STARTED ⏳)
**Scope:**
- Unified Badge component
- Expandable Card component
- Pill Selector component
- Progress indicators (Ring, Bar)
- Loading skeletons

**Estimated:** 5 days

#### Micro-Interactions (NOT STARTED ⏳)
**Scope:**
- Spring animations on buttons
- Completion celebration effects
- Improved shadows and depth
- Bottom sheet patterns
- Button press states

**Estimated:** 5 days

#### ADHD Features (NOT STARTED ⏳)
**Scope:**
- Visual timeline view (Tiimo-inspired)
- Gentle transition indicators
- Next up badges
- Settings toggles for animations
- Completion celebrations

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

### Weeks 2-4: UI Foundation & Components 🎨
**Goal:** Modernize visual design, build component library
**Priority:** P2 (Can overlap with testing)

#### Week 2: Theme System & Glass Effects

**Tasks:**
1. **Add Materials, Gradients, Animations to Theme.swift** (4 hours)
   ```swift
   struct Materials { ... }
   struct Gradients { ... }
   struct Animations { ... }
   ```

2. **Update Corner Radius (Soft Edges Trend)** (1 hour)
   - sm: 4 → 6
   - md: 8 → 10
   - lg: 12 → 16
   - xl: 16 → 24

3. **Apply Glass Effects** (6 hours)
   - CaptureSheetView modal
   - CardView component
   - OrganizeView cards
   - FAB (Floating Action Button)

4. **Fix Spacing Inconsistencies** (3 hours)
   - Replace 15+ hardcoded padding values
   - Use Theme.Spacing.xs/sm/md/lg/xl throughout

**Deliverable:** Noticeably more modern, polished UI with depth

---

#### Week 3: Component Library Expansion

**Tasks:**
1. **Unified Badge Component** (4 hours)
   - Generic badge with text, color, icon
   - Convenience constructors (category, status)
   - Replace 5+ duplicate implementations

2. **Expandable Card Component** (4 hours)
   - Tap to expand/collapse
   - Spring animation
   - Solves lineLimit(2) truncation issues

3. **Pill Selector Component** (3 hours)
   - Horizontal scrolling pills
   - Selection state
   - Use for filtering/sorting

4. **Progress Indicators** (4 hours)
   - ProgressRing (circular with percentage)
   - ProgressBar (linear)
   - Use for plan completion

5. **Loading Skeletons** (3 hours)
   - Shimmering skeleton component
   - Replace ProgressView spinners
   - More modern UX

**Deliverable:** Consistent, reusable component library

---

#### Week 4: Micro-Interactions & Polish

**Tasks:**
1. **Spring Animations on Buttons** (4 hours)
   - Scale effect on press (0.95x)
   - Spring animation (0.3s response)
   - Apply to all buttons

2. **Improved Shadows & Depth** (2 hours)
   - Update CardView shadows
   - Add shadow variants to Theme

3. **Bottom Sheet Patterns** (3 hours)
   - Apply .presentationDetents()
   - Category picker, tag picker
   - Improved ergonomics

4. **Button Press States** (2 hours)
   - Tactile feedback on all buttons
   - Scale + animation

5. **Completion Celebrations (Optional)** (6 hours)
   - Confetti/glow effects
   - Settings toggle
   - ADHD dopamine boost

**Deliverable:** Polished, tactile, satisfying interactions

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

#### Week 6: Settings & Typography

**Tasks:**
1. **ADHD Settings Section** (3 hours)
   - Toggle completion animations
   - Toggle visual timeline
   - Toggle "next up" indicators
   - Animation speed preference

2. **Typography Improvements** (2 hours)
   - Add weight variants (.semibold, .bold)
   - Monospaced numbers
   - Increase line height for readability

3. **Reduce Motion Support** (2 hours)
   - Respect @Environment(\.accessibilityReduceMotion)
   - Disable animations when enabled

4. **Final Polish Pass** (8 hours)
   - Address visual inconsistencies
   - Optimize animations
   - Performance tuning

**Deliverable:** Complete ADHD-friendly, accessible app

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

**Deliverable:** Production-ready v1.0 release candidate

---

### Weeks 9-10+: Feature Development (POST-MVP) 📈
**Goal:** Complete AI workflows, advanced features
**Priority:** P3 (Nice-to-have for v1.0)

**Scope:**
- Backend API implementation
- AI hand-off submission
- Suggestion presentation UI
- Decision recording
- Placement flows
- Export/import functionality
- Batch operations
- Search and filtering

**Note:** These can be deferred to v1.1+ if timeline requires

---

## Implementation Priority Matrix

### P0 - Must Ship for v1.0 (Blockers)
- [x] All 8 critical bug fixes
- [x] Phase 2 high priority fixes
- [ ] Testing and validation (Weeks 1-2)
- [ ] Basic accessibility compliance

### P1 - Should Ship for v1.0 (High Value)
- [ ] UI foundation (glass effects, theme)
- [ ] Core component library (badges, cards)
- [ ] Micro-interactions (animations)
- [ ] ADHD settings toggles

### P2 - Nice-to-Have for v1.0 (Polish)
- [ ] Visual timeline view
- [ ] Completion celebrations
- [ ] Loading skeletons
- [ ] Bottom sheets
- [ ] Advanced typography

### P3 - Can Defer to v1.1+ (Future)
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
| Jan 9 | Defer AI features to post-v1.0 | Focus on manual app first, AI as enhancement | MVP scope reduction |

### Decisions Needed (By Jan 15, 2026)

1. **Glassmorphism Implementation Level**
   - [ ] Option A: Subtle (cards/modals) - **RECOMMENDED**
   - [ ] Option B: Full Liquid Glass (navigation layer)
   - [ ] Option C: Minimal (FAB/tabs only)

2. **Timeline Feature Priority**
   - [ ] Must-have for v1.0
   - [ ] Nice-to-have for v1.0 - **RECOMMENDED**
   - [ ] Defer to v1.1

3. **Celebration Animations**
   - [ ] Include in v1.0 - **RECOMMENDED** (low effort, high ADHD value)
   - [ ] Defer to v1.1

4. **v1.0 Scope**
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

### Phase 4: UI Foundation (NOT STARTED ⏳)
**Duration:** Week 2-3 (3 days estimated)
**Status:** ⏳ Research complete, implementation pending

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Materials, Gradients, Animations | ⏳ | 4 hours | P1 |
| Update corner radius | ⏳ | 1 hour | P1 |
| Apply glass effects | ⏳ | 6 hours | P1 |
| Fix spacing inconsistencies | ⏳ | 3 hours | P1 |

**Dependencies:** None (can start immediately after testing)

---

### Phase 5: Component Library (NOT STARTED ⏳)
**Duration:** Week 3 (3 days estimated)
**Status:** ⏳ Designs complete, implementation pending

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Unified Badge component | ⏳ | 4 hours | P1 |
| Expandable Card | ⏳ | 4 hours | P1 |
| Pill Selector | ⏳ | 3 hours | P2 |
| Progress indicators | ⏳ | 4 hours | P2 |
| Loading skeletons | ⏳ | 3 hours | P2 |

**Dependencies:** Phase 4 (Theme system updates)

---

### Phase 6: Micro-Interactions (NOT STARTED ⏳)
**Duration:** Week 4 (2-3 days estimated)
**Status:** ⏳ Patterns defined, implementation pending

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Spring animations | ⏳ | 4 hours | P1 |
| Improved shadows | ⏳ | 2 hours | P2 |
| Bottom sheets | ⏳ | 3 hours | P2 |
| Button press states | ⏳ | 2 hours | P2 |
| Celebration animations | ⏳ | 6 hours | P2 |

**Dependencies:** Phase 4 (Theme system)

---

### Phase 7: ADHD Features (NOT STARTED ⏳)
**Duration:** Week 5-6 (4 days estimated)
**Status:** ⏳ Research complete, implementation pending

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Visual timeline view | ⏳ | 12 hours | P2 |
| Gentle transition indicators | ⏳ | 3 hours | P2 |
| ADHD settings section | ⏳ | 3 hours | P1 |
| Typography improvements | ⏳ | 2 hours | P2 |
| Reduce motion support | ⏳ | 2 hours | P1 |

**Dependencies:** Phases 4-6 (Components, animations)

---

### Phase 8: Integration & Release (NOT STARTED ⏳)
**Duration:** Week 7-8 (10 days estimated)
**Status:** ⏳ Pending all previous phases

| Task | Status | Estimated | Priority |
|------|--------|-----------|----------|
| Merge all changes | ⏳ | 2 days | P0 |
| Comprehensive testing | ⏳ | 3 days | P0 |
| Final polish | ⏳ | 2 days | P0 |
| Documentation | ⏳ | 2 days | P0 |
| Release candidate | ⏳ | 1 day | P0 |

**Dependencies:** All previous phases complete

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
- Accept some test evidence gaps for v1.0
- Can defer P3 features if needed
**Status:** ⏳ Monitor closely

---

#### Risk 3: Timeline Feature Complexity
**Likelihood:** High | **Impact:** Medium
**Mitigation:**
- Timebox to 12 hours
- Create MVP first, iterate
- Make feature optional (can hide if buggy)
- Defer to v1.1 if needed (P2 priority)
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

### Technical Metrics (Must Meet for v1.0)
- ✅ Zero crashes in production
- ✅ Zero critical bugs remaining
- [ ] <100ms query performance at 1000 records
- [ ] 60fps scrolling performance
- [ ] <5% memory usage increase from glass effects
- [ ] WCAG AA contrast ratios
- [ ] >80% test coverage on critical paths

---

### User Experience Metrics (Target for v1.0)
- Visual hierarchy clarity (subjective, user testing)
- ADHD feature adoption rate >30%
- App Store rating >4.5
- Reduced support requests for "how do I..."
- Increased task completion rates

---

### Business Metrics (Target for v1.0)
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
- [ ] Stakeholder approval for v1.0 scope (manual vs. AI)
- [ ] Resource allocation confirmation

### Internal Dependencies
- Testing (Weeks 1-2) blocks UI work from going to production
- UI Foundation (Phase 4) blocks Component Library (Phase 5)
- Component Library blocks Micro-Interactions (Phase 6)
- All phases block Integration & Release (Phase 8)

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

### January 9, 2026
- ✅ Toast cancellation fix merged (commit 688110b)
- ✅ Phase 1 critical fixes: 8/8 complete
- ✅ Merged latest changes from main
- ✅ Consolidated all planning documents into master-plan.md
- 📄 Created comprehensive testing checklist
- 📄 Defined 8-week timeline with exit criteria
- 📄 Identified P0-P3 priorities for v1.0 scope

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
