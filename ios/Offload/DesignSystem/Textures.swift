// Purpose: Texture overlays for retro digital warmth aesthetic
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep textures extremely subtle to maintain calm visual system.

import SwiftUI
import UIKit

// MARK: - Textures & Effects

extension Theme {
    struct Textures {

        // MARK: Scan Lines

        struct ScanLines: View {
            let opacity: Double
            let spacing: CGFloat

            var body: some View {
                GeometryReader { geometry in
                    Path { path in
                        let height = geometry.size.height
                        var y: CGFloat = 0

                        while y < height {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                            y += spacing
                        }
                    }
                    .stroke(Color.black, lineWidth: 1)
                    .opacity(opacity)
                    .blendMode(.multiply)
                }
            }
        }

        // MARK: Noise Overlay

        struct NoiseOverlay: View {
            let opacity: Double

            var body: some View {
                GeometryReader { _ in
                    Canvas { context, size in
                        let width = Int(size.width)
                        let height = Int(size.height)

                        for x in stride(from: 0, to: width, by: 2) {
                            for y in stride(from: 0, to: height, by: 2) {
                                let noise = Double.random(in: 0...1)
                                let alpha = noise * opacity
                                context.fill(
                                    Path(CGRect(x: x, y: y, width: 2, height: 2)),
                                    with: .color(.white.opacity(alpha))
                                )
                            }
                        }
                    }
                    .blendMode(.overlay)
                }
            }
        }

        // MARK: Pixel Grid

        struct PixelGrid: View {
            let cellSize: CGFloat
            let opacity: Double

            var body: some View {
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height

                        // Vertical lines
                        var x: CGFloat = 0
                        while x <= width {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                            x += cellSize
                        }

                        // Horizontal lines
                        var y: CGFloat = 0
                        while y <= height {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                            y += cellSize
                        }
                    }
                    .stroke(Color.primary, lineWidth: 0.5)
                    .opacity(opacity)
                }
            }
        }

        // MARK: - MCM Textures

        // MARK: Linen Overlay

        /// Mid-Century Modern linen texture - diagonal crosshatch pattern
        struct LinenOverlay: View {
            let opacity: Double
            @Environment(\.accessibilityReduceMotion) var reduceMotion

            var body: some View {
                if !reduceMotion {
                    Canvas { context, size in
                        let spacing: CGFloat = 4

                        // Diagonal lines (45°)
                        for y in stride(from: -size.width, to: size.height + size.width, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: min(size.width, y + size.width), y: max(0, y)))
                            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 0.5)
                        }

                        // Diagonal lines (135°)
                        for x in stride(from: 0, to: size.width + size.height, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: max(0, x - size.height), y: min(size.height, x)))
                            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 0.5)
                        }
                    }
                    .blendMode(.overlay)
                }
            }
        }

        // MARK: Canvas Texture

        /// Mid-Century Modern canvas texture - woven grid pattern
        struct CanvasTexture: View {
            let opacity: Double
            @Environment(\.accessibilityReduceMotion) var reduceMotion

            var body: some View {
                if !reduceMotion {
                    Canvas { context, size in
                        let gridSize: CGFloat = 8

                        // Horizontal weave
                        for y in stride(from: 0, to: size.height, by: gridSize) {
                            for x in stride(from: 0, to: size.width, by: gridSize * 2) {
                                let rect = CGRect(x: x, y: y, width: gridSize, height: 1)
                                context.fill(Path(rect), with: .color(.white.opacity(opacity)))
                            }
                        }

                        // Vertical weave
                        for x in stride(from: 0, to: size.width, by: gridSize) {
                            for y in stride(from: gridSize, to: size.height, by: gridSize * 2) {
                                let rect = CGRect(x: x, y: y, width: 1, height: gridSize)
                                context.fill(Path(rect), with: .color(.white.opacity(opacity)))
                            }
                        }
                    }
                    .blendMode(.overlay)
                }
            }
        }
    }

    // MARK: - Glass Effects

    struct Effects {
        /// Subtle glass sparkle effect for glassmorphic surfaces
        struct GlassNoise: View {
            let opacity: Double

            var body: some View {
                Canvas { context, size in
                    for _ in 0..<100 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let alpha = Double.random(in: 0...opacity)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(.white.opacity(alpha))
                        )
                    }
                }
                .blendMode(.overlay)
            }
        }
    }
}

// MARK: - View Extensions

extension View {

    /// Adds scan-line overlay texture
    /// - Parameters:
    ///   - opacity: Opacity of the scan lines (default: 0.02)
    ///   - spacing: Vertical spacing between lines in points (default: 2)
    func scanLineOverlay(opacity: Double = 0.02, spacing: CGFloat = 2) -> some View {
        overlay(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Textures.ScanLines(opacity: opacity, spacing: spacing)
                }
            }
        )
    }

    /// Adds noise/grain overlay texture
    /// - Parameter opacity: Opacity of the noise (default: 0.03)
    func noiseOverlay(opacity: Double = 0.03) -> some View {
        overlay(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Textures.NoiseOverlay(opacity: opacity)
                }
            }
        )
    }

    /// Adds pixel grid overlay texture
    /// - Parameters:
    ///   - cellSize: Size of grid cells in points (default: 20)
    ///   - opacity: Opacity of the grid (default: 0.02)
    func pixelGrid(cellSize: CGFloat = 20, opacity: Double = 0.02) -> some View {
        background(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Textures.PixelGrid(cellSize: cellSize, opacity: opacity)
                }
            }
        )
    }

    /// Adds glass noise sparkle effect for glassmorphic surfaces
    /// - Parameter opacity: Maximum opacity of sparkle points (default: 0.05)
    func glassNoise(opacity: Double = 0.05) -> some View {
        overlay(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Effects.GlassNoise(opacity: opacity)
                }
            }
        )
    }

    /// Optimizes gradient rendering performance by caching into an offscreen buffer
    func optimizedGradients() -> some View {
        self.drawingGroup()
    }

    // MARK: - MCM Textures

    /// Adds MCM linen overlay texture - diagonal crosshatch pattern
    /// - Parameter opacity: Opacity of the linen texture (default: 0.03)
    func linenOverlay(opacity: Double = 0.03) -> some View {
        overlay(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Textures.LinenOverlay(opacity: opacity)
                }
            }
        )
    }

    /// Adds MCM canvas texture - woven grid pattern
    /// - Parameter opacity: Opacity of the canvas texture (default: 0.04)
    func canvasTexture(opacity: Double = 0.04) -> some View {
        overlay(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Textures.CanvasTexture(opacity: opacity)
                }
            }
        )
    }

    /// Adds MCM card texture - linen overlay by default
    /// - Parameter colorScheme: Current color scheme to adjust opacity
    func cardTexture(_ colorScheme: ColorScheme) -> some View {
        overlay(
            Group {
                if !UIAccessibility.isReduceMotionEnabled {
                    Theme.Textures.LinenOverlay(
                        opacity: colorScheme == .dark ? 0.03 : 0.02
                    )
                }
            }
        )
    }
}
