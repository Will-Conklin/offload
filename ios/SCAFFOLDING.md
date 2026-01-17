<!-- Intent: Document the current iOS scaffolding and highlight the remaining gaps. -->

# iOS Scaffolding Summary

This document describes the current Offload iOS app scaffolding and what still needs to be built.

## Overview

The app compiles with functional capture and organization flows using a simplified data model. Items are captured and organized into Collections (Plans and Lists) with full CRUD operations.

## Layer Breakdown

### 1) App Layer (`App/`)
- **offloadApp.swift**: Injects `PersistenceController.shared`.
- **MainTabView.swift**: Main tab navigation with Captures, Plans, and Lists tabs, plus a floating capture button.

### 2) Features (`Features/`)
- **Captures/**:
  - `CaptureComposeView`: Provides text + voice capture through `VoiceRecordingService`, creating Items with type=nil (uncategorized captures). Items can be starred and tagged.
  - `CapturesListView`: Lists uncategorized Items (type=nil) with completion and deletion.
- **Organize/**:
  - `OrganizeView`: Unified view for Plans (isStructured=true) and Lists (isStructured=false) with create/edit flows.
  - `CollectionDetailView`: Unified detail view showing Collection items with inline editing, starring, tagging, and move operations.

### 3) Domain Models (`Domain/Models/`)
- **Item**: Core content entity with type (nil/"task"/"link"), completedAt timestamp, isStarred flag, and tags array.
- **Collection**: Container with isStructured flag (true=Plan with ordering, false=List without).
- **CollectionItem**: Junction table enabling many-to-many relationships with position and parentId for hierarchy.
- **Tag**: Simple categorization (name, color).
- All models use SwiftData `@Model` macro with appropriate delete rules for relationships.

### 4) Data Layer (`Data/`)
- **Persistence/**: `PersistenceController` and `SwiftDataManager` register the 4-model schema for production/preview; TODOs remain for migrations/CloudKit.
- **Repositories/**: CRUD operations for Item, Collection, CollectionItem, and Tag with SwiftData integration.
- **Services/**: `VoiceRecordingService` provides recording + on-device transcription.

### 5) Design System (`DesignSystem/`)
- **Theme.swift**: Spacing + corner radius tokens.
- **Components.swift**: Buttons and card placeholders.
- **Icons.swift**: Centralized SF Symbol names.

### 6) Resources (`Resources/`)
- **Assets.xcassets/**: App icon and accent color.

## Current Status

### ✅ Working
- Capture via text or voice, saved as Item with type=nil (uncategorized).
- CapturesListView lists uncategorized Items with completion and deletion.
- Organization views for Plans and Lists with create/edit/delete operations.
- CollectionDetailView with inline item editing, starring, tagging, and move operations.
- Simplified 4-model SwiftData schema registered for production and preview.
- Theme system with 4 color schemes (Ocean Teal, Violet Pop, Sunset Coral, Slate).

### 🔄 In Progress / TODO
- Settings view for app preferences and theme selection.
- Enhanced tag management flows.
- AI-assisted organization features (future enhancement).
- CloudKit/backup/migration strategy in `SwiftDataManager`.
- Comprehensive test suite for new model and repositories.

## Build Status

Project compiles in Xcode with the current scaffolding. Build by opening `ios/Offload.xcodeproj`, selecting a simulator, and pressing **Cmd+B**. The app launches with the main tab navigation (Captures, Plans, Lists) and a floating capture button.
