// Intent: Define Offload design tokens aligned with ADHD-friendly guardrails (calm palette, spacing, focus states).
//
//  Theme.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

/// Available color themes for the app
enum ThemeStyle: String, CaseIterable, Identifiable {
    case blueCool = "Blue Cool"
    case sageStone = "Sage & Stone"
    case lavenderCalm = "Lavender Calm"
    case oceanMinimal = "Ocean Minimal"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .blueCool:
            return "Classic blue-gray palette (default)"
        case .sageStone:
            return "Warm, grounded earth tones"
        case .lavenderCalm:
            return "Gentle, stress-reducing purple"
        case .oceanMinimal:
            return "Refined warm ocean blues"
        }
    }
}

/// App-wide theme configuration
struct Theme {
    // MARK: - Colors

    struct Colors {
        static func background(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.07, green: 0.08, blue: 0.10) // #121517
                    : Color(red: 0.97, green: 0.98, blue: 0.99) // #F7FAFD
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.11, green: 0.12, blue: 0.11) // #1C1E1B
                    : Color(red: 0.96, green: 0.95, blue: 0.94) // #F5F3EF
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.10, green: 0.09, blue: 0.15) // #1A1625
                    : Color(red: 0.96, green: 0.96, blue: 0.98) // #F6F5F9
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.06, green: 0.08, blue: 0.10) // #0F1419
                    : Color(red: 0.96, green: 0.97, blue: 0.98) // #F5F8FA
            }
        }

        static func surface(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.12, green: 0.13, blue: 0.15) // #1F2127
                    : Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.15, green: 0.16, blue: 0.15) // #272A26
                    : Color(red: 1.0, green: 0.99, blue: 0.98) // #FEFDFB
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.15, green: 0.13, blue: 0.20) // #252034
                    : Color(red: 0.99, green: 0.99, blue: 1.0) // #FDFCFE
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.10, green: 0.13, blue: 0.16) // #1A2028
                    : Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
            }
        }

        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.40, green: 0.70, blue: 0.98) // #66B3F7
                    : Color(red: 0.20, green: 0.45, blue: 0.85) // #3372D9
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.56, green: 0.73, blue: 0.62) // #8FBA9D
                    : Color(red: 0.37, green: 0.52, blue: 0.46) // #5F8575
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.65, green: 0.59, blue: 0.84) // #A797DB
                    : Color(red: 0.48, green: 0.41, blue: 0.72) // #7B68B8
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.36, green: 0.68, blue: 0.90) // #5DADE6
                    : Color(red: 0.17, green: 0.50, blue: 0.72) // #2B7FB8
            }
        }

        static func accentSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.60, green: 0.75, blue: 0.85) // #99BFDA
                    : Color(red: 0.30, green: 0.60, blue: 0.75) // #4D99BD
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.64, green: 0.71, blue: 0.68) // #A3B5AD
                    : Color(red: 0.55, green: 0.62, blue: 0.58) // #8B9D94
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.71, green: 0.67, blue: 0.82) // #B5AAD1
                    : Color(red: 0.61, green: 0.56, blue: 0.72) // #9B8FB8
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.55, green: 0.72, blue: 0.80) // #8BB8CC
                    : Color(red: 0.36, green: 0.61, blue: 0.71) // #5D9BB5
            }
        }

        static func success(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.40, green: 0.80, blue: 0.55) // #66CD8C
                    : Color(red: 0.30, green: 0.65, blue: 0.56) // #4DA68F
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.40, green: 0.79, blue: 0.61) // #66C89B
                    : Color(red: 0.29, green: 0.61, blue: 0.50) // #4A9B7F
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.42, green: 0.79, blue: 0.62) // #6BC99D
                    : Color(red: 0.37, green: 0.66, blue: 0.56) // #5FA88F
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.37, green: 0.80, blue: 0.60) // #5FCC9A
                    : Color(red: 0.24, green: 0.61, blue: 0.50) // #3D9B7F
            }
        }

        static func caution(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.95, green: 0.75, blue: 0.30) // #F2C04D
                    : Color(red: 0.90, green: 0.66, blue: 0.20) // #E6A834
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.90, green: 0.72, blue: 0.41) // #E5B869
                    : Color(red: 0.79, green: 0.59, blue: 0.31) // #C99750
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.90, green: 0.74, blue: 0.44) // #E5BD6F
                    : Color(red: 0.78, green: 0.63, blue: 0.33) // #C7A053
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.95, green: 0.78, blue: 0.39) // #F2C764
                    : Color(red: 0.84, green: 0.63, blue: 0.27) // #D6A045
            }
        }

        static func destructive(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.95, green: 0.45, blue: 0.45) // #F27272
                    : Color(red: 0.85, green: 0.25, blue: 0.25) // #DA4040
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.88, green: 0.50, blue: 0.50) // #E08080
                    : Color(red: 0.77, green: 0.33, blue: 0.33) // #C55555
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.90, green: 0.54, blue: 0.62) // #E5899D
                    : Color(red: 0.78, green: 0.36, blue: 0.44) // #C65B6F
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.95, green: 0.50, blue: 0.50) // #F28080
                    : Color(red: 0.80, green: 0.33, blue: 0.33) // #CC5555
            }
        }

        static func textPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.90, green: 0.92, blue: 0.94) // #E6EAEF
                    : Color(red: 0.10, green: 0.12, blue: 0.16) // #1A1F28
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.92, green: 0.94, blue: 0.93) // #EAF0ED
                    : Color(red: 0.17, green: 0.21, blue: 0.19) // #2C3531
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.93, green: 0.91, blue: 0.96) // #EDE9F4
                    : Color(red: 0.18, green: 0.15, blue: 0.22) // #2E2639
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.91, green: 0.93, blue: 0.95) // #E8EDF2
                    : Color(red: 0.12, green: 0.16, blue: 0.21) // #1F2835
            }
        }

        static func textSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.65, green: 0.68, blue: 0.72) // #A5ADB8
                    : Color(red: 0.35, green: 0.39, blue: 0.44) // #5A6370
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.72, green: 0.77, blue: 0.75) // #B8C5BF
                    : Color(red: 0.42, green: 0.47, blue: 0.45) // #6B7974
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.71, green: 0.68, blue: 0.78) // #B5AEC7
                    : Color(red: 0.40, green: 0.38, blue: 0.48) // #65607A
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.66, green: 0.72, blue: 0.78) // #A8B8C7
                    : Color(red: 0.35, green: 0.40, blue: 0.48) // #58657A
            }
        }

        static func borderMuted(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            switch style {
            case .blueCool:
                return colorScheme == .dark
                    ? Color(red: 0.26, green: 0.29, blue: 0.34) // #414B56
                    : Color(red: 0.86, green: 0.88, blue: 0.91) // #DCE1E8
            case .sageStone:
                return colorScheme == .dark
                    ? Color(red: 0.25, green: 0.27, blue: 0.25) // #3F4540
                    : Color(red: 0.88, green: 0.87, blue: 0.85) // #E0DDD8
            case .lavenderCalm:
                return colorScheme == .dark
                    ? Color(red: 0.23, green: 0.20, blue: 0.29) // #3A344A
                    : Color(red: 0.89, green: 0.88, blue: 0.92) // #E3E0EA
            case .oceanMinimal:
                return colorScheme == .dark
                    ? Color(red: 0.23, green: 0.27, blue: 0.32) // #3A4652
                    : Color(red: 0.85, green: 0.89, blue: 0.92) // #DAE3EA
            }
        }

        static func focusRing(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> Color {
            colorScheme == .dark
                ? accentSecondary(colorScheme, style: style).opacity(0.9)
                : accentSecondary(colorScheme, style: style).opacity(0.8)
        }
    }

    // MARK: - Typography

    struct Typography {
        // MARK: - Standard Text Styles (with Dynamic Type support)

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

        // MARK: - Semantic Styles (application-specific)

        /// Title for cards, sections, and main content areas
        static let cardTitle = Font.headline
        static let cardTitleEmphasis = Font.headline.weight(.semibold)

        /// Body text for cards and descriptions
        static let cardBody = Font.subheadline
        static let cardBodyEmphasis = Font.subheadline.weight(.semibold)

        /// Button labels across the app
        static let buttonLabel = Font.headline
        static let buttonLabelEmphasis = Font.headline.weight(.semibold)

        /// Input field labels
        static let inputLabel = Font.subheadline
        static let inputLabelEmphasis = Font.subheadline.weight(.semibold)

        /// Error and validation messages
        static let errorText = Font.caption

        /// Metadata and timestamps
        static let metadata = Font.caption
        static let metadataMonospaced = Font.caption.monospacedDigit()

        /// Badge text (lifecycle states, categories, etc.)
        static let badge = Font.caption2
        static let badgeEmphasis = Font.caption2.weight(.semibold)

        // MARK: - Line Spacing

        /// Tight line spacing for compact layouts
        static let lineSpacingTight: CGFloat = 2

        /// Normal line spacing (default)
        static let lineSpacingNormal: CGFloat = 6

        /// Relaxed line spacing for readability
        static let lineSpacingRelaxed: CGFloat = 10
    }

    // MARK: - Materials

    struct Materials {
        static let glass = Material.ultraThin
        static let glassStrong = Material.thin
        static let glassOverlayOpacity: Double = 0.6

        static func glassOverlay(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.black
                : Color.white
        }
    }

    // MARK: - Gradients

    struct Gradients {
        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> LinearGradient {
            LinearGradient(
                colors: [
                    Colors.accentPrimary(colorScheme, style: style),
                    Colors.accentSecondary(colorScheme, style: style).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func surfaceGlow(_ colorScheme: ColorScheme, style: ThemeStyle = .blueCool) -> RadialGradient {
            RadialGradient(
                colors: [
                    Colors.accentSecondary(colorScheme, style: style).opacity(0.35),
                    Colors.surface(colorScheme, style: style).opacity(0.1)
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 180
            )
        }
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        // TODO: Add more spacing scales as needed
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24

        // TODO: Add component-specific radii
    }

    // MARK: - Shadows

    struct Shadows {
        static let elevationSm: CGFloat = 2
        static let elevationMd: CGFloat = 6
    }

    // MARK: - Animations

    struct Animations {
        static let springDefault = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
        static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.75, blendDuration: 0.1)
        static let easeInOutShort = Animation.easeInOut(duration: 0.2)
    }

    // MARK: - Hit Targets

    struct HitTarget {
        static let minimum = CGSize(width: 44, height: 44)
    }
}
