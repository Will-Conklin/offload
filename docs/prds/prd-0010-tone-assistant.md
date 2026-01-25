---
id: prd-0010-tone-assistant
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

# Offload — Tone Assistant PRD

**Version:** 1.0
**Date:** 2026-01-24
**Status:** Draft
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [prd-0001: V1 Product Requirements](prd-0001-product-requirements.md)

---

## 1. Product overview

Tone Assistant helps users transform raw captured thoughts into appropriately
toned communication for different contexts. Whether turning a frustrated brain
dump into a professional email, a scattered idea into a clear message, or an
anxious ramble into a concise text, this feature bridges the gap between
authentic internal voice and socially expected communication.

**Key differentiator from Goblin Tools' Formalizer:**

- Integrated with Offload's capture workflow (not standalone tool)
- Multiple tone options beyond formal (friendly, concise, empathetic, direct)
- Preview and iterate before committing
- Save tone presets for frequently-used communication styles
- Works on captured items, maintaining privacy and context

---

## 2. Problem statement

Neurodivergent individuals often struggle with code-switching between their
authentic internal voice and socially expected communication styles. Writing
professional emails, texts to authority figures, or even friendly messages can
be paralyzing when unsure of the "right" tone. This leads to avoidance,
over-editing, or miscommunication.

**Core user pain:**
> "I know what I want to say, but I can't figure out how to say it
> professionally without sounding stiff or rude. I spend 30 minutes rewriting
> a 3-sentence email."

**Gap in existing tools (Goblin Tools):**

- Formalizer is standalone, requires copy-paste workflow
- Limited tone options (just formality levels)
- No integration with task/capture workflow
- No ability to save preferences or iterate on transformations
- Output is plain text with no further action

---

## 3. Product goals

- Reduce anxiety around written communication
- Transform captured thoughts into context-appropriate messages
- Provide multiple tone options (formal, friendly, concise, empathetic, direct)
- Enable preview and iteration before sharing
- Support saving tone presets for recurring communication needs
- Integrate with share/copy workflows for easy sending
- Maintain user's original voice while adapting tone
- Work offline with on-device processing for privacy

---

## 4. Non-goals (explicit)

- No automatic sending or sharing (user always controls)
- No grammar/spelling checking (tone only)
- No real-time writing assistance (operates on completed captures)
- No analysis of received messages (outbound communication only)
- No language translation
- No sentiment manipulation (maintains user's intent)

---

## 5. Target audience

- Autistic individuals who struggle with social communication expectations
- People with ADHD who write stream-of-consciousness and need structure
- Anyone with communication anxiety
- Users who overthink message tone and spend excessive time editing
- People who mask heavily and need help with code-switching

---

## 6. Success metrics (30-day post-launch)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-1000 | % of captures that use tone transformation | TBD | ≥15% | Analytics events |
| M-1001 | % of transformations that result in share/copy | TBD | ≥70% | Action completion rate |
| M-1002 | User satisfaction with tone quality | TBD | ≥4.4/5 | In-app survey |
| M-1003 | Average iterations per transformation | TBD | <2 | Iteration tracking |
| M-1004 | % of users who save tone presets | TBD | ≥25% | Preset creation events |
| M-1005 | Reduction in communication avoidance | TBD | -35% | User self-report |

---

## 7. Core user flows

### 7.1 Transform capture to email

1. User captures frustrated thought: "I'm really annoyed that the package still
   hasn't arrived and I paid for 2-day shipping like a week ago"
2. User taps "Adjust tone" action on captured item
3. User selects target tone: "Professional"
4. AI generates transformation:
   > "I wanted to follow up regarding my order that was scheduled for 2-day
   > shipping. It's been approximately one week and I haven't received
   > confirmation of delivery. Could you please provide an update on the status?"
5. User reviews, optionally tweaks wording
6. User taps "Copy" or "Share" to send via email/message app

### 7.2 Quick tone adjustments with presets

1. User captures: "Tell mom I can't make it to dinner Sunday, something came up
   with work"
2. User taps "Adjust tone" and sees saved preset "Family - Apologetic"
3. User applies preset, AI generates:
   > "Hi Mom, I'm so sorry but I won't be able to make Sunday dinner. Something
   > urgent came up at work. I really wish I could be there. Can we reschedule
   > for next weekend?"
4. User approves and shares directly to messages

### 7.3 Iterate on tone transformation

1. User generates initial transformation with "Friendly" tone
2. Result feels too casual for the recipient
3. User taps "Adjust" and changes to "Friendly-Professional"
4. Reviews new version, closer but still not quite right
5. User manually edits key phrase while keeping rest of transformation
6. User saves final version and sends

### 7.4 Save tone preset

1. User completes transformation they're happy with
2. User taps "Save as preset"
3. User names preset: "Professors - Respectful inquiry"
4. User optionally adds keywords: "professor, teacher, academic, school"
5. Preset saved with tone parameters and example
6. Future similar contexts suggest: "Use 'Professors - Respectful inquiry'?"

### 7.5 Multiple tone previews

1. User captures message and taps "Adjust tone"
2. Instead of selecting one tone, user taps "Show all options"
3. AI generates 3 versions simultaneously:
   - Formal
   - Friendly
   - Concise
4. User reviews side-by-side and selects preferred version
5. User can further refine selected version

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-1000 | Provide tone adjustment action for captured items | Must | US-1000 |
| FR-1001 | Support multiple tone options (formal, friendly, concise, empathetic, direct) | Must | US-1001 |
| FR-1002 | Generate tone transformation while preserving user's intent | Must | US-1002 |
| FR-1003 | Show preview before committing transformation | Must | US-1003 |
| FR-1004 | Enable iteration on transformation (regenerate with different tone) | Must | US-1004 |
| FR-1005 | Provide copy and share actions for transformed text | Must | US-1005 |
| FR-1006 | Support saving tone presets with names and keywords | Should | US-1006 |
| FR-1007 | Suggest relevant presets based on capture content | Should | US-1007 |
| FR-1008 | Show multiple tone previews simultaneously | Should | US-1008 |
| FR-1009 | Allow manual editing of transformed text before sharing | Should | US-1009 |
| FR-1010 | Preset management UI (view, edit, delete, rename) | Should | US-1010 |
| FR-1011 | Track transformation history on item | Could | US-1011 |
| FR-1012 | Compare original vs transformed side-by-side | Could | US-1012 |
| FR-1013 | Preset sharing between users | Won't | - |
| FR-1014 | Real-time tone adjustment as user types | Won't | - |

---

## 9. Pricing & limits (hybrid model)

### Free tier

- 10 tone transformations per month
- 3 saved presets
- Basic tone options (formal, friendly, concise)
- Single transformation preview

### Paid tier

- Unlimited tone transformations
- Unlimited presets
- Advanced tone options (empathetic, direct, nuanced blends)
- Multi-tone preview (see all options at once)
- Transformation history
- Priority processing

**Rationale:** Tone transformation is valuable for specific high-anxiety
communications. Free tier enables critical use cases; paid tier for frequent
communicators and power users.

---

## 10. AI & backend requirements

### On-device AI (Phase 1 - Offline)

- Language model capable of style transfer while preserving meaning
- Support for multiple tone parameters and blending
- Context window sufficient for ~500 word messages
- Response time <3 seconds for transformation
- Fallback gracefully if unavailable

### Backend AI (Phase 2+ - Optional)

- Cloud-based LLM for higher quality transformations (opt-in)
- Learning from user's accepted/rejected transformations
- Preset suggestion improvements based on usage patterns
- Support for longer documents

### Privacy requirements

- All processing happens on-device by default
- Message content never sent to cloud without explicit opt-in
- Presets stored locally in SwiftData
- If cloud AI used, content encrypted in transit and not retained
- No analysis of message recipients or context

---

## 11. Data model

### New models

#### TonePreset

- `id: UUID` - Unique identifier
- `name: String` - User-defined preset name
- `keywords: [String]` - Pattern matching keywords
- `toneParameters: ToneParameters` - Tone configuration
- `exampleInput: String?` - Optional example original text
- `exampleOutput: String?` - Optional example transformation
- `usageCount: Int` - Number of times applied
- `lastUsed: Date?` - Last application timestamp
- `createdAt: Date` - Creation timestamp
- `updatedAt: Date` - Last modification timestamp

#### ToneParameters (Codable)

- `baseStyle: ToneStyle` - Primary tone
- `formalityLevel: Int` - 1-5 scale
- `friendlinessLevel: Int` - 1-5 scale
- `concisenessLevel: Int` - 1-5 scale
- `empathyLevel: Int?` - Optional 1-5 scale
- `preserveHumor: Bool` - Maintain jokes/lightness

#### ToneStyle (Enum)

- `formal` - Professional, structured
- `friendly` - Warm, approachable
- `concise` - Brief, to the point
- `empathetic` - Understanding, validating
- `direct` - Clear, straightforward
- `neutral` - Balanced, middle ground

#### ToneTransformation

- `id: UUID` - Unique identifier
- `sourceItemId: UUID` - Original captured item
- `originalText: String` - User's original capture
- `transformedText: String` - AI-generated transformation
- `toneUsed: ToneParameters` - Tone settings applied
- `presetUsed: UUID?` - If preset was applied
- `userEdits: String?` - Manual modifications after transformation
- `wasShared: Bool` - Whether user copied/shared result
- `createdAt: Date` - Transformation timestamp

### Existing model changes

#### Item

- `transformationHistory: [UUID]?` - Links to ToneTransformation records
- No required changes, transformations tracked separately

---

## 12. UX & tone requirements

### Visual design

- Tone selector as horizontal scrolling chips (not overwhelming dropdown)
- Preview shows original and transformed side-by-side on larger screens
- Clear visual distinction between preview and committed transformation
- Preset suggestions appear as dismissible chips above tone selector
- Copy and share buttons prominent after transformation
- Iteration controls (regenerate, adjust tone) easily accessible

### Tone option labels and descriptions

- **Formal:** "Professional and structured" - For work, official requests
- **Friendly:** "Warm and approachable" - For casual but polite communication
- **Concise:** "Brief and to the point" - For busy recipients, quick updates
- **Empathetic:** "Understanding and validating" - For sensitive situations
- **Direct:** "Clear and straightforward" - For clarity, no ambiguity
- **Neutral:** "Balanced middle ground" - When unsure which tone to use

### Tone & messaging

- **Non-judgmental about original:** Never imply original text was "wrong"
- **Emphasize choice:** "Here's one way to phrase this" not "You should say this"
- **Acknowledge uncertainty:** "This is my interpretation of a [tone] version"
- **User control:** "You can edit any part of this before sharing"
- **Privacy assurance:** "This happens on your device—nothing is shared"

### Example transformations

**Original (frustrated):**
> "Why hasn't anyone responded to my email from 3 days ago? This is ridiculous."

**Formal transformation:**
> "I wanted to follow up on the email I sent on [date]. I understand you may be
> busy, but I would appreciate an update when you have a moment."

**Direct transformation:**
> "I'm following up on my email from [date] and would like a response. When can
> I expect to hear back?"

**Friendly transformation:**
> "Hey! Just wanted to check in on that email I sent a few days ago. No rush,
> but let me know when you get a chance!"

### Interaction patterns

- Tone adjustment available from:
  - Item detail view (prominent button)
  - Long-press context menu
  - Swipe action in Capture view
- Preview state shows both original and transformed (can toggle)
- Can dismiss transformation and return to original
- Copy action includes success haptic and toast
- Share action opens system share sheet with transformed text
- Undo available for 30 seconds after applying transformation to item

### Accessibility

- VoiceOver describes tone options with full explanations
- Haptic feedback for tone selection
- Sufficient contrast for preview vs original text
- Large touch targets for action buttons
- Keyboard navigation for all tone controls

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Transformations feel inauthentic or robotic | H | Preserve user's core meaning; allow editing; extensive testing with diverse inputs |
| Users over-rely on feature and lose their own voice | M | Encourage reviewing and editing; don't auto-send; maintain original text visible |
| On-device AI quality insufficient for nuanced tone shifts | H | Test extensively; fallback to cloud AI as opt-in; support manual editing |
| Privacy concerns about processing personal messages | H | Clear on-device messaging; explicit opt-in for cloud; no retention |
| Feature adds friction to quick communication | M | Make entirely optional; fast processing (<3s); preset shortcuts |
| Tone suggestions feel judgmental about original text | M | Careful UI/messaging; never show "before/after" framing; emphasize choice |
| Users don't understand when to use which tone | M | Provide clear tone descriptions with example use cases; suggest based on context |

---

## 14. Implementation tracking

### Dependencies

- On-device language model for style transfer
- Tone parameter configuration system
- Preset storage and retrieval in SwiftData
- Share/copy workflow integration
- Pattern matching for preset suggestions

### Related features

- Complements capture workflow
- Could integrate with future messaging/email features
- May inform organization categorization (formal items → work list)

### Complexity estimate

- **High complexity** due to nuanced AI tone transformation requirements
- Estimated 3-4 week implementation for MVP
- Additional 2 weeks for preset system and multi-tone preview

### Testing requirements

- Tone transformation quality testing with diverse messages
- Preservation of meaning while changing tone verification
- Edge case testing (very short messages, emoji-heavy, already formal)
- Privacy testing for on-device processing
- Accessibility testing for all tone controls
- User testing with autistic/ADHD focus group for tone anxiety validation

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Should we support tone blending (e.g., "formal + friendly")? | Product | Open | More flexible but potentially confusing; need UI clarity |
| Include emoji suggestion as part of tone transformation? | Product | Open | Could help friendliness but may feel juvenile to some users |
| Show confidence scores for transformation quality? | Design | Open | Transparency vs adding complexity |
| Support for multi-paragraph transformations? | Engineering | Open | Longer text requires different approach than short messages |
| Integration with future email/messaging apps? | Product | Deferred | Deep integration could streamline but adds scope |
| Should presets include recipient type (e.g., "For professors")? | Product | Open | Helpful but risks overfitting to specific people |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| 1.0 | 2026-01-24 | Initial draft based on Goblin Tools gap analysis |
