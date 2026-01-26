---
id: prd-0009-recurring-task-intelligence
type: product-requirements
status: draft
owners:
  - Will-Conklin
applies_to:
  - product
  - ai
  - organize
last_updated: 2026-01-24
related:
  - adr-0003-adhd-focused-ux-ui-guardrails
  - prd-0001-product-requirements
depends_on:
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
  - docs/prds/prd-0001-product-requirements.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---

# Offload — Recurring Task Intelligence PRD

**Date:** 2026-01-24
**Status:** Draft
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [prd-0001: Product Requirements](prd-0001-product-requirements.md)

---

## 1. Product overview

Recurring Task Intelligence detects natural patterns in completed tasks and
gently suggests (never enforces) when similar tasks might be relevant again.
Unlike traditional recurring task systems that impose rigid schedules, this
feature learns from actual completion behavior and provides context-aware,
shame-free nudges based on the user's real rhythms.

**Key differentiator from traditional task managers:**

- No rigid schedules or forced recurrence
- Learns from actual completion patterns, not user-declared intentions
- Gentle suggestions instead of overdue notifications
- Smart snooze that learns from dismissal patterns
- Zero guilt for skipped or delayed tasks

---

## 2. Problem statement

People struggle with traditional recurring task systems that impose rigid
schedules. When they miss a scheduled task, they feel guilty and overwhelmed.
Yet many tasks do recur naturally (groceries, laundry, medication refills) and
would benefit from gentle reminders based on actual patterns rather than
arbitrary schedules.

**Core user pain:**
> "I know I need to buy groceries every week, but sometimes it's 5 days,
> sometimes it's 10 days. Recurring task apps make me feel like a failure when
> I don't do it 'on schedule.' I need something that notices my patterns without
> judging me."

**Gap in existing productivity tools:**

- Many neurodivergent-focused tools lack calendar or recurrence features
- Traditional task managers use rigid schedules with "overdue" pressure
- Existing tools don't learn from actual completion behavior
- Missing a recurring task creates guilt and notification pile-up

---

## 3. Product goals

- Detect natural recurrence patterns from completed tasks
- Suggest task recurrence based on learned patterns, not rigid schedules
- Provide gentle, shame-free nudges without "overdue" language
- Learn from snooze/dismiss patterns to refine timing
- Support both regular patterns (weekly groceries) and irregular patterns (quarterly tasks)
- Maintain "no guilt, no pressure" principle from ADR-0003
- Give users full control to accept, modify, or ignore suggestions

---

## 4. Non-goals (explicit)

- No rigid recurring task schedules
- No "overdue" indicators or red warnings
- No streak tracking or completion pressure
- No calendar integration or time-based reminders initially
- No automatic task creation without user approval
- No nagging or escalating notifications
- No shared or collaborative recurring tasks

---

## 5. Target audience

- People who struggle with rigid schedules
- Users who have naturally recurring tasks but resist formal scheduling
- Those who feel guilt or shame from traditional recurring task systems
- Users who complete similar tasks irregularly but predictably
- People who want helpful suggestions without pressure

---

## 6. Success metrics (after deployment)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-900 | % of users with detected patterns | TBD | ≥40% | Pattern detection events |
| M-901 | % of pattern suggestions accepted | TBD | ≥50% | Suggestion acceptance rate |
| M-902 | Average time between pattern detection and task completion | TBD | <3 days | Timing analysis |
| M-903 | User satisfaction with suggestion timing | TBD | ≥4.3/5 | In-app survey |
| M-904 | % of suggestions snoozed (lower is better) | TBD | <25% | Snooze rate |
| M-905 | % of users who report feeling guilty from suggestions | TBD | <5% | User surveys |

---

## 7. Core user flows

### 7.1 Pattern detection and first suggestion

1. User has completed "Buy groceries" task 4 times over past 30 days
2. System detects pattern: ~7 day intervals (range: 5-9 days)
3. 6 days after last completion, gentle suggestion appears in Capture view:
   "You usually buy groceries around this time. Want to add it to your list?"
4. User can:
   - Accept (creates new item)
   - Snooze (ask again in 2 days)
   - Dismiss (not this time)
   - Never suggest this pattern (opts out permanently)
5. If accepted, new "Buy groceries" item created in Capture

### 7.2 Learning from dismissal patterns

1. User dismisses "Buy groceries" suggestion
2. User completes "Buy groceries" 3 days later
3. System learns: user's actual interval was 9 days, not 6
4. Next suggestion appears at 8-9 day mark instead of 6
5. Over time, confidence interval narrows to user's actual rhythm

### 7.3 Irregular pattern detection

1. User completes "Renew car registration" once
2. 11 months later, system suggests: "It's been about a year since you renewed
   car registration. Might be time again?"
3. Confidence indicator shows "low confidence - only happened once before"
4. User can accept, provide context ("Actually it's every 2 years"), or dismiss

### 7.4 Pattern refinement

1. User sees pattern suggestion
2. User taps "Edit pattern" instead of accept/dismiss
3. UI shows detected interval and confidence
4. User can:
   - Adjust interval ("Actually it's every 10-14 days, not weekly")
   - Add context ("Only in winter" or "Only when I run out")
   - Disable pattern entirely
5. System learns from adjustment and applies to future suggestions

### 7.5 Viewing all patterns

1. User navigates to Settings → Task Patterns
2. Sees list of detected patterns with:
   - Task name
   - Average interval
   - Last completed date
   - Next suggestion date (if active)
   - Confidence level
3. Can edit, disable, or manually trigger any pattern

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-900 | Detect patterns from completed task history (min 3 completions) | Must | US-900 |
| FR-901 | Calculate average interval and confidence range | Must | US-901 |
| FR-902 | Surface gentle suggestions at learned intervals | Must | US-902 |
| FR-903 | Provide accept, snooze, dismiss, and opt-out options | Must | US-903 |
| FR-904 | Learn from snooze/dismiss timing to refine intervals | Must | US-904 |
| FR-905 | Support both regular (weekly) and irregular (yearly) patterns | Should | US-905 |
| FR-906 | Allow manual pattern refinement (edit intervals) | Should | US-906 |
| FR-907 | Show all detected patterns in Settings | Should | US-907 |
| FR-908 | Display confidence level for pattern suggestions | Should | US-908 |
| FR-909 | Support manual triggering of pattern suggestions | Could | US-909 |
| FR-910 | Detect seasonal or contextual patterns | Could | US-910 |
| FR-911 | Pattern sharing between users | Won't | - |
| FR-912 | Time-based reminders or notifications | Won't | - |

---

## 9. Pricing & limits (hybrid model)

Pricing and limits are deferred; see
[prd-0013: Pricing and Limits](prd-0013-pricing-limits.md).

---

## 10. AI & backend requirements

### On-device processing (Phase 1)

- Pattern detection algorithm analyzing completion timestamps
- Statistical analysis for interval calculation and confidence ranges
- Simple machine learning for refinement from user behavior
- No external API calls required

### Cloud-based enhancements (Phase 2+ - Optional)

- More sophisticated pattern recognition (seasonal, contextual)
- Cross-user pattern insights (anonymized)
- Predictive modeling for irregular tasks
- Natural language pattern descriptions

### Privacy requirements

- All pattern detection happens on-device
- Completion history never leaves device
- If cloud features opt-in, only anonymized aggregate data shared
- User can delete all pattern data at any time

---

## 11. Data model

### New models

#### TaskPattern

- `id: UUID` - Unique identifier
- `taskSignature: String` - Normalized task description (for matching)
- `completionHistory: [Date]` - Timestamps of completions
- `averageInterval: TimeInterval` - Mean time between completions
- `intervalRange: ClosedRange<TimeInterval>` - Min and max observed intervals
- `confidence: Float` - Confidence in pattern (0-1), based on consistency
- `nextSuggestedDate: Date` - When to show next suggestion
- `isActive: Bool` - User can disable pattern
- `userAdjustments: [PatternAdjustment]` - Manual refinements
- `dismissalHistory: [DismissalEvent]` - Track snoozes and dismissals for learning
- `createdAt: Date` - When pattern first detected
- `updatedAt: Date` - Last calculation update

#### PatternAdjustment (Codable)

- `timestamp: Date` - When adjustment made
- `adjustmentType: AdjustmentType` - interval, context, disable
- `oldValue: String?` - Previous value
- `newValue: String` - New value
- `rationale: String?` - User-provided reason

#### AdjustmentType (Enum)

- `interval` - Changed expected recurrence timing
- `context` - Added conditional context
- `disable` - Turned off pattern
- `enable` - Re-enabled pattern

#### DismissalEvent (Codable)

- `timestamp: Date` - When dismissed or snoozed
- `eventType: DismissalType` - snoozed, dismissed, opted_out
- `actualCompletionDate: Date?` - If user completed task after dismissal
- `daysDifference: Int?` - Difference from suggested date

#### DismissalType (Enum)

- `snoozed` - Ask again later
- `dismissed` - Not this time
- `opted_out` - Never suggest this pattern

#### SuggestionEvent (Codable)

- `patternId: UUID` - Which pattern triggered suggestion
- `suggestedDate: Date` - When suggestion shown
- `userResponse: SuggestionResponse` - What user did
- `createdItemId: UUID?` - If accepted, the created item

#### SuggestionResponse (Enum)

- `accepted` - Created item from suggestion
- `snoozed` - Delayed suggestion
- `dismissed` - Ignored suggestion
- `opted_out` - Disabled pattern
- `no_response` - Suggestion expired without interaction

### Existing model changes

#### Item

- `sourcePattern: UUID?` - Link to TaskPattern if created from suggestion
- `completedAt: Date?` - Track completion for pattern detection

#### Collection

- No changes required

---

## 12. UX & tone requirements

### Visual design

- Pattern suggestions appear as gentle, dismissible cards in Capture view
- Not modal, not intrusive—just a suggestion among captures
- Confidence indicator as subtle visual element (not numerical percentage)
  - High confidence: Solid icon
  - Medium confidence: Outlined icon
  - Low confidence: Dotted icon with "First time suggesting this"
- Suggestion cards use calm colors (not attention-grabbing red/orange)
- Snooze action shows next suggestion date
- Pattern list in Settings shows visual timeline of completions

### Tone & messaging

- **Gentle, never demanding:** "You usually [task] around this time" not "Time to [task]!"
- **No guilt:** "Want to add it to your list?" not "You should do this"
- **Acknowledging uncertainty:** "Based on your pattern..." not "You must..."
- **Respecting dismissal:** "No problem, I'll check again later" not "Reminder postponed"
- **Learning language:** "I noticed you did this X days later than I suggested—I'll adjust"
- **No "overdue":** Never use words like late, behind, overdue, missed
- **Celebration without pressure:** "Nice! I'll remember this for next time"

### Example suggestion messages

**High confidence (weekly groceries):**
> "You usually buy groceries around this time. Want to add it to your list?"

**Medium confidence (monthly task):**
> "It's been about 3 weeks since you [task]. Might be time again?"

**Low confidence (first repeat):**
> "It's been about a year since you renewed car registration. Might be time
> again? (This is my first time suggesting this, so I might be off)"

**After dismissal learning:**
> "I suggested this a few days ago, but you did it today instead. I'll remember
> that you prefer a longer interval."

### Interaction patterns

- Suggestion cards can be swiped away (dismiss)
- Tap suggestion to see full pattern details and options
- Snooze offers smart defaults: "Ask me in 2 days" or custom date
- Accept creates item immediately with optional customization
- Opt-out is available but requires confirmation to prevent accidental taps
- All suggestions auto-dismiss after 7 days if no response

### Accessibility

- VoiceOver clearly describes suggestion vs regular item
- Haptic feedback on accept (gentle success haptic)
- Sufficient contrast for confidence indicators
- Large touch targets for accept/snooze/dismiss
- Keyboard navigation for all suggestion interactions

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Pattern detection too aggressive, annoying users | H | Require minimum 3 completions; easy opt-out; learn from dismissals |
| Suggestions feel like pressure, contradicting "no guilt" goal | H | Careful tone and messaging; extensive ADHD user testing; anonymous feedback |
| Pattern matching too loose, suggests wrong tasks | M | Use task signature normalization; show confidence; easy dismissal |
| Users never complete tasks, so no patterns detected | M | Feature is optional; value proposition clear for those who do complete tasks |
| Privacy concerns about tracking completion behavior | M | Clear on-device messaging; no external data sharing; user-controlled deletion |
| Feature complexity adds cognitive load | M | Suggestions are passive, never interrupt; can disable entirely in Settings |
| Users rely on suggestions and miss tasks without them | L | Suggestions are supplements, not reminders; educate on feature purpose |

---

## 14. Implementation tracking

### Dependencies

- Item completion tracking (need `completedAt` timestamp)
- Pattern detection algorithm
- Suggestion display UI in Capture view
- Learning system for refinement from user behavior
- Settings UI for pattern management

### Related features

- Complements existing capture and organization workflows
- May inform future scheduling or planning features
- Could integrate with future notification system (opt-in)

### Complexity estimate

- **Medium complexity** for pattern detection algorithm
- **Low complexity** for basic UI
- Estimated 2-3 week implementation
- Additional 1-2 weeks for learning refinements and Settings UI

### Testing requirements

- Pattern detection accuracy testing with diverse completion histories
- Edge case testing (irregular patterns, single completions, gaps)
- Performance testing for pattern calculation on large datasets
- Tone and messaging testing with diverse user group
- A/B testing of suggestion messaging to minimize guilt response
- Accessibility testing for all suggestion interactions

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Minimum completions to detect pattern (3, 4, or 5?) | Product | Open | Lower = more suggestions (possibly annoying); higher = fewer false positives |
| Should suggestions appear as notifications or in-app only? | Product | Deferred | Notifications risky for "no pressure" goal; defer to future iteration |
| How to handle tasks that change over time (e.g., "Buy groceries" vs "Restock kitchen")? | Engineering | Open | Need task signature normalization strategy |
| Show all suggestions in one place vs scattered among captures? | Design | Open | Pros/cons of dedicated "Suggestions" view vs inline |
| Support for conditional patterns (e.g., "Only in winter")? | Product | Deferred | Interesting but complex; defer to Phase 2 |
| Integration with future calendar features | Product | Deferred | If calendar added, patterns could inform it |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | 2026-01-24 | Initial draft based on user research |
