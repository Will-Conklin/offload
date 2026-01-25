---
id: prd-0008-brain-dump-compiler
type: product-requirements
status: draft
owners:
  - Offload
applies_to:
  - product
last_updated: 2026-01-24
related:
  - adr-0003-adhd-focused-ux-ui-guardrails
  - prd-0001-product-requirements
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---

# Offload — Brain Dump Compiler Enhancement PRD

**Version:** 1.0
**Date:** 2026-01-24
**Status:** Draft
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [prd-0001: V1 Product Requirements](prd-0001-product-requirements.md)

---

## 1. Product overview

Brain Dump Compiler transforms rambling, stream-of-consciousness captures into
organized, actionable items. This feature enhances Offload's existing text/voice
capture by intelligently detecting and extracting tasks, questions, decisions,
ideas, and concerns from unstructured brain dumps. It then suggests how to
categorize each extracted item (plan, list, or reference) and offers to create
the appropriate structures automatically.

**Key differentiator:** Deeply integrated with Offload's capture-and-organize
workflow, with smart suggestions for which items become plans vs lists, and
automatic creation of Collections based on detected patterns. Unlike standalone
compilation tools, this feature maintains context and enables seamless
organization.

---

## 2. Problem statement

During mental overload, users often capture everything in one long rambling
entry—mixing tasks, worries, ideas, and questions. Later, when organizing, they
face the cognitive burden of re-reading, parsing, and categorizing everything.
This creates a bottleneck between capture and organization.

**Core user pain:**
> "I just dumped everything in my head into one long voice note. Now I have to
> figure out what's actually a task, what's just worry, and what needs follow-up.
> It feels like starting over."

**Gap in existing productivity tools:**

- Brain dump compilers are standalone tools, not integrated with task management
- Output is plain text, requires manual copying and organizing
- Don't suggest categorization (task vs idea vs question)
- No automatic creation of structures from compiled output
- Don't learn from user's organization patterns

---

## 3. Product goals

- Reduce cognitive load of organizing rambling captures
- Automatically detect and extract actionable items from brain dumps
- Categorize extracted items by type (task, question, decision, idea, concern)
- Suggest appropriate organization structures (plans, lists, reference notes)
- Offer one-tap creation of suggested Collections with extracted items
- Learn from user's organization preferences over time
- Maintain user control: suggest, preview, never auto-organize

---

## 4. Non-goals (explicit)

- No automatic organization without user approval
- No rigid categorization rules (user can override AI suggestions)
- No sentiment analysis or emotional content extraction
- No therapy or mental health intervention features
- No automatic deletion of "non-actionable" content
- No forced separation of braindump into multiple items

---

## 5. Target audience

- Users who capture thoughts in long, unstructured bursts
- People who need to externalize thoughts rapidly
- Those who use voice capture extensively and produce lengthy transcriptions
- Users overwhelmed by the organizing phase after capture
- People who mix tasks, ideas, and worries in single capture sessions

---

## 6. Success metrics (30-day post-launch)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-800 | % of captures >100 words that use compiler | TBD | ≥35% | Analytics events |
| M-801 | % of compiled outputs accepted with minimal edits | TBD | ≥60% | Edit tracking |
| M-802 | Average time from capture to organized | TBD | -40% | Task timing analysis |
| M-803 | User satisfaction with categorization accuracy | TBD | ≥4.0/5 | In-app survey |
| M-804 | % of compiled items that result in Collection creation | TBD | ≥45% | Creation events |
| M-805 | Compiler feature awareness | TBD | ≥70% | User surveys |

---

## 7. Core user flows

### 7.1 Compile single brain dump

1. User captures long rambling entry (text or voice): "I need to call the doctor
   about the test results and also remember to pick up milk and I'm worried
   about the presentation on Friday maybe I should outline it tonight or tomorrow
   and did I pay the electric bill I can't remember..."
2. User taps "Compile" action (suggested automatically for captures >75 words)
3. AI analyzes and extracts distinct items with categories:
   - **Task:** Call doctor about test results
   - **Task:** Pick up milk
   - **Task:** Outline Friday presentation
   - **Question:** Did I pay the electric bill?
   - **Concern:** Worried about Friday presentation
4. AI suggests organization:
   - "Health & Errands" list (Call doctor, Pick up milk)
   - "Work - Friday Presentation" plan (Outline presentation, with concern noted)
   - "Follow-up Questions" list (Electric bill payment check)
5. User reviews, edits categories/groupings, and approves
6. Collections created automatically with extracted items linked

### 7.2 Batch compile multiple captures

1. User has accumulated 5-10 short captures over a few hours
2. User selects multiple items in Capture view
3. User taps "Compile selected" from context menu
4. AI analyzes all selected captures as a single context
5. Follows same extraction and organization flow as 7.1
6. Original captures remain intact; compiled items are new Collections

### 7.3 Review and refine compilation

1. After compilation, user sees preview of extracted items and suggested structure
2. User can:
   - Edit item text or category
   - Merge similar items
   - Split items into smaller pieces
   - Reject items (mark as "just venting, not actionable")
   - Change suggested Collections
3. User approves final structure
4. Original capture is optionally archived or tagged as "compiled"

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-800 | Detect captures >75 words and suggest compilation | Must | US-800 |
| FR-801 | Extract distinct items from unstructured text | Must | US-801 |
| FR-802 | Categorize extracted items (task, question, decision, idea, concern) | Must | US-802 |
| FR-803 | Suggest Collection groupings for extracted items | Must | US-803 |
| FR-804 | Show preview of compilation with edit capabilities | Must | US-804 |
| FR-805 | Create Collections automatically from approved compilation | Must | US-805 |
| FR-806 | Support batch compilation of multiple selected captures | Should | US-806 |
| FR-807 | Preserve original capture after compilation | Should | US-807 |
| FR-808 | Learn from user's category and grouping overrides | Should | US-808 |
| FR-809 | Allow merging similar extracted items | Should | US-809 |
| FR-810 | Support marking items as "not actionable" | Could | US-810 |
| FR-811 | Tag original capture as "compiled" with link to results | Could | US-811 |
| FR-812 | Undo compilation and restore to original state | Could | US-812 |

---

## 9. Pricing & limits (hybrid model)

### Free tier

- 5 compilations per month
- Unlimited manual organization
- Basic categorization (task, idea, question)

### Paid tier

- Unlimited compilations
- Advanced categorization (decision, concern, reference, insight)
- Learning from organization patterns
- Batch compilation of multiple captures
- Priority processing

**Rationale:** Compilation is a power feature that requires significant AI
processing. Free tier provides taste of value; paid tier unlocks full utility
for heavy users.

---

## 10. AI & backend requirements

### On-device AI (Phase 1 - Offline)

- Natural language processing for entity extraction
- Sentence boundary detection and topic segmentation
- Categorization model trained on common neurodivergent thought patterns
- Context window sufficient for ~1000 word captures
- Response time <5 seconds for typical brain dump

### Backend AI (Phase 2+ - Optional)

- Cloud-based LLM for higher quality extraction and categorization
- Learning from user's accepted/rejected categorizations
- Pattern recognition for recurring themes and organization preferences
- Support for longer captures (>1000 words)

### Privacy requirements

- All processing happens on-device by default
- No capture content sent to cloud without explicit opt-in
- If cloud AI used, content encrypted in transit and not retained
- Extracted items stored locally in SwiftData only

---

## 11. Data model

### New models

#### CompilationResult

- `id: UUID` - Unique identifier
- `sourceItemIds: [UUID]` - Original capture(s) compiled
- `extractedItems: [ExtractedItem]` - Parsed items with categories
- `suggestedCollections: [SuggestedCollection]` - Recommended groupings
- `userModifications: [UserEdit]` - Track overrides for learning
- `status: CompilationStatus` - draft, approved, rejected
- `createdAt: Date` - Compilation timestamp

#### ExtractedItem (Codable)

- `id: UUID` - Unique identifier
- `text: String` - Item content
- `category: ItemCategory` - task, question, decision, idea, concern, reference
- `confidence: Float` - AI confidence in categorization (0-1)
- `originalContext: String` - Surrounding text from source
- `userOverride: ItemCategory?` - If user changed category

#### ItemCategory (Enum)

- `task` - Actionable to-do
- `question` - Needs answer or follow-up
- `decision` - Choice to be made
- `idea` - Creative thought or suggestion
- `concern` - Worry or anxiety (acknowledged, not necessarily actionable)
- `reference` - Information to remember

#### SuggestedCollection (Codable)

- `name: String` - Suggested collection name
- `isStructured: Bool` - Plan (true) vs list (false)
- `itemIds: [UUID]` - Extracted items to include
- `rationale: String` - Why these items grouped together

#### UserEdit (Codable)

- `itemId: UUID` - Which item was modified
- `editType: EditType` - category_change, merge, split, reject
- `fromValue: String?` - Original value
- `toValue: String?` - New value
- `timestamp: Date` - When edit occurred

#### CompilationStatus (Enum)

- `draft` - User still reviewing
- `approved` - User accepted and Collections created
- `rejected` - User dismissed compilation

### Existing model changes

#### Item

- `compilationId: UUID?` - Link to CompilationResult if item was compiled
- `isCompiled: Bool` - Flag for UI filtering

#### Collection

- `sourceCompilation: UUID?` - Link to CompilationResult if created from compilation

---

## 12. UX & tone requirements

### Visual design

- Compilation preview uses card-based layout with clear category labels
- Category badges use distinct colors:
  - Task: Blue
  - Question: Purple
  - Decision: Orange
  - Idea: Green
  - Concern: Yellow
  - Reference: Gray
- Suggested Collections appear as grouped cards with Collection name headers
- Drag-and-drop support for moving items between suggested Collections
- Clear "Approve" and "Edit more" actions

### Tone & messaging

- **Non-judgmental about content:** Never label concerns as "irrational" or ideas as "unrealistic"
- **Encouraging:** "I found [X] actionable items in your brain dump"
- **Acknowledging mixed content:** "Some of this is tasks, some is just thoughts to acknowledge"
- **User control:** "Review and adjust the categories—I'm just making my best guess"
- **Celebration:** "Nice brain dump! This covers a lot of ground."

### Interaction patterns

- Automatic suggestion for compilation appears as non-intrusive banner
- User can dismiss "Compile?" suggestion and it won't re-appear for that capture
- Preview state allows extensive editing before commitment
- Can save compilation draft and return later
- Undo available for 30 seconds after approval
- Original capture optionally archived (not deleted) after compilation

### Accessibility

- VoiceOver reads category labels clearly
- Color is not the only indicator of category (icons + text)
- Sufficient touch targets for category editing
- Keyboard navigation for all editing actions
- High contrast mode support

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Categorization accuracy too low, users lose trust | H | Extensive training on neurodivergent thought patterns; show confidence scores; easy override |
| Users feel judged by "concern" vs "task" categorization | H | Careful messaging; emphasize concerns are valid; option to disable concern detection |
| Long brain dumps exceed AI processing capacity | M | Chunk long captures into segments; show progress indicator |
| Compilation feels like "extra work" instead of helpful | H | Make preview editing very fast and intuitive; show time savings metrics |
| Feature complexity contradicts "minimal friction" goal | M | Make compilation entirely optional; never interrupt capture flow |
| Privacy concerns about AI reading personal thoughts | H | Clear on-device processing messaging; sensitive content warnings; opt-in cloud |
| Over-extraction creates too many items, overwhelming user | M | Merge similar items automatically; adjustable extraction sensitivity |

---

## 14. Implementation tracking

### Dependencies

- Natural language processing framework for entity extraction
- Categorization model training dataset
- Preview/editing UI for compilation results
- Learning system to track user overrides and improve suggestions
- Batch processing for multiple selected captures

### Related features

- Depends on existing capture system (text and voice)
- Integrates with Collection creation workflows
- May influence future AI organization features

### Complexity estimate

- **High complexity** due to NLP requirements and learning system
- Estimated 4-5 week implementation for MVP
- Additional 2 weeks for batch compilation and learning refinements
- Requires significant testing with diverse brain dump content

### Testing requirements

- Categorization accuracy testing with real user brain dumps
- Edge case testing (very long dumps, short dumps, single topic)
- Performance testing for on-device NLP processing
- Accessibility testing for category editing interactions
- User testing with diverse user group for cognitive load validation
- Privacy testing to ensure no content leakage

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Should "concern" category be surfaced prominently or downplayed? | Product | Open | Risk of making users feel judged vs helping acknowledge worries |
| Automatically archive original capture after compilation? | Product | Open | Pros: cleaner inbox. Cons: loss of original context |
| How to handle brain dumps that are purely emotional venting? | Product | Open | Extract zero items and acknowledge? Suggest journaling feature? |
| Maximum number of extracted items before suggesting split | Engineering | Open | Too many items is overwhelming; what's the threshold? |
| Should compilation learning be explicit or implicit? | Product | Open | Show "I noticed you usually put X in plans" vs silent learning |
| Integration with future journaling or reflection features | Product | Deferred | Concerns/ideas might feed into separate reflection workflows |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| 1.0 | 2026-01-24 | Initial draft based on user research |
