//
//  CollectionDetailView.swift
//  Offload
//
//  Unified detail view for both structured (plans) and unstructured (lists) collections
//

import SwiftUI
import SwiftData
import UIKit

// AGENT NAV
// - State
// - Layout
// - Header
// - Quick Add
// - Data Loading
// - Item Row
// - Sheets

struct CollectionDetailView: View {
    let collectionID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var collection: Collection?
    @State private var items: [CollectionItem] = []
    @State private var showingAddItem = false
    @State private var showingEdit = false
    @State private var linkedCollection: Collection?
    @State private var editingItem: Item?
    @State private var tagPickerItem: Item?

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }
    private var tagLookup: [String: Tag] {
        Dictionary(uniqueKeysWithValues: allTags.map { ($0.name, $0) })
    }

    var body: some View {
        ZStack {
            Theme.Colors.background(colorScheme, style: style)
                .ignoresSafeArea()

            if let collection = collection {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        // Collection header
                        collectionHeader(collection)

                        // Items list
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(items) { collectionItem in
                                if let item = collectionItem.item {
                                    ItemRow(
                                        item: item,
                                        collectionItem: collectionItem,
                                        isStructured: collection.isStructured,
                                        colorScheme: colorScheme,
                                        style: style,
                                        tagLookup: tagLookup,
                                        onAddTag: { tagPickerItem = item },
                                        onDelete: { deleteItem(collectionItem) },
                                        onEdit: { editingItem = item },
                                        onOpenLink: { openLinkedCollection($0) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        quickAddButton
                            .padding(.top, Theme.Spacing.sm)
                            .padding(.bottom, Theme.Spacing.sm)
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: floatingTabBarClearance)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEdit = true } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(collectionID: collectionID, collection: collection)
        }
        .sheet(isPresented: $showingEdit) {
            if let collection = collection {
                EditCollectionSheet(collection: collection)
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditSheet(item: item)
        }
        .sheet(item: $tagPickerItem) { item in
            TagPickerSheet(
                item: item,
                allTags: allTags,
                colorScheme: colorScheme,
                style: style,
                onCreateTag: { name in
                    createTag(name: name, for: item)
                },
                onToggleTag: { tag in
                    toggleTag(tag, for: item)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $linkedCollection) { collection in
            CollectionDetailView(collectionID: collection.id)
        }
        .onChange(of: showingAddItem) { _, isPresented in
            if !isPresented {
                loadItems()
            }
        }
        .onAppear {
            loadCollection()
        }
    }

    // MARK: - Collection Header

    private func collectionHeader(_ collection: Collection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(collection.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                Spacer()
            }

            Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button {
            showingAddItem = true
        } label: {
            HStack {
                AppIcon(name: Icons.addCircleFilled, size: 18)
                Text("Add Item")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.primary(colorScheme, style: style))
            .clipShape(Capsule())
            .shadow(radius: 4)
        }
    }

    // MARK: - Data Loading

    private func loadCollection() {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.id == collectionID }
        )
        if let fetchedCollection = try? modelContext.fetch(descriptor).first {
            self.collection = fetchedCollection
            loadItems()
        }
    }

    private func loadItems() {
        guard let collection = collection else { return }
        self.items = collection.sortedItems
    }

    private func deleteItem(_ collectionItem: CollectionItem) {
        modelContext.delete(collectionItem)
        try? modelContext.save()
        loadItems()
    }

    private func createTag(name: String, for item: Item) {
        let tag = Tag(name: name)
        modelContext.insert(tag)
        if !item.tags.contains(name) {
            item.tags.append(name)
        }
    }

    private func toggleTag(_ tag: Tag, for item: Item) {
        if let index = item.tags.firstIndex(of: tag.name) {
            item.tags.remove(at: index)
        } else {
            item.tags.append(tag.name)
        }
    }

    private func openLinkedCollection(_ collectionID: UUID) {
        let targetId = collectionID
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate<Collection> { collection in
                collection.id == targetId
            }
        )
        if let fetched = try? modelContext.fetch(descriptor).first {
            linkedCollection = fetched
        }
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    let item: Item
    let collectionItem: CollectionItem
    let isStructured: Bool
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let tagLookup: [String: Tag]
    let onAddTag: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onOpenLink: (UUID) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showingMenu = false
    @State private var linkedCollectionName: String?

    private var isLink: Bool {
        item.itemType == .link
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(displayTitle)
                        .font(.body)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))

                    if let attachmentData = item.attachmentData,
                       let uiImage = UIImage(data: attachmentData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 140)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    }

                    if let type = item.type {
                        Text(type.capitalized)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button {
                    showingMenu = true
                } label: {
                    AppIcon(name: Icons.more, size: 12)
                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                        .frame(width: 28, height: 28)
                }
                .confirmationDialog("Item Actions", isPresented: $showingMenu) {
                    Button("Remove from Collection", role: .destructive) {
                        onDelete()
                    }
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                ItemActionButton(
                    iconName: Icons.add,
                    tint: Theme.Colors.primary(colorScheme, style: style),
                    action: onAddTag
                )

                if item.tags.isEmpty {
                    Spacer()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(item.tags, id: \.self) { tagName in
                                TagPill(
                                    name: tagName,
                                    color: tagLookup[tagName]
                                        .flatMap { $0.color }
                                        .map { Color(hex: $0) }
                                        ?? Theme.Colors.primary(colorScheme, style: style),
                                    colorScheme: colorScheme,
                                    style: style
                                )
                            }
                        }
                    }
                }

                ItemActionButton(
                    iconName: item.isStarred ? Icons.starFilled : Icons.star,
                    tint: item.isStarred
                        ? Theme.Colors.caution(colorScheme, style: style)
                        : Theme.Colors.cardTextSecondary(colorScheme, style: style),
                    action: toggleStar
                )
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.card(colorScheme, style: style))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .contentShape(Rectangle())
        .onTapGesture {
            if isLink, let linkedId = item.linkedCollectionId {
                onOpenLink(linkedId)
            } else {
                onEdit()
            }
        }
        .onAppear {
            loadLinkedCollectionName()
        }
        .onChange(of: item.linkedCollectionId) { _, _ in
            loadLinkedCollectionName()
        }
    }

    private var displayTitle: String {
        if isLink, let linkedCollectionName = linkedCollectionName {
            return linkedCollectionName
        }
        if isLink, item.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Linked Collection"
        }
        return item.content
    }

    private func toggleStar() {
        item.isStarred.toggle()
        try? modelContext.save()
    }

    private func loadLinkedCollectionName() {
        guard let linkedId = item.linkedCollectionId else {
            linkedCollectionName = nil
            return
        }
        let targetId = linkedId
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate<Collection> { collection in
                collection.id == targetId
            }
        )
        linkedCollectionName = (try? modelContext.fetch(descriptor).first)?.name
    }
}

// MARK: - Tag Picker Sheet

private struct TagPickerSheet: View {
    let item: Item
    let allTags: [Tag]
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onCreateTag: (String) -> Void
    let onToggleTag: (Tag) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newTagName = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Create New Tag") {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                            .focused($focused)
                        Button("Add") {
                            onCreateTag(newTagName)
                            newTagName = ""
                        }
                        .disabled(newTagName.isEmpty)
                    }
                }

                Section("Select Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            onToggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if item.tags.contains(tag.name) {
                                    AppIcon(name: Icons.check, size: 12)
                                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Tag Selection Sheet

private struct TagSelectionSheet: View {
    @Binding var selectedTags: [Tag]
    let colorScheme: ColorScheme
    let style: ThemeStyle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var allTags: [Tag] = []
    @State private var newName = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New tag", text: $newName)
                            .focused($focused)
                        Button("Add") {
                            let tag = Tag(name: newName)
                            modelContext.insert(tag)
                            allTags.append(tag)
                            selectedTags.append(tag)
                            newName = ""
                        }
                        .disabled(newName.isEmpty)
                    }
                }

                Section("Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                selectedTags.remove(at: index)
                            } else {
                                selectedTags.append(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    AppIcon(name: Icons.check, size: 12)
                                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                let desc = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
                allTags = (try? modelContext.fetch(desc)) ?? []
            }
        }
    }
}

// MARK: - Tag Pill

private struct TagPill: View {
    let name: String
    let color: Color
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        Text(name)
            .font(.caption)
            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.Colors.cardTextPrimary(colorScheme, style: style).opacity(0.14))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.6), lineWidth: 1)
            )
    }
}

// MARK: - Item Action Button

private struct ItemActionButton: View {
    let iconName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(name: iconName, size: 12)
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.16))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Edit Sheet

private struct ItemEditSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var content: String

    init(item: Item) {
        self.item = item
        _content = State(initialValue: item.content)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }

                if let attachmentData = item.attachmentData,
                   let uiImage = UIImage(data: attachmentData) {
                    Section("Attachment") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
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
                    Button("Save") {
                        item.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Item Sheet

private struct AddItemSheet: View {
    let collectionID: UUID
    let collection: Collection?

    @Query(sort: \Collection.name) private var collections: [Collection]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var content = ""
    @State private var type: ItemType = .task
    @State private var isStarred = false
    @State private var selectedTags: [Tag] = []
    @State private var linkedCollectionId: UUID?
    @State private var attachmentData: Data?
    @State private var showingTags = false
    @State private var voiceService = VoiceRecordingService()
    @State private var preRecordingText = ""
    @State private var showingPermissionAlert = false
    @State private var showingAttachmentSource = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingCameraUnavailableAlert = false

    @FocusState private var isFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    private var linkableCollections: [Collection] {
        collections.filter { $0.id != collectionID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputSection
                Spacer()
                bottomBar
            }
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTags) {
                TagSelectionSheet(
                    selectedTags: $selectedTags,
                    colorScheme: colorScheme,
                    style: style
                )
                .presentationDetents([.medium])
            }
            .confirmationDialog("Add Attachment", isPresented: $showingAttachmentSource) {
                Button("Camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    } else {
                        showingCameraUnavailableAlert = true
                    }
                }
                Button("Photo Library") {
                    imagePickerSource = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imagePickerSource, imageData: $attachmentData)
            }
            .alert("Mic Permission Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device does not support camera capture.")
            }
            .onChange(of: voiceService.transcribedText) { _, newValue in
                guard type != .link, !newValue.isEmpty else { return }
                let sep = preRecordingText.isEmpty || preRecordingText.hasSuffix(" ") ? "" : " "
                content = preRecordingText + sep + newValue
            }
            .onAppear {
                isFocused = true
                if type == .link && linkedCollectionId == nil {
                    linkedCollectionId = linkableCollections.first?.id
                }
            }
            .onChange(of: type) { _, newValue in
                if newValue == .link {
                    if voiceService.isRecording {
                        voiceService.stopRecording()
                    }
                    linkedCollectionId = linkableCollections.first?.id
                } else {
                    linkedCollectionId = nil
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Picker("Type", selection: $type) {
                ForEach(ItemType.allCases, id: \.self) { itemType in
                    Text(itemType.displayName).tag(itemType)
                }
            }
            .pickerStyle(.segmented)

            if type == .link {
                linkPicker
            } else {
                TextEditor(text: $content)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                    .frame(minHeight: 100)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty && !isFocused {
                            Text("Add details...")
                                .font(.body)
                                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }

                if voiceService.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.destructive(colorScheme, style: style))
                            .frame(width: 8, height: 8)
                        Text(formatDuration(voiceService.recordingDuration))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                    }
                }

                if let attachmentData, let uiImage = UIImage(data: attachmentData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                        Button {
                            self.attachmentData = nil
                        } label: {
                            AppIcon(name: Icons.closeCircleFilled, size: 18)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .padding(4)
                    }
                }

            }

            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedTags) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.card(colorScheme, style: style))
    }

    private var linkPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Linked Collection")
                .font(.caption)
                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

            if linkableCollections.isEmpty {
                Text("No other collections available.")
                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
            } else {
                Picker("Collection", selection: $linkedCollectionId) {
                    ForEach(linkableCollections) { collection in
                        Text(collection.name).tag(Optional(collection.id))
                    }
                }
                .pickerStyle(.menu)
                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            if type != .link {
                Button(action: handleVoice) {
                    AppIcon(
                        name: voiceService.isRecording ? Icons.stopFilled : Icons.microphone,
                        size: 20
                    )
                        .foregroundStyle(
                            voiceService.isRecording
                                ? Theme.Colors.destructive(colorScheme, style: style)
                                : Theme.Colors.textSecondary(colorScheme, style: style)
                        )
                        .frame(width: 44, height: 44)
                }

                Button { showingAttachmentSource = true } label: {
                    AppIcon(
                        name: attachmentData != nil ? Icons.cameraFilled : Icons.camera,
                        size: 20
                    )
                        .foregroundStyle(
                            attachmentData != nil
                                ? Theme.Colors.primary(colorScheme, style: style)
                                : Theme.Colors.textSecondary(colorScheme, style: style)
                        )
                        .frame(width: 44, height: 44)
                }
            }

            Button { showingTags = true } label: {
                AppIcon(
                    name: selectedTags.isEmpty ? Icons.tag : Icons.tagFilled,
                    size: 20
                )
                    .foregroundStyle(
                        selectedTags.isEmpty
                            ? Theme.Colors.textSecondary(colorScheme, style: style)
                            : Theme.Colors.primary(colorScheme, style: style)
                    )
                    .frame(width: 44, height: 44)
            }

            Button { isStarred.toggle() } label: {
                AppIcon(
                    name: isStarred ? Icons.starFilled : Icons.star,
                    size: 20
                )
                    .foregroundStyle(
                        isStarred
                            ? Theme.Colors.caution(colorScheme, style: style)
                            : Theme.Colors.textSecondary(colorScheme, style: style)
                    )
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: save) {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.primary(colorScheme, style: style))
                    .clipShape(Capsule())
            }
            .disabled(isAddDisabled)
            .opacity(isAddDisabled ? 0.5 : 1)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface(colorScheme, style: style))
    }

    private func handleVoice() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            preRecordingText = content
            _Concurrency.Task {
                do { try await voiceService.startRecording() }
                catch { showingPermissionAlert = true }
            }
        }
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }

    private var isAddDisabled: Bool {
        if type == .link {
            return linkedCollectionId == nil
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        if voiceService.isRecording { voiceService.stopRecording() }
        addItem()
        dismiss()
    }

    private func addItem() {
        let linkedId = type == .link ? linkedCollectionId : nil
        let linkedName = linkableCollections.first { $0.id == linkedId }?.name
        let resolvedContent = type == .link ? (linkedName ?? "Linked Collection") : content
        let item = Item(
            type: type.rawValue,
            content: resolvedContent.trimmingCharacters(in: .whitespacesAndNewlines),
            attachmentData: attachmentData,
            linkedCollectionId: linkedId,
            tags: selectedTags.map { $0.name },
            isStarred: isStarred
        )
        modelContext.insert(item)

        var position: Int? = nil
        if let collection = collection {
            if collection.isStructured {
                position = collection.collectionItems?.count ?? 0
            }
        }

        let collectionItem = CollectionItem(
            collectionId: collectionID,
            itemId: item.id,
            position: position
        )
        if let collection = collection {
            collectionItem.collection = collection
            collectionItem.item = item
        }
        modelContext.insert(collectionItem)

        try? modelContext.save()
    }
}

// MARK: - Edit Collection Sheet

private struct EditCollectionSheet: View {
    let collection: Collection

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    init(collection: Collection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Collection name", text: $name)
                }

                Section {
                    Button("Delete Collection", role: .destructive) {
                        modelContext.delete(collection)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        collection.name = name
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CollectionDetailView(collectionID: UUID())
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
