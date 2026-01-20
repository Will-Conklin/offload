---
id: research-color-scheme-alternatives
type: research
status: informational
owners:
  - Offload
applies_to:
  - color
  - scheme
  - alternatives
last_updated: 2026-01-13
related:
  - research-color-palettes
  - research-adhd-ux-ui
  - research-ios-ui-trends-2025
  - adr-0003-adhd-focused-ux-ui-guardrails
structure_notes:
  - "Section order: Executive Summary; Current Color Scheme Analysis; Design Principles for Alternatives; Alternative Color Schemes; Comparison Matrix; ADHD-Friendliness Assessment; Implementation Recommendations; Testing Strategy; Accessibility Validation Checklist; Conclusion; Next Steps."
  - "Keep the top-level section outline intact."
---

<!-- Intent: Research and propose alternative color schemes for Offload based on current implementation analysis and ADHD-friendly design principles. -->

# Color Scheme Alternatives for Offload

**Created:** 2026-01-10
**Status:** Research Complete
**Related Documents:**

- [Current Color Palettes](research-color-palettes.md)
- [ADHD UX/UI Research](research-adhd-ux-ui.md)
- [iOS UI Trends 2025](research-ios-ui-trends-2025.md)
- [adr-0003: ADHD UX Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)

---

## Executive Summary

This document analyzes the current Offload color scheme and proposes alternative options that maintain ADHD-friendly design principles while offering fresh visual directions. All alternatives prioritize calm palettes, accessible contrast, and reduced visual noise.

**Current Assessment:** The existing color scheme is well-designed and ADHD-friendly, but feels somewhat clinical and could benefit from warmer tones or more personality while maintaining psychological safety.

**Top Recommendations:**

1. **Sage & Stone** - Warmer, more grounded alternative with natural tones
2. **Lavender Calm** - Gentle, stress-reducing purple-based palette
3. **Ocean Minimal** - Refined evolution of current blue with better warmth
4. **Sunset Productivity** - Energizing but calm amber/coral palette

---

## Current Color Scheme Analysis

### Light Mode (Current)

```text
Background:    #F7FAFD (soft gray-blue, very light)
Surface:       #FFFFFF (pure white)
Primary:       #3372D9 (medium blue)
Secondary:     #4D99BD (muted teal-blue)
Success:       #4DA68F (muted teal-green)
Caution:       #E6A834 (warm amber)
Destructive:   #DA4040 (controlled red)
Text Primary:  #1A1F28 (very dark blue-gray)
Text Secondary:#5A6370 (medium gray)
Border:        #DCE1E8 (light gray-blue)
```

### Dark Mode (Current)

```text
Background:    #121517 (deep charcoal)
Surface:       #1F2127 (lighter charcoal)
Primary:       #66B3F7 (bright soft blue)
Secondary:     #99BFDA (light blue-gray)
Success:       #66CD8C (bright muted green)
Caution:       #F2C04D (bright amber)
Destructive:   #F27272 (soft coral-red)
Text Primary:  #E6EAEF (very light gray)
Text Secondary:#A5ADB8 (medium light gray)
Border:        #414B56 (medium gray)
```

### Strengths

✅ **High Contrast:** Excellent text readability
✅ **Calm Blue:** Non-stimulating primary accent
✅ **Muted Tones:** Reduces visual noise and overstimulation
✅ **Consistent Semantics:** Clear success/caution/error hierarchy
✅ **Dark Mode Excellence:** Well-balanced dark palette
✅ **Accessible:** Meets WCAG AA standards

### Areas for Improvement

⚠️ **Slightly Clinical:** Cool blue-gray tones can feel sterile
⚠️ **Limited Warmth:** Could benefit from warmer base tones
⚠️ **Generic Blue:** Common in productivity apps, lacks uniqueness
⚠️ **Low Emotional Connection:** Safe but not particularly inviting

---

## Design Principles for Alternatives

Based on ADHD UX research and app philosophy, all alternatives must:

1. **Reduce Cognitive Load:** Limit simultaneous colors, clear hierarchy
2. **Maintain Calm:** Avoid harsh, saturated, or jarring colors
3. **Support Focus:** Clear visual distinction for active/focus states
4. **Ensure Accessibility:** Minimum 4.5:1 contrast for text, 3:1 for UI elements
5. **Respect Psychology:** No guilt-inducing reds, no anxiety-triggering urgency
6. **Support Dark Mode:** Both modes should feel cohesive

---

## Alternative Color Schemes

### Option 1: Sage & Stone (Recommended)

**Theme:** Natural, grounded, warm minimalism
**Mood:** Calm confidence, organic productivity
**Best For:** Users who find blue too cold or clinical

#### Light Mode (Sage & Stone)

```text
Background:    #F5F3EF (warm off-white, stone)
Surface:       #FEFDFB (warm white)
Primary:       #5F8575 (sage green)
Secondary:     #8B9D94 (muted sage-gray)
Success:       #4A9B7F (forest green)
Caution:       #C99750 (warm gold)
Destructive:   #C55555 (terracotta red)
Text Primary:  #2C3531 (dark forest)
Text Secondary:#6B7974 (warm gray)
Border:        #E0DDD8 (warm divider)
Focus:         #78A694 (bright sage)
```

#### Dark Mode (Sage & Stone)

```text
Background:    #1C1E1B (deep forest)
Surface:       #272A26 (charcoal-green)
Primary:       #8FBA9D (light sage)
Secondary:     #A3B5AD (pale sage-gray)
Success:       #66C89B (bright mint)
Caution:       #E5B869 (soft gold)
Destructive:   #E08080 (muted coral)
Text Primary:  #EAF0ED (pale mint-white)
Text Secondary:#B8C5BF (sage-gray)
Border:        #3F4540 (muted forest)
```

**Why it works:**

- Warm, natural tones feel less sterile than blue
- Green is psychologically calming and associated with growth
- Earth tones create sense of stability and groundedness
- Unique in productivity app space (most use blue)
- Maintains accessibility while feeling warmer

**Implementation Note:**
Replace `accentPrimary` blue with sage, keep all other semantic colors similar structure.

---

### Option 2: Lavender Calm

**Theme:** Gentle, stress-reducing, creative
**Mood:** Peaceful focus, calm creativity
**Best For:** Users sensitive to overstimulation, night-time usage

#### Light Mode (Lavender Calm)

```text
Background:    #F6F5F9 (pale lavender-gray)
Surface:       #FDFCFE (near-white with purple tint)
Primary:       #7B68B8 (soft purple)
Secondary:     #9B8FB8 (muted lilac)
Success:       #5FA88F (teal-green)
Caution:       #C7A053 (amber)
Destructive:   #C65B6F (muted rose)
Text Primary:  #2E2639 (deep purple-black)
Text Secondary:#65607A (purple-gray)
Border:        #E3E0EA (lavender divider)
Focus:         #9B85D4 (bright lavender)
```

#### Dark Mode (Lavender Calm)

```text
Background:    #1A1625 (deep purple-black)
Surface:       #252034 (dark purple-gray)
Primary:       #A797DB (light lavender)
Secondary:     #B5AAD1 (pale purple)
Success:       #6BC99D (bright teal)
Caution:       #E5BD6F (soft gold)
Destructive:   #E5899D (soft pink-red)
Text Primary:  #EDE9F4 (pale lavender-white)
Text Secondary:#B5AEC7 (lavender-gray)
Border:        #3A344A (muted purple)
```

**Why it works:**

- Purple reduces stress and promotes calm (color psychology)
- Less common in productivity apps = more distinctive
- Gentle enough to avoid overstimulation
- Good for evening/night usage (warmer than blue)
- Creative vibe fits "brain dump" concept

**Considerations:**

- Some users may find purple too "soft" for productivity
- Less traditional than blue (could be pro or con)

---

### Option 3: Ocean Minimal

**Theme:** Refined evolution of current scheme with more warmth
**Mood:** Clean, professional, trusted
**Best For:** Users who like current blue but want slightly more personality

#### Light Mode (Ocean Minimal)

```text
Background:    #F5F8FA (soft blue-white, warmer than current)
Surface:       #FFFFFF (pure white)
Primary:       #2B7FB8 (ocean blue, warmer than current)
Secondary:     #5D9BB5 (teal-blue)
Success:       #3D9B7F (sea green)
Caution:       #D6A045 (warm amber)
Destructive:   #CC5555 (warm red)
Text Primary:  #1F2835 (navy)
Text Secondary:#58657A (slate)
Border:        #DAE3EA (blue-gray divider)
Focus:         #4DA3D9 (bright ocean)
```

#### Dark Mode (Ocean Minimal)

```text
Background:    #0F1419 (deep ocean)
Surface:       #1A2028 (dark slate)
Primary:       #5DADE6 (bright ocean)
Secondary:     #8BB8CC (sky blue)
Success:       #5FCC9A (bright sea green)
Caution:       #F2C764 (bright amber)
Destructive:   #F28080 (soft coral)
Text Primary:  #E8EDF2 (ice white)
Text Secondary:#A8B8C7 (light slate)
Border:        #3A4652 (ocean gray)
```

**Why it works:**

- Familiar to users who like current scheme
- Warmer blue feels less clinical
- Maintains trust/reliability of blue
- Safe, incremental change
- Proven color psychology for productivity

**Best use case:**
Conservative update that improves current scheme without dramatic change.

---

### Option 4: Sunset Productivity

**Theme:** Energizing warmth with calm undertones
**Mood:** Motivated, warm, optimistic
**Best For:** Users who need energy boost without anxiety

#### Light Mode (Sunset Productivity)

```text
Background:    #FBF7F3 (warm cream)
Surface:       #FFFEFB (warm white)
Primary:       #E37A5F (coral-orange, muted)
Secondary:     #C9977D (warm taupe)
Success:       #66B685 (fresh green)
Caution:       #D6A547 (golden amber)
Destructive:   #D66360 (warm red)
Text Primary:  #2D2420 (dark brown)
Text Secondary:#6B5D54 (warm brown-gray)
Border:        #EBE3DA (warm divider)
Focus:         #F59D82 (bright coral)
```

#### Dark Mode (Sunset Productivity)

```text
Background:    #1A1411 (dark chocolate)
Surface:       #26211C (warm charcoal)
Primary:       #F4A88A (soft coral)
Secondary:     #D9B8A3 (warm sand)
Success:       #7ACC9A (bright green)
Caution:       #E8BD6C (bright gold)
Destructive:   #EB8B89 (soft salmon)
Text Primary:  #F5F0EB (warm white)
Text Secondary:#C7BDB4 (warm gray)
Border:        #3F3832 (warm brown)
```

**Why it works:**

- Warm colors create sense of optimism and energy
- Coral is less aggressive than pure orange
- Brown/cream base feels organic and grounded
- Stands out in productivity app market
- Warm tones can improve mood

**Considerations:**

- Most "bold" option - may not suit all users
- Warmer palette may feel less "serious" for some

---

### Option 5: Monochrome Focus

**Theme:** Ultimate minimal distraction
**Mood:** Zen, focused, distraction-free
**Best For:** Users who want absolute minimal visual noise

#### Light Mode (Monochrome Focus)

```text
Background:    #F9F9F9 (near white)
Surface:       #FFFFFF (pure white)
Primary:       #3D3D3D (dark gray - used sparingly)
Secondary:     #6B6B6B (medium gray)
Success:       #4A9B6E (muted green - only semantic color)
Caution:       #C9A050 (muted gold - only semantic color)
Destructive:   #C55555 (muted red - only semantic color)
Text Primary:  #1A1A1A (near black)
Text Secondary:#737373 (medium gray)
Border:        #E5E5E5 (light gray)
Focus:         #000000 (pure black with stroke weight)
```

#### Dark Mode (Monochrome Focus)

```text
Background:    #121212 (true dark)
Surface:       #1E1E1E (elevated dark)
Primary:       #E0E0E0 (light gray - used sparingly)
Secondary:     #A8A8A8 (medium gray)
Success:       #66C089 (bright green)
Caution:       #E0B55F (bright gold)
Destructive:   #E57373 (bright red)
Text Primary:  #F5F5F5 (near white)
Text Secondary:#B3B3B3 (light gray)
Border:        #3D3D3D (dark gray)
```

**Why it works:**

- Absolute minimal distraction - no color to process
- Forces focus on content and hierarchy
- Semantic colors (success/caution/error) stand out more
- Ultimate "calm" approach
- Very modern, sophisticated look

**Considerations:**

- May feel too stark for some users
- Less personality/warmth
- Could feel depressing if not executed well
- Requires excellent typography and spacing

---

### Option 6: Mint Fresh

**Theme:** Light, airy, refreshing minimalism
**Mood:** Clean energy, mental clarity
**Best For:** Users who want calm but with subtle energy

#### Light Mode (Mint Fresh)

```text
Background:    #F6FAFA (pale mint)
Surface:       #FFFFFF (pure white)
Primary:       #4DB8A6 (mint teal)
Secondary:     #7BC5B8 (soft mint)
Success:       #5DBF8F (fresh green)
Caution:       #D9A84A (warm amber)
Destructive:   #D66360 (warm red)
Text Primary:  #1F2D2B (dark teal-black)
Text Secondary:#5A716D (teal-gray)
Border:        #E0ECEB (mint divider)
Focus:         #6DD9C4 (bright mint)
```

#### Dark Mode (Mint Fresh)

```text
Background:    #0F1615 (deep teal-black)
Surface:       #1A2322 (dark teal-gray)
Primary:       #6FD9C4 (bright mint)
Secondary:     #95CFC2 (pale mint)
Success:       #6FCC96 (bright green)
Caution:       #E8BE6F (bright gold)
Destructive:   #EB8B89 (soft salmon)
Text Primary:  #E8F2F0 (pale mint-white)
Text Secondary:#ADBFBD (mint-gray)
Border:        #2E3F3D (muted teal)
```

**Why it works:**

- Mint is psychologically refreshing and clarity-inducing
- Cooler than green but warmer than blue
- Modern and on-trend
- Distinctive without being jarring
- Good balance of calm and energy

---

## Comparison Matrix

| Scheme | Uniqueness | Warmth | Calm | Energy | Accessibility | Dark Mode |
| ------ | ---------- | ------ | ---- | ------ | ------------- | --------- |
| **Current (Blue-Gray)** | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Sage & Stone** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Lavender Calm** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Ocean Minimal** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Sunset Productivity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Monochrome Focus** | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Mint Fresh** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## ADHD-Friendliness Assessment

### Most ADHD-Friendly (in order)

1. **Monochrome Focus** - Absolute minimal distraction, pure hierarchy
2. **Lavender Calm** - Proven stress-reduction, gentle on senses
3. **Sage & Stone** - Grounding, natural, non-stimulating
4. **Ocean Minimal** - Familiar, trusted, low cognitive load
5. **Mint Fresh** - Refreshing but calm
6. **Sunset Productivity** - More stimulating (could help or hinder depending on user)

### Key ADHD Considerations

- **Visual Noise:** All options limit simultaneous colors ✅
- **Contrast:** All maintain accessible contrast ratios ✅
- **Focus States:** All use color + stroke weight for clarity ✅
- **Psychological Safety:** All avoid harsh, jarring colors ✅
- **Overstimulation:** Monochrome, Lavender, Sage best; Sunset highest risk ⚠️

---

## Implementation Recommendations

### Quick Win: Ocean Minimal

**Effort:** Low (minimal code changes)
**Impact:** Medium (subtle improvement)
**Risk:** Very Low (conservative evolution)

Adjust existing color values slightly warmer. Requires only Theme.swift updates.

### Recommended: Sage & Stone

**Effort:** Low-Medium (color value changes + testing)
**Impact:** High (distinctive, warmer, fresh)
**Risk:** Medium (bigger change, may need user feedback)

Replace blue system with sage green. Maintains all ADHD principles while adding warmth and uniqueness.

### Bold Option: Lavender Calm

**Effort:** Low-Medium
**Impact:** Very High (unique positioning)
**Risk:** Medium-High (less traditional for productivity)

Best for truly differentiating from competitors while maintaining calm ADHD-friendly approach.

### User Choice Approach

Consider implementing multiple themes as user-selectable options:

- **Default:** Ocean Minimal (safe, refined)
- **Warm:** Sage & Stone (natural, grounded)
- **Calm:** Lavender Calm (stress-reducing)
- **Focus:** Monochrome (minimal distraction)

---

## Testing Strategy

### Phase 1: Visual Mockups

1. Update Theme.swift with new color values in a feature branch
2. Screenshot key screens (Capture, Organize, Settings) in both modes
3. Compare side-by-side with current scheme
4. Assess with team for ADHD-friendliness

### Phase 2: User Feedback (Optional)

1. Create prototype builds with 2-3 finalist schemes
2. TestFlight with small user group
3. Survey on: calm feeling, focus support, visual appeal, eye strain
4. Analyze feedback for ADHD-specific concerns

### Phase 3: Implementation

1. Update Theme.swift with chosen scheme
2. Test all components in both light/dark modes
3. Verify accessibility with VoiceOver and contrast tools
4. Update marketing materials if visual identity changes

---

## Accessibility Validation Checklist

For any chosen alternative:

- [ ] Text contrast ≥ 4.5:1 for normal text
- [ ] Text contrast ≥ 3:1 for large text (18pt+)
- [ ] UI element contrast ≥ 3:1
- [ ] Focus indicators visible in both modes
- [ ] Success/Caution/Error colors distinguishable for colorblind users
- [ ] Dark mode doesn't cause eye strain (no pure white on pure black)
- [ ] Tested with Color Blindness simulators (Protanopia, Deuteranopia, Tritanopia)

---

## Conclusion

### Top Recommendation: Sage & Stone

This scheme provides:

- ✅ Significant differentiation from current blue
- ✅ Warmer, more inviting feel without sacrificing calm
- ✅ Unique positioning in productivity app market
- ✅ Maintains all ADHD-friendly principles
- ✅ Natural, grounded psychology aligns with app philosophy
- ✅ Excellent accessibility
- ✅ Works beautifully in dark mode

### Runner-up: Ocean Minimal

If team prefers conservative evolution:

- ✅ Minimal risk, familiar to current users
- ✅ Slight warmth improvement over current
- ✅ Safe, proven color psychology
- ✅ Easy implementation

### Wild Card: Lavender Calm

For bold differentiation:

- ✅ Most unique among competitors
- ✅ Strong stress-reduction psychology
- ✅ Appeals to creative ADHD users
- ⚠️ Less traditional (could be strength or weakness)

---

## Next Steps

1. **Review with team** - Discuss top 3 options
2. **Create visual mockups** - Update Theme.swift in branch, screenshot key views
3. **Validate accessibility** - Run contrast checkers, colorblind simulations
4. **Decision** - Select scheme or plan user testing
5. **Implementation** - Update Theme.swift, test thoroughly, commit

---

**Document Status:** ✅ Ready for Team Review
**Recommended Decision Timeline:** Week of 2026-01-13
**Implementation Estimate:** 1-2 days (color values only)
