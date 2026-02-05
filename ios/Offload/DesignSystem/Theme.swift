// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve established theme defaults and component APIs.

//  Mid-Century Modern design system

import SwiftUI

// MARK: - Theme Style

/// Available color themes for the app
enum ThemeStyle: String, CaseIterable, Identifiable {
    case midCenturyModern

    var id: String { rawValue }

    var displayName: String { "Mid-Century Modern" }

    var description: String { "Warm atomic age optimism" }
}

// MARK: - Theme

/// App-wide theme configuration - flat design with bold colors
enum Theme {
    // MARK: - Colors

    enum Colors {
        // MARK: Primary Accent

        static func primary(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "E67E22") // Burnt orange (dark mode)
                : Color(hex: "D35400") // Burnt orange (light mode)
        }

        // MARK: Secondary Accent

        static func secondary(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "27AE60") // Avocado green (dark mode)
                : Color(hex: "229954") // Avocado green (light mode)
        }

        // MARK: Backgrounds

        static func background(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "2C1810") // Chocolate brown
                : Color(hex: "F5F0E8") // Warm beige
        }

        static func surface(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "3E2723") // Chocolate
                : Color(hex: "FFF9F0") // Cream
        }

        static func buttonDark(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(hex: "2D2D2D")
                : Color(hex: "1F1F1F")
        }

        // MARK: Card (tinted backgrounds)

        static func card(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            cardPalette(colorScheme, style: style).first ?? surface(colorScheme, style: style)
        }

        // MARK: Multi-accent palette (for varied card surfaces)

        static func cardPalette(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> [Color] {
            if colorScheme == .dark {
                return [
                    Color(hex: "D84315"), // Burnt orange
                    Color(hex: "7D5229"), // Goldenrod brown
                    Color(hex: "1F5C47"), // Teal green
                    Color(hex: "795548"), // Warm brown
                    Color(hex: "00695C"), // Teal blue
                ]
            }

            return [
                Color(hex: "FFE0B2"), // Pale orange
                Color(hex: "FFF3D6"), // Goldenrod cream
                Color(hex: "B2DFDB"), // Soft teal
                Color(hex: "D7CCC8"), // Warm taupe
                Color(hex: "80CBC4"), // Light teal
            ]
        }

        static func cardColor(index: Int, _ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            let palette = cardPalette(colorScheme, style: style)
            guard !palette.isEmpty else { return card(colorScheme, style: style) }
            let i = ((index % palette.count) + palette.count) % palette.count
            return palette[i]
        }

        static func tagColor(for _: String, _ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            primary(colorScheme, style: style)
        }

        // MARK: Text

        static func textPrimary(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "FFF8E1") // Warm cream
                : Color(hex: "3E2723") // Chocolate brown
        }

        static func cardTextPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            textPrimary(colorScheme, style: style)
        }

        static func textSecondary(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "BCAAA4") // Warm gray
                : Color(hex: "8D6E63") // Taupe gray
        }

        static func cardTextSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            textSecondary(colorScheme, style: style)
        }

        static func icon(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            textSecondary(colorScheme, style: style)
        }

        // MARK: Borders

        static func border(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "4E342E") // Deep brown
                : Color(hex: "D7CCC8") // Soft taupe
        }

        static func borderMuted(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "4E342E") // Deep brown
                : Color(hex: "D7CCC8") // Soft taupe
        }

        // MARK: Semantic Colors

        static func success(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "66BB6A") // Mint green
                : Color(hex: "388E3C") // Dark mint
        }

        static func caution(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "FFB300") // Goldenrod
                : Color(hex: "F57C00") // Amber
        }

        static func destructive(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "E57373") // Coral red
                : Color(hex: "D32F2F") // Dark red
        }

        // MARK: Compatibility

        static func accentPrimary(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            primary(colorScheme, style: style)
        }

        static func accentSecondary(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            secondary(colorScheme, style: style)
        }

        static func cardBackground(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            card(colorScheme, style: style)
        }

        static func focusRing(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            primary(colorScheme, style: style).opacity(0.5)
        }

        // MARK: Retro Digital Warmth Colors

        static func amber(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "FFB366") // Amber (dark mode)
                : Color(hex: "FF9F40") // Amber (light mode)
        }

        static func terminalGreen(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "50FA7B") // Terminal green (dark mode)
                : Color(hex: "3DD68C") // Terminal green (light mode)
        }

        static func crtBlue(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> Color {
            colorScheme == .dark
                ? Color(hex: "8BE9FD") // CRT blue (dark mode)
                : Color(hex: "5AC8FA") // CRT blue (light mode)
        }
    }

    // MARK: - Surfaces

    enum Surface {
        static func background(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            Colors.background(colorScheme, style: style)
        }

        static func card(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            Colors.card(colorScheme, style: style)
        }

        static func highlight(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            Colors.card(colorScheme, style: style)
        }
    }

    // MARK: - Content

    enum Content {
        static func secondary(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
            Colors.textSecondary(colorScheme, style: style)
        }
    }

    // MARK: - Typography

    enum Typography {
        // MCM Custom Fonts
        private static func bebas(size: CGFloat) -> Font {
            Font.custom("BebasNeue-Regular", size: size)
        }

        private static func spaceGrotesk(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            // Space Grotesk weight mapping
            let fontName = switch weight {
            case .bold, .semibold, .heavy, .black:
                "SpaceGrotesk-Bold"
            default:
                "SpaceGrotesk-Regular"
            }
            return Font.custom(fontName, size: size)
        }

        // Fallback to system font if custom font fails to load
        private static func system(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            Font.system(style, design: .default).weight(weight)
        }

        // MCM Display Fonts (Bebas Neue - geometric, bold, condensed)
        static let largeTitle = bebas(size: 34)
        static let title = bebas(size: 28)
        static let title2 = bebas(size: 22)
        static let title3 = bebas(size: 20)
        static let headline = bebas(size: 17)

        // MCM Body Fonts (Space Grotesk - retro-futuristic, readable)
        static let body = spaceGrotesk(size: 17)
        static let callout = spaceGrotesk(size: 16)
        static let subheadline = spaceGrotesk(size: 15)
        static let subheadlineSemibold = spaceGrotesk(size: 15, weight: .semibold)
        static let footnote = spaceGrotesk(size: 13)
        static let caption = spaceGrotesk(size: 12)
        static let caption2 = spaceGrotesk(size: 11)
        static let monospacedBody = Font.system(.body, design: .monospaced).monospacedDigit()

        // Semantic styles (use these in components)
        static let cardTitle = bebas(size: 22) // Bold geometric display
        static let cardTitleEmphasis = bebas(size: 26) // Extra large for emphasis
        static let cardBody = spaceGrotesk(size: 16)
        static let cardBodyEmphasis = spaceGrotesk(size: 16, weight: .bold)

        static let buttonLabel = bebas(size: 17) // Strong geometric buttons
        static let buttonLabelEmphasis = bebas(size: 18)

        static let inputLabel = spaceGrotesk(size: 15, weight: .semibold)
        static let inputLabelEmphasis = spaceGrotesk(size: 15, weight: .bold)

        static let errorText = spaceGrotesk(size: 12, weight: .semibold)
        static let metadata = spaceGrotesk(size: 12, weight: .semibold)
        static let metadataMonospaced = Font.system(.caption, design: .monospaced).monospacedDigit()

        static let badge = spaceGrotesk(size: 11, weight: .semibold)
        static let badgeEmphasis = spaceGrotesk(size: 11, weight: .bold)

        // Retro monospaced typography
        static let timestampMono = Font.system(.caption2, design: .monospaced).weight(.semibold).monospacedDigit()
        static let metadataMonospacedRetro = Font.system(.caption, design: .monospaced).weight(.medium).monospacedDigit()
        static let bodyMonospaced = Font.system(.body, design: .monospaced).weight(.regular).monospacedDigit()

        // Line spacing
        static let lineSpacingTight: CGFloat = 2
        static let lineSpacingNormal: CGFloat = 6
        static let lineSpacingRelaxed: CGFloat = 10
    }

    // MARK: - Spacing (simplified scale)

    enum Spacing {
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

    enum CornerRadius {
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let cardSoft: CGFloat = 32
        static let iconTile: CGFloat = 12
        static let button: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Shapes

    enum Shapes {
        static func card(_ radius: CGFloat? = nil, style _: ThemeStyle = .midCenturyModern) -> UnevenRoundedRectangle {
            // MCM: kidney shape - all corners evenly rounded
            let r = radius ?? CornerRadius.cardSoft
            return UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: r,
                    bottomLeading: r,
                    bottomTrailing: r,
                    topTrailing: r
                ),
                style: .continuous
            )
        }
    }

    // MARK: - Opacity

    enum Opacity {
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

    enum Cards {
        static let rowHeight: CGFloat = 80
        static let pressScale: CGFloat = 0.98
        static let horizontalInset: CGFloat = Spacing.md
        static let verticalInset: CGFloat = Spacing.sm
        static let contentPadding: CGFloat = Spacing.md
        static let edgeWidth: CGFloat = 7
        static let borderWidth: CGFloat = 0.6
    }

    // MARK: - Shadows (minimal for flat design)

    enum Shadows {
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

    enum Animations {
        // MCM mechanical animations - smooth and satisfying
        static let springDefault = Animation.easeInOut(duration: 0.3)
        static let springSnappy = Animation.easeInOut(duration: 0.2)
        static let easeInOutShort = Animation.easeInOut(duration: 0.2)

        // MCM-specific smooth slide (analog clock movement)
        static let mechanicalSlide = Animation.easeInOut(duration: 0.4)

        // Satisfying snap-to-grid
        static let snapToGrid = Animation.spring(
            response: 0.25,
            dampingFraction: 0.98, // Almost no bounce
            blendDuration: 0
        )

        // Compatibility with existing usage
        static let springOvershoot = Animation.easeInOut(duration: 0.3)
        static let springBouncy = Animation.easeInOut(duration: 0.3)
        static let gradientShift = Animation.easeInOut(duration: 0.3)
        static let scaleRotate = Animation.easeInOut(duration: 0.3)
        static let typewriterDing = Animation.easeInOut(duration: 0.2)
        static let crtFlicker = Animation.easeInOut(duration: 0.08)
    }

    // MARK: - Hit Targets

    enum HitTarget {
        static let minimum = CGSize(width: 44, height: 44)
    }

    // MARK: - Materials (kept but simplified)

    enum Materials {
        static let glass = Material.ultraThin
        static let glassStrong = Material.thin
        static let glassOverlayOpacity: Double = 0.6

        static func glassOverlay(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.black : Color.white
        }
    }

    // MARK: - Gradients (minimal - solid colors preferred)

    enum Gradients {
        // Only use when needed for visual interest
        static func accentPrimary(_ colorScheme: ColorScheme, style _: ThemeStyle = .midCenturyModern) -> LinearGradient {
            let color = Colors.buttonDark(colorScheme)
            return LinearGradient(
                colors: [
                    color,
                    color,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Subtle background - nearly flat
        static func appBackground(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> LinearGradient {
            LinearGradient(
                colors: [
                    Colors.background(colorScheme, style: style),
                    Colors.background(colorScheme, style: style),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static func surfaceGlow(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> RadialGradient {
            RadialGradient(
                colors: [
                    Colors.primary(colorScheme, style: style).opacity(0.08),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 200
            )
        }

        // MARK: - MCM Gradient System

        // MCM earth tone gradients
        static func electricBlueViolet(_: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [Color(hex: "E67E22"), Color(hex: "D35400")], // Burnt orange
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func coralPink(_: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [Color(hex: "27AE60"), Color(hex: "229954")], // Avocado green
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func emeraldTeal(_: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [Color(hex: "00695C"), Color(hex: "1F5C47")], // Teal
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func amberOrange(_: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [Color(hex: "FFB300"), Color(hex: "F57C00")], // Goldenrod/amber
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func violetPink(_: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [Color(hex: "795548"), Color(hex: "7D5229")], // Warm brown/goldenrod
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Background gradient - MCM warm earth tones
        static func deepBackground(_ colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color(hex: "2C1810"), Color(hex: "1F1108"), // Chocolate brown gradient
                ] : [
                    Color(hex: "F5F0E8"), Color(hex: "FFF9F0"), // Warm beige to cream
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        // Card gradients palette (cycling)
        static func cardGradient(index: Int, _ colorScheme: ColorScheme) -> LinearGradient {
            let gradients = [
                electricBlueViolet(colorScheme),
                coralPink(colorScheme),
                emeraldTeal(colorScheme),
                amberOrange(colorScheme),
                violetPink(colorScheme),
            ]
            let i = ((index % gradients.count) + gradients.count) % gradients.count
            return gradients[i]
        }
    }

    // MARK: - Glass System

    enum Glass {
        static let blurRadius: CGFloat = DeviceCapability.supportsHighQualityBlur ? 20 : 10

        static func surface(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.1)
                : Color.white.opacity(0.7)
        }

        static func border(_: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static let rainbowBorder = LinearGradient(
            colors: [
                Color(hex: "E67E22"), Color(hex: "27AE60"),
                Color(hex: "D35400"), Color(hex: "229954"),
                Color(hex: "E67E22"),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Device Capability

enum DeviceCapability {
    static var supportsHighQualityBlur: Bool {
        // iPhone 12 and newer (6 or more cores)
        ProcessInfo.processInfo.processorCount >= 6
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
