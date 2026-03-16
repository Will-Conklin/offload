// Purpose: Share Extension principal class — embeds SwiftUI compose view for capturing shared content.
// Authority: Code-level
// Governed by: CLAUDE.md

import MobileCoreServices
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// UIViewController subclass that hosts the SwiftUI share compose view.
/// Receives shared items from any app and enqueues them for the main Offload app.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        extractSharedContent { [weak self] content, sourceURL in
            guard let self else { return }
            let shareView = ShareComposeView(
                initialContent: content,
                sourceURL: sourceURL,
                onSave: { [weak self] text, type in
                    guard let self else { return }
                    let capture = PendingCapture(content: text, type: type, sourceURL: sourceURL)
                    PendingCaptureStore.enqueue(capture)
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: ShareError.cancelled)
                }
            )
            let host = UIHostingController(rootView: shareView)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(host)
            view.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: view.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            host.didMove(toParent: self)
        }
    }

    /// Extracts text, URL, or image description from the extension context's input items.
    private func extractSharedContent(completion: @escaping (_ text: String, _ sourceURL: String?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            completion("", nil)
            return
        }

        let attachments = item.attachments ?? []

        // 1. Plain text
        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { value, _ in
                DispatchQueue.main.async {
                    completion((value as? String) ?? "", nil)
                }
            }
            return
        }

        // 2. URL — use the URL string as content with sourceURL set
        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { value, _ in
                DispatchQueue.main.async {
                    let urlString = (value as? URL)?.absoluteString ?? ""
                    completion(urlString, urlString)
                }
            }
            return
        }

        // 3. Image — use a placeholder description
        if attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) != nil {
            DispatchQueue.main.async {
                completion("", nil)
            }
            return
        }

        DispatchQueue.main.async { completion("", nil) }
    }
}

private enum ShareError: Error {
    case cancelled
}
