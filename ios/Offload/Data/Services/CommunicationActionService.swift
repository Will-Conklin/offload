// Purpose: One-touch communication actions via URL schemes.
// Authority: Code-level
// Governed by: CLAUDE.md

import Foundation
import UIKit

/// Opens phone, messages, or mail apps for one-touch communication actions.
@MainActor
enum CommunicationActionService {
    /// Attempts to open the appropriate app for the given channel and contact value.
    /// - Parameters:
    ///   - channel: The communication channel (call, text, email).
    ///   - contactValue: The phone number or email address.
    ///   - subject: Optional email subject line.
    ///   - body: Optional message body (email only).
    /// - Returns: `true` if the URL was opened successfully.
    @discardableResult
    static func performAction(
        channel: CommunicationChannel,
        contactValue: String,
        subject: String? = nil,
        body: String? = nil
    ) -> Bool {
        guard let url = buildURL(channel: channel, contactValue: contactValue, subject: subject, body: body) else {
            return false
        }
        guard UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }

    /// Checks whether the device supports opening the given channel.
    static func canPerformAction(channel: CommunicationChannel, contactValue: String) -> Bool {
        guard let url = buildURL(channel: channel, contactValue: contactValue) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private static func buildURL(
        channel: CommunicationChannel,
        contactValue: String,
        subject: String? = nil,
        body: String? = nil
    ) -> URL? {
        let encoded = contactValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? contactValue
        switch channel {
        case .call:
            return URL(string: "tel:\(encoded)")
        case .text:
            return URL(string: "sms:\(encoded)")
        case .email:
            var urlString = "mailto:\(encoded)"
            var queryItems: [String] = []
            if let subject, let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                queryItems.append("subject=\(encodedSubject)")
            }
            if let body, let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                queryItems.append("body=\(encodedBody)")
            }
            if !queryItems.isEmpty {
                urlString += "?" + queryItems.joined(separator: "&")
            }
            return URL(string: urlString)
        }
    }
}
