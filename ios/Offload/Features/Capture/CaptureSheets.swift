// Purpose: Sheet views for CaptureView.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI
import UIKit

// MARK: - Capture Detail View

struct CaptureDetailView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var errorPresenter = ErrorPresenter()
    @State private var content: String
    @State private var selectedType: ItemType?
    @State private var isStarred: Bool
    @State private var selectedTags: [Tag]
    @State private var attachmentData: Data?
    @State private var showingTags = false
    @State private var showingAttachmentSource = false
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingCameraUnavailableAlert = false
    @State private var selectedChannel: CommunicationChannel?
    @State private var commContactName: String?
    @State private var commContactIdentifier: String?
    @State private var commContactValue: String?
    @State private var showingContactPicker = false
    @State private var contactValuePickerValues: [String] = []
    @State private var showingContactValuePicker = false
    @State private var contactValuePickerChannel: CommunicationChannel = .call
    @FocusState private var isFocused: Bool

    private var style: ThemeStyle { themeManager.currentStyle }

    init(item: Item) {
        self.item = item
        _content = State(initialValue: item.content)
        _selectedType = State(initialValue: item.itemType)
        _isStarred = State(initialValue: item.isStarred)
        _selectedTags = State(initialValue: item.tags)
        let commMeta = item.communicationMetadata
        _selectedChannel = State(initialValue: commMeta?.channel)
        _commContactName = State(initialValue: commMeta?.contactName)
        _commContactIdentifier = State(initialValue: commMeta?.contactIdentifier)
        _commContactValue = State(initialValue: commMeta?.contactValue)
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputSection
                Spacer()
                bottomBar
            }
            .background(Theme.Gradients.deepBackground(colorScheme).ignoresSafeArea())
            .navigationTitle("Capture Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTags) {
                TagSelectionSheet(selectedTags: $selectedTags)
                    .environmentObject(themeManager)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog("Add Attachment", isPresented: $showingAttachmentSource) {
                Button("Camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    } else {
                        showingCameraUnavailableAlert = true
                    }
                }
                Button("Photo Library") {
                    imagePickerSource = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imagePickerSource, imageData: $attachmentData)
            }
            .alert("Camera Unavailable", isPresented: $showingCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device does not support camera capture.")
            }
            .onAppear {
                attachmentData = itemRepository.attachmentDataForDisplay(item)
                isFocused = true
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(
                    onSelect: { result in
                        commContactName = result.name
                        commContactIdentifier = result.identifier
                        let channel = selectedChannel ?? .call
                        let values = channel == .email ? result.emailAddresses : result.phoneNumbers
                        if values.count == 1 {
                            commContactValue = values.first
                        } else if values.count > 1 {
                            contactValuePickerValues = values
                            contactValuePickerChannel = channel
                            showingContactValuePicker = true
                        }
                    },
                    onCancel: {}
                )
            }
            .sheet(isPresented: $showingContactValuePicker) {
                ContactValuePickerSheet(
                    contactName: commContactName ?? "",
                    values: contactValuePickerValues,
                    channel: contactValuePickerChannel,
                    onSelect: { value in
                        commContactValue = value
                    }
                )
                .environmentObject(themeManager)
                .presentationDetents([.medium])
            }
        }
        .errorToasts(errorPresenter)
    }

    private var inputSection: some View {
        InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(ItemType.allCases.filter(\.isUserAssignable), id: \.self) { type in
                            Button {
                                selectedType = selectedType == type ? nil : type
                            } label: {
                                Text(type.displayName)
                                    .font(Theme.Typography.metadata)
                                    .foregroundStyle(
                                        selectedType == type
                                            ? Theme.Colors.accentButtonText(colorScheme, style: style)
                                            : Theme.Colors.textSecondary(colorScheme, style: style)
                                    )
                                    .padding(.horizontal, Theme.Spacing.sm)
                                    .padding(.vertical, Theme.Spacing.xs)
                                    .background(
                                        Capsule().fill(
                                            selectedType == type
                                                ? Theme.Colors.primary(colorScheme, style: style)
                                                : Theme.Colors.primary(colorScheme, style: style).opacity(0.08)
                                        )
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            Theme.Colors.primary(colorScheme, style: style).opacity(selectedType == type ? 0 : 0.25),
                                            lineWidth: 0.6
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(type.displayName) filter")
                            .accessibilityAddTraits(selectedType == type ? .isSelected : [])
                        }
                    }
                }

                if selectedType == .communication {
                    communicationFieldsSection
                }

                TextEditor(text: $content)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                    .frame(minHeight: 120)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.surface(colorScheme, style: style))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                            .stroke(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.35), lineWidth: 0.6)
                    )

                if let attachmentData, let uiImage = UIImage(data: attachmentData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))

                        Button {
                            self.attachmentData = nil
                        } label: {
                            IconTile(
                                iconName: Icons.closeCircleFilled,
                                iconSize: 16, tileSize: 44,
                                style: .primaryFilled(Theme.Colors.destructive(colorScheme, style: style))
                            )
                        }
                        .padding(Theme.Spacing.xs)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove attachment")
                    }
                }

                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(selectedTags) { tag in
                                TagPill(
                                    name: tag.name,
                                    color: Theme.Colors.tagColor(for: tag.name, colorScheme, style: style)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var bottomBar: some View {
        ActionBarContainer(fill: Theme.Colors.cardColor(index: 1, colorScheme, style: style)) {
            HStack(spacing: Theme.Spacing.md) {
                Button { showingAttachmentSource = true } label: {
                    IconTile(
                        iconName: attachmentData != nil ? Icons.cameraFilled : Icons.camera,
                        iconSize: 20, tileSize: 44,
                        style: attachmentData != nil
                            ? .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(attachmentData == nil ? "Add attachment" : "Change attachment")

                Button { showingTags = true } label: {
                    IconTile(
                        iconName: selectedTags.isEmpty ? Icons.tag : Icons.tagFilled,
                        iconSize: 20, tileSize: 44,
                        style: selectedTags.isEmpty
                            ? .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                            : .primaryFilled(Theme.Colors.primary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectedTags.isEmpty ? "Add tags" : "Edit tags")

                Button { isStarred.toggle() } label: {
                    IconTile(
                        iconName: isStarred ? Icons.starFilled : Icons.star,
                        iconSize: 20, tileSize: 44,
                        style: isStarred
                            ? .primaryFilled(Theme.Colors.caution(colorScheme, style: style))
                            : .secondaryOutlined(Theme.Colors.textSecondary(colorScheme, style: style))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isStarred ? "Unstar item" : "Star item")

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(Theme.Colors.buttonDarkText(colorScheme, style: style))
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.buttonDark(colorScheme))
                        .clipShape(Capsule())
                        .shadow(color: Theme.Shadows.ultraLight(colorScheme), radius: Theme.Shadows.elevationUltraLight, y: Theme.Shadows.offsetYUltraLight)
                }
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    private var communicationFieldsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(CommunicationChannel.allCases, id: \.rawValue) { channel in
                        let isSelected = selectedChannel == channel
                        Button {
                            selectedChannel = isSelected ? nil : channel
                        } label: {
                            Label(channel.displayName, systemImage: channel.icon)
                                .font(Theme.Typography.metadata)
                                .foregroundStyle(
                                    isSelected
                                        ? Theme.Colors.secondaryButtonText(colorScheme, style: style)
                                        : Theme.Colors.textSecondary(colorScheme, style: style)
                                )
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(
                                            isSelected
                                                ? Theme.Colors.secondary(colorScheme, style: style)
                                                : Theme.Colors.secondary(colorScheme, style: style).opacity(0.08)
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            Theme.Colors.secondary(colorScheme, style: style).opacity(isSelected ? 0 : 0.25),
                                            lineWidth: 0.8
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(channel.displayName) channel")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }

            if let contactName = commContactName {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: Icons.contactLink)
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                    Text(contactName)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                    if let value = commContactValue {
                        Text(value)
                            .font(Theme.Typography.metadata)
                            .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))
                    }
                    Spacer()
                    Button {
                        commContactName = nil
                        commContactIdentifier = nil
                        commContactValue = nil
                    } label: {
                        Image(systemName: Icons.closeCircleFilled)
                            .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove contact")
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface(colorScheme, style: style))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous))
            } else {
                Button { showingContactPicker = true } label: {
                    Label("Link Contact", systemImage: Icons.contactLink)
                        .font(Theme.Typography.metadata)
                        .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    Theme.Colors.accentPrimary(colorScheme, style: style).opacity(0.25),
                                    lineWidth: 0.8
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Link a contact")
            }
        }
    }

    private func save() {
        do {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            try itemRepository.updateContent(item, content: trimmed)
            try itemRepository.updateType(item, type: selectedType?.rawValue)

            // Persist communication metadata
            if selectedType == .communication, let channel = selectedChannel {
                item.communicationMetadata = CommunicationMetadata(
                    channel: channel,
                    contactName: commContactName,
                    contactIdentifier: commContactIdentifier,
                    contactValue: commContactValue
                )
            } else if selectedType != .communication {
                item.communicationMetadata = nil
            }

            if isStarred != item.isStarred {
                try itemRepository.toggleStar(item)
            }

            let currentTagIds = Set(item.tags.map(\.id))
            let selectedTagIds = Set(selectedTags.map(\.id))
            for tag in item.tags where !selectedTagIds.contains(tag.id) {
                try itemRepository.removeTag(item, tag: tag)
            }
            for tag in selectedTags where !currentTagIds.contains(tag.id) {
                try itemRepository.addTag(item, tag: tag)
            }

            let hadAttachment = itemRepository.attachmentDataForDisplay(item) != nil
            if attachmentData != nil || hadAttachment {
                try itemRepository.updateAttachment(item, attachmentData: attachmentData)
            }

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        } catch {
            errorPresenter.present(error)
        }
    }
}

// MARK: - Move to Collection Sheet (unified Plan/List)

/// Unified sheet for moving an item to a plan or list collection.
struct MoveToCollectionSheet: View {
    let item: Item
    let isStructured: Bool
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.itemRepository) private var itemRepository
    @Environment(\.collectionRepository) private var collectionRepository
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var collections: [Collection] = []
    @State private var selectedCollection: Collection?
    @State private var createNew = false
    @State private var newCollectionName = ""
    @State private var isLoading = true
    @State private var errorPresenter = ErrorPresenter()

    private var style: ThemeStyle { themeManager.currentStyle }
    private var collectionLabel: String { isStructured ? "Plan" : "List" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    if isLoading {
                        ProgressView()
                            .padding(.vertical, Theme.Spacing.xl)
                    } else if !collections.isEmpty {
                        InputCard(fill: Theme.Colors.cardColor(index: 0, colorScheme, style: style)) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Select \(collectionLabel)")
                                    .font(Theme.Typography.metadata)
                                    .foregroundStyle(Theme.Colors.cardTextSecondary(colorScheme, style: style))

                                ForEach(collections) { collection in
                                    Button {
                                        selectedCollection = collection
                                        moveToSelected()
                                    } label: {
                                        HStack {
                                            Text(collection.name)
                                                .font(Theme.Typography.body)
                                                .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: style))
                                            Spacer()
                                            AppIcon(name: Icons.chevronRight, size: 12)
                                                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                                        }
                                        .padding(.vertical, Theme.Spacing.xs)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Button {
                        createNew = true
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            IconTile(
                                iconName: Icons.addCircleFilled,
                                iconSize: 16,
                                tileSize: 44,
                                style: .secondaryOutlined(Theme.Colors.accentPrimary(colorScheme, style: style))
                            )
                            Text("Create New \(collectionLabel)")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: style))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Gradients.deepBackground(colorScheme).ignoresSafeArea())
            .navigationTitle("Move to \(collectionLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("New \(collectionLabel)", isPresented: $createNew) {
                TextField("\(collectionLabel) name", text: $newCollectionName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    createNewAndMove()
                }
            } message: {
                Text("Enter a name for the new \(collectionLabel.lowercased())")
            }
            .onAppear {
                loadCollections()
            }
        }
        .errorToasts(errorPresenter)
    }

    private func loadCollections() {
        do {
            collections = isStructured
                ? try collectionRepository.fetchStructured()
                : try collectionRepository.fetchUnstructured()
        } catch {
            errorPresenter.present(error)
            collections = []
        }
        isLoading = false
    }

    private func moveToSelected() {
        guard let collection = selectedCollection else { return }

        do {
            let position = isStructured
                ? collectionRepository.nextPosition(in: collection, parentId: nil)
                : nil
            try itemRepository.moveToCollectionAtomically(
                item, collection: collection, targetType: "task", position: position
            )
            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }

    private func createNewAndMove() {
        let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let collection = try collectionRepository.create(name: trimmed, isStructured: isStructured)
            let position = isStructured ? 0 : nil
            try itemRepository.moveToCollectionAtomically(
                item, collection: collection, targetType: "task", position: position
            )
            dismiss()
            onComplete()
        } catch {
            errorPresenter.present(error)
        }
    }
}
