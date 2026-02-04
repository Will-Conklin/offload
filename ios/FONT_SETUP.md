# Font Setup Issue - NEEDS MANUAL FIX

## Problem

The app shows these errors in the console logs:
```
GSFont: invalid font file - "file:///.../BebasNeue-Regular.ttf"
GSFont: invalid font file - "file:///.../SpaceGrotesk-Bold.ttf"
GSFont: invalid font file - "file:///.../SpaceGrotesk-Regular.ttf"
```

## Root Cause

The font files exist in `ios/Offload/Resources/Fonts/` and are declared in `Info.plist` under `UIAppFonts`, but they are **not in the "Copy Bundle Resources" build phase**. Target membership alone is not sufficient - the files must be explicitly added to the Copy Bundle Resources phase to be included in the app bundle.

## Solution - Manual Steps Required

You need to add the fonts to the Copy Bundle Resources build phase in Xcode:

### Method 1: Via Build Phases
1. Open `Offload.xcodeproj` in Xcode
2. Select the "Offload" target in the project navigator
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Click the "+" button
6. Add all three font files:
   - `BebasNeue-Regular.ttf`
   - `SpaceGrotesk-Bold.ttf`
   - `SpaceGrotesk-Regular.ttf`
7. Rebuild the project

### Method 2: Via File Inspector
1. Open `Offload.xcodeproj` in Xcode
2. Select all three font files in the Project Navigator:
   - `ios/Offload/Resources/Fonts/BebasNeue-Regular.ttf`
   - `ios/Offload/Resources/Fonts/SpaceGrotesk-Bold.ttf`
   - `ios/Offload/Resources/Fonts/SpaceGrotesk-Regular.ttf`
3. Open File Inspector (⌘⌥1)
4. Check "Target Membership" for "Offload" (if not already checked)
5. The files should automatically be added to Copy Bundle Resources
6. If they're not added automatically, use Method 1 above

## Current Impact

- App falls back to system fonts (San Francisco)
- Typography doesn't match MCM design specifications
- No crashes or functional issues

## Verification

After adding fonts to Copy Bundle Resources:
1. Clean build folder (⇧⌘K)
2. Rebuild (⌘B)
3. Run app
4. Check console - GSFont errors should be gone
5. Custom fonts should display correctly
