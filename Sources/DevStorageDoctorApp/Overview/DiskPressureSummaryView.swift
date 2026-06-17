import SwiftUI
import DevStorageCore

struct DiskPressureSummaryView: View {
    let results: [StorageItem]
    var lastScanDate: Date? = nil

    private var volumeAttrs: [FileAttributeKey: Any]? {
        try? FileManager.default.attributesOfFileSystem(
            forPath: FileManager.default.homeDirectoryForCurrentUser.path
        )
    }

    private var totalBytes: Int64 {
        Int64((volumeAttrs?[.systemSize] as? UInt64) ?? 0)
    }

    private var freeBytes: Int64 {
        Int64((volumeAttrs?[.systemFreeSize] as? UInt64) ?? 0)
    }

    private var usedBytes: Int64 { max(0, totalBytes - freeBytes) }

    private var recoverableCells: [(label: String, bytes: UInt64, color: Color, icon: String)] {
        let low = results
            .filter { $0.riskLevel == .low && $0.status == .found }
            .compactMap(\.sizeBytes).reduce(0, +)
        let medium = results
            .filter { $0.riskLevel == .medium && $0.status == .found }
            .compactMap(\.sizeBytes).reduce(0, +)
        return [
            ("Low Risk",    low,    .riskLow,    "checkmark.circle.fill"),
            ("Medium Risk", medium, .riskMedium, "exclamationmark.circle.fill"),
        ].filter { $0.bytes > 0 }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.base) {
                diskBarSection
                if !recoverableCells.isEmpty {
                    Divider()
                    recoverableSection
                }
            }
        }
    }

    private var diskBarSection: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            HStack {
                Label("Macintosh HD", systemImage: "internaldrive")
                    .font(.headline)
                Spacer()
                if let date = lastScanDate {
                    Text("Scanned \(date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if totalBytes > 0 {
                ProgressView(value: Double(usedBytes), total: Double(totalBytes))
                    .progressViewStyle(.linear)
                    .tint(.primary.opacity(0.35))

                HStack {
                    Text(Int64(usedBytes).formatted(.byteCount(style: .file)) + " used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Int64(freeBytes).formatted(.byteCount(style: .file)) + " free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("of " + Int64(totalBytes).formatted(.byteCount(style: .file)))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var recoverableSection: some View {
        HStack(spacing: Spacing.large) {
            ForEach(recoverableCells, id: \.label) { cell in
                HStack(spacing: Spacing.tight) {
                    Image(systemName: cell.icon)
                        .foregroundStyle(cell.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(cell.bytes.formatted(.byteCount(style: .file)))
                            .font(.callout)
                            .fontWeight(.medium)
                            .monospacedDigit()
                        Text(cell.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
    }
}
