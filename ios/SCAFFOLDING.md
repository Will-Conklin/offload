<!-- Intent: Document the current iOS scaffolding and highlight the remaining gaps. -->

# iOS Scaffolding Summary

This document describes the current Offload iOS app scaffolding and what still needs to be built.

## Overview

The app compiles with functional capture + inbox flows. Organization now supports quick-add for plans, categories, and tags, while AI hand-off and settings remain mostly placeholder.

## Layer Breakdown

### 1) App Layer (`App/`)
- **offloadApp.swift**: Injects `PersistenceController.shared`.
- **AppRootView.swift**: Current entry point that navigates directly to `InboxView`.
- **MainTabView.swift**: Tab shell (Inbox, Organize, Settings placeholder) with a floating capture button; not yet wired as the root.

### 2) Features (`Features/`)
- **Inbox/**: `InboxView` lists `CaptureEntry` items via `CaptureWorkflowService` and supports deletion.
- **Capture/**: `CaptureSheetView` is the primary experience with text + voice capture through `VoiceRecordingService`; `CaptureView` is a legacy text-only modal kept for reference.
- **Organize/**: `OrganizeView` lists plans, categories, and tags with lightweight quick-add sheets; editing flows are still TODO.
- **ContentView.swift**: Legacy scaffold view retained for reference.

### 3) Domain Models (`Domain/Models/`)
- Capture workflow: `CaptureEntry`, `HandOffRequest`, `HandOffRun`, `Suggestion`, `SuggestionDecision`, `Placement`.
- Destinations: `Plan`, `Task` (simplified), `Tag`, `Category`, `ListEntity`, `ListItem`, `CommunicationItem`.
- Enum values stored as strings for SwiftData compatibility; relationships use cascade/nullify delete rules per entity needs.

### 4) Data Layer (`Data/`)
- **Persistence/**: `PersistenceController` registers the full schema for production/preview; `SwiftDataManager` provides a configurable container with TODOs for migrations/CloudKit.
- **Repositories/**: CRUD + lifecycle helpers for capture, hand-off, suggestions, placements, plans, tasks, tags, categories, lists, and communication items.
- **Services/**: `CaptureWorkflowService` (capture/inbox orchestration; AI hand-off methods stubbed) and `VoiceRecordingService` (recording + transcription).

### 5) Design System (`DesignSystem/`)
- **Theme.swift**: Spacing + corner radius tokens.
- **Components.swift**: Buttons and card placeholders.
- **Icons.swift**: Centralized SF Symbol names.

### 6) Resources (`Resources/`)
- **Assets.xcassets/**: App icon and accent color.

## Current Status

### ✅ Working
- Capture via text or voice, saved as `CaptureEntry` with lifecycle state.
- Inbox list with delete/archive operations through `CaptureWorkflowService`.
- Manual creation of plans, categories, and tags through Organize quick-add sheets.
- SwiftData schema registered for production and preview containers.
- Repository + workflow tests using in-memory SwiftData.

### 🔄 In Progress / TODO
- AI hand-off submission, suggestion presentation, decisions, and placement flows (`CaptureWorkflowService` stubs).
- Organize tab editing flows for plans, categories, tags, plus creation/editing for lists and communication items.
- Settings view and decision on using `MainTabView` as the app shell.
- CloudKit/backup/migration strategy in `SwiftDataManager`.

## Build Status

Project compiles in Xcode with the current scaffolding. Build by opening `ios/Offload.xcodeproj`, selecting a simulator, and pressing **Cmd+B**. The app currently launches into the Inbox; tab navigation and settings are pending.
