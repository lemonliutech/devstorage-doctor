import Foundation

public struct CleanupExecutor: Sendable {

    public init() {}

    /// Execute cleanup for the given items. Progress is reported via the callback
    /// (called on whatever thread the executor runs on — callers must dispatch to main
    /// if they update UI directly).
    public func execute(
        items: [StorageItem],
        onProgress: @Sendable (Int, Int, String) -> Void
    ) -> CleanupReport {
        let startedAt = Date()
        var results: [CleanupItemResult] = []
        let fm = FileManager.default

        for (index, item) in items.enumerated() {
            onProgress(index, items.count, item.displayName)

            // Guard: never execute on protected or manual-review items
            guard item.riskLevel != .protected,
                  item.category != .packageOutput,
                  item.category != .manualReview,
                  item.status == .found else {
                let reason: String
                switch item.riskLevel {
                case .protected:   reason = "Protected"
                case .unsupported: reason = "Unsupported"
                default:
                    reason = item.category == .packageOutput ? "Manual review required" : "Not found"
                }
                results.append(CleanupItemResult(item: item, status: .skipped(reason: reason)))
                continue
            }

            // Measure size before deletion for accurate recovery reporting
            let sizeBefore = item.sizeBytes ?? directorySize(at: item.path, fm: fm)

            do {
                try fm.removeItem(atPath: item.path)
                results.append(CleanupItemResult(item: item, status: .succeeded(bytesRecovered: sizeBefore)))
            } catch {
                results.append(CleanupItemResult(item: item, status: .failed(error: error.localizedDescription)))
            }
        }

        onProgress(items.count, items.count, "")
        return CleanupReport(results: results, startedAt: startedAt, finishedAt: Date())
    }

    private func directorySize(at path: String, fm: FileManager) -> UInt64 {
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: UInt64 = 0
        for case let url as URL in enumerator {
            total += UInt64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }
}
