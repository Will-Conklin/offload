//
//  OrganizeView.swift
//  Offload
//
//  Simplified design for Plans and Lists tabs using Collections
//

import SwiftUI
import SwiftData

// AGENT NAV
// - Scope
// - Layout
// - Collections
// - Picker
// - Sheets

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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Collection.createdAt, order: .reverse) private var allCollections: [Collection]

    @AppStorage("organize.scope") private var selectedScopeRaw = Scope.plans.rawValue
    @State private var showingCreate = false
    @State private var showingSettings = false
    @State private var showingAccount = false
    @State private var selectedCollection: Collection?

    private var style: ThemeStyle { themeManager.currentStyle }
    private var floatingTabBarClearance: CGFloat {
        Theme.Spacing.xxl + Theme.Spacing.xl + Theme.Spacing.lg + Theme.Spacing.md
    }

    private var selectedScope: Scope {
        Scope(rawValue: selectedScopeRaw) ?? .plans
    }

    private var filteredCollections: [Collection] {
        allCollections.filter { $0.isStructured == selectedScope.isStructured }
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
                    Button {
                        showingAccount = true
                    } label: {
                        IconTile(
                            iconName: Icons.account,
                            iconSize: 18,
                            tileSize: 32,
                            style: .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                        )
                    }
                    .accessibilityLabel("Account")

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
            .sheet(isPresented: $showingCreate) {
                createSheet
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAccount) {
                AccountView()
            }
            .navigationDestination(item: $selectedCollection) { collection in
                CollectionDetailView(collectionID: collection.id)
            }
        }
    }

    // MARK: - Collections Content

    @ViewBuilder
    private var collectionsContent: some View {
        if filteredCollections.isEmpty {
            emptyState
        } else {
            ForEach(Array(filteredCollections.enumerated()), id: \.element.id) { index, collection in
                Button {
                    selectedCollection = collection
                } label: {
                    CollectionCard(paletteIndex: index, collection: collection, colorScheme: colorScheme, style: style)
                }
                .buttonStyle(.plain)
                .cardButtonStyle()
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
            let collection = Collection(name: name, isStructured: selectedScope.isStructured)
            modelContext.insert(collection)
        }
    }
}

// MARK: - Collection Card

private struct CollectionCard: View {
    let paletteIndex: Int
    let collection: Collection
    let colorScheme: ColorScheme
    let style: ThemeStyle

    private var tagNames: [String] {
        let names = collection.collectionItems?
            .compactMap { $0.item?.tags }
            .flatMap { $0 } ?? []
        return Array(Set(names)).sorted()
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

                if !tagNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(tagNames, id: \.self) { tagName in
                                TagPill(
                                    name: tagName,
                                    color: Theme.Colors.tagColor(for: tagName, colorScheme, style: style)
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
}
