# Font Setup Issue

## Problem

The app shows these errors in the console logs:
```
GSFont: invalid font file - "file:///.../BebasNeue-Regular.ttf"
GSFont: invalid font file - "file:///.../SpaceGrotesk-Bold.ttf"
GSFont: invalid font file - "file:///.../SpaceGrotesk-Regular.ttf"
```

## Root Cause

The font files exist in `ios/Offload/Resources/Fonts/` and are declared in `Info.plist` under `UIAppFonts`, but they are not added to the Xcode project's build target. This means they aren't being copied into the app bundle at build time.

## Solution

Open the project in Xcode and add the font files to the build target:

1. Open `Offload.xcodeproj` in Xcode
2. In the Project Navigator, select all three font files:
   - `BebasNeue-Regular.ttf`
   - `SpaceGrotesk-Bold.ttf`
   - `SpaceGrotesk-Regular.ttf`
3. Open the File Inspector (⌘⌥1)
4. Under "Target Membership", ensure "Offload" is checked
5. Alternatively, in Build Phases → Copy Bundle Resources, add these three files

## Verification

After fixing, the fonts should load correctly and no GSFont errors should appear in the console.

## Current Impact

- The app is falling back to system fonts
- Typography doesn't match the MCM design system specification
- No crashes or functional issues, just incorrect visual appearance
