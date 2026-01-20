// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve established theme defaults and component APIs.


import SwiftUI
import SwiftData


// MARK: - Buttons

struct FloatingActionButton: View {
    let title: String
    let iconName: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                AppIcon(name: iconName, size: 14)
            }
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.md)
                .background(
                    Capsule()
                        .fill(Theme.Colors.buttonDark(colorScheme))
                )
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationSm, y: Theme.Shadows.offsetYSm)
        }
    }
}

// MARK: - Icon Tiles

enum IconContainerStyle {
    case primaryFilled(Color)
    case secondaryOutlined(Color)
    case none(Color)
}

struct IconTile: View {
    let iconName: String
    var iconSize: CGFloat = 16
    var tileSize: CGFloat = 36
    let style: IconContainerStyle

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        AppIcon(name: iconName, size: iconSize)
            .foregroundStyle(iconColor)
            .frame(width: tileSize, height: tileSize)
            .background(tileBackground)
            .overlay(tileBorder)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.iconTile, style: .continuous))
    }

    private var iconColor: Color {
        Theme.Colors.icon(colorScheme, style: themeManager.currentStyle)
    }

    private var tileBackground: Color {
        .clear
    }

    @ViewBuilder
    private var tileBorder: some View {
        EmptyView()
    }
}

// MARK: - Cards

struct AnyShape: Shape, @unchecked Sendable {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        self.pathBuilder = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.Cards.pressScale : 1)
            .animation(Theme.Animations.easeInOutShort, value: configuration.isPressed)
    }
}

enum CardVariant {
    case floatingSoft
}

struct CardSurface<Content: View>: View {
    let shape: AnyShape
    let fill: Color?
    let showsEdge: Bool
    let showsBorder: Bool
    let contentPadding: EdgeInsets
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(
        shape: AnyShape = AnyShape(Theme.Shapes.card()),
        fill: Color? = nil,
        showsEdge: Bool = true,
        showsBorder: Bool = true,
        contentPadding: EdgeInsets = EdgeInsets(
            top: Theme.Cards.contentPadding,
            leading: Theme.Cards.contentPadding,
            bottom: Theme.Cards.contentPadding,
            trailing: Theme.Cards.contentPadding
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.shape = shape
        self.fill = fill
        self.showsEdge = showsEdge
        self.showsBorder = showsBorder
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        let style = themeManager.currentStyle
        let cardFill = fill ?? Theme.Colors.surface(colorScheme, style: style)

        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                shape
                    .fill(cardFill)
                    .overlay(edgeOverlay, alignment: .leading)
                    .overlay(borderOverlay)
            )
            .shadow(
                color: Theme.Shadows.ultraLight(colorScheme),
                radius: Theme.Shadows.elevationUltraLight,
                y: Theme.Shadows.offsetYUltraLight
            )
    }

    @ViewBuilder
    private var edgeOverlay: some View {
        if showsEdge {
            Rectangle()
                .fill(Color.black.opacity(Theme.Opacity.cardEdge(colorScheme)))
                .frame(width: Theme.Cards.edgeWidth)
                .blendMode(.multiply)
                .clipShape(shape)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if showsBorder {
            shape.stroke(
                Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle)
                    .opacity(Theme.Opacity.borderMuted(colorScheme)),
                lineWidth: Theme.Cards.borderWidth
            )
        }
    }
}

struct InputCard<Content: View>: View {
    let fill: Color?
    let content: Content

    init(fill: Color? = nil, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        CardSurface(
            shape: AnyShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)),
            fill: fill,
            showsEdge: true,
            showsBorder: true
        ) {
            content
        }
    }
}

struct ActionBarContainer<Content: View>: View {
    let fill: Color?
    let showsBorder: Bool
    let content: Content

    init(fill: Color? = nil, showsBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.showsBorder = showsBorder
        self.content = content()
    }

    var body: some View {
        CardSurface(
            shape: AnyShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous)),
            fill: fill,
            showsEdge: false,
            showsBorder: showsBorder,
            contentPadding: EdgeInsets()
        ) {
            content
        }
    }
}

struct CardContainer<Content: View>: View {
    let variant: CardVariant
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(variant: CardVariant = .floatingSoft, @ViewBuilder content: () -> Content) {
        self.variant = variant
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: themeManager.currentStyle))
            .background(Theme.Surface.card(colorScheme, style: themeManager.currentStyle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous))
            .shadow(color: Theme.Shadows.ultraLight(colorScheme), radius: Theme.Shadows.elevationUltraLight, y: Theme.Shadows.offsetYUltraLight)
    }
}

extension View {
    func cardButtonStyle() -> some View {
        buttonStyle(CardButtonStyle())
    }
}

enum RowStyle {
    case card
}

extension View {
    @ViewBuilder
    func rowStyle(_ style: RowStyle) -> some View {
        switch style {
        case .card:
            CardContainer(variant: .floatingSoft) {
                self
            }
            .listRowSeparator(.hidden)
            .listRowInsets(
                EdgeInsets(
                    top: Theme.Spacing.xs,
                    leading: Theme.Spacing.md,
                    bottom: Theme.Spacing.xs,
                    trailing: Theme.Spacing.md
                )
            )
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Tags

/// Displays a tag as a pill-shaped badge with theme-aware colors
struct TagPill: View {
    let name: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(name)
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.pillHorizontal)
            .padding(.vertical, Theme.Spacing.pillVertical)
            .background(
                Capsule()
                    .fill(color.opacity(Theme.Opacity.tagFill(colorScheme)))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(Theme.Opacity.tagStroke(colorScheme)), lineWidth: 1)
            )
    }
}

/// Displays an item type as a small chip badge
struct TypeChip: View {
    let type: String

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        let chipColor = Theme.Colors.tagColor(for: type, colorScheme, style: style)

        Text(type.capitalized)
            .font(Theme.Typography.metadata)
            .foregroundStyle(chipColor)
            .padding(.horizontal, Theme.Spacing.chipHorizontal)
            .padding(.vertical, Theme.Spacing.chipVertical)
            .background(
                chipColor.opacity(Theme.Opacity.chipBackground(colorScheme))
            )
            .clipShape(Capsule())
    }
}

/// Action button for item cards (add tag, star, etc.)
struct ItemActionButton: View {
    enum Variant {
        case primaryFilled
        case secondaryOutlined
        case plain
    }

    let iconName: String
    let tint: Color
    var variant: Variant = .plain
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            AppIcon(name: iconName, size: 14)
                .foregroundStyle(foreground)
                .frame(width: Theme.Spacing.actionButtonSize, height: Theme.Spacing.actionButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        Theme.Colors.icon(colorScheme, style: themeManager.currentStyle)
    }

    @ViewBuilder
    private var background: some View {
        Color.clear
    }
}

// MARK: - Item Actions

struct ItemActionRow: View {
    let tags: [String]
    let tagLookup: [String: Tag]
    let isStarred: Bool
    let onAddTag: () -> Void
    let onToggleStar: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ItemActionButton(
                iconName: Icons.add,
                tint: Theme.Colors.accentPrimary(colorScheme, style: style),
                variant: .primaryFilled,
                action: onAddTag
            )
            .accessibilityLabel("Add tag")
            .accessibilityHint("Assign a tag to this item.")

            if tags.isEmpty {
                Spacer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(tags, id: \.self) { tagName in
                            TagPill(
                                name: tagName,
                                color: tagLookup[tagName]
                                    .flatMap { $0.color }
                                    .map { Color(hex: $0) }
                                    ?? Theme.Colors.tagColor(for: tagName, colorScheme, style: style)
                            )
                        }
                    }
                }
            }

            ItemActionButton(
                iconName: isStarred ? Icons.starFilled : Icons.star,
                tint: isStarred
                    ? Theme.Colors.caution(colorScheme, style: style)
                    : Theme.Colors.cardTextSecondary(colorScheme, style: style),
                variant: isStarred ? .primaryFilled : .secondaryOutlined,
                action: onToggleStar
            )
            .accessibilityLabel(isStarred ? "Unstar item" : "Star item")
            .accessibilityHint("Toggle the star for this item.")
        }
    }
}

// MARK: - Tag Sheets

struct ItemTagPickerSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
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
            try itemRepository.addTag(item, tag: tag.name)
            newTagName = ""
        } catch {
            errorPresenter.present(error)
        }
    }

    private func toggleTag(_ tag: Tag) {
        do {
            if item.tags.contains(tag.name) {
                try itemRepository.removeTag(item, tag: tag.name)
            } else {
                try itemRepository.addTag(item, tag: tag.name)
            }
        } catch {
            errorPresenter.present(error)
        }
    }
}

struct TagSelectionSheet: View {
    @Binding var selectedTags: [Tag]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.tagRepository) private var tagRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var newName = ""
    @State private var errorPresenter = ErrorPresenter()
    @FocusState private var focused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New tag", text: $newName)
                            .focused($focused)
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                            .tint(Theme.Colors.primary(colorScheme, style: style))
                        Button("Add") {
                            addTag()
                        }
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .rowStyle(.card)
                }

                Section("Tags") {
                    ForEach(allTags) { tag in
                        Button {
                            toggleSelection(for: tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                Spacer()
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    AppIcon(name: Icons.check, size: 12)
                                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
                                }
                            }
                        }
                        .rowStyle(.card)
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

    private func addTag() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let tag = try tagRepository.fetchOrCreate(trimmed)
            if !selectedTags.contains(where: { $0.id == tag.id }) {
                selectedTags.append(tag)
            }
            newName = ""
        } catch {
            errorPresenter.present(error)
        }
    }

    private func toggleSelection(for tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - Previews

#Preview("Components") {
    let previewScheme: ColorScheme = .light
    return VStack(spacing: Theme.Spacing.md) {
        FloatingActionButton(title: "Add Capture", iconName: Icons.addCircleFilled) {}

        HStack(spacing: Theme.Spacing.md) {
            IconTile(
                iconName: Icons.settings,
                iconSize: 18,
                tileSize: 36,
                style: .secondaryOutlined(Theme.Colors.primary(previewScheme, style: .elijah))
            )

            TagPill(
                name: "Personal",
                color: Theme.Colors.tagColor(for: "Personal", previewScheme, style: .elijah)
            )

            TypeChip(type: "task")
        }

        ItemActionButton(
            iconName: Icons.starFilled,
            tint: Theme.Colors.primary(previewScheme, style: .elijah),
            variant: .primaryFilled
        ) {}
    }
    .padding(Theme.Spacing.lg)
    .background(Theme.Colors.background(previewScheme, style: .elijah))
    .environment(\.colorScheme, previewScheme)
    .environmentObject(ThemeManager.shared)
}
