// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve established theme defaults and component APIs.

import SwiftData
import SwiftUI

// MARK: - Buttons

struct FloatingActionButton: View {
    let title: String
    let iconName: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var isPressed = false

    var body: some View {
        let style = themeManager.currentStyle

        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Label {
                Text(title.uppercased())
            } icon: {
                AppIcon(name: iconName, size: 14)
            }
            .font(.system(.footnote, design: .default).weight(.black))
            .tracking(0.8)
            .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
            .padding(.vertical, Theme.Spacing.sm + 2)
            .padding(.horizontal, Theme.Spacing.md + 4)
            .background(
                Capsule()
                    .fill(Theme.Colors.primary(colorScheme, style: style))
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .padding(1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(Theme.Animations.motion(.easeInOut(duration: 0.4), reduceMotion: reduceMotion), value: isPressed)
        .accessibilityLabel(title)
    }
}

/// Reusable star/favorite button component
struct StarButton: View {
    let isStarred: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        Button(action: action) {
            AppIcon(
                name: isStarred ? Icons.starFilled : Icons.star,
                size: 18
            )
            .foregroundStyle(
                isStarred
                    ? Theme.Colors.caution(colorScheme, style: style)
                    : Theme.Colors.textSecondary(colorScheme, style: style)
            )
            .padding(Theme.Spacing.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isStarred ? "Unstar" : "Star")
        .accessibilityValue(isStarred ? "starred" : "not starred")
        .accessibilityHint("Toggles favorite status")
    }
}

/// Reusable empty state view
struct EmptyStateView: View {
    let iconName: String
    let message: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    init(iconName: String, message: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.iconName = iconName
        self.message = message
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            AppIcon(name: iconName, size: 34)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            VStack(spacing: Theme.Spacing.xs) {
                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                }
            }
            if let actionTitle, let action {
                FloatingActionButton(title: actionTitle, iconName: Icons.addCircleFilled, action: action)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
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

enum CardVariant {
    case floatingSoft
}

struct CardSurface<Content: View>: View {
    let shape: AnyShape
    let fill: Color?
    let showsEdge: Bool
    let showsBorder: Bool
    let contentPadding: EdgeInsets
    let gradientIndex: Int?
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var isPressed = false

    init(
        shape: AnyShape = AnyShape(Theme.Shapes.card()),
        fill: Color? = nil,
        showsEdge: Bool = true,
        showsBorder: Bool = true,
        gradientIndex: Int? = nil,
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
        self.gradientIndex = gradientIndex
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
                ZStack {
                    if let gradientIndex {
                        // Vibrant glassmorphic card with gradient
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                            .fill(Theme.Glass.surface(colorScheme))

                        Theme.Gradients.cardGradient(index: gradientIndex, colorScheme)
                            .opacity(0.15)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous))

                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                            .stroke(Theme.Glass.border(colorScheme), lineWidth: 1.5)
                    } else {
                        // MCM: Bold gradient backgrounds instead of flat
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        cardFill,
                                        cardFill.opacity(0.7),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(retroDiagonalPattern, alignment: .topTrailing)
                            .overlay(organicAccentBlob, alignment: .leading)
                            .overlay(borderOverlay)
                            .cardTexture(colorScheme)
                    }
                }
            )
            .clipShape(gradientIndex != nil
                ? AnyShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous))
                : shape)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(Theme.Animations.motion(.easeInOut(duration: 0.4), reduceMotion: reduceMotion), value: isPressed)
    }

    @ViewBuilder
    private var retroDiagonalPattern: some View {
        if showsEdge {
            // Retro atomic-age diagonal stripe pattern in corner
            GeometryReader { geo in
                ZStack {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 2, height: 80)
                            .rotationEffect(.degrees(45))
                            .offset(x: CGFloat(index) * 12, y: -20)
                    }
                }
                .frame(width: 80, height: 80)
                .offset(x: geo.size.width - 40, y: -20)
                .clipShape(shape)
            }
        }
    }

    @ViewBuilder
    private var organicAccentBlob: some View {
        if showsEdge {
            // Organic kidney-shaped blob accent - bold MCM style
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .offset(x: -40, y: 20)
                .blendMode(.multiply)
                .clipShape(shape)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if showsBorder {
            // Bold border with subtle inner highlight
            ZStack {
                shape.stroke(
                    Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle),
                    lineWidth: 2
                )

                // Inner highlight for depth
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .padding(1)
            }
        }
    }

    func onPress(_ pressed: Bool) -> Self {
        let copy = self
        copy.isPressed = pressed
        return copy
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isPressed = false

    var body: some View {
        Text(name.uppercased())
            .font(.system(size: 10, weight: .bold, design: .default))
            .tracking(0.5)
            .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: themeManager.currentStyle))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                color.opacity(0.8),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(Theme.Animations.motion(.easeInOut(duration: 0.4), reduceMotion: reduceMotion), value: isPressed)
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
    var label: String = ""
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
        .accessibilityLabel(label)
    }

    private var foreground: Color {
        Theme.Colors.icon(colorScheme, style: themeManager.currentStyle)
    }

    @ViewBuilder
    private var background: some View {
        Color.clear
    }
}

// MARK: - MCM Card Content

/// Mid-Century Modern asymmetric two-column card content layout
struct MCMCardContent: View {
    enum Size {
        case standard // For collections - bold, prominent
        case compact // For items - smaller, de-emphasized
    }

    let icon: String?
    let title: String
    let bodyText: String?
    let typeLabel: String?
    let timestamp: String?
    let image: UIImage?
    let tags: [Tag]
    let onAddTag: (() -> Void)?
    let size: Size

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    init(
        icon: String? = nil,
        title: String,
        bodyText: String? = nil,
        typeLabel: String? = nil,
        timestamp: String? = nil,
        image: UIImage? = nil,
        tags: [Tag] = [],
        onAddTag: (() -> Void)? = nil,
        size: Size = .standard
    ) {
        self.icon = icon
        self.title = title
        self.bodyText = bodyText
        self.typeLabel = typeLabel
        self.timestamp = timestamp
        self.image = image
        self.tags = tags
        self.onAddTag = onAddTag
        self.size = size
    }

    // Size-dependent values
    private var iconSize: CGFloat {
        size == .compact ? 32 : 42
    }

    private var iconGlyphSize: CGFloat {
        size == .compact ? 14 : 18
    }

    private var titleSize: CGFloat {
        size == .compact ? 18 : 26
    }

    private var titleWeight: Font.Weight {
        size == .compact ? .bold : .heavy
    }

    private var bodySize: CGFloat {
        size == .compact ? 14 : 15
    }

    private var columnSpacing: CGFloat {
        size == .compact ? Theme.Spacing.sm : Theme.Spacing.md
    }

    private var showIconGradient: Bool {
        size == .standard
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column (narrow - metadata gutter with bold icon)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if let icon {
                    // Icon container - gradient for standard, simple for compact
                    ZStack {
                        if showIconGradient {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.Colors.primary(colorScheme, style: style).opacity(0.2),
                                            Theme.Colors.secondary(colorScheme, style: style).opacity(0.15),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: iconSize, height: iconSize)
                        } else {
                            Circle()
                                .fill(Theme.Colors.primary(colorScheme, style: style).opacity(0.1))
                                .frame(width: iconSize, height: iconSize)
                        }

                        AppIcon(name: icon, size: iconGlyphSize)
                            .foregroundStyle(Theme.Colors.primary(colorScheme, style: style).opacity(size == .compact ? 0.7 : 1.0))
                    }
                }

                if let typeLabel {
                    Text(typeLabel.uppercased())
                        .font(.system(size: size == .compact ? 8 : 9, weight: .bold, design: .default))
                        .tracking(0.5)
                        .foregroundStyle(Theme.Colors.primary(colorScheme, style: style).opacity(0.6))
                }

                if let timestamp {
                    Text(timestamp)
                        .font(.system(size: size == .compact ? 8 : 9, weight: .medium, design: .default))
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style).opacity(0.8))
                }
            }
            .frame(width: size == .compact ? 50 : 60, alignment: .leading)

            // Right column (wide - content hierarchy)
            VStack(alignment: .leading, spacing: columnSpacing) {
                // Title - dramatic for collections, moderate for items
                Text(title)
                    .font(.system(size: titleSize, weight: titleWeight, design: .default))
                    .foregroundStyle(
                        size == .standard
                            ? LinearGradient(
                                colors: [
                                    Theme.Colors.textPrimary(colorScheme, style: style),
                                    Theme.Colors.textPrimary(colorScheme, style: style).opacity(0.8),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Theme.Colors.textPrimary(colorScheme, style: style),
                                    Theme.Colors.textPrimary(colorScheme, style: style),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .lineLimit(3)
                    .lineSpacing(size == .compact ? 1 : 2)

                if let bodyText {
                    Text(bodyText)
                        .font(.system(size: bodySize, weight: .regular, design: .default))
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .lineLimit(size == .compact ? 3 : 4)
                        .lineSpacing(size == .compact ? 2 : 4)
                }

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: size == .compact ? 100 : 140)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(size == .compact ? 0.1 : 0.2),
                                            Color.clear,
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }

                // Tags - smaller for compact cards
                if !tags.isEmpty {
                    FlowLayout(spacing: size == .compact ? 6 : 8) {
                        ForEach(tags) { tag in
                            let tagColor = tag.color
                                .map { Color(hex: $0) }
                                ?? Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)

                            Text(tag.name.uppercased())
                                .font(.system(size: size == .compact ? 8 : 10, weight: .bold, design: .default))
                                .tracking(0.5)
                                .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
                                .padding(.horizontal, size == .compact ? 8 : 10)
                                .padding(.vertical, size == .compact ? 4 : 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    tagColor,
                                                    tagColor.opacity(0.8),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }

                        if let onAddTag {
                            Button(action: onAddTag) {
                                HStack(spacing: 4) {
                                    AppIcon(name: Icons.add, size: size == .compact ? 8 : 10)
                                    Text("TAG")
                                        .font(.system(size: size == .compact ? 8 : 10, weight: .bold, design: .default))
                                        .tracking(0.5)
                                }
                                .foregroundStyle(Theme.Colors.primary(colorScheme, style: style))
                                .padding(.horizontal, size == .compact ? 8 : 10)
                                .padding(.vertical, size == .compact ? 4 : 6)
                                .background(
                                    Capsule()
                                        .strokeBorder(
                                            Theme.Colors.primary(colorScheme, style: style),
                                            lineWidth: size == .compact ? 1 : 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.leading, size == .compact ? 12 : 16) // Less margin for compact
        }
    }
}

/// Simple flow layout for tags (wraps to multiple rows)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var size: CGSize = .zero
            var positions: [CGPoint] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth, currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX - spacing)
                size.height = currentY + lineHeight
            }

            self.size = size
            self.positions = positions
        }
    }
}

// MARK: - Item Actions

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
                                if item.tags.contains(where: { $0.id == tag.id }) {
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
            try itemRepository.addTag(item, tag: tag)
            newTagName = ""
        } catch {
            errorPresenter.present(error)
        }
    }

    private func toggleTag(_ tag: Tag) {
        do {
            if item.tags.contains(where: { $0.id == tag.id }) {
                try itemRepository.removeTag(item, tag: tag)
            } else {
                try itemRepository.addTag(item, tag: tag)
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
    VStack(spacing: Theme.Spacing.md) {
        FloatingActionButton(title: "Add Capture", iconName: Icons.addCircleFilled) {}

        HStack(spacing: Theme.Spacing.md) {
            IconTile(
                iconName: Icons.settings,
                iconSize: 18,
                tileSize: 36,
                style: .secondaryOutlined(Theme.Colors.primary(previewScheme, style: .midCenturyModern))
            )

            TagPill(
                name: "Personal",
                color: Theme.Colors.tagColor(for: "Personal", previewScheme, style: .midCenturyModern)
            )

            TypeChip(type: "task")
        }

        ItemActionButton(
            iconName: Icons.starFilled,
            tint: Theme.Colors.primary(previewScheme, style: .midCenturyModern),
            variant: .primaryFilled
        ) {}
    }
    .padding(Theme.Spacing.lg)
    .background(Theme.Colors.background(previewScheme, style: .midCenturyModern))
    .environment(\.colorScheme, previewScheme)
    .environmentObject(ThemeManager.shared)
}
