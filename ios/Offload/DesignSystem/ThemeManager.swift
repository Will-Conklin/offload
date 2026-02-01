// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve established theme defaults and component APIs.


import SwiftUI
import Combine


/// Manages the app's color theme selection and persistence
@MainActor
class ThemeManager: ObservableObject {
    private enum Keys {
        static let selectedThemeStyle = "selectedThemeStyle"
    }

    /// The currently selected theme style
    @Published var currentStyle: ThemeStyle {
        didSet {
            guard oldValue.rawValue != currentStyle.rawValue else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                UserDefaults.standard.set(currentStyle.rawValue, forKey: Keys.selectedThemeStyle)
            }
        }
    }

    /// Singleton instance for app-wide access
    static let shared = ThemeManager()

    /// Creates a new ThemeManager instance
    /// - Parameter loadFromUserDefaults: Whether to load saved theme from UserDefaults (default: true)
    init(loadFromUserDefaults: Bool = true) {
        if loadFromUserDefaults {
            // Load saved theme from UserDefaults, default to Mid-Century Modern.
            if let savedStyleString = UserDefaults.standard.string(forKey: Keys.selectedThemeStyle) {
                // Migrate old theme names to Mid-Century Modern
                if savedStyleString == "cooper" || savedStyleString == "elijah" {
                    self.currentStyle = .midCenturyModern
                    UserDefaults.standard.set(ThemeStyle.midCenturyModern.rawValue, forKey: Keys.selectedThemeStyle)
                } else if let savedStyle = ThemeStyle(rawValue: savedStyleString) {
                    self.currentStyle = savedStyle
                } else {
                    self.currentStyle = .midCenturyModern
                }
            } else {
                self.currentStyle = .midCenturyModern
            }
        } else {
            // For testing: use default theme without persisting.
            self.currentStyle = .midCenturyModern
        }
    }

    /// Update the current theme style
    func setTheme(_ style: ThemeStyle) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStyle = style
        }
    }
}
