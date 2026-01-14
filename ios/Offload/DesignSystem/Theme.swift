//
//  Theme.swift
//  Offload
//
//  Flat design system with bold, clean colors
//

import SwiftUI

// AGENT NAV
// - Theme Style
// - Colors
// - Typography
// - Spacing
// - Corner Radius
// - Cards
// - Shadows
// - Animations

// MARK: - Theme Style

/// Available color themes for the app
enum ThemeStyle: String, CaseIterable, Identifiable {
    case oceanTeal = "Ocean Teal"
    case violetPop = "Violet Pop"
    case sunsetCoral = "Sunset Coral"
    case slate = "Slate"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .oceanTeal: return "Fresh, calm energy"
        case .violetPop: return "Creative, playful"
        case .sunsetCoral: return "Energetic, warm"
        case .slate: return "Neutral, professional"
        }
    }
}

// MARK: - Theme

/// App-wide theme configuration - flat design with bold colors
struct Theme {

    // MARK: - Colors

    struct Colors {

        // MARK: Primary Accent

        static func primary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            switch style {
            case .oceanTeal:
                return colorScheme == .dark
                    ? Color(hex: "22D3EE") // Bright cyan
                    : Color(hex: "0891B2") // Teal
            case .violetPop:
                return colorScheme == .dark
                    ? Color(hex: "A78BFA") // Light violet
                    : Color(hex: "8B5CF6") // Vivid purple
            case .sunsetCoral:
                return colorScheme == .dark
                    ? Color(hex: "FB923C") // Light orange
                    : Color(hex: "F97316") // Bright orange
            case .slate:
                return colorScheme == .dark
                    ? Color(hex: "94A3B8") // Light slate
                    : Color(hex: "64748B") // Slate gray
            }
        }

        // MARK: Secondary Accent

        static func secondary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            switch style {
            case .oceanTeal:
                return colorScheme == .dark
                    ? Color(hex: "67E8F9") // Lighter cyan
                    : Color(hex: "06B6D4") // Cyan
            case .violetPop:
                return colorScheme == .dark
                    ? Color(hex: "C4B5FD") // Lighter violet
                    : Color(hex: "A78BFA") // Light purple
            case .sunsetCoral:
                return colorScheme == .dark
                    ? Color(hex: "FDBA74") // Lighter orange
                    : Color(hex: "FB923C") // Orange
            case .slate:
                return colorScheme == .dark
                    ? Color(hex: "CBD5E1") // Lighter slate
                    : Color(hex: "94A3B8") // Light slate
            }
        }

        // MARK: Backgrounds

        static func background(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "0A0A0A") // Near black
                : Color(hex: "FAFAFA") // Near white
        }

        static func surface(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "171717") // Dark gray
                : Color.white
        }

        // MARK: Card (tinted backgrounds)

        static func card(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            switch style {
            case .oceanTeal:
                return colorScheme == .dark
                    ? Color(hex: "0C4A5E") // Deep teal
                    : Color(hex: "0E7490") // Deep teal
            case .violetPop:
                return colorScheme == .dark
                    ? Color(hex: "3B2D63") // Deep purple
                    : Color(hex: "6D28D9") // Deep violet
            case .sunsetCoral:
                return colorScheme == .dark
                    ? Color(hex: "5C2E0E") // Deep amber
                    : Color(hex: "C2410C") // Deep orange
            case .slate:
                return colorScheme == .dark
                    ? Color(hex: "1E293B") // Deep slate
                    : Color(hex: "334155") // Deep slate
            }
        }

        // MARK: Text

        static func textPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "F5F5F5") // Off white
                : Color(hex: "171717") // Near black
        }

        static func cardTextPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? textPrimary(colorScheme, style: style)
                : Color.white
        }

        static func textSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "A3A3A3") // Gray
                : Color(hex: "525252") // Dark gray
        }

        static func cardTextSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? textSecondary(colorScheme, style: style)
                : Color.white.opacity(0.75)
        }

        // MARK: Borders

        static func border(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "262626") // Dark border
                : Color(hex: "E5E5E5") // Light border
        }

        static func borderMuted(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "1F1F1F") // Subtle dark border
                : Color(hex: "F5F5F5") // Subtle light border
        }

        // MARK: Semantic Colors

        static func success(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "22C55E") // Green
                : Color(hex: "16A34A") // Dark green
        }

        static func caution(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "FACC15") // Yellow
                : Color(hex: "CA8A04") // Dark yellow
        }

        static func destructive(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            colorScheme == .dark
                ? Color(hex: "EF4444") // Red
                : Color(hex: "DC2626") // Dark red
        }

        // MARK: Legacy compatibility

        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            primary(colorScheme, style: style)
        }

        static func accentSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            secondary(colorScheme, style: style)
        }

        static func cardBackground(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            card(colorScheme, style: style)
        }

        static func focusRing(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> Color {
            primary(colorScheme, style: style).opacity(0.5)
        }
    }

    // MARK: - Typography

    struct Typography {
        // Standard text styles
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        static let monospacedBody = Font.body.monospacedDigit()

        // Semantic styles
        static let cardTitle = Font.title3.weight(.semibold)
        static let cardTitleEmphasis = Font.title3.weight(.bold)
        static let cardBody = Font.callout
        static let cardBodyEmphasis = Font.callout.weight(.semibold)
        static let buttonLabel = Font.headline
        static let buttonLabelEmphasis = Font.headline.weight(.semibold)
        static let inputLabel = Font.subheadline
        static let inputLabelEmphasis = Font.subheadline.weight(.semibold)
        static let errorText = Font.caption
        static let metadata = Font.caption
        static let metadataMonospaced = Font.caption.monospacedDigit()
        static let badge = Font.caption2
        static let badgeEmphasis = Font.caption2.weight(.semibold)

        // Line spacing
        static let lineSpacingTight: CGFloat = 2
        static let lineSpacingNormal: CGFloat = 6
        static let lineSpacingRelaxed: CGFloat = 10
    }

    // MARK: - Spacing (simplified scale)

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
    }

    // MARK: - Cards

    struct Cards {
        static let rowHeight: CGFloat = 80
        static let pressScale: CGFloat = 0.98
        static let horizontalInset: CGFloat = Spacing.md
        static let verticalInset: CGFloat = Spacing.sm
    }

    // MARK: - Shadows (minimal for flat design)

    struct Shadows {
        // Use sparingly - prefer borders for flat design
        static let elevationXs: CGFloat = 1
        static let elevationSm: CGFloat = 2
        static let elevationMd: CGFloat = 4

        static func ambient(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.black.opacity(0.3)
                : Color.black.opacity(0.05)
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
        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> LinearGradient {
            LinearGradient(
                colors: [
                    Colors.primary(colorScheme, style: style),
                    Colors.secondary(colorScheme, style: style)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Subtle background - nearly flat
        static func appBackground(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> LinearGradient {
            LinearGradient(
                colors: [
                    Colors.background(colorScheme, style: style),
                    Colors.background(colorScheme, style: style)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static func surfaceGlow(_ colorScheme: ColorScheme, style: ThemeStyle = .oceanTeal) -> RadialGradient {
            RadialGradient(
                colors: [
                    Colors.primary(colorScheme, style: style).opacity(0.1),
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
