// Purpose: Organize feature views and flows.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep collection ordering aligned with Collection.sortedItems and CollectionItem.position.

//  Simplified design for Plans and Lists tabs using Collections

import SwiftUI
import SwiftData

struct OrganizeView: View {
    enum Scope: String, CaseIterable, Identifiable {
        case plans, lists

        var id: String { rawValue }

        var title: String {
            switch self {
            case .plans: return "Plans"
            case .lists: return "Lists"
            }
        }

        var isStructured: Bool {
            switch self {
            case .plans: return true
            case .lists: return false
            }
        }
    }

    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @AppStorage("organize.scope") private var selectedScopeRaw = Scope.plans.rawValue
    @State private var showingCreate = false
    @State private var showingSettings = false
    @State private var selectedCollection: Collection?
    @State private var tagPickerCollection: Collection?
    @State private var errorPresenter = ErrorPresenter()
    @State private var viewModel = OrganizeListViewModel()

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }

    private var selectedScope: Scope {
        Scope(rawValue: selectedScopeRaw) ?? .plans
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Vibrant gradient background
                Theme.Gradients.deepBackground(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.sm) {
                    scopePicker

                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            collectionsContent
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)
                        .padding(.bottom, Theme.Spacing.lg)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: floatingTabBarClearance)
                    }
                }
            }
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        IconTile(
                            iconName: Icons.settings,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingCreate, onDismiss: refreshCollections) {
                createSheet
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $tagPickerCollection) { collection in
                CollectionTagPickerSheet(collection: collection)
                    .presentationDetents([.medium])
            }
            .navigationDestination(item: $selectedCollection) { collection in
                CollectionDetailView(collectionID: collection.id)
            }
            .errorToasts(errorPresenter)
        }
        .onAppear {
            loadScopeIfNeeded()
        }
        .onChange(of: selectedScopeRaw) { _, _ in
            updateScope()
        }
    }

    // MARK: - Collections Content

    @ViewBuilder
    private var collectionsContent: some View {
        if viewModel.collections.isEmpty {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                emptyState
            }
        } else {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) { index, collection in
                Button {
                    selectedCollection = collection
                } label: {
                    CollectionCard(
                        paletteIndex: index,
                        collection: collection,
                        colorScheme: colorScheme,
                        style: style,
                        onAddTag: { tagPickerCollection = collection },
                        onToggleStar: { toggleStar(collection) }
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    if index == viewModel.collections.count - 1 {
                        loadNextPage()
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.sm)
            }

            addCollectionButton
                .padding(.top, Theme.Spacing.sm)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            AppIcon(name: selectedScope == .plans ? Icons.plans : Icons.lists, size: 34)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            Text("No \(selectedScope.title.lowercased()) yet")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            addCollectionButton
                .padding(.top, Theme.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }

    private var addCollectionButton: some View {
        FloatingActionButton(
            title: "Add \(selectedScope == .plans ? "Plan" : "List")",
            iconName: Icons.addCircleFilled
        ) {
            showingCreate = true
        }
        .accessibilityLabel("Add \(selectedScope.title)")
    }

    // MARK: - Scope Picker

    private var scopePicker: some View {
        let fill = Theme.Colors.surface(colorScheme, style: style)

        return HStack(spacing: Theme.Spacing.xs) {
            scopeButton(.plans)
            scopeButton(.lists)
        }
        .padding(Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)
                        .stroke(
                            Theme.Colors.borderMuted(colorScheme, style: style)
                                .opacity(Theme.Opacity.borderMuted(colorScheme)),
                            lineWidth: 0.6
                        )
                )
        )
        .shadow(
            color: Theme.Shadows.ultraLight(colorScheme),
            radius: Theme.Shadows.elevationUltraLight,
            y: Theme.Shadows.offsetYUltraLight
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }

    private func scopeButton(_ scope: Scope) -> some View {
        Button {
            selectedScopeRaw = scope.rawValue
        } label: {
            Text(scope.title)
                .font(selectedScope == scope ? Theme.Typography.subheadlineSemibold : Theme.Typography.subheadline)
                .foregroundStyle(
                    selectedScope == scope
                        ? Theme.Colors.cardTextPrimary(colorScheme, style: style)
                        : Theme.Colors.textSecondary(colorScheme, style: style)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    selectedScope == scope
                        ? Theme.Surface.card(colorScheme, style: style)
                        : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create Sheet

    @ViewBuilder
    private var createSheet: some View {
        CollectionFormSheet(isStructured: selectedScope.isStructured) { name in
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                errorPresenter.present(ValidationError("Collection name cannot be empty."))
                return
            }
            do {
                _ = try collectionRepository.create(
                    name: trimmedName,
                    isStructured: selectedScope.isStructured
                )
            } catch {
                errorPresenter.present(error)
            }
        }
    }

    private func toggleStar(_ collection: Collection) {
        do {
            try collectionRepository.toggleStar(collection)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func loadScopeIfNeeded() {
        guard !viewModel.hasLoaded else { return }
        updateScope()
    }

    private func updateScope() {
        do {
            try viewModel.setScope(isStructured: selectedScope.isStructured, using: collectionRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func loadNextPage() {
        do {
            try viewModel.loadNextPage(using: collectionRepository)
        } catch {
            errorPresenter.present(error)
        }
    }

    private func refreshCollections() {
        do {
            try viewModel.refresh(using: collectionRepository)
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Collection Card

private struct CollectionCard: View {
    let paletteIndex: Int
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onAddTag: () -> Void
    let onToggleStar: () -> Void

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: paletteIndex, colorScheme, style: style)) {
            // MCM card content with custom metadata for collections
            HStack(alignment: .top, spacing: 0) {
                    // Left column (narrow - metadata gutter)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        IconTile(
                            iconName: collection.isStructured ? Icons.plans : Icons.lists,
                            iconSize: 16,
                            tileSize: 36,
                            style: .none(Theme.Colors.icon(colorScheme, style: style))
                        )

                        Text(collection.isStructured ? "PLAN" : "LIST")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                        Text(collection.createdAt, format: .dateTime.month(.abbreviated).day())
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))

                        if let count = collection.collectionItems?.count, count > 0 {
                            Text("\(count) item\(count == 1 ? "" : "s")")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        }
                    }
                    .frame(width: 60, alignment: .leading)

                    // Right column (wide - main content)
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(collection.name)
                            .font(.system(.title2, design: .default).weight(.bold))
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            .lineLimit(3)

                        // Tags in flow layout
                        if !collection.tags.isEmpty {
                            FlowLayout(spacing: Theme.Spacing.xs) {
                                ForEach(collection.tags) { tag in
                                    TagPill(
                                        name: tag.name,
                                        color: tag.color
                                            .map { Color(hex: $0) }
                                            ?? Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                    )
                                }

                                Button(action: onAddTag) {
                                    HStack(spacing: 4) {
                                        AppIcon(name: Icons.add, size: 10)
                                        Text("Tag")
                                            .font(Theme.Typography.caption)
                                    }
                                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                                    .padding(.horizontal, Theme.Spacing.pillHorizontal)
                                    .padding(.vertical, Theme.Spacing.pillVertical)
                                    .background(
                                        Capsule()
                                            .strokeBorder(
                                                Theme.Colors.borderMuted(colorScheme, style: style),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.leading, 12)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: onToggleStar) {
                AppIcon(
                    name: collection.isStarred ? Icons.starFilled : Icons.star,
                    size: 18
                )
                .foregroundStyle(
                    collection.isStarred
                        ? Theme.Colors.caution(colorScheme, style: style)
                        : Theme.Colors.textSecondary(colorScheme, style: style)
                )
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(collection.isStarred ? "Unstar collection" : "Star collection")
        }
    }
}

// MARK: - Form Sheet

private struct CollectionFormSheet: View {
    let isStructured: Bool
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(isStructured ? "Plan name" : "List name", text: $name)
            }
            .navigationTitle(isStructured ? "New Plan" : "New List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Collection Tag Picker Sheet

private struct CollectionTagPickerSheet: View {
    let collection: Collection

    @Environment(\.dismiss) private var dismiss
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var newTagName = ""
    @State private var errorPresenter = ErrorPresenter()
    @FocusState private var focused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                Section("Create New Tag") {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                            .focused($focused)
                        Button("Add") {
                            createTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Select Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if collection.tags.contains(where: { $0.id == tag.id }) {
                                    AppIcon(name: Icons.check, size: 12)
                                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background(colorScheme, style: style))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .errorToasts(errorPresenter)
    }

    private func createTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let tag = try tagRepository.fetchOrCreate(trimmed)
            try collectionRepository.addTag(collection, tag: tag)
            newTagName = ""
        } catch {
            errorPresenter.present(error)
        }
    }

    private func toggleTag(_ tag: Tag) {
        do {
            if collection.tags.contains(where: { $0.id == tag.id }) {
                try collectionRepository.removeTag(collection, tag: tag)
            } else {
                try collectionRepository.addTag(collection, tag: tag)
            }
        } catch {
            errorPresenter.present(error)
        }
    }
}

#Preview {
    OrganizeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
