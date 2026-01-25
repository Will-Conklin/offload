---
id: prd-0012-decision-fatigue-reducer
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
  - prd-0011-executive-function-prompts
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---

# Offload — Decision Fatigue Reducer PRD

**Version:** 1.0
**Date:** 2026-01-24
**Status:** Draft
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [prd-0001: V1 Product Requirements](prd-0001-product-requirements.md)

**Related PRDs:**

- [prd-0011: Executive Function Prompts](prd-0011-executive-function-prompts.md)

---

## 1. Product overview

Decision Fatigue Reducer helps users break through analysis paralysis when
facing multiple options or competing priorities. Instead of presenting all
choices equally, this feature asks clarifying questions to understand what
matters most, then recommends 2-3 "good enough" options with brief rationale.
The goal is to reduce decision-making from overwhelming to manageable,
following Offload's "fewer options over many" principle.

**Key differentiator from Goblin Tools' Consultant:**

- Integrated with user's existing captures and priorities
- Learns from user's stated values and past decisions
- Emphasizes "good enough" over perfect choice
- Reduces options to 2-3 instead of analyzing all
- Context-aware based on user's energy and capacity

---

## 2. Problem statement

People with ADHD and executive dysfunction often experience decision paralysis,
especially when every option seems equally valid or when the decision feels
high-stakes. Traditional decision tools present frameworks or pros/cons lists
that require more cognitive work. What users need is someone to just help them
pick something reasonable and move forward.

**Core user pain:**
> "I have 8 things I could work on and I've spent 20 minutes trying to decide
> which one. Now I'm exhausted and haven't done any of them. I just need
> someone to tell me 'do this one' so I can stop thinking about it."

**Gap in existing tools (Goblin Tools):**

- Consultant is standalone, not integrated with task management
- Provides analysis but doesn't reduce options
- Doesn't learn from user's priorities over time
- No support for the "just pick for me" feeling

---

## 3. Product goals

- Reduce cognitive load of choosing between options
- Provide "good enough" recommendations, not perfect solutions
- Limit choices to 2-3 options (never present all options)
- Ask minimal clarifying questions (1-2 max)
- Learn from user's stated priorities and past decisions
- Support both task prioritization and life decisions
- Emphasize that any choice is better than no choice
- Maintain encouraging, pressure-free tone

---

## 4. Non-goals (explicit)

- No complex decision frameworks or matrices
- No lengthy pros/cons analysis
- No assumption that "optimal" decisions exist
- No judgment about decision difficulty
- No life coaching or values clarification exercises
- No tracking of "right" vs "wrong" decisions

---

## 5. Target audience

- People with ADHD who experience analysis paralysis
- Users overwhelmed by competing priorities
- Those who spend excessive time making decisions
- People who seek external validation for choices
- Anyone experiencing decision fatigue from mental overload

---

## 6. Success metrics (30-day post-launch)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-1200 | % of users who use decision support | TBD | ≥25% | Analytics events |
| M-1201 | % of decision sessions that result in task start | TBD | ≥65% | Task initiation tracking |
| M-1202 | Average time from decision request to selection | TBD | <2 min | Session duration |
| M-1203 | User satisfaction with recommendations | TBD | ≥4.2/5 | In-app survey |
| M-1204 | % of users who report reduced decision anxiety | TBD | ≥45% | User self-report |
| M-1205 | Recommendation acceptance rate (chose suggested option) | TBD | ≥60% | Selection tracking |

---

## 7. Core user flows

### 7.1 "Help me choose what to work on"

1. User has 8 items in Capture view, feels stuck
2. User selects multiple items and taps "Help me decide"
3. System asks one clarifying question: "What matters most right now?"
   - Get something done that's been nagging me
   - Make progress on something important
   - Build momentum with something easy
   - Work on whatever I have energy for
4. User selects "Build momentum with something easy"
5. System analyzes selected items and recommends 2 options:
   > **Option 1: Order new phone charger** (5 min, you've been putting this
   > off, easy win)
   >
   > **Option 2: Text Sarah about lunch** (2 min, quick and friendly)
6. User picks Option 1, other items remain for later
7. System: "Great choice. The rest can wait—just focus on this."

### 7.2 "Just pick for me"

1. User has competing priorities and taps "Just pick for me"
2. System skips clarifying questions and immediately recommends:
   > "Start with 'Call pharmacy.' It's time-sensitive, you've done this before,
   > and it'll feel good to have it done."
3. User can accept, reject for different suggestion, or cancel
4. If accepted, item is highlighted and others temporarily dimmed

### 7.3 "Which approach should I take?"

1. User has captured multiple ways to approach a problem:
   - "Apply for new job"
   - "Ask for raise at current job"
   - "Look for freelance work"
2. User selects all three and taps "Help me decide"
3. System asks: "What feels most important?"
   - Stability and security
   - Growth and challenge
   - Flexibility and control
4. User selects "Stability and security"
5. System recommends:
   > **Recommended: Ask for raise at current job**
   > Keeps your current stability while improving income. Less risky than job
   > change. You can always explore other options later if this doesn't work.
   >
   > **Alternative: Look for freelance work**
   > Gives you flexibility to test waters while keeping current job. Lower
   > risk than full job change.
6. User reviews and picks one approach to pursue

### 7.4 Learning from decisions

1. User gets recommendation based on "build momentum" priority
2. User rejects it and asks for different recommendation
3. User selects the alternative suggestion
4. System notes: User prioritized differently than expected
5. Next decision session, system adjusts weighting:
   > "Last time you chose the slightly harder task. Want me to suggest based
   > on that pattern, or stick with easy wins?"

### 7.5 "Break the tie between two options"

1. User has narrowed down to 2 competing options but still can't decide
2. User selects both and taps "Help me pick"
3. System analyzes context (time of day, recent completions, stated priorities)
4. System flips a weighted coin and recommends:
   > "Go with Option A. Here's why: you tend to do better with tasks like this
   > in the afternoon, and you just finished something similar successfully."
5. User accepts and proceeds, relieved to have decision made

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-1200 | Provide decision support for selected items | Must | US-1200 |
| FR-1201 | Ask max 1-2 clarifying questions before recommending | Must | US-1201 |
| FR-1202 | Recommend 2-3 options maximum, never all choices | Must | US-1202 |
| FR-1203 | Provide brief rationale for recommendations | Must | US-1203 |
| FR-1204 | Support "just pick for me" mode with zero questions | Must | US-1204 |
| FR-1205 | Learn from user's priority selections over time | Should | US-1205 |
| FR-1206 | Track which recommendations user accepts vs rejects | Should | US-1206 |
| FR-1207 | Adjust weighting based on user's decision patterns | Should | US-1207 |
| FR-1208 | Support tie-breaking between 2 final options | Should | US-1208 |
| FR-1209 | Temporarily hide non-selected items to reduce distraction | Could | US-1209 |
| FR-1210 | Show decision history and patterns | Could | US-1210 |
| FR-1211 | Multi-criteria decision analysis | Won't | - |
| FR-1212 | Long-term decision tracking and outcomes | Won't | - |

---

## 9. Pricing & limits (hybrid model)

### Free tier

- 10 decision sessions per month
- Basic recommendations (2 options)
- Single clarifying question

### Paid tier

- Unlimited decision sessions
- Advanced recommendations (context-aware, pattern-learning)
- "Just pick for me" instant recommendations
- Decision history and pattern insights
- Custom priority weighting

**Rationale:** Decision support is valuable for critical moments of paralysis.
Free tier provides essential help; paid tier for users who rely on decision
scaffolding regularly.

---

## 10. AI & backend requirements

### On-device AI (Phase 1 - Offline)

- Priority detection from user's selections and stated preferences
- Basic recommendation logic based on task attributes
- Pattern recognition for repeated decision types
- No internet required for core functionality

### Backend AI (Phase 2+ - Optional)

- More sophisticated priority understanding from LLM
- Cross-user decision pattern insights (anonymized)
- Natural language processing for user's priorities
- Advanced context awareness (time, energy, history)

### Privacy requirements

- All decision processing happens on-device by default
- User priorities stored locally in SwiftData
- No sharing of decision content or user choices
- If cloud AI used, decisions encrypted and not retained

---

## 11. Data model

### New models

#### DecisionSession

- `id: UUID` - Unique identifier
- `itemIds: [UUID]` - Items being decided between
- `clarifyingQuestion: String?` - Question asked (if any)
- `userPriority: DecisionPriority?` - User's stated priority
- `recommendedOptions: [RecommendedOption]` - What was suggested
- `userSelection: UUID?` - Which option user chose
- `selectionWasRecommended: Bool` - Did user pick suggested option?
- `skipQuestions: Bool` - "Just pick for me" mode
- `sessionDuration: TimeInterval` - Time to make decision
- `createdAt: Date` - When session started

#### DecisionPriority (Enum)

- `naggerRelief` - Get rid of something bothering me
- `importantProgress` - Make progress on important goal
- `easyMomentum` - Build momentum with easy task
- `energyMatched` - Whatever I have energy for
- `timeSensitive` - Handle urgent/time-sensitive item
- `curiosity` - Work on what interests me right now

#### RecommendedOption (Codable)

- `itemId: UUID` - Which item
- `rank: Int` - 1st, 2nd, or 3rd recommendation
- `rationale: String` - Why this was suggested
- `confidence: Float` - System confidence in suggestion

#### DecisionPattern

- `id: UUID` - Unique identifier
- `priorityType: DecisionPriority` - What user typically values
- `contextPatterns: [String: Any]` - When this priority applies
- `successRate: Float` - % of time this leads to task completion
- `timesObserved: Int` - How many decisions show this pattern
- `lastObserved: Date` - Most recent observation

### Existing model changes

#### Item

- `decisionSessionIds: [UUID]?` - Links to DecisionSession records
- No required changes, sessions tracked separately

---

## 12. UX & tone requirements

### Visual design

- Decision entry point as clear action button when multiple items selected
- Priority selector as large, easy-to-tap cards with icons
- Recommendations shown as distinct cards with rank badges (1st, 2nd)
- Rationale text in friendly, conversational style
- "Just pick for me" as prominent alternative action
- Non-selected items visually dimmed after decision
- Celebration for making decision, not specific choice

### Tone & messaging

- **Normalizing decision difficulty:** "Choosing is hard—that's normal"
- **Emphasizing good enough:** "Any of these is a good choice" not "Here's the best one"
- **Relieving pressure:** "You can't make a wrong choice here"
- **Acknowledging uncertainty:** "I'm making an educated guess based on..."
- **Celebrating decision, not outcome:** "You made a choice! That's the hard part."
- **No second-guessing:** Never ask "Are you sure?" after user picks

### Example recommendation messages

**For momentum-seeking user:**
> **1st: Order new phone charger** (5 min)
> This is super quick and you've been putting it off. Easy win to get you moving.
>
> **2nd: Text Sarah about lunch** (2 min)
> Even faster, and you like connecting with friends. Another quick momentum builder.

**For "just pick for me" mode:**
> **Do this one: Call pharmacy**
> It's time-sensitive, you've done this before, and it'll feel good to have it done.
> The rest can wait.

**For important progress priority:**
> **1st: Outline presentation for Friday**
> This is your most important deadline. Getting the outline done today means less
> stress tomorrow.
>
> **2nd: Review contract for client**
> Also important and time-sensitive, but the presentation feels more urgent.

### Clarifying question examples

- "What matters most right now?"
- "What kind of energy do you have?"
- "What would feel best to accomplish today?"
- "Which of these has been nagging you the most?"

### Interaction patterns

- Decision flow is quick (max 3 taps: action → priority → select)
- Can skip clarifying question with "Just pick for me" at any time
- Can request different recommendation if first doesn't resonate
- Non-selected items remain accessible, just visually de-emphasized
- Undo available: "Changed your mind? Pick something else"
- No penalty for rejecting recommendations

### Accessibility

- VoiceOver reads full rationale for each recommendation
- Haptic feedback for recommendation selection
- High contrast for recommended vs non-recommended items
- Large touch targets for all priority and selection options
- Keyboard navigation through decision flow

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Recommendations feel arbitrary or unhelpful | H | Transparent rationale; learn from rejections; extensive testing |
| Users second-guess AI recommendations, adding anxiety | M | Emphasize "good enough"; celebrate decision regardless of choice |
| Feature becomes crutch, users can't decide without it | L | Frame as scaffolding, not replacement for judgment; gradual independence |
| Priority questions feel like quiz, adding cognitive load | M | Limit to 1-2 questions max; "just pick for me" always available |
| Privacy concerns about tracking decision patterns | M | Clear on-device processing; user controls pattern learning |
| Recommendations too conservative or risk-averse | M | Include stretch options occasionally; learn from user's actual picks |
| Users disagree with recommendation rationale | L | Allow feedback; adjust future recommendations; normalize different preferences |

---

## 14. Implementation tracking

### Dependencies

- Multi-select UI in Capture and Organize views
- Priority understanding and recommendation logic
- Pattern learning from decision history
- Integration with item attributes and user context
- User feedback collection

### Related features

- Complements Executive Function Prompts (prd-0011)
- May inform future prioritization and planning features
- Could integrate with recurring task patterns

### Complexity estimate

- **Medium complexity** for recommendation logic
- **Low complexity** for basic UI
- Estimated 2-3 week implementation for MVP
- Additional 1-2 weeks for pattern learning and refinements

### Testing requirements

- Recommendation quality testing with diverse item sets
- Priority detection accuracy validation
- Pattern learning effectiveness over time
- User satisfaction testing with decision-anxious users
- Accessibility testing for all decision interactions
- A/B testing of clarifying questions to minimize cognitive load

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Should we show confidence scores for recommendations? | Design | Open | Transparency vs additional information to process |
| Include "I'll come back to this" option to defer decision? | Product | Open | Could enable avoidance vs relieve pressure |
| How many past decisions to use for pattern learning? | Engineering | Open | Balance between personalization and recency |
| Support for non-task decisions (e.g., "what to eat")? | Product | Deferred | Interesting but scope expansion; defer to Phase 2 |
| Show other users' anonymous decision patterns? | Product | Open | Could normalize choices vs add comparison pressure |
| Integration with future calendar/scheduling features? | Product | Deferred | Decisions could inform time blocking |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| 1.0 | 2026-01-24 | Initial draft based on Goblin Tools gap analysis |
