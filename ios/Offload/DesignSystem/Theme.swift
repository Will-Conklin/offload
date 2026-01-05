// Intent: Define Offload design tokens aligned with ADHD-friendly guardrails (calm palette, spacing, focus states).
//
//  Theme.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

/// App-wide theme configuration
struct Theme {
    // MARK: - Colors

    struct Colors {
        static func background(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.07, green: 0.08, blue: 0.10)
                : Color(red: 0.97, green: 0.98, blue: 0.99)
        }

        static func surface(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.12, green: 0.13, blue: 0.15)
                : Color(red: 1.0, green: 1.0, blue: 1.0)
        }

        static func accentPrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.40, green: 0.70, blue: 0.98) // softened blue
                : Color(red: 0.20, green: 0.45, blue: 0.85)
        }

        static func accentSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.60, green: 0.75, blue: 0.85) // muted teal
                : Color(red: 0.30, green: 0.60, blue: 0.75)
        }

        static func success(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.40, green: 0.80, blue: 0.55)
                : Color(red: 0.25, green: 0.65, blue: 0.45)
        }

        static func caution(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.95, green: 0.75, blue: 0.35)
                : Color(red: 0.90, green: 0.65, blue: 0.25)
        }

        static func destructive(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.95, green: 0.45, blue: 0.45)
                : Color(red: 0.85, green: 0.25, blue: 0.30)
        }

        static func textPrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.90, green: 0.92, blue: 0.95)
                : Color(red: 0.10, green: 0.12, blue: 0.16)
        }

        static func textSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.65, green: 0.68, blue: 0.72)
                : Color(red: 0.35, green: 0.40, blue: 0.45)
        }

        static func borderMuted(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(red: 0.25, green: 0.28, blue: 0.32)
                : Color(red: 0.86, green: 0.89, blue: 0.92)
        }

        static func focusRing(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? accentSecondary(colorScheme).opacity(0.9)
                : accentSecondary(colorScheme).opacity(0.8)
        }
    }

    // MARK: - Typography

    struct Typography {
        // TODO: Define font families
        // TODO: Define text styles (headline, body, caption, etc.)
        // TODO: Define font weights
        // TODO: Define line heights
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
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16

        // TODO: Add component-specific radii
    }

    // MARK: - Shadows

    struct Shadows {
        static let elevationSm: CGFloat = 2
        static let elevationMd: CGFloat = 6
    }

    // MARK: - Hit Targets

    struct HitTarget {
        static let minimum = CGSize(width: 44, height: 44)
    }
}
