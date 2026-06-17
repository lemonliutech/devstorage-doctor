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
        .animation(.standard, value: isExpanded)
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
                } else if item.subPaths.isEmpty {
                    Toggle("", isOn: Binding(
                        get: { isSelected },
                        set: { _ in onToggle() }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                } else {
                    // Aggregated item — tri-state checkbox
                    AggregateCheckbox(item: item, onToggle: onToggle)
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
            if item.subPaths.isEmpty {
                // Single path item
                detailRow("Path") {
                    pathButton(item.path)
                }
            } else {
                // Aggregated item — per-sub-path checkboxes
                detailRow("Paths") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(item.subPaths) { sub in
                            SubPathRowView(item: item, subPath: sub)
                        }
                    }
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

    // Sub-path rows defined at file scope below as SubPathRowView

    private func pathButton(_ path: String) -> some View {
        let exists = FileManager.default.fileExists(atPath: path)
        return Button {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        } label: {
            Text(path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(exists ? Color.accentColor : .secondary)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
        .help(exists ? "Show in Finder" : path)
        .disabled(!exists)
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

// MARK: - Aggregate tri-state checkbox

struct AggregateCheckbox: View {
    @Environment(AppState.self) private var state
    let item: StorageItem
    let onToggle: () -> Void

    var body: some View {
        let selState = state.subPathSelectionState(for: item)
        Button {
            onToggle()
        } label: {
            Image(systemName: iconName(for: selState))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(selState == .none ? Color(nsColor: .tertiaryLabelColor) : Color.accentColor)
        }
        .buttonStyle(.plain)
        .frame(width: 14)
    }

    private func iconName(for state: SubPathSelectionState) -> String {
        switch state {
        case .none:    return "square"
        case .partial: return "minus.square.fill"
        case .all:     return "checkmark.square.fill"
        }
    }
}

// MARK: - Sub-path row

struct SubPathRowView: View {
    @Environment(AppState.self) private var state
    let item: StorageItem
    let subPath: StorageSubPath

    private var isSelected: Bool {
        (state.selectedSubPaths[item.id] ?? Set(item.subPaths.map(\.path)))
            .contains(subPath.path)
    }

    private var canSelect: Bool {
        item.riskLevel != .protected && item.category != .packageOutput
    }

    var body: some View {
        HStack(spacing: Spacing.small) {
            if canSelect {
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { _ in state.toggleSubPath(subPath, in: item) }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            } else {
                Image(systemName: "minus")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
            }

            Button {
                NSWorkspace.shared.selectFile(subPath.path, inFileViewerRootedAtPath: "")
            } label: {
                Text(subPath.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(
                        FileManager.default.fileExists(atPath: subPath.path)
                            ? Color.accentColor : .secondary
                    )
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .help("Show in Finder")
            .disabled(!FileManager.default.fileExists(atPath: subPath.path))

            Spacer()

            if let bytes = subPath.sizeBytes {
                Text(bytes.formatted(.byteCount(style: .file)))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}
