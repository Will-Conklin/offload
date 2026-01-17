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
                        LazyVStack(spacing: Theme.Spacing.md) {
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
        .navigationBarTitleDisplayMode(.large)
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
            ItemTagPickerSheet(item: item)
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
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                Spacer()
            }

            Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        FloatingActionButton(title: "Add Item", iconName: Icons.addCircleFilled) {
            showingAddItem = true
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
        Button {
            if isLink, let linkedId = item.linkedCollectionId {
                onOpenLink(linkedId)
            } else {
                onEdit()
            }
        } label: {
            CardSurface {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(displayTitle)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))

                            if let attachmentData = item.attachmentData,
                               let uiImage = UIImage(data: attachmentData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                            }

                            if let type = item.type {
                                TypeChip(type: type)
                            }
                        }

                        Spacer()

                        Button {
                            showingMenu = true
                        } label: {
                            IconTile(
                                iconName: Icons.more,
                                iconSize: 16,
                                tileSize: 32,
                                style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                            )
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Item Actions", isPresented: $showingMenu) {
                            Button("Remove from Collection", role: .destructive) {
                                onDelete()
                            }
                        }
                    }

                    ItemActionRow(
                        tags: item.tags,
                        tagLookup: tagLookup,
                        isStarred: item.isStarred,
                        onAddTag: onAddTag,
                        onToggleStar: toggleStar
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .cardButtonStyle()
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
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.large)
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
        collections.filter { $0.id != collectionID && !$0.isStructured }
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTags) {
                TagSelectionSheet(selectedTags: $selectedTags)
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
                if type == .link {
                    if linkedCollectionId == nil || linkedCollectionId == collectionID {
                        linkedCollectionId = linkableCollections.first?.id
                    }
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
        InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
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
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                        .frame(minHeight: 100)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty && !isFocused {
                                Text("Add details...")
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface(colorScheme, style: style))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                                .stroke(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.35), lineWidth: 0.6)
                        )

                    if voiceService.isRecording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.Colors.destructive(colorScheme, style: style))
                                .frame(width: 8, height: 8)
                            Text(formatDuration(voiceService.recordingDuration))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                        }
                    }

                    if let attachmentData, let uiImage = UIImage(data: attachmentData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))

                            Button {
                                self.attachmentData = nil
                            } label: {
                                IconTile(
                                    iconName: Icons.closeCircleFilled,
                                    iconSize: 16,
                                    tileSize: 32,
                                    style: .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                                )
                                .shadow(color: Theme.Shadows.ultraLight(colorScheme), radius: Theme.Shadows.elevationUltraLight, y: Theme.Shadows.offsetYUltraLight)
                            }
                            .padding(4)
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(selectedTags) { tag in
                                TagPill(
                                    name: tag.name,
                                    color: Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var linkPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Linked List")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

            if linkableCollections.isEmpty {
                Text("No lists available.")
                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
            } else {
                Picker("List", selection: $linkedCollectionId) {
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
        ActionBarContainer(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
            HStack(spacing: Theme.Spacing.md) {
                if type != .link {
                    Button(action: handleVoice) {
                        IconTile(
                            iconName: voiceService.isRecording ? Icons.stopFilled : Icons.microphone,
                            iconSize: 20,
                            tileSize: 44,
                            style: voiceService.isRecording
                                ? .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                                : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .buttonStyle(.plain)

                    Button { showingAttachmentSource = true } label: {
                        IconTile(
                            iconName: attachmentData != nil ? Icons.cameraFilled : Icons.camera,
                            iconSize: 20,
                            tileSize: 44,
                            style: attachmentData != nil
                                ? .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                                : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button { showingTags = true } label: {
                    IconTile(
                        iconName: selectedTags.isEmpty ? Icons.tag : Icons.tagFilled,
                        iconSize: 20,
                        tileSize: 44,
                        style: selectedTags.isEmpty
                            ? .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                            : .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)

                Button { isStarred.toggle() } label: {
                    IconTile(
                        iconName: isStarred ? Icons.starFilled : Icons.star,
                        iconSize: 20,
                        tileSize: 44,
                        style: isStarred
                            ? .primaryFilled(Theme.Colors.caution(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.buttonDark(colorScheme))
                        .clipShape(Capsule())
                        .shadow(
                            color: Theme.Shadows.ultraLight(colorScheme),
                            radius: Theme.Shadows.elevationUltraLight,
                            y: Theme.Shadows.offsetYUltraLight
                        )
                }
                .disabled(isAddDisabled)
                .opacity(isAddDisabled ? 0.5 : 1)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
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
            return linkedCollectionId == nil || linkedCollectionId == collectionID
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
            .navigationBarTitleDisplayMode(.large)
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
