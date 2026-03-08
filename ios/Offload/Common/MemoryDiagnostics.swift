// Purpose: Shared utilities and helpers.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Prefer small, reusable helpers and avoid feature-specific coupling.

import Darwin.Mach
import Foundation

enum MemoryDiagnostics {
    static func residentMemoryBytes() -> UInt64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        let result: kern_return_t = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    integerPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        return UInt64(info.resident_size)
    }

    static func residentMemoryMBString() -> String {
        guard let bytes = residentMemoryBytes() else {
            return "unavailable"
        }
        return formatMB(bytes)
    }

    static func deltaMBString(before: UInt64?, after: UInt64?) -> String {
        guard let before, let after else {
            return "unavailable"
        }

        let delta = Int64(after) - Int64(before)
        let sign = delta >= 0 ? "+" : "-"
        let magnitude = UInt64(abs(delta))
        return "\(sign)\(formatMB(magnitude))"
    }

    private static func formatMB(_ bytes: UInt64) -> String {
        String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
    }
}
