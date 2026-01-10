//
//  ThemeManager.swift
//  Offload
//
//  Created by Claude Code on 1/10/26.
//
//  Intent: Manage user-selected theme style with persistence via AppStorage.
//

import SwiftUI
import Combine

/// Manages the app's color theme selection and persistence
@MainActor
class ThemeManager: ObservableObject {
    /// The currently selected theme style
    @Published var currentStyle: ThemeStyle {
        didSet {
            UserDefaults.standard.set(currentStyle.rawValue, forKey: "selectedThemeStyle")
        }
    }

    /// Singleton instance for app-wide access
    static let shared = ThemeManager()

    /// Creates a new ThemeManager instance
    /// - Parameter loadFromUserDefaults: Whether to load saved theme from UserDefaults (default: true)
    init(loadFromUserDefaults: Bool = true) {
        if loadFromUserDefaults {
            // Load saved theme from UserDefaults, default to blueCool
            if let savedStyleString = UserDefaults.standard.string(forKey: "selectedThemeStyle"),
               let savedStyle = ThemeStyle(rawValue: savedStyleString) {
                self.currentStyle = savedStyle
            } else {
                self.currentStyle = .blueCool
            }
        } else {
            // For testing: use default theme without persisting
            self.currentStyle = .blueCool
        }
    }

    /// Update the current theme style
    func setTheme(_ style: ThemeStyle) {
        currentStyle = style
    }
}

/// Environment key for ThemeManager
struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
