//
//  Theme.swift
//  Offload
//
//  Elijah lavender/cream design system
//

import SwiftUI

// AGENT NAV
// - Theme Style
// - Colors
// - Surfaces
// - Content
// - Typography
// - Spacing
// - Corner Radius
// - Shapes
// - Opacity
// - Cards
// - Shadows
// - Animations

// MARK: - Theme Style

/// Available color themes for the app
enum ThemeStyle: String, CaseIterable, Identifiable {
    case elijah

    var id: String { rawValue }

    var displayName: String { "Elijah" }

    var description: String { "Lavender + cream calm" }
}

// MARK: - Theme

/// App-wide theme configuration - flat design with bold colors
struct Theme {

    // MARK: - Colors

    struct Colors {

        // MARK: Primary Accent

        static func primary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "C4B5FD") // Lavender (dark mode)
                : Color(hex: "DDD6FE") // Lavender (light mode)
        }

        // MARK: Secondary Accent

        static func secondary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "FDE68A") // Cream (dark mode)
                : Color(hex: "FEF3C7") // Cream (light mode)
        }

        // MARK: Backgrounds

        static func background(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "0E1116") // Soft dark
                : Color(hex: "FAF5FF") // Lavender-tinted light
        }

        static func surface(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "161A22") // Deep slate
                : Color(hex: "FFFFFF") // Clean white
        }

        static func buttonDark(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(hex: "2D2D2D")
                : Color(hex: "1F1F1F")
        }

        // MARK: Card (tinted backgrounds)

        static func card(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            cardPalette(colorScheme, style: style).first ?? surface(colorScheme, style: style)
        }

        // MARK: Multi-accent palette (for varied card surfaces)

        static func cardPalette(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> [Color] {
            if colorScheme == .dark {
                return [
                    Color(hex: "2B2248"), // Deep lavender
                    Color(hex: "3B2F1A"), // Deep cream
                    Color(hex: "3B1F2F"), // Deep pink
                    Color(hex: "1E2A44"), // Deep blue
                    Color(hex: "0F3D2E")  // Deep mint
                ]
            }

            return [
                Color(hex: "EDE9FE"), // Lavender tint
                Color(hex: "FEF3C7"), // Cream/yellow tint
                Color(hex: "FCE7F3"), // Soft pink
                Color(hex: "DBEAFE"), // Soft blue
                Color(hex: "D1FAE5")  // Soft mint
            ]
        }

        static func cardColor(index: Int, _ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            let palette = cardPalette(colorScheme, style: style)
            guard !palette.isEmpty else { return card(colorScheme, style: style) }
            let i = ((index % palette.count) + palette.count) % palette.count
            return palette[i]
        }

        static func tagColor(for name: String, _ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            primary(colorScheme, style: style)
        }

        // MARK: Text

        static func textPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "F5F5F5") // Off white
                : Color(hex: "1B1B1B") // Charcoal
        }

        static func cardTextPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            textPrimary(colorScheme, style: style)
        }

        static func textSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "9CA3AF") // Muted gray
                : Color(hex: "6B7280") // Cool gray
        }

        static func cardTextSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            textSecondary(colorScheme, style: style)
        }

        static func icon(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            textSecondary(colorScheme, style: style)
        }

        // MARK: Borders

        static func border(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "232830") // Soft dark border
                : Color(hex: "E5E7EB") // Neutral light border
        }

        static func borderMuted(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "1A1F27") // Subtle dark border
                : Color(hex: "EEF2F7") // Neutral muted border
        }

        // MARK: Semantic Colors

        static func success(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "22C55E") // Green
                : Color(hex: "16A34A") // Dark green
        }

        static func caution(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "FACC15") // Yellow
                : Color(hex: "CA8A04") // Dark yellow
        }

        static func destructive(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            colorScheme == .dark
                ? Color(hex: "EF4444") // Red
                : Color(hex: "DC2626") // Dark red
        }

        // MARK: Compatibility

        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            primary(colorScheme, style: style)
        }

        static func accentSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            secondary(colorScheme, style: style)
        }

        static func cardBackground(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            card(colorScheme, style: style)
        }

        static func focusRing(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            primary(colorScheme, style: style).opacity(0.5)
        }
    }

    // MARK: - Surfaces

    struct Surface {
        static func background(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            Colors.background(colorScheme, style: style)
        }

        static func card(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            Colors.card(colorScheme, style: style)
        }

        static func highlight(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            Colors.card(colorScheme, style: style)
        }
    }

    // MARK: - Content

    struct Content {
        static func secondary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> Color {
            Colors.textSecondary(colorScheme, style: style)
        }
    }

    // MARK: - Typography

    struct Typography {
        // Base builder (keeps Dynamic Type)
        private static func system(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            Font.system(style, design: .rounded).weight(weight)
        }

        // Standard text styles (rounded)
        static let largeTitle = system(.largeTitle, weight: .bold)
        static let title = system(.title, weight: .bold)
        static let title2 = system(.title2, weight: .semibold)
        static let title3 = system(.title3, weight: .semibold)
        static let headline = system(.headline, weight: .semibold)
        static let body = system(.body, weight: .regular)
        static let callout = system(.callout, weight: .regular)
        static let subheadline = system(.subheadline, weight: .regular)
        static let subheadlineSemibold = system(.subheadline, weight: .semibold)
        static let footnote = system(.footnote, weight: .regular)
        static let caption = system(.caption, weight: .medium)
        static let caption2 = system(.caption2, weight: .medium)
        static let monospacedBody = Font.system(.body, design: .monospaced).monospacedDigit()

        // Semantic styles (use these in components)
        static let cardTitle = system(.title2, weight: .bold)
        static let cardTitleEmphasis = system(.title2, weight: .heavy)
        static let cardBody = system(.callout, weight: .regular)
        static let cardBodyEmphasis = system(.callout, weight: .semibold)

        static let buttonLabel = system(.headline, weight: .bold)
        static let buttonLabelEmphasis = system(.headline, weight: .heavy)

        static let inputLabel = system(.subheadline, weight: .semibold)
        static let inputLabelEmphasis = system(.subheadline, weight: .bold)

        static let errorText = system(.caption, weight: .semibold)
        static let metadata = system(.caption, weight: .semibold)
        static let metadataMonospaced = Font.system(.caption, design: .monospaced).monospacedDigit()

        static let badge = system(.caption2, weight: .semibold)
        static let badgeEmphasis = system(.caption2, weight: .bold)

        // Line spacing
        static let lineSpacingTight: CGFloat = 2
        static let lineSpacingNormal: CGFloat = 6
        static let lineSpacingRelaxed: CGFloat = 10
    }

    // MARK: - Spacing (simplified scale)

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 18
        static let lgSoft: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        // Pill/chip padding (for TagPill)
        static let pillHorizontal: CGFloat = 10
        static let pillVertical: CGFloat = 6

        // Type chip padding (smaller than pill)
        static let chipHorizontal: CGFloat = 8
        static let chipVertical: CGFloat = 4

        // Action button size
        static let actionButtonSize: CGFloat = 30
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let cardSoft: CGFloat = 24
        static let iconTile: CGFloat = 16
        static let button: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Shapes

    struct Shapes {
        static func card(_ radius: CGFloat = CornerRadius.cardSoft) -> UnevenRoundedRectangle {
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: 0,
                    bottomLeading: 0,
                    bottomTrailing: radius,
                    topTrailing: radius
                ),
                style: .continuous
            )
        }
    }

    // MARK: - Opacity

    struct Opacity {
        /// Card edge strip (left accent bar on cards)
        static func cardEdge(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.22 : 0.08
        }

        /// Border muted overlay
        static func borderMuted(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.55 : 0.35
        }

        /// Tag pill fill
        static func tagFill(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.2 : 0.12
        }

        /// Tag pill stroke
        static func tagStroke(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.45 : 0.3
        }

        /// Item type chip background
        static func chipBackground(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.22 : 0.14
        }

        /// Tab bar selection highlight
        static func tabSelection(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.18 : 0.12
        }

        /// Tab button selection highlight (MainTabView)
        static func tabButtonSelection(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.16 : 0.10
        }

        /// Action button secondary background
        static func actionSecondary(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.22 : 0.14
        }

        /// Action button plain background
        static func actionPlain(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.14 : 0.10
        }

        /// Modal/sheet backdrop
        static func backdrop(_ colorScheme: ColorScheme) -> Double {
            colorScheme == .dark ? 0.45 : 0.25
        }
    }

    // MARK: - Cards

    struct Cards {
        static let rowHeight: CGFloat = 80
        static let pressScale: CGFloat = 0.98
        static let horizontalInset: CGFloat = Spacing.md
        static let verticalInset: CGFloat = Spacing.sm
        static let contentPadding: CGFloat = Spacing.md
        static let edgeWidth: CGFloat = 7
        static let borderWidth: CGFloat = 0.6
    }

    // MARK: - Shadows (minimal for flat design)

    struct Shadows {
        // Use sparingly - prefer borders for flat design
        static let elevationUltraLight: CGFloat = 8
        static let elevationXs: CGFloat = 2
        static let elevationSm: CGFloat = 6
        static let elevationMd: CGFloat = 12
        static let offsetYUltraLight: CGFloat = 2
        static let offsetYXs: CGFloat = 1
        static let offsetYSm: CGFloat = 2
        static let offsetYMd: CGFloat = 6

        static func ultraLight(_ colorScheme: ColorScheme) -> Color {
            Color.black.opacity(colorScheme == .dark ? 0.12 : 0.04)
        }

        static func ambient(_ colorScheme: ColorScheme) -> Color {
            // Softer default ambient shadow; ultraLight should be preferred for new floating surfaces.
            colorScheme == .dark
                ? Color.black.opacity(0.28)
                : Color.black.opacity(0.06)
        }
    }

    // MARK: - Animations

    struct Animations {
        static let springDefault = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
        static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0.1)
        static let easeInOutShort = Animation.easeInOut(duration: 0.2)
    }

    // MARK: - Hit Targets

    struct HitTarget {
        static let minimum = CGSize(width: 44, height: 44)
    }

    // MARK: - Materials (kept but simplified)

    struct Materials {
        static let glass = Material.ultraThin
        static let glassStrong = Material.thin
        static let glassOverlayOpacity: Double = 0.6

        static func glassOverlay(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.black : Color.white
        }
    }

    // MARK: - Gradients (minimal - solid colors preferred)

    struct Gradients {
        // Only use when needed for visual interest
        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> LinearGradient {
            let color = Colors.buttonDark(colorScheme)
            return LinearGradient(
                colors: [
                    color,
                    color
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Subtle background - nearly flat
        static func appBackground(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> LinearGradient {
            LinearGradient(
                colors: [
                    Colors.background(colorScheme, style: style),
                    Colors.background(colorScheme, style: style)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static func surfaceGlow(_ colorScheme: ColorScheme, style: ThemeStyle = .elijah) -> RadialGradient {
            RadialGradient(
                colors: [
                    Colors.primary(colorScheme, style: style).opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 200
            )
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
