// Intent: Provide shallow navigation with a persistent capture entry point aligned to ADHD-friendly guardrails.
//
//  MainTabView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Tab = .captures
    @State private var showingCapture = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CapturesView()
                .tabItem {
                    Label("Captures", systemImage: Icons.inbox)
                }
                .tag(Tab.captures)

            OrganizeView()
                .tabItem {
                    Label("Organize", systemImage: Icons.organize)
                }
                .tag(Tab.organize)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: Icons.settings)
                }
                .tag(Tab.settings)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                // Floating Action Button for quick capture
                Button {
                    showingCapture = true
                } label: {
                    Label {
                        Text("Capture")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(.top, 2)
                    } icon: {
                        Image(systemName: Icons.capture)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.md)
                    .frame(minWidth: Theme.HitTarget.minimum.width,
                           minHeight: Theme.HitTarget.minimum.height)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.accentPrimary(colorScheme))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.Colors.focusRing(colorScheme), lineWidth: 2)
                    )
                    .shadow(color: Theme.Colors.focusRing(colorScheme).opacity(0.35),
                            radius: Theme.Shadows.elevationMd,
                            y: 4)
                }
                .accessibilityLabel("Capture new entry")
                .accessibilityHint("Opens quick capture sheet; you can organize later")
            }
            .padding(.trailing, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xs)
            .background(Color.clear)
        }
        .sheet(isPresented: $showingCapture) {
            CaptureView()
        }
    }

    enum Tab {
        case captures
        case organize
        case settings
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
}
