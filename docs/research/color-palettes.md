<!-- Intent: Outline Offload-ready color scheme options derived from ADHD-focused UX/UI research. -->

# Color Scheme Options for Offload

These palettes translate the ADHD-first visual guidance into concrete color sets that keep focus states clear, reduce visual noise, and reserve urgency for true alerts.

## Option 1: Calm Focus (Light)
- **Base/Background:** `#F6F7F9` (soft gray-white) with cards at `#FFFFFF`
- **Primary Accent:** `#3A7BD5` (calm blue) for focus states, primary buttons, and active tabs
- **Secondary Accent:** `#7D8899` (muted slate) for secondary controls and labels
- **Success:** `#2D9D6F` (muted green) for saves and confirmations
- **Caution:** `#D6862F` (amber) for reminders and non-blocking warnings
- **Error:** `#D64545` (controlled red) for destructive actions and validation errors
- **Neutrals:** Dividers at `#E1E5EB`; icons/text at `#1F2933` (primary) and `#4B5563` (secondary)
- **Why it fits:** Soft neutrals reduce stimulation, blue anchors focus, and limited accent count keeps hierarchy simple.

## Option 2: Warm Minimal (Light)
- **Base/Background:** `#FDF9F4` (warm parchment) with cards at `#FFFFFF`
- **Primary Accent:** `#E07A5F` (terracotta) for primary actions and highlights
- **Secondary Accent:** `#5F6B71` (cool graphite) for secondary text and controls
- **Success:** `#5FAF90` (sage green) for confirmations
- **Caution:** `#C7A146` (goldenrod) for nudges and non-blocking warnings
- **Error:** `#C44343` (cranberry) for errors and destructive actions
- **Neutrals:** Dividers at `#E6DFD6`; text at `#1E2A32` (primary) and `#4E5A63` (secondary)
- **Why it fits:** Warm base lowers clinical feel while a single strong accent keeps actions obvious without adding clutter.

## Option 3: Cool Clarity (Light)
- **Base/Background:** `#F3F6F8` (cool mist) with cards at `#FFFFFF`
- **Primary Accent:** `#2F80ED` (focused blue) for selection, focus, and primary calls-to-action
- **Secondary Accent:** `#6C8CA8` (steel blue) for secondary buttons and chips
- **Success:** `#1B9C7B` (teal green) for success banners and badges
- **Caution:** `#D9A21B` (soft amber) for gentle prompts
- **Error:** `#CC2F45` (deep red) for errors
- **Neutrals:** Dividers at `#E0E6ED`; text at `#0F172A` (primary) and `#475569` (secondary)
- **Why it fits:** Cool palette stays calming, with crisp contrast for focus states and readable hierarchy.

## Option 4: Dark Focus (Dark Mode)
- **Base/Background:** `#0F141A` (charcoal) with surfaces at `#161D24`
- **Primary Accent:** `#4DA3FF` (luminous blue) for active states and primary buttons
- **Secondary Accent:** `#A7B4C2` (cool gray) for secondary controls and body text
- **Success:** `#4CC38A` (emerald) for confirmations
- **Caution:** `#D0A64A` (amber) for warnings and reminders
- **Error:** `#F15B63` (soft coral) for errors
- **Neutrals:** Dividers at `#25303D`; disabled at `#3A4654`; text at `#E7EDF5` (primary) and `#B8C4D3` (secondary)
- **Why it fits:** Maintains high contrast without glare, uses restrained accenting to keep focus cues clear at night.

## Usage Guidance
- Limit simultaneous accent usage to one primary and one secondary element per view to reduce visual noise.
- Pair focus states with both color and stroke weight (e.g., 2 pt outline plus glow at 20% opacity).
- Keep success and error colors reserved for confirmations and destructive actions; use caution amber for gentle nudges.
- Ensure chips and pills maintain at least 3:1 contrast in their unselected state and 4.5:1 for selected/active states.
- Apply consistent spacing tokens with these palettes to preserve calm hierarchy (spacing guidance lives in the design system).
