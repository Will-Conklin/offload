---
id: prd-0007-smart-task-breakdown
type: product-requirements
status: draft
owners:
  - Will-Conklin
applies_to:
  - product
  - ai
  - organize
last_updated: 2026-02-15
related:
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0008-backend-api-privacy-mvp
  - prd-0001-product-requirements
depends_on:
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
  - docs/adrs/adr-0008-backend-api-privacy-mvp.md
  - docs/prds/prd-0001-product-requirements.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---

# Offload — Smart Task Breakdown PRD

**Date:** 2026-01-24
**Status:** Draft
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [prd-0001: Product Requirements](prd-0001-product-requirements.md)

---

## 1. Product overview

Smart Task Breakdown transforms overwhelming tasks into manageable step-by-step
plans using AI. Unlike traditional task managers that require users to manually
decompose tasks, this feature intelligently suggests subtasks with adjustable
granularity. Users can save breakdown templates for recurring task types,
creating a personalized library of task patterns that work for their brain.

**Key differentiator:** Breakdown templates persist and can be reused, edited,
and refined over time. The AI learns from user's preferred breakdown patterns,
unlike standalone task decomposition tools.

---

## 2. Problem statement

People often know what needs to be done but feel paralyzed by not knowing where
to start. Breaking down tasks into smaller steps is cognitively expensive and
feels like additional work before the "real" work can begin.

**Core user pain:**
> "I know I need to clean the apartment, but I can't figure out where to start.
> By the time I've thought through all the steps, I'm already exhausted."

**Gap in existing productivity tools:**

- Task breakdown tools don't save custom edits
- Cannot reuse breakdown patterns for similar tasks
- No learning from user preferences over time
- Breakdowns often don't persist after task completion

---

## 3. Product goals

- Reduce the cognitive load of task decomposition
- Enable users to save and reuse breakdown templates for recurring tasks
- Provide adjustable granularity to match current executive function capacity
- Maintain user control: AI suggests, never auto-creates without approval
- Support both one-off breakdowns and template creation
- Work completely offline with on-device AI processing

---

## 4. Non-goals (explicit)

- No automatic task scheduling or calendar integration
- No time-based reminders or notifications
- No collaboration or shared task templates
- No rigid task hierarchies (maintain flexible structure)
- No forced completion of all subtasks to complete parent task
- No gamification, streaks, or completion pressure

---

## 5. Target audience

- Users who struggle with task initiation
- People who know what needs doing but can't break it down into steps
- Those who have recurring tasks (cleaning routines, packing, project workflows)
- Users who want AI assistance without giving up control
- Existing Offload users who capture tasks but struggle to organize them

---

## 6. Success metrics (after deployment)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-700 | % of items that use breakdown | TBD | ≥20% | Analytics events |
| M-701 | % of breakdowns that are saved as templates | TBD | ≥30% | Template creation events |
| M-702 | Template reuse rate | TBD | ≥15% | Template application events |
| M-703 | User satisfaction with breakdown quality | TBD | ≥4.2/5 | In-app survey |
| M-704 | Average time from capture to first subtask completion | TBD | -30% | Task timing analysis |
| M-705 | % of users who customize suggested breakdowns | TBD | ≥40% | Edit events |

---

## 7. Core user flows

### 7.1 One-off task breakdown

1. User has a captured item: "Clean the apartment"
2. User taps breakdown action (from context menu or detail view)
3. User adjusts granularity slider (1-5 detail level)
4. AI generates breakdown as a structured Collection with subtasks
5. User reviews, edits, approves breakdown
6. Item is converted to a Plan with hierarchical subtasks
7. User can check off subtasks as they complete them

### 7.2 Save breakdown as template

1. User completes flow 7.1 and reviews generated breakdown
2. User taps "Save as template"
3. User names template (e.g., "Deep clean routine")
4. Template is saved with pattern matching keywords
5. Future similar tasks suggest: "Apply 'Deep clean routine' template?"

### 7.3 Apply existing template

1. User captures: "Clean before guests arrive"
2. AI recognizes similarity to saved template
3. Suggestion appears: "Apply 'Deep clean routine'?" with preview
4. User taps apply, reviews generated breakdown (customized to context)
5. User edits if needed and approves

### 7.4 Manage templates

1. User navigates to Settings → Task Templates
2. User sees list of saved templates with usage count
3. User can view, edit, delete, or rename templates
4. User can manually apply template to any captured item

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-700 | Provide breakdown action for captured items | Must | US-700 |
| FR-701 | AI generates subtask breakdown with adjustable granularity | Must | US-701 |
| FR-702 | Granularity control (1-5 levels) affects number and detail of subtasks | Must | US-702 |
| FR-703 | User can edit suggested breakdown before accepting | Must | US-703 |
| FR-704 | Breakdown creates structured Collection with hierarchical CollectionItems | Must | US-704 |
| FR-705 | Support saving breakdown as reusable template | Must | US-705 |
| FR-706 | Templates include name and pattern matching keywords | Must | US-706 |
| FR-707 | AI suggests relevant templates for new captures | Should | US-707 |
| FR-708 | User can manually apply template to any item | Should | US-708 |
| FR-709 | Template management UI (view, edit, delete, rename) | Should | US-709 |
| FR-710 | Templates show usage count and last used date | Could | US-710 |
| FR-711 | User can share individual subtasks with others | Won't | - |
| FR-712 | Templates sync across devices | Won't | - |

---

## 9. Pricing & limits (hybrid model)

Pricing and limits are deferred; see
[prd-0013: Pricing and Limits](prd-0013-pricing-limits.md).

---

## 10. AI & backend requirements

### On-device AI (Phase 1 - Offline)

- Use on-device language model for breakdown generation
- Model must understand task decomposition patterns
- Context window sufficient for ~500 words of task description
- Response time <3 seconds for breakdown generation
- Fallback gracefully if AI unavailable

### Backend AI (Phase 2+ - Optional)

- Cloud-based LLM for higher quality breakdowns (opt-in)
- Learning from user's accepted/rejected patterns over time
- Template pattern recognition and suggestion improvements

### Backend MVP contract (Breakdown-first)

- Backend stack: Python + FastAPI.
- Identity model: anonymous device session token from
  `POST /v1/sessions/anonymous`.
- Breakdown endpoint contract: `POST /v1/ai/breakdown/generate`.
- Usage reconcile contract: `POST /v1/usage/reconcile`.
- Provider strategy: single provider (OpenAI) behind backend adapter.
- Session token required for `/v1/ai/*` and `/v1/usage/*`.

### Privacy requirements

- All processing happens on-device by default
- No task content sent to cloud without explicit user opt-in
- Templates stored locally in SwiftData
- If cloud AI used, task content encrypted in transit and not retained
- Backend must not persist prompt/response content to durable storage.

---

## 11. Data model

### New models

#### BreakdownTemplate

- `id: UUID` - Unique identifier
- `name: String` - User-defined template name
- `keywords: [String]` - Pattern matching keywords
- `defaultGranularity: Int` - Preferred detail level (1-5)
- `structure: BreakdownStructure` - Template structure
- `usageCount: Int` - Number of times applied
- `lastUsed: Date?` - Last application timestamp
- `createdAt: Date` - Creation timestamp
- `updatedAt: Date` - Last modification timestamp

#### BreakdownStructure (Codable)

- `steps: [BreakdownStep]` - Ordered list of steps
- `isHierarchical: Bool` - Whether steps have substeps

#### BreakdownStep (Codable)

- `title: String` - Step description
- `substeps: [BreakdownStep]?` - Optional nested steps
- `estimatedDuration: TimeInterval?` - Optional time estimate

### Existing model changes

#### Item

- No changes required

#### Collection

- `sourceTemplate: UUID?` - Optional reference to template used
- Existing `isStructured: Bool` already supports plans vs lists

#### CollectionItem

- Existing `parentId`, `position` already support hierarchy
- No changes required

---

## 12. UX & tone requirements

### Visual design

- Granularity slider with clear labels:
  - 1: "Just the main steps"
  - 2: "Moderate detail"
  - 3: "Step by step"
  - 4: "Very detailed"
  - 5: "Tiny micro-steps"
- Preview breakdown before accepting (scrollable list)
- Edit inline with drag-to-reorder support
- Template suggestions appear as non-intrusive cards, not modals

### Tone & messaging

- **Encouraging, not prescriptive:** "Here's one way to break this down" vs "You should do these steps"
- **No judgment:** Never imply the task is "easy" or "simple"
- **User control emphasized:** "Review and adjust" vs "Accept"
- **Celebrate template reuse:** "You've used this pattern before—want to apply it again?"

### Interaction patterns

- Breakdown action available from:
  - Item detail view (prominent button)
  - Long-press context menu on item
  - Swipe action in Capture view
- Template application is always optional and preview-able
- Can dismiss breakdown and return to original captured item
- Undo support for accepting breakdown

### Accessibility

- VoiceOver descriptions for granularity levels
- Haptic feedback at granularity extremes (1 and 5)
- Sufficient contrast for preview vs accepted state
- Keyboard navigation for editing breakdown steps

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| On-device AI quality not good enough | H | Extensive testing with real user tasks; fallback to cloud AI as opt-in |
| Users overwhelmed by breakdown options | M | Default to mid-level granularity; remember last used setting per user |
| Templates become stale or irrelevant | M | Show last used date; prompt to archive unused templates after 90 days |
| Generated breakdowns feel generic or unhelpful | H | Allow editing before accepting; learn from user modifications over time |
| Template matching suggests wrong templates | M | Show confidence score; allow "not this time" option without dismissing forever |
| Privacy concerns about AI processing task content | H | Clear messaging about on-device processing; explicit opt-in for cloud AI |
| Feature complexity contradicts "minimal friction" goal | M | Make breakdown optional, never default; extensive UX testing with target users |

---

## 14. Implementation tracking

### Dependencies

- On-device AI framework selection and integration
- Template storage and retrieval system in SwiftData
- Pattern matching algorithm for template suggestion
- Hierarchical CollectionItem creation from breakdown structure

### Complexity estimate

- **High complexity** due to AI integration and template matching logic
- Estimated 3-4 week implementation
- Additional 2 weeks for template management UI and refinement

### Testing requirements

- AI breakdown quality testing with diverse task types
- Template pattern matching accuracy testing
- Performance testing for on-device AI response times
- Accessibility testing for all breakdown interactions
- User testing with diverse user group for cognitive load validation

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| On-device AI model selection (Core ML, other) | Engineering | Open | Need to evaluate available models for task decomposition quality |
| Should templates include estimated time per step? | Product | Open | Helpful but may add pressure; conflicts with "no time pressure" principle |
| Template sharing between users | Product | Deferred | Community templates could be valuable but adds complexity |
| How to handle template versioning when user edits | Engineering | Open | Allow template updates vs create new template from edited breakdown |
| Maximum subtask depth in hierarchy | Product | Open | Unlimited depth may be overwhelming; consider 2-3 level maximum |
| Should breakdown consider user's current context (time of day, energy)? | Product | Deferred | Interesting but complex; defer to future iteration |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | 2026-01-24 | Initial draft based on user research |
| N/A | 2026-02-15 | Added backend MVP contract and privacy retention constraints for breakdown-first cloud fallback. |
