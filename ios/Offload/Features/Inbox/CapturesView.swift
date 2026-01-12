//
//  CapturesView.swift
//  Offload
//
//  Flat design captures list with inline tagging and swipe actions
//

import SwiftUI
import SwiftData

struct CapturesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingSettings = false
    @State private var workflowService: CaptureWorkflowService?
    @State private var entries: [CaptureEntry] = []
    @State private var allTags: [Tag] = []
    @State private var errorMessage: String?
    @State private var selectedEntry: CaptureEntry?
    @State private var tagPickerEntry: CaptureEntry?
    @State private var moveEntry: CaptureEntry?
    @State private var moveDestination: MoveDestination?

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(entries) { entry in
                            CaptureCard(
                                entry: entry,
                                colorScheme: colorScheme,
                                style: style,
                                onTap: { selectedEntry = entry },
                                onAddTag: {
                                    tagPickerEntry = entry
                                },
                                onDelete: { deleteEntry(entry) },
                                onComplete: { completeEntry(entry) },
                                onMoveTo: { destination in
                                    moveEntry(entry, to: destination)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            .navigationTitle("Captures")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: Icons.settings)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $selectedEntry) { entry in
                CaptureEditView(entry: entry)
            }
            .sheet(item: $tagPickerEntry) { entry in
                TagPickerSheet(
                    entry: entry,
                    allTags: allTags,
                    colorScheme: colorScheme,
                    style: style,
                    onCreateTag: { name in
                        createTag(name: name, for: entry)
                    },
                    onToggleTag: { tag in
                        toggleTag(tag, for: entry)
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: .constant(moveEntry != nil && moveDestination == .plan)) {
                if let entry = moveEntry {
                    MoveToPlanSheet(entry: entry, modelContext: modelContext) {
                        moveEntry = nil
                        moveDestination = nil
                        _Concurrency.Task { await loadData() }
                    }
                }
            }
            .sheet(isPresented: .constant(moveEntry != nil && moveDestination == .list)) {
                if let entry = moveEntry {
                    MoveToListSheet(entry: entry, modelContext: modelContext) {
                        moveEntry = nil
                        moveDestination = nil
                        _Concurrency.Task { await loadData() }
                    }
                }
            }
            .task {
                if workflowService == nil {
                    workflowService = CaptureWorkflowService(modelContext: modelContext)
                }
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let workflowService = workflowService else { return }
        do {
            entries = try workflowService.fetchInbox()
            allTags = try fetchAllTags()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchAllTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Actions

    private func deleteEntry(_ entry: CaptureEntry) {
        guard let workflowService = workflowService else { return }
        _Concurrency.Task {
            do {
                try await workflowService.deleteEntry(entry)
                await loadData()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }

    private func completeEntry(_ entry: CaptureEntry) {
        entry.currentLifecycleState = .archived
        _Concurrency.Task { await loadData() }
    }

    private func moveEntry(_ entry: CaptureEntry, to destination: MoveDestination) {
        moveEntry = entry
        moveDestination = destination
    }

    private func createTag(name: String, for entry: CaptureEntry) {
        let tag = Tag(name: name)
        modelContext.insert(tag)
        if entry.tags == nil {
            entry.tags = [tag]
        } else {
            entry.tags?.append(tag)
        }
        _Concurrency.Task { await loadData() }
    }

    private func toggleTag(_ tag: Tag, for entry: CaptureEntry) {
        if let index = entry.tags?.firstIndex(where: { $0.id == tag.id }) {
            entry.tags?.remove(at: index)
        } else {
            if entry.tags == nil {
                entry.tags = [tag]
            } else {
                entry.tags?.append(tag)
            }
        }
    }
}

// MARK: - Move Destination

enum MoveDestination {
    case plan
    case list
}

// MARK: - Capture Card

private struct CaptureCard: View {
    let entry: CaptureEntry
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onTap: () -> Void
    let onAddTag: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void
    let onMoveTo: (MoveDestination) -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // Swipe background
            HStack(spacing: 0) {
                // Complete (swipe right)
                Theme.Colors.success(colorScheme, style: style)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.leading, Theme.Spacing.lg),
                        alignment: .leading
                    )

                Spacer()

                // Delete (swipe left)
                Theme.Colors.destructive(colorScheme, style: style)
                    .overlay(
                        Image(systemName: "trash")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.trailing, Theme.Spacing.lg),
                        alignment: .trailing
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

            // Card content
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Main text
                Text(entry.rawText)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Tags row
                HStack(spacing: Theme.Spacing.xs) {
                    // Existing tags
                    if let tags = entry.tags, !tags.isEmpty {
                        ForEach(tags) { tag in
                            TagChip(tag: tag, colorScheme: colorScheme, style: style)
                        }
                    }

                    // Add tag button
                    Button(action: onAddTag) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    .highPriorityGesture(TapGesture().onEnded { onAddTag() })

                    Spacer()

                    // Metadata
                    HStack(spacing: Theme.Spacing.xs) {
                        if entry.entryInputType == .voice {
                            Image(systemName: "waveform")
                                .font(.caption)
                        }
                        Text(entry.createdAt, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.card(colorScheme, style: style))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width > 100 {
                                offset = 0
                                onComplete()
                            } else if value.translation.width < -100 {
                                offset = 0
                                onDelete()
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
            .onTapGesture(perform: onTap)
            .contextMenu {
                Button {
                    onMoveTo(.plan)
                } label: {
                    Label("Move to Plan", systemImage: Icons.plans)
                }

                Button {
                    onMoveTo(.list)
                } label: {
                    Label("Move to List", systemImage: Icons.lists)
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: Tag
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var chipColor: Color {
        if let colorHex = tag.color {
            return Color(hex: colorHex)
        }
        return Theme.Colors.primary(colorScheme, style: style)
    }

    var body: some View {
        Text(tag.name)
            .font(.caption.weight(.medium))
            .foregroundStyle(chipColor)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(chipColor.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Tag Picker Sheet

private struct TagPickerSheet: View {
    let entry: CaptureEntry
    let allTags: [Tag]
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onCreateTag: (String) -> Void
    let onToggleTag: (Tag) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newTagName = ""

    var body: some View {
        NavigationStack {
            List {
                // Create new tag
                Section {
                    HStack {
                        TextField("New tag name", text: $newTagName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            onCreateTag(trimmed)
                            newTagName = ""
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Create New Tag")
                }

                // Existing tags
                if !allTags.isEmpty {
                    Section("Select Tags") {
                        ForEach(allTags) { tag in
                            Button {
                                onToggleTag(tag)
                            } label: {
                                HStack {
                                    Text(tag.name)
                                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                    Spacer()
                                    if entry.tags?.contains(where: { $0.id == tag.id }) == true {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Text("No tags yet. Create one above!")
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Add Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Capture Edit View

struct CaptureEditView: View {
    @Bindable var entry: CaptureEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var editedText: String = ""
    @State private var showingTagPicker = false
    @State private var allTags: [Tag] = []

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Text editor
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Content")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                        TextEditor(text: $editedText)
                            .font(.body)
                            .frame(minHeight: 150)
                            .padding(Theme.Spacing.sm)
                            .background(Theme.Colors.surface(colorScheme, style: style))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                    .stroke(Theme.Colors.border(colorScheme, style: style), lineWidth: 1)
                            )
                    }

                    // Tags section
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Tags")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                            Spacer()

                            Button {
                                showingTagPicker = true
                            } label: {
                                Label("Add Tag", systemImage: "plus.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                            }
                        }

                        if let tags = entry.tags, !tags.isEmpty {
                            FlowLayout(spacing: Theme.Spacing.xs) {
                                ForEach(tags) { tag in
                                    TagChipRemovable(
                                        tag: tag,
                                        colorScheme: colorScheme,
                                        style: style,
                                        onRemove: { removeTag(tag) }
                                    )
                                }
                            }
                        } else {
                            Text("No tags")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                                .padding(.vertical, Theme.Spacing.sm)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background(colorScheme, style: style))
            .navigationTitle("Edit Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.rawText = editedText
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerSheet(
                    entry: entry,
                    allTags: allTags,
                    colorScheme: colorScheme,
                    style: style,
                    onCreateTag: { name in
                        let tag = Tag(name: name)
                        modelContext.insert(tag)
                        if entry.tags == nil {
                            entry.tags = []
                        }
                        entry.tags?.append(tag)
                        loadTags()
                    },
                    onToggleTag: { tag in
                        if let tags = entry.tags, tags.contains(where: { $0.id == tag.id }) {
                            entry.tags?.removeAll(where: { $0.id == tag.id })
                        } else {
                            if entry.tags == nil {
                                entry.tags = []
                            }
                            entry.tags?.append(tag)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                editedText = entry.rawText
                loadTags()
            }
        }
    }

    private func loadTags() {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        allTags = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func removeTag(_ tag: Tag) {
        entry.tags?.removeAll(where: { $0.id == tag.id })
    }
}

// MARK: - Tag Chip with Remove Button

private struct TagChipRemovable: View {
    let tag: Tag
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onRemove: () -> Void

    var chipColor: Color {
        if let colorHex = tag.color {
            return Color(hex: colorHex)
        }
        return Theme.Colors.primary(colorScheme, style: style)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(chipColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(chipColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout for Tags

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                      y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Move to Plan Sheet

private struct MoveToPlanSheet: View {
    let entry: CaptureEntry
    let modelContext: ModelContext
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newPlanName = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !collections.isEmpty {
                    Section("Select Plan") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelectedPlan()
                            } label: {
                                Text(collection.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label("Create New Plan", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New Plan", isPresented: $createNew) {
                TextField("Plan name", text: $newPlanName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewPlanAndMove()
                }
            } message: {
                Text("Enter a name for the new plan")
            }
            .onAppear {
                loadCollections()
            }
        }
    }

    private func loadCollections() {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        collections = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func moveToSelectedPlan() {
        guard let collection = selectedCollection else { return }

        // Create item
        let item = Item(type: "task", content: entry.rawText)
        modelContext.insert(item)

        // Link to collection
        let position = collection.collectionItems?.count ?? 0
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: position
        )
        modelContext.insert(collectionItem)

        entry.currentLifecycleState = .placed
        dismiss()
        onComplete()
    }

    private func createNewPlanAndMove() {
        let trimmed = newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Create collection
        let collection = Collection(name: trimmed, isStructured: true)
        modelContext.insert(collection)

        // Create item
        let item = Item(type: "task", content: entry.rawText)
        modelContext.insert(item)

        // Link to collection
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: 0
        )
        modelContext.insert(collectionItem)

        entry.currentLifecycleState = .placed
        dismiss()
        onComplete()
    }
}

// MARK: - Move to List Sheet

private struct MoveToListSheet: View {
    let entry: CaptureEntry
    let modelContext: ModelContext
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newListName = ""

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                if !collections.isEmpty {
                    Section("Select List") {
                        ForEach(collections) { collection in
                            Button {
                                selectedCollection = collection
                                moveToSelectedList()
                            } label: {
                                Text(collection.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            }
                        }
                    }
                }

                Section {
                    Button {
                        createNew = true
                    } label: {
                        Label("Create New List", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                    }
                }
            }
            .navigationTitle("Move to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New List", isPresented: $createNew) {
                TextField("List name", text: $newListName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewListAndMove()
                }
            } message: {
                Text("Enter a name for the new list")
            }
            .onAppear {
                loadCollections()
            }
        }
    }

    private func loadCollections() {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        collections = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func moveToSelectedList() {
        guard let collection = selectedCollection else { return }

        // Create item
        let item = Item(type: "note", content: entry.rawText)
        modelContext.insert(item)

        // Link to collection (no position for unstructured lists)
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: nil
        )
        modelContext.insert(collectionItem)

        entry.currentLifecycleState = .placed
        dismiss()
        onComplete()
    }

    private func createNewListAndMove() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Create collection
        let collection = Collection(name: trimmed, isStructured: false)
        modelContext.insert(collection)

        // Create item
        let item = Item(type: "note", content: entry.rawText)
        modelContext.insert(item)

        // Link to collection
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: nil
        )
        modelContext.insert(collectionItem)

        entry.currentLifecycleState = .placed
        dismiss()
        onComplete()
    }
}

#Preview {
    CapturesView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
