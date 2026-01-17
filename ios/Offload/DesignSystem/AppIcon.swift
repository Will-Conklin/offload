//
//  AppIcon.swift
//  Offload
//
//  SF Symbols wrapper for consistent sizing and template rendering.
//

import SwiftUI

// AGENT NAV
// - App Icon

struct AppIcon: View {
    let name: String
    var size: CGFloat
    var renderingMode: Image.TemplateRenderingMode

    init(name: String, size: CGFloat = 16, renderingMode: Image.TemplateRenderingMode = .template) {
        self.name = name
        self.size = size
        self.renderingMode = renderingMode
    }

    var body: some View {
        Image(systemName: name)
            .renderingMode(renderingMode)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
