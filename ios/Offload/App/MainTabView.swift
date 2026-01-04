//
//  MainTabView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Primary tab shell for inbox, organize, and settings with quick capture access.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .inbox
    @State private var showingCapture = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InboxView()
            }
            .tabItem {
                Label("Inbox", systemImage: Icons.inbox)
            }
            .tag(Tab.inbox)

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
        .overlay(alignment: .bottomTrailing) {
            // Floating Action Button for quick capture
            Button {
                showingCapture = true
            } label: {
                Image(systemName: Icons.capture)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .sheet(isPresented: $showingCapture) {
            CaptureSheetView()
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
