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
                Theme.Colors.background(colorScheme, style: style)
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
                    CollectionCard(paletteIndex: index, collection: collection, colorScheme: colorScheme, style: style)
                }
                .buttonStyle(.plain)
                .cardButtonStyle()
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

    private var tags: [Tag] {
        let tags = collection.collectionItems?
            .compactMap { $0.item?.tags }
            .flatMap { $0 } ?? []
        return Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })
            .values
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(collection.name)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))

                    Spacer()
                }

                HStack {
                    Text(collection.createdAt, format: .dateTime.month(.abbreviated).day())
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

                    Spacer()

                    if let count = collection.collectionItems?.count, count > 0 {
                        Text("\(count) item\(count == 1 ? "" : "s")")
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                    }
                }

                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(tags) { tag in
                                TagPill(
                                    name: tag.name,
                                    color: tag.color
                                        .map { Color(hex: $0) }
                                        ?? Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                )
                            }
                        }
                    }
                }
            }
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

#Preview {
    OrganizeView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
        .withToast()
}
