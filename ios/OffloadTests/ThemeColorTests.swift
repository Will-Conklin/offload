// Purpose: Unit tests for Theme color token helpers.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftUI
import XCTest

final class ThemeColorTests: XCTestCase {
    /// Verify buttonDarkText returns distinct values per color scheme
    func testButtonDarkTextReturnsContrastSafeColors() {
        let lightColor = Theme.Colors.buttonDarkText(.light)
        let darkColor = Theme.Colors.buttonDarkText(.dark)

        // Light mode should return white for contrast on dark button
        XCTAssertEqual(lightColor, .white)

        // Dark mode should return textPrimary (warm cream), not white
        let expectedDark = Theme.Colors.textPrimary(.dark)
        XCTAssertEqual(darkColor, expectedDark)
    }

    /// Verify buttonDarkText follows same pattern as accentButtonText
    func testButtonDarkTextMatchesAccentButtonTextPattern() {
        // Both should return .white in light mode
        XCTAssertEqual(
            Theme.Colors.buttonDarkText(.light),
            Theme.Colors.accentButtonText(.light)
        )

        // Both should return textPrimary in dark mode
        XCTAssertEqual(
            Theme.Colors.buttonDarkText(.dark),
            Theme.Colors.accentButtonText(.dark)
        )
    }
}
