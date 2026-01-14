        //
//  ThemePreview.swift
//  Offload
//
//  Preview for proposed new flat theme system
//

import SwiftUI
import UIKit

// MARK: - Proposed New Themes

enum ProposedTheme: String, CaseIterable, Identifiable {
    case oceanTeal = "Ocean Teal"
    case violetPop = "Violet Pop"
    case sunsetCoral = "Sunset Coral"
    case slate = "Slate"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .oceanTeal: return Color(hex: "0891B2")
        case .violetPop: return Color(hex: "8B5CF6")
        case .sunsetCoral: return Color(hex: "F97316")
        case .slate: return Color(hex: "64748B")
        }
    }

    var primaryLight: Color {
        switch self {
        case .oceanTeal: return Color(hex: "06B6D4")
        case .violetPop: return Color(hex: "A78BFA")
        case .sunsetCoral: return Color(hex: "FB923C")
        case .slate: return Color(hex: "94A3B8")
        }
    }

    var backgroundLight: Color { Color(hex: "FAFAFA") }
    var backgroundDark: Color { Color(hex: "0F0F0F") }

    var surfaceLight: Color { .white }
    var surfaceDark: Color { Color(hex: "1A1A1A") }

    // Tinted card backgrounds
    var cardLight: Color {
        switch self {
        case .oceanTeal: return Color(hex: "ECFEFF")    // Very light teal
        case .violetPop: return Color(hex: "F5F3FF")    // Very light purple
        case .sunsetCoral: return Color(hex: "FFF7ED")  // Very light orange
        case .slate: return Color(hex: "F8FAFC")        // Very light gray
        }
    }

    var cardDark: Color {
        switch self {
        case .oceanTeal: return Color(hex: "0C4A5E")    // Deep teal
        case .violetPop: return Color(hex: "3B2D63")    // Deep purple
        case .sunsetCoral: return Color(hex: "5C2E0E")  // Deep orange/brown
        case .slate: return Color(hex: "1E293B")        // Deep slate
        }
    }

    var textPrimaryLight: Color { Color(hex: "171717") }
    var textPrimaryDark: Color { Color(hex: "F5F5F5") }

    var textSecondaryLight: Color { Color(hex: "525252") }
    var textSecondaryDark: Color { Color(hex: "A3A3A3") }

    var borderLight: Color { Color(hex: "E5E5E5") }
    var borderDark: Color { Color(hex: "2A2A2A") }
}

// MARK: - Preview Components

struct ThemePreviewCard: View {
    let theme: ProposedTheme
    let isDark: Bool

    var background: Color { isDark ? theme.backgroundDark : theme.backgroundLight }
    var surface: Color { isDark ? theme.surfaceDark : theme.surfaceLight }
    var card: Color { isDark ? theme.cardDark : theme.cardLight }
    var textPrimary: Color { isDark ? theme.textPrimaryDark : theme.textPrimaryLight }
    var textSecondary: Color { isDark ? theme.textSecondaryDark : theme.textSecondaryLight }
    var border: Color { isDark ? theme.borderDark : theme.borderLight }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(theme.rawValue)
                    .font(.headline)
                    .foregroundColor(textPrimary)
                Spacer()
                Text(isDark ? "Dark" : "Light")
                    .font(.caption)
                    .foregroundColor(textSecondary)
            }

            // Sample card with tinted background
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Card")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(textPrimary)
                Text("This is how content looks with tinted card backgrounds.")
                    .font(.caption)
                    .foregroundColor(textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Another card variant - surface with border
            VStack(alignment: .leading, spacing: 8) {
                Text("Alternate Card")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(textPrimary)
                Text("Plain surface with subtle border.")
                    .font(.caption)
                    .foregroundColor(textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Buttons
            HStack(spacing: 8) {
                // Primary button
                Text("Primary")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Secondary button
                Text("Secondary")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }

            // Color swatches
            HStack(spacing: 8) {
                ColorSwatch(color: theme.primary, label: "Primary")
                ColorSwatch(color: theme.primaryLight, label: "Light")
                ColorSwatch(color: card, label: "Card")
                ColorSwatch(color: isDark ? Color(hex: "22C55E") : Color(hex: "16A34A"), label: "Success")
                ColorSwatch(color: isDark ? Color(hex: "EF4444") : Color(hex: "DC2626"), label: "Error")
            }
        }
        .padding(16)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ColorSwatch: View {
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 40, height: 40)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Main Preview

struct ThemePreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Proposed Flat Themes")
                    .font(.title2.weight(.bold))
                    .padding(.top, 20)

                Text("Minimal • Clean • Bold Colors")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(ProposedTheme.allCases) { theme in
                    VStack(spacing: 12) {
                        ThemePreviewCard(theme: theme, isDark: false)
                        ThemePreviewCard(theme: theme, isDark: true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    ThemePreviewView()
}
