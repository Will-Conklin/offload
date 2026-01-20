---
id: plan-view-decomposition
type: plan
status: active
owners:
  - Offload
applies_to:
  - view
  - decomposition
last_updated: 2026-01-17
related: []
structure_notes:
  - "Section order: Overview; Problem Statement; Current State; Proposed Solution; Implementation Steps; Shared Components; Testing Strategy; Success Criteria; Next Steps; Related Documents."
  - "Keep the top-level section outline intact."
---

# View Decomposition Plan

**Priority**: Low
**Estimated Effort**: Medium
**Impact**: Code maintainability and readability

## Overview

Break down large, complex view files into smaller, focused, reusable components to improve maintainability, testability, and team collaboration.

## Problem Statement

### Current Issues

1. **CollectionDetailView is Too Large** (782 lines):
   - Single file handles detail, edit, add, tag picking, linking
   - Hard to understand at a glance
   - Difficult to test individual pieces
   - Merge conflicts likely with multiple developers

2. **Mixed Responsibilities**:
   - Views handle both presentation and business logic
   - Nested structs make navigation difficult
   - State management scattered throughout

3. **Code Reuse Challenges**:
   - Similar patterns duplicated across views
   - Hard to extract common components
   - Inconsistent implementations

4. **Testing Difficulties**:
   - Can't test subviews in isolation
   - Preview generation slow for large files
   - Hard to mock dependencies

## Current State

### CollectionDetailView Structure (782 lines)

```text
CollectionDetailView
├── Main body (collection header, item list)
├── AddItemSheet (nested struct, ~100 lines)
├── EditItemSheet (nested struct, ~150 lines)
├── TagPickerSheet (nested struct, ~100 lines)
├── LinkCollectionSheet (nested struct, ~80 lines)
└── Helper methods and state management
```

### Other Large Views

- **CaptureComposeView**: ~460 lines (voice recording, attachments, tags)
- **CaptureView**: ~450 lines (list, swipe actions, context menus)
- **OrganizeView**: ~300 lines (tabs, collection lists)

## Proposed Solution

### Decomposition Principles

1. **Single Responsibility**: Each view has one clear purpose
2. **Small Surface Area**: Views should be <200 lines ideally, <300 max
3. **Reusability**: Extract common patterns into shared components
4. **Testability**: Each component testable in isolation
5. **Clear Hierarchy**: Parent → Child relationships obvious

### File Organization Strategy

```text
Features/
├── Capture/
│   ├── CaptureView.swift (list container)
│   ├── CaptureComposeView.swift (compose screen)
│   ├── Components/
│   │   ├── CaptureItemCard.swift
│   │   ├── VoiceRecordingButton.swift
│   │   ├── AttachmentPicker.swift
│   │   └── TagSelector.swift
│   └── ViewModels/
│       └── CaptureViewModel.swift
├── Organize/
│   ├── OrganizeView.swift (tab container)
│   ├── CollectionListView.swift (list of collections)
│   ├── CollectionDetailView.swift (simplified, ~200 lines)
│   ├── Components/
│   │   ├── CollectionItemCard.swift
│   │   ├── QuickAddButton.swift
│   │   ├── ItemActionsMenu.swift
│   │   └── CollectionHeader.swift
│   ├── Sheets/
│   │   ├── AddItemSheet.swift
│   │   ├── EditItemSheet.swift
│   │   ├── TagPickerSheet.swift
│   │   └── LinkCollectionSheet.swift
│   └── ViewModels/
│       └── CollectionDetailViewModel.swift
└── Shared/
    ├── Components/
    │   ├── ItemCard.swift (base card)
    │   ├── TagPill.swift
    │   ├── EmptyStateView.swift
    │   └── LoadingView.swift
    └── ViewModels/
        └── BaseViewModel.swift (if needed)
```

## Implementation Steps

### Phase 1: Extract CollectionDetailView Components (4-5 hours)

#### 1.1 Create Sheets Directory

```text
Features/Organize/Sheets/
├── AddItemSheet.swift
├── EditItemSheet.swift
├── TagPickerSheet.swift
└── LinkCollectionSheet.swift
```

#### 1.2 Extract AddItemSheet

```swift
// Features/Organize/Sheets/AddItemSheet.swift
struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.errorPresenter) private var errorPresenter

    let collection: Collection

    @State private var itemText = ""
    @State private var selectedTags: [Tag] = []
    @State private var attachmentData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("What needs to be done?", text: $itemText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Tags") {
                    TagSelector(selectedTags: $selectedTags)
                }

                Section("Attachment") {
                    AttachmentPicker(attachmentData: $attachmentData)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addItem() }
                        .disabled(itemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addItem() {
        do {
            let item = try itemRepository.create(
                type: collection.isStructured ? "task" : nil,
                content: itemText,
                tags: selectedTags,
                attachmentData: attachmentData
            )

            // Add to collection
            let position = collection.isStructured ? (collection.items?.count ?? 0) : nil
            let collectionItem = CollectionItem(
                collectionId: collection.id,
                itemId: item.id,
                position: position
            )
            // Save collection item...

            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// Preview
#Preview {
    AddItemSheet(collection: Collection.preview)
        .environment(\.itemRepository, ItemRepository.preview)
}
```

#### 1.3 Extract EditItemSheet

```swift
// Features/Organize/Sheets/EditItemSheet.swift
struct EditItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.errorPresenter) private var errorPresenter

    @Bindable var item: Item

    @State private var editedContent: String
    @State private var editedTags: [Tag]
    @State private var attachmentData: Data?

    init(item: Item) {
        self.item = item
        _editedContent = State(initialValue: item.content)
        _editedTags = State(initialValue: item.tags ?? [])
        _attachmentData = State(initialValue: item.attachmentData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Content", text: $editedContent, axis: .vertical)
                        .lineLimit(3...10)
                }

                Section("Tags") {
                    TagSelector(selectedTags: $editedTags)
                }

                Section("Attachment") {
                    AttachmentPicker(attachmentData: $attachmentData)
                }

                if item.isCompleted {
                    Section {
                        Button("Mark Incomplete") {
                            markIncomplete()
                        }
                    }
                } else {
                    Section {
                        Button("Mark Complete") {
                            markComplete()
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
        }
    }

    private func saveChanges() {
        do {
            try itemRepository.update(
                item,
                content: editedContent,
                tags: editedTags,
                attachmentData: attachmentData
            )
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func markComplete() {
        do {
            try itemRepository.markCompleted(item)
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func markIncomplete() {
        item.completedAt = nil
        saveChanges()
    }
}
```

#### 1.4 Extract TagPickerSheet

```swift
// Features/Organize/Sheets/TagPickerSheet.swift
struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tagRepository) private var tagRepository

    @Binding var selectedTags: [Tag]

    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var searchText = ""
    @State private var showingCreateTag = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTags) { tag in
                    HStack {
                        TagPill(tag: tag)

                        Spacer()

                        if selectedTags.contains(where: { $0.id == tag.id }) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleTag(tag)
                    }
                }

                if !searchText.isEmpty {
                    Button(action: createNewTag) {
                        Label("Create \"\(searchText)\"", systemImage: "plus.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search tags")
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        }
        return allTags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func createNewTag() {
        do {
            let newTag = try tagRepository.create(name: searchText)
            selectedTags.append(newTag)
            searchText = ""
        } catch {
            // Handle error
        }
    }
}
```

#### 1.5 Extract LinkCollectionSheet

```swift
// Features/Organize/Sheets/LinkCollectionSheet.swift
struct LinkCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.itemRepository) private var itemRepository

    let sourceCollection: Collection

    @Query private var allCollections: [Collection]

    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCollections) { collection in
                    Button(action: { linkToCollection(collection) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(collection.name)
                                    .font(.headline)
                                Text("\(collection.items?.count ?? 0) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "link")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Link to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var availableCollections: [Collection] {
        allCollections.filter { $0.id != sourceCollection.id }
    }

    private func linkToCollection(_ targetCollection: Collection) {
        do {
            // Create link item
            let linkItem = try itemRepository.create(
                type: "link",
                content: "Link to \(targetCollection.name)",
                linkedCollectionId: targetCollection.id
            )

            // Add to source collection
            // ... collection item creation logic

            dismiss()
        } catch {
            // Handle error
        }
    }
}
```

#### 1.6 Simplify CollectionDetailView

After extractions, main view becomes much simpler:

```swift
// Features/Organize/CollectionDetailView.swift (~200 lines)
struct CollectionDetailView: View {
    @Environment(\.itemRepository) private var itemRepository

    let collection: Collection

    @State private var showingAddItem = false
    @State private var showingEditItem: Item?
    @State private var showingTagPicker = false
    @State private var showingLinkCollection = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(collection.sortedItems) { item in
                    ItemCard(item: item)
                        .contextMenu {
                            ItemContextMenu(item: item) {
                                showingEditItem = item
                            }
                        }
                }
            }
            .padding()
        }
        .navigationTitle(collection.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(collection: collection)
        }
        .sheet(item: $showingEditItem) { item in
            EditItemSheet(item: item)
        }
    }
}
```

### Phase 2: Extract Shared Components (3-4 hours)

#### 2.1 Create ItemCard Base Component

```swift
// Features/Shared/Components/ItemCard.swift
struct ItemCard: View {
    let item: Item

    @Environment(\.itemRepository) private var itemRepository
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content
            Text(item.content)
                .font(.body)

            // Tags
            if let tags = item.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags) { tag in
                            TagPill(tag: tag)
                        }
                    }
                }
            }

            // Metadata
            HStack {
                if item.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }

                Spacer()

                Text(item.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}
```

#### 2.2 Create TagPill Component

```swift
// Features/Shared/Components/TagPill.swift
struct TagPill: View {
    let tag: Tag
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption)

            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tagColor)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    private var tagColor: Color {
        if let colorHex = tag.color {
            return Color(hex: colorHex) ?? .blue
        }
        return .blue
    }
}
```

#### 2.3 Create EmptyStateView Component

```swift
// Features/Shared/Components/EmptyStateView.swift
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }
}
```

### Phase 3: Extract Capture Components (3-4 hours)

#### 3.1 Create VoiceRecordingButton

```swift
// Features/Capture/Components/VoiceRecordingButton.swift
struct VoiceRecordingButton: View {
    @Binding var isRecording: Bool
    @Binding var transcribedText: String

    @StateObject private var voiceService = VoiceRecordingService()

    var body: some View {
        Button(action: toggleRecording) {
            HStack {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                Text(isRecording ? "Stop" : "Record")
            }
            .padding()
            .background(isRecording ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .onChange(of: voiceService.transcribedText) { _, newValue in
            transcribedText = newValue
        }
    }

    private func toggleRecording() {
        if isRecording {
            voiceService.stopRecording()
        } else {
            voiceService.startRecording()
        }
        isRecording.toggle()
    }
}
```

#### 3.2 Create AttachmentPicker

```swift
// Features/Capture/Components/AttachmentPicker.swift
struct AttachmentPicker: View {
    @Binding var attachmentData: Data?

    @State private var showingImagePicker = false
    @State private var showingCamera = false

    var body: some View {
        VStack {
            if let data = attachmentData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Remove", role: .destructive) {
                    attachmentData = nil
                }
            } else {
                HStack {
                    Button(action: { showingImagePicker = true }) {
                        Label("Photo Library", systemImage: "photo")
                    }

                    Button(action: { showingCamera = true }) {
                        Label("Camera", systemImage: "camera")
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imageData: $attachmentData, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(imageData: $attachmentData, sourceType: .camera)
        }
    }
}
```

#### 3.3 Create TagSelector

```swift
// Features/Capture/Components/TagSelector.swift
struct TagSelector: View {
    @Binding var selectedTags: [Tag]

    @State private var showingTagPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedTags) { tag in
                        TagPill(tag: tag) {
                            removeTag(tag)
                        }
                    }

                    Button(action: { showingTagPicker = true }) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagPicker) {
            TagPickerSheet(selectedTags: $selectedTags)
        }
    }

    private func removeTag(_ tag: Tag) {
        selectedTags.removeAll { $0.id == tag.id }
    }
}
```

### Phase 4: Testing (2-3 hours)

#### 4.1 Component Preview Tests

Each component should have comprehensive previews:

```swift
// Preview tests for AddItemSheet
#Preview("Empty") {
    AddItemSheet(collection: Collection.preview)
}

#Preview("With Content") {
    let sheet = AddItemSheet(collection: Collection.preview)
    // Set initial state
    return sheet
}

#Preview("Error State") {
    AddItemSheet(collection: Collection.preview)
        // Trigger error
}
```

#### 4.2 Snapshot Tests (Optional)

```swift
// OffloadTests/SnapshotTests/ItemCardSnapshotTests.swift
import SnapshotTesting

class ItemCardSnapshotTests: XCTestCase {
    func testItemCardDefault() {
        let item = Item.mock(content: "Test item")
        let view = ItemCard(item: item)

        assertSnapshot(matching: view, as: .image)
    }

    func testItemCardWithTags() {
        let item = Item.mock(
            content: "Test item",
            tags: [Tag(name: "work"), Tag(name: "urgent")]
        )
        let view = ItemCard(item: item)

        assertSnapshot(matching: view, as: .image)
    }
}
```

### Phase 5: Documentation (1 hour)

#### 5.1 Update AGENTS.md

Document component organization and guidelines

#### 5.2 Create Component Catalog

```markdown
# Component Catalog

## Shared Components

### ItemCard
**Purpose**: Base card for displaying items
**Location**: `Features/Shared/Components/ItemCard.swift`
**Usage**: `ItemCard(item: item)`

### TagPill
**Purpose**: Display tag with optional remove button
**Location**: `Features/Shared/Components/TagPill.swift`
**Usage**: `TagPill(tag: tag, onRemove: { })`

... etc
```

## Testing Strategy

### Component Testing

- [ ] Each component has preview
- [ ] Each component has unit tests (if logic present)
- [ ] Snapshot tests for visual regression

### Integration Testing

- [ ] Parent views work with extracted components
- [ ] Data flow works correctly
- [ ] State management works

### Manual Testing

- [ ] All features still work after refactor
- [ ] No visual regressions
- [ ] Performance is same or better

## Success Criteria

### File Size

- [ ] No view file >300 lines
- [ ] Most view files <200 lines
- [ ] Clear single responsibility

### Reusability

- [ ] Common components extracted to Shared/
- [ ] No duplicate implementations
- [ ] Easy to use in new contexts

### Maintainability

- [ ] Easy to find relevant code
- [ ] Clear file organization
- [ ] Good separation of concerns

### Testability

- [ ] Components testable in isolation
- [ ] Preview generation fast
- [ ] Easy to mock dependencies

## Next Steps

1. Review decomposition strategy
2. Start with CollectionDetailView (highest impact)
3. Extract sheets first (easiest)
4. Extract shared components
5. Apply to other views

## Related Documents

- `plan-repository-pattern-consistency.md` - ViewModels extract business logic
- `plan-error-handling-improvements.md` - Error handling in components
- `AGENTS.md` - Architecture overview
