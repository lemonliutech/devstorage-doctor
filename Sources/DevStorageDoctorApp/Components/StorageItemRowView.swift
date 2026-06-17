import SwiftUI
import DevStorageCore

struct StorageItemRowView: View {
    let item: StorageItem
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var isExpanded = false

    private var canSelect: Bool {
        item.status == .found
            && item.riskLevel != .protected
            && item.riskLevel != .unsupported
            && item.category != .packageOutput
    }

    var body: some View {
        VStack(spacing: 0) {
            rowLabel
                .contentShape(Rectangle())
                .onTapGesture {
                    isExpanded.toggle()
                }

            if isExpanded {
                expandedDetail
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
    }

    // MARK: - Collapsed label

    private var rowLabel: some View {
        HStack(spacing: Spacing.small) {
            // Selection control
            Group {
                if item.riskLevel == .protected {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                } else if !canSelect {
                    Image(systemName: "minus")
                        .foregroundStyle(.tertiary)
                } else {
                    Toggle("", isOn: Binding(
                        get: { isSelected },
                        set: { _ in onToggle() }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                }
            }
            .frame(width: 18)

            // Name + short explanation
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(item.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Size
            if let bytes = item.sizeBytes {
                Text(bytes.formatted(.byteCount(style: .file)))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text("—")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(width: 70, alignment: .trailing)
            }

            RiskBadgeView(riskLevel: item.riskLevel)
                .frame(width: 90, alignment: .trailing)

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 12)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Expanded detail

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            detailRow("Path") {
                let pathExists = FileManager.default.fileExists(atPath: item.path)
                Text(item.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(pathExists ? Color.accentColor : .secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .help(pathExists ? "Click to show in Finder" : item.path)
                    .onTapGesture {
                        guard pathExists else { return }
                        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                    }
            }
            detailRow("Toolchain") {
                Text(item.toolchain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let ex = item.exception {
                detailRow("Issue") {
                    Text(ex.message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                detailRow("Fix") {
                    Text(ex.suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.leading, 26)
        .padding(.vertical, 6)
    }

    private func detailRow<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 56, alignment: .trailing)
            content()
            Spacer()
        }
    }
}
