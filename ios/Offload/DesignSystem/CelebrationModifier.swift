// Purpose: Celebration animation modifier for positive feedback moments.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI
import UIKit

// MARK: - Celebration Style

/// Defines the three celebration moments with their animation parameters.
enum CelebrationStyle {
    case itemCompleted
    case firstCapture
    case collectionCompleted

    /// Haptic feedback intensity for this celebration.
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .itemCompleted: .light
        case .firstCapture, .collectionCompleted: .medium
        }
    }

    /// Whether this celebration includes particle effects.
    var showsParticles: Bool {
        switch self {
        case .itemCompleted: false
        case .firstCapture, .collectionCompleted: true
        }
    }

    /// Number of particles to generate (5-8 range).
    var particleCount: Int {
        Int.random(in: 5 ... 8)
    }

    /// Peak scale factor during the pulse animation.
    var scalePeak: CGFloat {
        switch self {
        case .itemCompleted, .firstCapture: 1.15
        case .collectionCompleted: 1.0
        }
    }

    /// Duration of the full celebration sequence.
    var duration: TimeInterval {
        switch self {
        case .itemCompleted: 0.4
        case .firstCapture: 1.5
        case .collectionCompleted: 2.0
        }
    }
}

// MARK: - Celebration Particles

/// Lightweight pure-SwiftUI particle effect using MCM palette colors.
struct CelebrationParticlesView: View {
    let particleCount: Int

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var isAnimating = false

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        ZStack {
            ForEach(0 ..< particleCount, id: \.self) { index in
                particleShape(index: index)
                    .frame(width: particleSize(index: index), height: particleSize(index: index))
                    .foregroundStyle(Theme.Colors.cardColor(index: index, colorScheme, style: style))
                    .offset(
                        x: isAnimating ? CGFloat.random(in: -40 ... 40) : 0,
                        y: isAnimating ? CGFloat.random(in: -80 ... -20) : 0
                    )
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0.3 : 1.0)
            }
        }
        .onAppear {
            withAnimation(Theme.Animations.motion(Theme.Animations.mechanicalSlide, reduceMotion: false)) {
                isAnimating = true
            }
        }
    }

    /// Returns a circle or rotated rounded rectangle based on particle index.
    @ViewBuilder
    private func particleShape(index: Int) -> some View {
        if index % 2 == 0 {
            Circle()
        } else {
            RoundedRectangle(cornerRadius: 2)
                .rotationEffect(.degrees(Double.random(in: 0 ... 45)))
        }
    }

    /// Returns a random size for the particle at the given index.
    private func particleSize(index _: Int) -> CGFloat {
        CGFloat.random(in: 6 ... 12)
    }
}

// MARK: - Celebration Overlay Modifier

/// ViewModifier that overlays celebration animations on any view.
///
/// Applies scale pulse, optional particles, haptic feedback, and respects
/// reduced motion settings. Auto-resets `isActive` after animation completes.
struct CelebrationOverlayModifier: ViewModifier {
    let style: CelebrationStyle
    @Binding var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showParticles = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var colorFlashOpacity: Double = 0

    private var themeStyle: ThemeStyle { themeManager.currentStyle }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleEffect)
            .overlay {
                if colorFlashOpacity > 0 {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.success(colorScheme, style: themeStyle).opacity(colorFlashOpacity))
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if showParticles, !reduceMotion {
                    CelebrationParticlesView(particleCount: style.particleCount)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerCelebration()
                }
            }
    }

    /// Orchestrates haptic, scale, color flash, and particle animations.
    private func triggerCelebration() {
        // Haptic fires regardless of reduce motion
        UIImpactFeedbackGenerator(style: style.hapticStyle).impactOccurred()

        guard !reduceMotion else {
            // Skip visual animation, just reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isActive = false
            }
            return
        }

        // Scale pulse
        if style.scalePeak > 1.0 {
            withAnimation(Theme.Animations.motion(Theme.Animations.springSnappy, reduceMotion: false)) {
                scaleEffect = style.scalePeak
            }
            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: false).delay(0.15)) {
                scaleEffect = 1.0
            }
        }

        // Color flash for itemCompleted
        if style == .itemCompleted {
            withAnimation(Theme.Animations.motion(Theme.Animations.typewriterDing, reduceMotion: false)) {
                colorFlashOpacity = 0.15
            }
            withAnimation(Theme.Animations.motion(Theme.Animations.springDefault, reduceMotion: false).delay(0.2)) {
                colorFlashOpacity = 0
            }
        }

        // Particles
        if style.showsParticles {
            showParticles = true
            DispatchQueue.main.asyncAfter(deadline: .now() + style.duration) {
                showParticles = false
            }
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + style.duration) {
            isActive = false
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds a celebration animation overlay to the view.
    ///
    /// - Parameters:
    ///   - style: The celebration type determining animation intensity.
    ///   - isActive: Binding that triggers the celebration when set to true.
    ///     Auto-resets to false after the animation completes.
    func celebrationOverlay(style: CelebrationStyle, isActive: Binding<Bool>) -> some View {
        modifier(CelebrationOverlayModifier(style: style, isActive: isActive))
    }
}
