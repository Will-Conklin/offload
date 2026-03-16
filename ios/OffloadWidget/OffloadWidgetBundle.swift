// Purpose: Widget bundle entry point — registers all Offload widgets.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI
import WidgetKit

@main
struct OffloadWidgetBundle: WidgetBundle {
    var body: some Widget {
        OffloadSmallWidget()
        OffloadMediumWidget()
    }
}
