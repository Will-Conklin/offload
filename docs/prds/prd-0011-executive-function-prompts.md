---
id: prd-0011-executive-function-prompts
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
  - prd-0007-smart-task-breakdown
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---

# Offload — Executive Function Prompts PRD

**Version:** 1.0
**Date:** 2026-01-24
**Status:** Draft
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [prd-0001: V1 Product Requirements](prd-0001-product-requirements.md)

**Related PRDs:**

- [prd-0007: Smart Task Breakdown](prd-0007-smart-task-breakdown.md)

---

## 1. Product overview

Executive Function Prompts provides contextual guidance when users feel stuck,
overwhelmed, or don't know how to proceed with a task. Instead of generic
productivity advice, this feature asks clarifying questions and offers
personalized micro-strategies based on the specific challenge the user is
facing (task initiation, decision paralysis, time blindness, etc.).

**Key differentiator from Goblin Tools:**

- Addresses the "general questions about how to exist" gap identified by users
- Context-aware guidance based on user's current state and task
- Interactive dialogue, not just one-shot answers
- Learns from user's successful strategies over time
- Integrated with Offload's task and capture data for personalized help

---

## 2. Problem statement

People with executive dysfunction experience recurring challenges that generic
productivity tools don't address: "I don't know where to start," "This feels
overwhelming," "I can't figure out how long this will take," "I'm stuck and
can't make myself do this." These are executive function challenges, not
motivation issues, and they benefit from specific prompting and scaffolding.

**Core user pain:**
> "I'm staring at 'Clean the apartment' and I just... can't. I know what needs
> doing but my brain won't let me start. I need someone to just tell me the
> literal first step, like 'put on your shoes and grab a trash bag.'"

**Gap in existing tools (Goblin Tools):**

- Tools focus on task decomposition but not on the emotional/cognitive blocks
- No support for the "I don't even know what to ask for help with" feeling
- No guided prompting through executive function challenges
- Users noted wanting "specific questions on how to exist" answered

---

## 3. Product goals

- Provide immediate, actionable guidance when users feel stuck
- Detect common executive function challenges (initiation, overwhelm, time blindness)
- Ask clarifying questions to understand the specific block
- Offer micro-strategies and scaffolding tailored to the challenge
- Learn which strategies work for the user over time
- Reduce the activation energy required to start tasks
- Normalize executive dysfunction without pathologizing
- Maintain encouraging, non-judgmental tone

---

## 4. Non-goals (explicit)

- No therapy or mental health diagnosis
- No motivational platitudes ("You can do it!")
- No rigid productivity methodologies (Pomodoro unless user requests)
- No shame or judgment about struggles
- No assumption of neurotypical executive function
- No forced solutions (always offer options)

---

## 5. Target audience

- People with ADHD experiencing task initiation difficulty
- Those with executive dysfunction from any cause
- Users who know what to do but can't start
- People who feel overwhelmed by decision-making
- Those who struggle with time estimation and planning
- Anyone who experiences analysis paralysis

---

## 6. Success metrics (30-day post-launch)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-1100 | % of users who use prompts feature | TBD | ≥30% | Analytics events |
| M-1101 | % of prompted tasks that get started within 1 hour | TBD | ≥55% | Task initiation tracking |
| M-1102 | User satisfaction with prompt helpfulness | TBD | ≥4.5/5 | In-app survey |
| M-1103 | Average prompt interactions per session | TBD | 2-4 | Interaction depth |
| M-1104 | % of users who report reduced task avoidance | TBD | ≥40% | User self-report |
| M-1105 | Strategy reuse rate (using same strategy again) | TBD | ≥35% | Strategy tracking |

---

## 7. Core user flows

### 7.1 "I don't know where to start"

1. User has task "Clean the apartment" and feels stuck
2. User taps "Help me start" action
3. System asks: "What's making this hard right now?"
   - It feels too big
   - I don't have enough time
   - I don't know what order to do things
   - I just can't make myself do it
   - Something else
4. User selects "It feels too big"
5. System offers micro-strategy:
   > "Let's shrink it. What's one tiny visible thing you could do right now—
   > something that takes less than 2 minutes? Maybe just clearing one surface
   > or picking up trash from one room?"
6. User captures micro-task: "Clear coffee table"
7. System: "Perfect. Just that one thing. You can decide what's next after."
8. User completes micro-task and momentum builds

### 7.2 "I'm overwhelmed by everything"

1. User has 15 uncompleted captures and feels paralyzed
2. User taps "I'm overwhelmed" from Capture view
3. System asks: "What would help right now?"
   - Pick just one thing for me
   - Hide everything else temporarily
   - Help me sort by what's actually urgent
   - I don't know
4. User selects "Pick just one thing for me"
5. System analyzes captures and suggests:
   > "Based on your patterns, start with 'Call pharmacy for refill'—it's
   > quick, important, and you usually feel relief after handling health stuff."
6. User can accept suggestion or ask for different recommendation
7. Other captures temporarily hidden until task complete

### 7.3 "How long will this actually take?"

1. User has task "Prepare presentation" with no time sense
2. User taps "Help me estimate time"
3. System asks clarifying questions:
   - Have you done this before?
   - How complex is this presentation?
   - Are you starting from scratch or using a template?
4. User answers questions
5. System provides range estimate with buffer:
   > "Based on similar tasks you've done, probably 2-3 hours. But build in an
   > extra hour for unexpected formatting issues—you mentioned those happen a lot."
6. System suggests time-boxing strategy if user interested
7. User can save estimate to task

### 7.4 "I can't decide what to do"

1. User has captured multiple competing priorities
2. User taps "Help me decide" from selection
3. System asks: "What matters most today?"
   - Get something done that's been bothering me
   - Handle the most urgent thing
   - Build momentum with something easy
   - Work on what I have energy for right now
4. User selects "Build momentum with something easy"
5. System filters and suggests 2-3 easy wins
6. User picks one and starts

### 7.5 Learning from successful strategies

1. User uses "Help me start" and completes micro-task successfully
2. System notices completion and asks:
   > "You started by just clearing the coffee table. Did that help you keep going?"
3. User confirms yes
4. System saves strategy: "Start with visible micro-task" for cleaning tasks
5. Next time user faces similar task, system proactively suggests:
   > "Last time you cleaned, starting with one small visible thing helped. Want
   > to try that again?"

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-1100 | Provide "Help me start" action for tasks | Must | US-1100 |
| FR-1101 | Detect common executive function challenges (initiation, overwhelm, time, decision) | Must | US-1101 |
| FR-1102 | Ask clarifying questions to understand specific block | Must | US-1102 |
| FR-1103 | Offer personalized micro-strategies based on challenge type | Must | US-1103 |
| FR-1104 | Support "I'm overwhelmed" mode to simplify view | Must | US-1104 |
| FR-1105 | Provide time estimation help with contextual questions | Should | US-1105 |
| FR-1106 | Track which strategies lead to task completion | Should | US-1106 |
| FR-1107 | Learn and suggest previously successful strategies | Should | US-1107 |
| FR-1108 | Offer decision support for competing priorities | Should | US-1108 |
| FR-1109 | Allow user to save favorite strategies | Could | US-1109 |
| FR-1110 | Provide "unstuck" prompts during long idle periods | Could | US-1110 |
| FR-1111 | Share strategies with other users | Won't | - |
| FR-1112 | Push notifications for prompts | Won't | - |

---

## 9. Pricing & limits (hybrid model)

### Free tier

- 10 prompt sessions per month
- Basic challenge types (initiation, overwhelm)
- Manual strategy invocation

### Paid tier

- Unlimited prompt sessions
- Advanced challenge types (decision, time, energy)
- Automatic strategy learning and suggestions
- Historical strategy analytics
- Priority response times

**Rationale:** Executive function support is core to the neurodivergent value
proposition. Free tier provides essential scaffolding; paid tier for users who
rely heavily on prompting support.

---

## 10. AI & backend requirements

### On-device AI (Phase 1 - Offline)

- Natural language understanding for clarifying questions
- Context analysis to detect challenge type from task and user state
- Strategy recommendation based on rules and learned patterns
- Personalization from tracked completions
- No internet required for core functionality

### Backend AI (Phase 2+ - Optional)

- More sophisticated strategy recommendations from LLM
- Cross-user pattern insights (anonymized)
- Advanced time estimation using project decomposition
- Natural conversation flow improvements

### Privacy requirements

- All prompt interactions happen on-device by default
- Task content never sent to cloud without explicit opt-in
- Strategy learning stored locally in SwiftData
- No tracking of emotional states or mental health data

---

## 11. Data model

### New models

#### PromptSession

- `id: UUID` - Unique identifier
- `taskId: UUID?` - Related task if applicable
- `challengeType: ChallengeType` - What user struggled with
- `clarifyingQuestions: [QuestionAnswer]` - Dialogue history
- `strategySuggested: String` - What guidance was provided
- `strategyAccepted: Bool` - Whether user followed suggestion
- `outcomeSuccess: Bool?` - If task was completed after prompt
- `completionDelay: TimeInterval?` - Time from prompt to completion
- `userFeedback: PromptFeedback?` - User rating of helpfulness
- `createdAt: Date` - When session started

#### ChallengeType (Enum)

- `initiation` - Can't start task
- `overwhelm` - Too many things, paralyzed
- `timeBlindness` - Can't estimate duration
- `decision` - Can't choose what to do
- `energy` - Low capacity, need right-sized task
- `order` - Don't know sequence of steps
- `unknown` - User isn't sure what the block is

#### QuestionAnswer (Codable)

- `question: String` - System question
- `answer: String` - User response
- `timestamp: Date` - When answered

#### PromptFeedback (Codable)

- `helpful: Bool` - Did the prompt help?
- `rating: Int?` - 1-5 optional rating
- `comment: String?` - Optional user notes

#### SuccessfulStrategy

- `id: UUID` - Unique identifier
- `challengeType: ChallengeType` - What it helps with
- `strategyDescription: String` - What to do
- `taskPattern: String?` - Type of task this works for
- `timesUsed: Int` - How often applied
- `successRate: Float` - % of times it led to completion
- `lastUsed: Date?` - Most recent application
- `createdAt: Date` - When first identified

### Existing model changes

#### Item

- `promptSessionIds: [UUID]?` - Links to PromptSession records
- No required changes, sessions tracked separately

---

## 12. UX & tone requirements

### Visual design

- Prompt entry point as calm, inviting button (not emergency-feeling)
- Challenge type selector uses cards with clear icons and descriptions
- Conversational UI for clarifying questions (chat-like bubbles)
- Strategy suggestions in highlighted, easy-to-read cards
- Progress indicator for multi-step prompts
- Success confirmation after task completion tied to prompt

### Tone & messaging

- **Normalizing, not pathologizing:** "This is a really common challenge" vs "You have a problem"
- **Concrete, not abstract:** "Clear one surface" vs "Start small"
- **Collaborative:** "Let's figure this out together" not "Here's what you should do"
- **Non-judgmental:** Never imply task avoidance is laziness or lack of willpower
- **Empowering:** Emphasize user's agency and past successes
- **Patient:** No rush, no pressure, user can exit anytime

### Example prompt dialogues

**Initiation challenge:**
> **System:** "What's making this hard to start right now?"
> **User:** "It feels too big"
> **System:** "That makes sense. What if we found just the tiniest first step—
> something you could do in under 2 minutes? What's one small visible thing?"
> **User:** "I could pick up the mugs from my desk"
> **System:** "Perfect. Just that. You can figure out what's next after those
> mugs are in the sink."

**Overwhelm challenge:**
> **System:** "You have 12 things in your inbox and it looks like you're stuck.
> Want me to help you focus on just one thing?"
> **User:** "Yes please"
> **System:** "What would help most right now—tackling something urgent, or
> getting an easy win for momentum?"
> **User:** "Easy win"
> **System:** "Got it. How about 'Order new phone charger'? You can do that in
> 2 minutes and cross it off. The rest can wait."

**Time estimation challenge:**
> **System:** "You're not sure how long 'Tax prep' will take. Have you gathered
> your documents yet?"
> **User:** "No"
> **System:** "Okay, so there's gathering docs, then the actual forms. Doc
> gathering usually takes longer than people think—maybe budget 1-2 hours for
> that first. Then the forms might be another hour. Sound about right?"
> **User:** "Yeah that feels better than 'do taxes' with no time"

### Interaction patterns

- Prompt sessions can be paused and resumed
- User can back up to previous question
- Can exit prompt session anytime without penalty
- Successful strategies saved automatically with opt-out
- Strategy suggestions appear proactively but are dismissible
- Celebration after completion: "You did it! That strategy worked."

### Accessibility

- VoiceOver reads full prompt dialogue with appropriate pausing
- Haptic feedback for successful strategy identification
- High contrast for clarifying questions
- Large touch targets for all response options
- Keyboard navigation through prompt flow

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Prompts feel like therapy/diagnosis, making users uncomfortable | H | Clear messaging this is productivity scaffolding, not mental health care |
| Users feel judged by questions about what's blocking them | H | Extensive tone testing with neurodivergent users; normalize struggles |
| Strategies feel too simplistic or patronizing | M | Concrete and specific, not generic advice; acknowledge user's intelligence |
| Feature increases cognitive load instead of reducing it | H | Simple interaction flow; easy exit; optional feature |
| Privacy concerns about tracking struggles and blocks | M | Clear on-device processing; no mental health data collection |
| Users become dependent on prompts and can't self-advocate | L | Teach strategies, not just provide answers; gradual independence |
| Prompt timing feels intrusive or nagging | M | User-initiated only; no automatic prompts without permission |

---

## 14. Implementation tracking

### Dependencies

- Prompt dialogue system with conversational flow
- Strategy recommendation engine
- Success tracking and learning system
- Integration with task and capture views
- User feedback collection

### Related features

- Complements Smart Task Breakdown (prd-0007)
- May inform future coaching or onboarding features
- Could integrate with future time estimation features

### Complexity estimate

- **Medium-high complexity** due to conversational AI and learning requirements
- Estimated 3-4 week implementation for MVP
- Additional 2 weeks for strategy learning and refinements

### Testing requirements

- Prompt dialogue quality testing with diverse challenges
- Strategy effectiveness validation with real user tasks
- Learning system accuracy for successful strategy identification
- Tone and messaging testing with ADHD/autistic focus groups
- Privacy testing for prompt session data
- Accessibility testing for conversational UI

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Should prompts be purely conversational or include visual guides? | Design | Open | Text may not be enough for some users; consider diagrams/videos |
| Integrate with body doubling or accountability features? | Product | Deferred | Could be powerful but adds scope |
| Allow users to create custom prompt flows? | Product | Open | Power feature but risks complexity |
| Surface when user is stuck based on idle time? | Product | Open | Could be helpful vs intrusive; needs careful testing |
| Include library of common neurodivergent challenges and strategies? | Product | Open | Educational value but risks feeling prescriptive |
| Partner with ADHD coaches for strategy content? | Business | Deferred | Could improve quality but adds dependency |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| 1.0 | 2026-01-24 | Initial draft based on Goblin Tools gap analysis |
