<!-- Intent: Consolidated implementation plan merging critical remediation fixes with UI/UX enhancements for production-ready release. -->

> **⚠️ DEPRECATED:** This document has been superseded by [master-plan.md](./master-plan.md) as of January 9, 2026.
> Please refer to the master plan for the single source of truth on all implementation planning.

# Consolidated Implementation Plan: Offload iOS App
**Created:** January 9, 2026
**Status:** Active Planning
**Scope:** Critical Remediation + UI/UX Modernization
**Timeline:** 6-8 weeks
**Goal:** Production-ready release with modern UI and zero critical bugs

---

## Executive Summary

This plan consolidates two parallel work streams into a unified implementation strategy:

1. **Critical Remediation:** 8 critical and 12 high-priority bugs blocking production (from [remediation-plan.md](./remediation-plan.md))
2. **UI/UX Modernization:** Modern iOS design patterns for 2025-2026 (from [ios-ui-trends-2025.md](../research/ios-ui-trends-2025.md))

**Strategic Approach:**
- Fix critical bugs FIRST (Weeks 1-3)
- Implement UI improvements in parallel where non-blocking (Weeks 2-6)
- Polish and test comprehensive release (Weeks 7-8)

**Key Milestones:**
- ✅ Week 3: All critical bugs resolved
- ✅ Week 5: UI modernization complete
- ✅ Week 6: Full testing and validation
- ✅ Week 8: Production release candidate

---

## Work Stream Overview

### Stream A: Critical Remediation (Priority: P0-P1)
**Status:** Phase 1: 7/8 complete; Phase 2: In progress
**Owner:** TBD
**Blockers:** None
**Dependencies:** Must complete before production release

**Remaining Critical Items:**
- Toast cancellation fix (P0)
- Fetch optimization for suggestions (P1)
- Testing/validation evidence collection

---

### Stream B: UI/UX Modernization (Priority: P2-P3)
**Status:** Research complete, implementation pending
**Owner:** TBD
**Blockers:** None
**Dependencies:** Can proceed in parallel with remediation

**Key Deliverables:**
- Glassmorphism/Liquid Glass effects
- Gradient accent system
- Unified component library
- ADHD-specific enhancements
- Accessibility improvements

---

## Phase 1: Critical Stability (Weeks 1-3)
**Goal:** Eliminate all production blockers
**Priority:** CRITICAL - Must complete before any UI work goes to prod

### Week 1: Data Safety & Integrity

#### Day 1-2: Final Critical Fixes ⚠️ CRITICAL
**Status:** 🟡 1 item remaining

**Tasks:**
1. **Fix ToastView Task Cancellation** (P0)
   - File: `ios/Offload/DesignSystem/ToastView.swift:87-102`
   - Issue: Incorrect `Task.isCancelled` check
   - Fix: Add proper CancellationError handling
   - Testing: Auto-dismiss, rapid show, manual dismiss
   - **Estimated:** 2 hours

**Acceptance Criteria:**
- [ ] Task.sleep properly handles cancellation
- [ ] No memory leaks with weak self
- [ ] Toast dismisses after duration
- [ ] Multiple rapid toasts handled correctly

**Code Changes:**
```swift
// BEFORE (BROKEN)
if !_Concurrency.Task.isCancelled {  // ⚠️ Checks type, not instance
    await MainActor.run { currentToast = nil }
}

// AFTER (FIXED)
do {
    try await _Concurrency.Task.sleep(for: .seconds(duration))
    guard !_Concurrency.Task.isCancelled else { return }
    await MainActor.run { self.currentToast = nil }
} catch is CancellationError {
    return  // Expected on rapid toast changes
}
```

---

#### Day 3-5: Fetch Optimization & Testing ⚠️ HIGH
**Status:** 🟡 In Progress

**Tasks:**
1. **Optimize Pending Suggestions Query** (P1)
   - File: `ios/Offload/Data/Repositories/SuggestionRepository.swift`
   - Issue: In-memory filtering after fetch-all (SwiftData limitation)
   - Options:
     - Option A: Denormalize `entryId` onto Suggestion model
     - Option B: Accept in-memory filter (document limitation)
     - Option C: Use compound fetch with explicit joins
   - **Decision Needed:** Which approach?
   - **Estimated:** 4-6 hours (if denormalizing)

2. **Performance Benchmarking** (P1)
   - Run query benchmarks: 100, 1000, 10000 records
   - Document before/after performance
   - Establish baseline metrics
   - **Estimated:** 4 hours

**Acceptance Criteria:**
- [ ] Fetch queries perform <100ms at 1000 records
- [ ] Memory usage stable during bulk operations
- [ ] Benchmark results documented

---

### Week 2-3: Testing & Validation ⚠️ CRITICAL

#### Comprehensive Testing Checklist

**Unit Tests** (P0)
- [ ] Repository query tests (verify predicates)
- [ ] Validation logic tests
- [ ] Error handling tests (21 fixed instances)
- [ ] URL validation tests
- [ ] Permission caching tests

**Integration Tests** (P1)
- [ ] Full capture workflow (text + voice)
- [ ] Delete operations (single, multiple, rapid)
- [ ] Concurrent operations (race conditions)
- [ ] Save/rollback behavior
- [ ] Relationship integrity (cascade, nullify)

**Manual Testing** (P0)
- [ ] Delete items from inbox (single, batch, rapid)
- [ ] Form validation (empty, invalid, valid inputs)
- [ ] Error display (toast notifications, inline messages)
- [ ] API endpoint validation (HTTPS enforcement)
- [ ] Permission requests (microphone, speech)
- [ ] Voice recording lifecycle

**Performance Testing** (P1)
- [ ] Query performance with 1000+ entries
- [ ] Memory usage during bulk operations
- [ ] UI responsiveness during async operations
- [ ] Scrolling performance (60fps target)

**Regression Testing** (P0)
- [ ] All fixed bugs remain fixed
- [ ] No new crashes introduced
- [ ] Error messages display correctly
- [ ] Data integrity maintained

**Estimated Testing Time:** 2-3 days

---

**Phase 1 Exit Criteria:**
- ✅ All 8 critical bugs resolved
- ✅ All 21 error suppression instances fixed
- ✅ All repositories use predicate-based queries
- ✅ All relationships properly declared
- ✅ Zero force unwraps on dynamic values
- ✅ All async patterns correctly implemented
- ✅ Input validation on all user inputs
- ✅ >80% test coverage on critical paths
- ✅ Performance benchmarks meet targets

---

## Phase 2: UI Foundation (Weeks 2-4)
**Goal:** Establish modern design system foundation
**Priority:** HIGH - Can proceed in parallel with Phase 1 testing

### Week 2: Theme System Enhancements 🎨

#### Day 1-2: Glassmorphism & Materials
**Status:** ⏳ Not Started
**Priority:** P2 (High Visual Impact)

**Tasks:**
1. **Add Materials to Theme.swift**
   ```swift
   struct Materials {
       static func glass(_ colorScheme: ColorScheme) -> Material { ... }
       static func cardGlass(_ colorScheme: ColorScheme) -> Material { ... }
   }
   ```

2. **Add Gradients to Theme.swift**
   ```swift
   struct Gradients {
       static func primaryAction(_ colorScheme: ColorScheme) -> LinearGradient { ... }
       static func success(_ colorScheme: ColorScheme) -> LinearGradient { ... }
       static func surfaceDepth(_ colorScheme: ColorScheme) -> RadialGradient { ... }
   }
   ```

3. **Add Animation Presets**
   ```swift
   struct Animations {
       static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
       static let quickSpring = Animation.spring(response: 0.2, dampingFraction: 0.8)
       static let easeOut = Animation.easeOut(duration: 0.25)
       static let celebration = Animation.easeOut(duration: 0.6)
   }
   ```

**Estimated:** 4 hours

**Testing:**
- [ ] Light mode appearance
- [ ] Dark mode appearance
- [ ] Performance impact (should be negligible)

---

#### Day 3-4: Update Corner Radius & Apply Glass Effects
**Status:** ⏳ Not Started
**Priority:** P2 (High Visual Impact)

**Tasks:**
1. **Update CornerRadius Values** (Soft Edges Trend)
   ```swift
   // In Theme.swift
   struct CornerRadius {
       static let sm: CGFloat = 6   // Was 4
       static let md: CGFloat = 10  // Was 8
       static let lg: CGFloat = 16  // Was 12
       static let xl: CGFloat = 24  // Was 16
   }
   ```

2. **Apply Glass Effects to Key Components**
   - CaptureSheetView modal → `.background(.ultraThinMaterial)`
   - CardView component → Optional glass background
   - OrganizeView cards → Subtle glass effect
   - FAB → Glass ring effect

**Estimated:** 4 hours

**Decision Point: Glassmorphism Level**
- [ ] **Option A (Recommended):** Subtle glass on cards/modals only
- [ ] **Option B:** Full Liquid Glass on navigation layer
- [ ] **Option C:** Minimal - FAB and tab bar only

---

#### Day 5: Fix Spacing Inconsistencies
**Status:** ⏳ Not Started
**Priority:** P3 (Polish)

**Tasks:**
1. **Audit and Replace Hardcoded Spacing** (15+ instances)
   - Search: `padding()` without Theme.Spacing
   - Search: `spacing: [0-9]` (raw numbers)
   - Replace with: `Theme.Spacing.xs/sm/md/lg/xl`

2. **Update Component Spacing**
   - CaptureRow
   - TaskRowView
   - ListDetailView
   - PlanDetailView
   - OrganizeView

**Estimated:** 3 hours

**Verification:**
```bash
# Find remaining hardcoded spacing
grep -r "\.padding()" ios/Offload --include="*.swift" | grep -v "Theme.Spacing"
grep -r "spacing: [0-9]" ios/Offload --include="*.swift"
```

---

### Week 3-4: Component Library Expansion 🧩

#### Day 1: Unified Badge Component
**Status:** ⏳ Not Started
**Priority:** P2 (High Consistency Value)

**Tasks:**
1. **Create Badge.swift**
   - Generic badge with text, color, icon
   - Convenience constructors (category, status, count)
   - Consistent styling (opacity 0.2, padding, corner radius)

2. **Replace Existing Badge Implementations**
   - OrganizeView (Plan lifecycle badges)
   - ListDetailView (List kind badges)
   - TaskRowView (Importance indicators)
   - Settings (Category/Tag display)

**Estimated:** 4 hours

**Before/After:**
- Before: 5+ different badge implementations
- After: Single Badge component, ~100 lines removed

---

#### Day 2: Expandable Card Component
**Status:** ⏳ Not Started
**Priority:** P2 (Solves Truncation Issue)

**Tasks:**
1. **Create ExpandableCard.swift**
   - Tap to expand/collapse
   - Spring animation transition
   - Optional line limit in collapsed state

2. **Apply to Views with lineLimit(2) Issues**
   - CapturesView (capture text)
   - OrganizeView (plan descriptions)
   - ListDetailView (list descriptions)
   - CommunicationItem (content preview)

**Estimated:** 4 hours

**Result:** Better readability for long content

---

#### Day 3: Pill Selector Component
**Status:** ⏳ Not Started
**Priority:** P3 (Modern Pattern)

**Tasks:**
1. **Create PillSelector.swift**
   - Horizontal scrolling pills
   - Selection state management
   - Animated selection transitions

2. **Use Cases**
   - Category filtering in OrganizeView
   - Status filters in CapturesView
   - Sort options

**Estimated:** 3 hours

---

#### Day 4: Progress Indicators
**Status:** ⏳ Not Started
**Priority:** P3 (Visual Feedback)

**Tasks:**
1. **Create ProgressRing.swift**
   - Circular progress indicator
   - Percentage text in center
   - Animated progress changes

2. **Create ProgressBar.swift**
   - Linear progress bar
   - Loading state variant

3. **Apply to Features**
   - Plan completion percentage (PlanDetailView)
   - Task progress visualization
   - Loading states (replace spinners)

**Estimated:** 4 hours

---

#### Day 5: Loading Skeletons
**Status:** ⏳ Not Started
**Priority:** P3 (Modern UX)

**Tasks:**
1. **Create SkeletonView.swift**
   - Shimmering gradient animation
   - Reusable skeleton shapes (card, list row, text line)

2. **Replace ProgressView Spinners**
   - CapturesView loading state
   - OrganizeView loading state
   - Settings data loading

**Estimated:** 3 hours

**Result:** More polished, less jarring loading experience

---

## Phase 3: Micro-Interactions & Polish (Weeks 4-5)
**Goal:** Add purposeful animations and tactile feedback
**Priority:** MEDIUM - Enhances user experience

### Week 4: Animations & Feedback ✨

#### Day 1-2: Spring Animations on Buttons
**Status:** ⏳ Not Started
**Priority:** P2 (High Satisfaction Value)

**Tasks:**
1. **Create SpringButtonStyle**
   - Scale effect on press (0.95x)
   - Spring animation (0.3s response, 0.7 damping)

2. **Apply to All Buttons**
   - PrimaryButton
   - SecondaryButton
   - Custom action buttons
   - FAB

**Estimated:** 4 hours

**Testing:**
- [ ] No frame drops during animation
- [ ] Feels responsive and tactile

---

#### Day 3: Improved Shadows & Depth
**Status:** ⏳ Not Started
**Priority:** P3 (Polish)

**Tasks:**
1. **Update CardView Shadow**
   ```swift
   .shadow(
       color: Color.black.opacity(0.1),
       radius: Theme.Shadows.elevationMd,
       x: 0,
       y: 2
   )
   ```

2. **Add Shadow Variants to Theme**
   ```swift
   struct Shadows {
       static let card = (color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
       static let elevated = (color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
   }
   ```

**Estimated:** 2 hours

---

#### Day 4-5: Completion Celebration Animations (Optional)
**Status:** ⏳ Not Started
**Priority:** P3 (ADHD Dopamine Boost)

**Tasks:**
1. **Create CelebrationEffect.swift**
   - Confetti particles
   - Scale pulse effect
   - Color glow animation

2. **Add Settings Toggle**
   - "Show completion animations" preference
   - Default: ON

3. **Apply to Completion Events**
   - Task marked complete
   - Capture accepted
   - Plan achieved

**Estimated:** 6 hours

**ADHD Benefit:** Positive reinforcement, dopamine hit

---

### Week 5: Bottom Sheets & Accessibility ♿

#### Day 1-2: Bottom Sheet Patterns
**Status:** ⏳ Not Started
**Priority:** P2 (Ergonomics)

**Tasks:**
1. **Apply `.presentationDetents()` to Sheets**
   - Category picker → [.medium, .large]
   - Tag picker → [.medium]
   - Quick action sheets → [.medium]

2. **Add Drag Indicators**
   - `.presentationDragIndicator(.visible)`

**Estimated:** 3 hours

**Result:** Improved thumb-reachability, modern iOS feel

---

#### Day 3-4: Accessibility Audit & Fixes
**Status:** ⏳ Not Started
**Priority:** P2 (Required for Production)

**Tasks:**
1. **Add Accessibility Labels to Icon Buttons**
   - Delete buttons
   - Edit buttons
   - Navigation buttons
   - Action buttons

2. **Test with VoiceOver**
   - Navigate all screens
   - Verify labels are descriptive
   - Test form interactions

3. **Verify Contrast Ratios**
   - Text on backgrounds (WCAG AA)
   - Glass effects don't obscure text
   - Badge colors meet contrast requirements

**Estimated:** 6 hours

**Acceptance Criteria:**
- [ ] All interactive elements have labels
- [ ] VoiceOver navigation works smoothly
- [ ] Contrast ratios meet WCAG AA standards

---

#### Day 5: Typography Improvements
**Status:** ⏳ Not Started
**Priority:** P3 (Visual Hierarchy)

**Tasks:**
1. **Add Weight Variants to Typography**
   ```swift
   static let cardTitle = Font.headline.weight(.semibold)
   static let sectionTitle = Font.title2.weight(.bold)
   ```

2. **Add Monospaced Numbers**
   ```swift
   static let numeric = Font.body.monospacedDigit()
   ```

3. **Increase Line Height for Readability**
   ```swift
   static let lineSpacingNormal: CGFloat = 6  // Was 4
   static let lineSpacingRelaxed: CGFloat = 10 // Was 8
   ```

**Estimated:** 2 hours

---

## Phase 4: ADHD-Specific Enhancements (Week 6)
**Goal:** Add cognitive support features for ADHD users
**Priority:** HIGH VALUE - Differentiating features

### Week 6: Visual Timeline & Cognitive Support 🎭

#### Day 1-3: Visual Timeline View (Tiimo-Inspired)
**Status:** ⏳ Not Started
**Priority:** P2 (High ADHD Value)

**Tasks:**
1. **Create TimelineView.swift**
   - Horizontal scrolling timeline
   - Hour-by-hour columns (24 hours)
   - Color-coded capture blocks
   - Time-of-day visualization

2. **Create TimelineBlock.swift**
   - Capture representation on timeline
   - Tap to view details
   - Duration visualization

3. **Add View Toggle in CapturesView**
   - Switch between List and Timeline views
   - Persist user preference

**Estimated:** 12 hours (Complex feature)

**ADHD Benefit:**
- Reduces time blindness
- Makes time concrete and visual
- Easier to see patterns
- Reduces cognitive load for planning

**Testing:**
- [ ] Timeline renders correctly for 0-100 captures
- [ ] Scrolling performance is smooth
- [ ] Tap interactions work correctly
- [ ] View preference persists

---

#### Day 4: Gentle Transition Indicators
**Status:** ⏳ Not Started
**Priority:** P3 (ADHD Support)

**Tasks:**
1. **Create NextUpIndicator.swift**
   - "Up next" badge for next task
   - Gentle visual cue (no pressure)
   - Accent color, subtle animation

2. **Apply to Task Lists**
   - Show on first incomplete task
   - Optional countdown (if user enables)

**Estimated:** 3 hours

**ADHD Benefit:** Reduces transition anxiety

---

#### Day 5: Settings & Preferences
**Status:** ⏳ Not Started
**Priority:** P3 (User Control)

**Tasks:**
1. **Add ADHD-Specific Settings Section**
   - Toggle completion animations
   - Toggle visual timeline
   - Toggle "next up" indicators
   - Animation speed preference

2. **Add Explanatory Text**
   - Why these features exist
   - How they help with ADHD

**Estimated:** 3 hours

**Philosophy:** User control, no forced patterns

---

## Phase 5: Integration & Testing (Week 7)
**Goal:** Integrate all changes, comprehensive testing
**Priority:** CRITICAL - Ensure quality

### Week 7: Full Integration Testing

#### Day 1-2: Integration & Bug Fixes
**Tasks:**
1. Merge all UI changes with remediation fixes
2. Resolve any conflicts
3. Fix integration bugs
4. Update dependencies

**Estimated:** 2 days

---

#### Day 3-5: Comprehensive Testing
**Tasks:**

**Functional Testing:**
- [ ] All features work as designed
- [ ] No regressions in existing functionality
- [ ] Error handling works correctly
- [ ] Data integrity maintained

**Visual Testing:**
- [ ] Light mode appearance
- [ ] Dark mode appearance
- [ ] Dynamic Type (small/large text)
- [ ] Various screen sizes (SE, Pro Max)
- [ ] Landscape orientation (if supported)

**Performance Testing:**
- [ ] Scrolling is smooth (60fps)
- [ ] Animations don't cause frame drops
- [ ] Glass effects perform well
- [ ] Memory usage is stable
- [ ] Battery usage is reasonable

**ADHD User Testing:**
- [ ] Visual timeline reduces time blindness
- [ ] Animations provide feedback without distraction
- [ ] Color-coding improves task recognition
- [ ] Cognitive load remains low
- [ ] No pressure or guilt feelings

**Accessibility Testing:**
- [ ] VoiceOver navigation works
- [ ] Contrast ratios meet WCAG AA
- [ ] Dynamic Type scales correctly
- [ ] Reduced motion respected
- [ ] Color blindness accommodated

**Estimated:** 3 days

---

## Phase 6: Polish & Release Prep (Week 8)
**Goal:** Final polish, documentation, release candidate
**Priority:** CRITICAL - Production readiness

### Week 8: Release Preparation

#### Day 1-2: Final Polish
**Tasks:**
1. Address any remaining visual inconsistencies
2. Optimize animations and transitions
3. Final accessibility pass
4. Performance optimizations
5. Code cleanup

**Estimated:** 2 days

---

#### Day 3-4: Documentation & Release Notes
**Tasks:**
1. **Update User-Facing Documentation**
   - New features (visual timeline, glass effects)
   - ADHD-specific settings
   - Accessibility improvements

2. **Update Developer Documentation**
   - New design system components
   - Theme system additions
   - Component usage examples

3. **Create Release Notes**
   - Bug fixes (from remediation)
   - New features (UI enhancements)
   - Known limitations

4. **Update App Store Materials**
   - Screenshots (show new UI)
   - Feature descriptions
   - What's New text

**Estimated:** 2 days

---

#### Day 5: Release Candidate
**Tasks:**
1. Create release build
2. Final QA pass
3. TestFlight distribution
4. Internal dogfooding
5. Fix any critical issues
6. Sign off for production

**Estimated:** 1 day

---

## Resource Requirements

### Development Team
**Recommended:**
- 1 Senior iOS Developer (full-time, 8 weeks)
- 1 UI/UX Designer (part-time, consultation)
- 1 QA Engineer (full-time, Weeks 7-8)

**Minimum:**
- 1 iOS Developer (full-time, 8 weeks)
- Self-testing and design implementation

---

### Design Assets
- [ ] Updated screenshots for App Store
- [ ] Icon refinements (if needed)
- [ ] Onboarding screens (if adding timeline)

---

### Testing Devices
- iPhone SE (small screen)
- iPhone 14/15 Pro (standard)
- iPhone 14/15 Pro Max (large screen)
- iOS 17.0, 17.5, 18.0 testing

---

## Risk Assessment & Mitigation

### High Risk Items

#### Risk 1: Performance Degradation from Glass Effects
**Likelihood:** Medium
**Impact:** High
**Mitigation:**
- Benchmark before/after glass application
- Use lighter materials if performance suffers
- Profile with Instruments
- Test on older devices (iPhone SE)

---

#### Risk 2: Timeline Feature Complexity
**Likelihood:** High
**Impact:** Medium
**Mitigation:**
- Timebox to 12 hours
- Create MVP first, iterate
- Make feature optional (can hide if buggy)
- Defer to post-launch if needed

---

#### Risk 3: Regression from Remediation Fixes
**Likelihood:** Medium
**Impact:** Critical
**Mitigation:**
- Comprehensive test suite
- Manual regression testing
- Git branch strategy (can revert)
- Staged rollout

---

#### Risk 4: Timeline Slippage
**Likelihood:** Medium
**Impact:** Medium
**Mitigation:**
- De-scope P3 items if needed
- Timeline feature is optional
- Celebration animations are optional
- Focus on P0-P2 items first

---

### Medium Risk Items

#### Risk 5: Accessibility Issues
**Likelihood:** Low
**Impact:** High
**Mitigation:**
- Early VoiceOver testing
- Contrast ratio tools
- Accessibility audit checklist

---

#### Risk 6: ADHD Features Not Resonating
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- Make features toggleable
- Gather user feedback early
- Iterate based on real usage

---

## Success Metrics

### Technical Metrics (Must Meet)
- ✅ Zero crashes in production
- ✅ Zero critical bugs remaining
- ✅ <100ms query performance at 1000 records
- ✅ 60fps scrolling performance
- ✅ <5% memory usage increase
- ✅ WCAG AA contrast ratios
- ✅ >80% test coverage on critical paths

---

### User Experience Metrics (Target)
- 📈 Visual hierarchy clarity (subjective, user testing)
- 📈 ADHD feature adoption rate >30%
- 📈 App Store rating improvement
- 📈 Reduced support requests for "how do I..."
- 📈 Increased task completion rates

---

### Business Metrics (Target)
- 📈 Increased user retention
- 📈 Positive App Store reviews mentioning design
- 📈 Feature parity with award-winning ADHD apps
- 📈 App Store feature consideration

---

## Decision Log

### Decisions Needed (By Jan 15, 2026)

1. **Glassmorphism Level**
   - [ ] Option A: Subtle (cards/modals)
   - [ ] Option B: Full Liquid Glass
   - [ ] Option C: Minimal (FAB/tabs)
   - **Recommendation:** Option A

2. **Suggestion Fetch Optimization**
   - [ ] Option A: Denormalize entryId
   - [ ] Option B: Accept in-memory filter
   - [ ] Option C: Compound fetch
   - **Recommendation:** Option B (document limitation)

3. **Timeline Feature Priority**
   - [ ] Must-have for v1
   - [ ] Nice-to-have for v1
   - [ ] Defer to v1
   - **Recommendation:** Nice-to-have (defer if timeline slips)

4. **Celebration Animations**
   - [ ] Include in v1
   - [ ] Defer to v1
   - **Recommendation:** Include (high ADHD value, low effort)

5. **Resource Allocation**
   - [ ] 1 developer (8 weeks)
   - [ ] 2 developers (4 weeks each)
   - **Recommendation:** 1 developer (8 weeks, better continuity)

---

### Decisions Made

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| Jan 8, 2026 | Fix remediation items first | Critical bugs block production | Phase 1 prioritized |
| Jan 9, 2026 | Consolidated planning approach | Avoid duplicate effort, clarity | This document |

---

## Communication Plan

### Weekly Status Updates
**Audience:** Stakeholders, team
**Format:**
- Progress on both streams (remediation + UI)
- Blockers and risks
- Decisions needed
- Demo of visual changes

**Schedule:** Every Friday

---

### Demo Schedule
**Week 3:** Critical fixes demo (error handling, race conditions resolved)
**Week 4:** UI foundation demo (glass effects, badges, spacing)
**Week 5:** Micro-interactions demo (animations, buttons, polish)
**Week 6:** ADHD features demo (timeline, celebrations, indicators)
**Week 7:** Full integration demo (everything together)
**Week 8:** Release candidate demo (final product)

---

## Rollback Strategy

### Git Branch Strategy
```
main (protected)
├── remediation/phase-1 (critical fixes)
├── remediation/phase-2 (high priority)
├── ui/foundation (theme system)
├── ui/components (component library)
├── ui/animations (micro-interactions)
├── ui/adhd-features (timeline, celebrations)
└── integration/v1 (merge all)
```

**Merge Strategy:**
1. Merge remediation branches first (Weeks 1-3)
2. Merge UI foundation after remediation (Week 4)
3. Merge UI components (Week 5)
4. Merge animations & ADHD features (Week 6)
5. Integration branch for testing (Week 7)
6. Release from integration branch (Week 8)

**Rollback Plan:**
- Can revert individual feature branches
- Critical fixes remain separate (always keep)
- UI features can be disabled via feature flags
- Integration branch can be rebuilt if needed

---

## Appendix A: Task Dependency Graph

```
Phase 1: Critical Fixes (MUST COMPLETE FIRST)
├── Toast Cancellation Fix
├── Fetch Optimization
└── Comprehensive Testing
    ↓
Phase 2: UI Foundation (CAN START AFTER WEEK 1)
├── Theme Enhancements (Materials, Gradients)
├── Corner Radius Updates
├── Spacing Consistency Fixes
└── Apply Glass Effects
    ↓
Phase 3: Components & Polish (DEPENDS ON PHASE 2)
├── Badge Component → (depends on Theme)
├── Expandable Card → (depends on Theme)
├── Pill Selector → (depends on Theme)
├── Progress Indicators → (depends on Theme)
└── Loading Skeletons → (depends on Theme)
    ↓
Phase 4: Animations (DEPENDS ON PHASE 2)
├── Spring Button Animations → (depends on Theme)
├── Celebration Effects → (optional, independent)
├── Shadows & Depth → (depends on Theme)
└── Bottom Sheets → (independent)
    ↓
Phase 5: ADHD Features (DEPENDS ON PHASES 2-4)
├── Visual Timeline → (depends on Components, Theme)
├── Next Up Indicators → (depends on Badge component)
└── Settings Toggles → (independent)
    ↓
Phase 6: Integration & Testing (DEPENDS ON ALL)
└── Release Candidate
```

---

## Appendix B: File Change Inventory

### New Files (Create)
- `ios/Offload/DesignSystem/Badge.swift`
- `ios/Offload/DesignSystem/ExpandableCard.swift`
- `ios/Offload/DesignSystem/PillSelector.swift`
- `ios/Offload/DesignSystem/ProgressRing.swift`
- `ios/Offload/DesignSystem/ProgressBar.swift`
- `ios/Offload/DesignSystem/SkeletonView.swift`
- `ios/Offload/DesignSystem/CelebrationEffect.swift`
- `ios/Offload/Features/Timeline/TimelineView.swift`
- `ios/Offload/Features/Timeline/TimelineBlock.swift`
- `ios/Offload/Features/Timeline/NextUpIndicator.swift`

### Modified Files (Update)
- `ios/Offload/DesignSystem/Theme.swift` (add Materials, Gradients, Animations, update CornerRadius)
- `ios/Offload/DesignSystem/ToastView.swift` (fix cancellation)
- `ios/Offload/DesignSystem/Components.swift` (add SpringButtonStyle, update shadows)
- `ios/Offload/Data/Repositories/SuggestionRepository.swift` (optimize fetch)
- `ios/Offload/Features/Inbox/CapturesView.swift` (add timeline toggle, fix spacing)
- `ios/Offload/Features/Organize/OrganizeView.swift` (apply glass, badges, spacing)
- `ios/Offload/Features/Organize/PlanDetailView.swift` (apply badges, spacing)
- `ios/Offload/Features/Organize/ListDetailView.swift` (apply badges, spacing)
- `ios/Offload/Features/Settings/SettingsView.swift` (add ADHD settings section)
- `ios/Offload/MainTabView.swift` (apply glass to FAB, update shadows)

### Lines Changed Estimate
- **New code:** ~1200 lines (components, timeline, animations)
- **Modified code:** ~500 lines (theme updates, glass effects, spacing fixes)
- **Removed code:** ~100 lines (duplicate badge implementations, old spacing)
- **Net change:** ~1600 lines

---

## Appendix C: Testing Checklist (Comprehensive)

### Phase 1: Remediation Testing

#### Critical Bug Verification
- [ ] Toast cancellation works correctly
- [ ] No race conditions in delete operations
- [ ] All 21 error suppression fixes work
- [ ] Repository queries use predicates
- [ ] Relationships properly declared
- [ ] No force unwraps crash
- [ ] MainActor synchronization correct
- [ ] Input validation prevents MITM

#### Performance Validation
- [ ] Query benchmarks at 100 records
- [ ] Query benchmarks at 1000 records
- [ ] Query benchmarks at 10000 records
- [ ] Memory usage during bulk ops
- [ ] No memory leaks detected

---

### Phase 2: UI Foundation Testing

#### Visual Consistency
- [ ] Light mode: All screens
- [ ] Dark mode: All screens
- [ ] Glass effects visible but subtle
- [ ] Corner radius consistent
- [ ] Spacing consistent (no hardcoded values)
- [ ] Shadows provide depth
- [ ] Gradients render correctly

#### Responsiveness
- [ ] iPhone SE (small screen)
- [ ] iPhone 14/15 Pro (standard)
- [ ] iPhone 15 Pro Max (large)
- [ ] Portrait orientation
- [ ] Landscape orientation (if supported)

---

### Phase 3: Component Testing

#### Badge Component
- [ ] Category badges render correctly
- [ ] Status badges show correct colors
- [ ] Icons display when provided
- [ ] Text truncates gracefully
- [ ] Tappable area sufficient (44pt)

#### Expandable Card
- [ ] Tap to expand works
- [ ] Animation is smooth
- [ ] Collapsed state shows preview
- [ ] Expanded state shows full content
- [ ] No layout jumping

#### Other Components
- [ ] Pill selector scrolls horizontally
- [ ] Progress ring animates smoothly
- [ ] Loading skeletons shimmer
- [ ] All components respect color scheme

---

### Phase 4: Animation Testing

#### Performance
- [ ] Spring animations at 60fps
- [ ] No frame drops on button press
- [ ] Celebration animations smooth
- [ ] Glass effects don't degrade scrolling

#### Accessibility
- [ ] Reduced motion respected
- [ ] Animations can be disabled
- [ ] No flashing content (seizure risk)

---

### Phase 5: ADHD Feature Testing

#### Visual Timeline
- [ ] Renders 0 captures correctly
- [ ] Renders 50 captures correctly
- [ ] Renders 100+ captures correctly
- [ ] Scrolling is smooth
- [ ] Tap to view capture works
- [ ] Color coding is clear
- [ ] Time labels are readable

#### Cognitive Load Assessment
- [ ] Timeline reduces time blindness (user feedback)
- [ ] Next up indicators not anxiety-inducing
- [ ] Completion animations feel rewarding
- [ ] Settings allow customization
- [ ] Features can be turned off

---

### Phase 6: Accessibility Testing

#### VoiceOver
- [ ] All screens navigable
- [ ] All buttons have labels
- [ ] Form inputs announced correctly
- [ ] Lists read items correctly
- [ ] Modals announced properly

#### Contrast
- [ ] Text on backgrounds meets WCAG AA
- [ ] Badge colors meet requirements
- [ ] Glass effects don't obscure text
- [ ] Focus indicators visible

#### Dynamic Type
- [ ] Small text readable
- [ ] Large text doesn't break layout
- [ ] All font sizes scale correctly

---

### Phase 7: Integration Testing

#### End-to-End Flows
- [ ] Capture → Organize → Complete (full flow)
- [ ] Voice capture → Transcription → Accept
- [ ] Create Plan → Add Tasks → Mark Complete
- [ ] Create List → Add Items → Check Off
- [ ] Settings changes persist

#### Error Handling
- [ ] Network errors display correctly
- [ ] Validation errors show inline
- [ ] Toast notifications appear/dismiss
- [ ] Retry actions work
- [ ] Data rollback on error works

---

## Appendix D: Code Review Checklist

### Pre-Merge Requirements

#### Code Quality
- [ ] No force unwraps on dynamic values
- [ ] No `try?` without justification
- [ ] All TODOs addressed or tracked
- [ ] No debug print statements
- [ ] Logging uses AppLogger

#### Performance
- [ ] No N+1 queries
- [ ] Async operations properly isolated
- [ ] No main thread blocking
- [ ] Memory leaks addressed

#### Design System Compliance
- [ ] Uses Theme.Colors
- [ ] Uses Theme.Spacing
- [ ] Uses Theme.Typography
- [ ] Uses Theme.CornerRadius
- [ ] No hardcoded magic numbers

#### Testing
- [ ] Unit tests added for new code
- [ ] Integration tests updated
- [ ] Manual testing completed
- [ ] Performance impact assessed

#### Documentation
- [ ] Code comments for complex logic
- [ ] Intent comments at file level
- [ ] README updated if needed
- [ ] ADR created for major decisions

---

## Appendix E: Quick Reference

### Key Contacts
- **Project Lead:** TBD
- **iOS Developer:** TBD
- **UI/UX Designer:** TBD
- **QA Engineer:** TBD

### Important Links
- [Remediation Plan](./remediation-plan.md)
- [Remediation Tracking](./remediation-tracking.md)
- [UI Trends Research](../research/ios-ui-trends-2025.md)
- [ADHD UX Guardrails](../decisions/ADR-0003-adhd-ux-guardrails.md)

### Command Reference
```bash
# Find remaining issues
grep -r "try?" ios/Offload --include="*.swift" | grep -v "test"
grep -r "!" ios/Offload --include="*.swift" | grep "URL(string:"
grep -r "\.padding()" ios/Offload --include="*.swift" | grep -v "Theme.Spacing"

# Run tests
xcodebuild test -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 15'

# Performance profiling
instruments -t "Time Profiler" -D trace.trace path/to/Offload.app
```

---

**Document Version:** 1.0
**Last Updated:** January 9, 2026
**Status:** Ready for Review & Approval
**Next Review:** Weekly (every Friday)

---

## Sign-Off

**Phase 1 (Critical Fixes) Approved:**
- [ ] Project Lead: ________________ Date: ________
- [ ] iOS Developer: ________________ Date: ________

**Phase 2-6 (UI/UX) Approved:**
- [ ] Project Lead: ________________ Date: ________
- [ ] UI/UX Designer: ________________ Date: ________

**Timeline Approved:**
- [ ] Project Lead: ________________ Date: ________

**Resource Allocation Approved:**
- [ ] Project Lead: ________________ Date: ________
