// Purpose: Brain Dump Compiler sheet — extract and categorize items from long captures, save as list.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

// MARK: - ViewModel

/// Manages the brain dump compilation and editing flow for a single item.
@Observable
@MainActor
final class BrainDumpSheetViewModel {

    enum Phase: Equatable {
        case configure
        case preview
    }

    struct EditableBrainDumpItem: Identifiable {
        let id: UUID
        var title: String
        var itemType: ItemType

        init(title: String, typeString: String) {
            id = UUID()
            self.title = title
            self.itemType = ItemType(rawValue: typeString) ?? .note
        }
    }

    var extractedItems: [EditableBrainDumpItem] = []
    var listName: String = ""
    var isCompiling: Bool = false
    var phase: Phase = .configure

    /// True when `listName` is blank after trimming whitespace.
    var isListNameEmpty: Bool {
        listName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// True when there are no non-empty items to save.
    var hasNoItems: Bool {
        extractedItems.allSatisfy { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Requests a brain dump compilation from the service and transitions to the preview phase.
    /// - Parameters:
    ///   - inputText: The item content to compile.
    ///   - service: The brain dump service to call.
    func compile(inputText: String, using service: BrainDumpService) async throws {
        isCompiling = true
        defer { isCompiling = false }

        let result = try await service.compileBrainDump(
            inputText: inputText,
            contextHints: []
        )

        extractedItems = result.items.map { EditableBrainDumpItem(title: $0.title, typeString: $0.type) }

        if listName.isEmpty {
            listName = String(inputText.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        phase = .preview
    }

    /// Saves the approved items as a new unstructured list collection.
    func save(
        itemRepository: ItemRepository,
        collectionRepository: CollectionRepository,
        collectionItemRepository: CollectionItemRepository
    ) throws {
        let trimmedName = listName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("List name cannot be empty.")
        }

        let collection = try collectionRepository.create(name: trimmedName, isStructured: false)

        for extracted in extractedItems {
            let trimmedTitle = extracted.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }
            let item = try itemRepository.create(type: extracted.itemType.rawValue, content: trimmedTitle)
            _ = try collectionItemRepository.addItemToCollection(
                itemId: item.id,
                collectionId: collection.id,
                position: nil,
                parentId: nil
            )
        }
    }

    /// Removes an item from the preview list.
    func removeItem(_ item: EditableBrainDumpItem) {
        extractedItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Sheet View

/// Presents the Brain Dump Compiler experience: compile a long capture into categorized items, edit, then save as a list.
struct BrainDumpSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.brainDumpService) private var brainDumpService
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.collectionItemRepository) private var collectionItemRepository
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var viewModel = BrainDumpSheetViewModel()
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Surface.background(colorScheme, style: style)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        itemPreviewSection
                            .padding(.top, Theme.Spacing.sm)

                        phaseContent
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
                if viewModel.phase == .preview {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: reduceMotion)) {
                                viewModel.phase = .configure
                            }
                        }
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    }
                }
            }
        }
        .errorToasts(errorPresenter)
    }

    // MARK: - Phase content

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .configure:
            compileButtonSection
        case .preview:
            itemsSection
            listNameSection
            saveButtonSection
        }
    }

    // MARK: - Sections

    private var itemPreviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Capture")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            CardSurface(fill: Theme.Colors.cardColor(index: item.stableColorIndex, colorScheme, style: style)) {
                Text(item.content)
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
            }
            .accessibilityLabel("Capture: \(item.content)")
        }
    }

    @ViewBuilder
    private var compileButtonSection: some View {
        if viewModel.isCompiling {
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Colors.accentPrimary(colorScheme, style: style))
                Text("Extracting items…")
                    .font(Theme.Typography.buttonLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .accessibilityLabel("Extracting items, please wait")
        } else {
            FloatingActionButton(title: "Extract Items", iconName: Icons.brainDump) {
                Task {
                    do {
                        try await viewModel.compile(inputText: item.content, using: brainDumpService)
                    } catch {
                        errorPresenter.present(error)
                    }
                }
            }
            .accessibilityLabel("Extract items from capture")
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Extracted items — tap to edit")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.xs) {
                ForEach($viewModel.extractedItems) { $extracted in
                    BrainDumpItemRow(
                        extracted: $extracted,
                        colorScheme: colorScheme,
                        style: style,
                        onDelete: { viewModel.removeItem(extracted) }
                    )
                }
            }
        }
    }

    private var listNameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("List Name")
                .font(Theme.Typography.metadata)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

            TextField("Name your list", text: $viewModel.listName)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                .padding(Theme.Spacing.md)
                .background(Theme.Surface.card(colorScheme, style: style))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .accessibilityLabel("List name")
                .accessibilityHint("Name for the new list that will be created from these items")
        }
    }

    private var saveButtonSection: some View {
        FloatingActionButton(title: "Save as List", iconName: Icons.lists) {
            saveBrainDump()
        }
        .disabled(viewModel.isListNameEmpty || viewModel.hasNoItems)
        .accessibilityLabel("Save as list")
        .accessibilityHint("Creates a new list with the extracted items")
    }

    // MARK: - Actions

    private func saveBrainDump() {
        do {
            try viewModel.save(
                itemRepository: itemRepository,
                collectionRepository: collectionRepository,
                collectionItemRepository: collectionItemRepository
            )
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Item Row

private struct BrainDumpItemRow: View {
    @Binding var extracted: BrainDumpSheetViewModel.EditableBrainDumpItem

    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onDelete: () -> Void

    var body: some View {
        CardSurface(fill: Theme.Surface.card(colorScheme, style: style)) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                TextField("Item description", text: $extracted.title, axis: .vertical)
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                    .lineLimit(2...)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: Theme.Spacing.xs) {
                    Picker("Type", selection: $extracted.itemType) {
                        ForEach(ItemType.allCases.filter(\.isUserAssignable), id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    .accessibilityLabel("Item type: \(extracted.itemType.displayName)")

                    Button(action: onDelete) {
                        AppIcon(name: Icons.closeCircleFilled, size: 18)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    .accessibilityLabel("Remove item")
                }
            }
            .padding(Theme.Spacing.md)
        }
        .accessibilityLabel("Item: \(extracted.title), type: \(extracted.itemType.displayName)")
        .accessibilityHint("Tap to edit")
    }
}
