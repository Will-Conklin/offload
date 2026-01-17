//
//  ThemeManager.swift
//  Offload
//
//  Created by Claude Code on 1/10/26.
//
//  Intent: Manage user-selected theme style with persistence via UserDefaults.
//

import SwiftUI
import Combine

// AGENT NAV
// - State
// - Persistence
// - Updates

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
            // Load saved theme from UserDefaults, default to Elijah.
            if let savedStyleString = UserDefaults.standard.string(forKey: Keys.selectedThemeStyle) {
                if savedStyleString == "cooper" {
                    self.currentStyle = .elijah
                    UserDefaults.standard.set(ThemeStyle.elijah.rawValue, forKey: Keys.selectedThemeStyle)
                } else if let savedStyle = ThemeStyle(rawValue: savedStyleString) {
                    self.currentStyle = savedStyle
                } else {
                    self.currentStyle = .elijah
                }
            } else {
                self.currentStyle = .elijah
            }
        } else {
            // For testing: use default theme without persisting.
            self.currentStyle = .elijah
        }
    }

    /// Update the current theme style
    func setTheme(_ style: ThemeStyle) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStyle = style
        }
    }
}
