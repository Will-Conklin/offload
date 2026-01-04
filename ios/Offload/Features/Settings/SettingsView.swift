//
//  SettingsView.swift
//  Offload
//
//  Created by OpenAI Assistant on 1/14/25.
//
//  Intent: Minimal settings hub for capture preferences and app info.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("settings.voicePromptsEnabled") private var voicePromptsEnabled = true
    @AppStorage("settings.shareDiagnostics") private var shareDiagnostics = false

    @Environment(\.openURL) private var openURL

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "v\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Capture") {
                    Toggle("Haptics on save", isOn: $hapticsEnabled)
                    Toggle("Show voice capture tips", isOn: $voicePromptsEnabled)
                }

                Section("Privacy & Data") {
                    Toggle("Share anonymized diagnostics", isOn: $shareDiagnostics)
                }

                Section("About") {
                    LabeledContent("Version", value: versionString)

                    Button {
                        guard let url = URL(string: "mailto:hello@offload.app") else { return }
                        openURL(url)
                    } label: {
                        Label("Email feedback", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
