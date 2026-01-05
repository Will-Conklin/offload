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
    @State private var selectedTab: Tab = .inbox
    @State private var showingCapture = false

    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: Icons.inbox)
                }
                .tag(Tab.inbox)

            OrganizeView()
                .tabItem {
                    Label("Organize", systemImage: Icons.organize)
                }
                .tag(Tab.organize)

            // TODO: Add Settings view
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: Icons.settings)
                }
                .tag(Tab.settings)
        }
        .overlay(alignment: .bottomTrailing) {
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
            .padding(.trailing, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
            .accessibilityLabel("Capture new entry")
            .accessibilityHint("Opens quick capture sheet; you can organize later")
        }
        .sheet(isPresented: $showingCapture) {
            CaptureView()
        }
    }

    enum Tab {
        case inbox
        case organize
        case settings
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
}
