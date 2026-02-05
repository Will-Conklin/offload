// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve established theme defaults and component APIs.

//  SF Symbols wrapper for consistent sizing and template rendering.

import SwiftUI

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
