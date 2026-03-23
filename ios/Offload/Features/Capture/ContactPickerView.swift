// Purpose: UIKit wrapper for CNContactPickerViewController.
// Authority: Code-level
// Governed by: CLAUDE.md

import ContactsUI
import SwiftUI

/// Result returned from the contact picker with extracted contact details.
struct ContactPickerResult {
    let name: String
    let identifier: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
}

/// SwiftUI wrapper around `CNContactPickerViewController` for single contact selection.
struct ContactPickerView: UIViewControllerRepresentable {
    let onSelect: (ContactPickerResult) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: CNContactPickerViewController, context _: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (ContactPickerResult) -> Void
        let onCancel: () -> Void

        init(onSelect: @escaping (ContactPickerResult) -> Void, onCancel: @escaping () -> Void) {
            self.onSelect = onSelect
            self.onCancel = onCancel
        }

        func contactPicker(_: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let phones = contact.phoneNumbers.map { $0.value.stringValue }
            let emails = contact.emailAddresses.map { $0.value as String }

            onSelect(ContactPickerResult(
                name: name.isEmpty ? "Unknown" : name,
                identifier: contact.identifier,
                phoneNumbers: phones,
                emailAddresses: emails
            ))
        }

        func contactPickerDidCancel(_: CNContactPickerViewController) {
            onCancel()
        }
    }
}

/// Sheet for selecting a specific phone number or email when a contact has multiple.
struct ContactValuePickerSheet: View {
    let contactName: String
    let values: [String]
    let channel: CommunicationChannel
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(values, id: \.self) { value in
                        Button {
                            onSelect(value)
                            dismiss()
                        } label: {
                            CardSurface(fill: Theme.Colors.cardColor(index: values.firstIndex(of: value) ?? 0, colorScheme, style: style)) {
                                HStack {
                                    Image(systemName: channel.icon)
                                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                                    Text(value)
                                        .font(Theme.Typography.body)
                                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                                    Spacer()
                                    AppIcon(name: Icons.chevronRight, size: 12)
                                        .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                                }
                                .padding(Theme.Spacing.md)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(channel == .email ? "Email" : "Phone number"): \(value)")
                        .accessibilityHint("Select this \(channel == .email ? "email address" : "phone number").")
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Gradients.deepBackground(colorScheme).ignoresSafeArea())
            .navigationTitle("Select \(channel == .email ? "Email" : "Number")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
