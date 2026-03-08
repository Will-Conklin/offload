// Purpose: File-backed storage for item attachments.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep attachment writes atomic and scoped to app-owned storage.

import Foundation

protocol AttachmentStorage {
    /// Persists attachment bytes for an item and returns a storage path.
    /// - Parameters:
    ///   - data: Attachment bytes to write.
    ///   - itemId: Item identifier used for file naming.
    /// - Returns: Absolute file path of stored attachment.
    func storeAttachment(_ data: Data, for itemId: UUID) throws -> String
    /// Loads attachment bytes from a previously stored attachment path.
    /// - Parameter path: Absolute file path previously returned by `storeAttachment`.
    /// - Returns: Attachment bytes.
    func loadAttachment(at path: String) throws -> Data
    /// Removes a stored attachment file if it exists.
    /// - Parameter path: Absolute file path previously returned by `storeAttachment`.
    func removeAttachment(at path: String) throws
    /// Indicates whether a stored attachment exists at a path.
    /// - Parameter path: Absolute attachment file path to test.
    /// - Returns: `true` when attachment exists and path is valid.
    func attachmentExists(at path: String) -> Bool
}

struct AttachmentStorageService: AttachmentStorage {
    private let fileManager: FileManager
    private let attachmentsDirectoryURL: URL

    /// Creates a file-backed attachment storage service.
    /// - Parameters:
    ///   - fileManager: File manager used for filesystem operations.
    ///   - baseDirectoryURL: Optional directory override for attachment root (used in tests).
    init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        if let baseDirectoryURL {
            attachmentsDirectoryURL = baseDirectoryURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            attachmentsDirectoryURL = appSupport
                .appendingPathComponent("Offload", isDirectory: true)
                .appendingPathComponent("Attachments", isDirectory: true)
        }
    }

    /// Persists attachment data atomically under the managed attachments directory.
    /// - Parameters:
    ///   - data: Attachment bytes to write.
    ///   - itemId: Item identifier used to derive a stable filename prefix.
    /// - Returns: Standardized absolute path to the newly written attachment file.
    func storeAttachment(_ data: Data, for itemId: UUID) throws -> String {
        try ensureAttachmentsDirectory()
        let filename = "\(itemId.uuidString)-\(UUID().uuidString).attachment"
        let fileURL = attachmentsDirectoryURL.appendingPathComponent(filename, isDirectory: false)
        try data.write(to: fileURL, options: .atomic)
        return fileURL.standardizedFileURL.path
    }

    /// Reads attachment data after validating path ownership under managed storage.
    /// - Parameter path: Absolute attachment file path.
    /// - Returns: Attachment bytes loaded from disk.
    func loadAttachment(at path: String) throws -> Data {
        let fileURL = try validatedAttachmentURL(for: path)
        return try Data(contentsOf: fileURL, options: .mappedIfSafe)
    }

    /// Deletes an attachment file after validating path ownership under managed storage.
    /// - Parameter path: Absolute attachment file path.
    func removeAttachment(at path: String) throws {
        let fileURL = try validatedAttachmentURL(for: path)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    /// Checks whether a valid managed attachment path exists.
    /// - Parameter path: Absolute attachment file path.
    /// - Returns: `true` when the validated path exists in managed storage.
    func attachmentExists(at path: String) -> Bool {
        guard let fileURL = try? validatedAttachmentURL(for: path) else {
            return false
        }
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Ensures the managed attachments directory exists before write operations.
    private func ensureAttachmentsDirectory() throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: attachmentsDirectoryURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return
        }
        try fileManager.createDirectory(
            at: attachmentsDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    /// Validates that a path resolves within the app-managed attachments directory.
    /// - Parameter path: Absolute path to validate.
    /// - Returns: Canonicalized file URL rooted within managed storage.
    private func validatedAttachmentURL(for path: String) throws -> URL {
        let candidateURL = URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let rootURL = attachmentsDirectoryURL
            .standardizedFileURL
            .resolvingSymlinksInPath()

        let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"
        guard candidateURL.path.hasPrefix(rootPath) else {
            throw ValidationError("Attachment path is outside app-managed storage.")
        }
        return candidateURL
    }
}
