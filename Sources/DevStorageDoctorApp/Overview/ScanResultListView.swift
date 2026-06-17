import SwiftUI
import DevStorageCore

struct ScanResultListView: View {
    @Environment(AppState.self) private var state

    private let toolchainOrder = [
        "Xcode / iOS",
        "Android / Gradle",
        "Flutter / Dart / FVM",
        "CocoaPods",
        "Node / pnpm / npm",
        "HarmonyOS / DevEco",
    ]

    private var toolchains: [String] {
        let inResults = Set(state.results.map(\.toolchain))
        var ordered = toolchainOrder.filter { inResults.contains($0) }
        let extras = inResults.subtracting(toolchainOrder).sorted()
        ordered.append(contentsOf: extras)
        return ordered
    }

    var body: some View {
        List {
            ForEach(toolchains, id: \.self) { toolchain in
                ToolchainSectionView(
                    toolchain: toolchain,
                    items: state.items(for: toolchain),
                    selectedIDs: state.selectedItemIDs,
                    onToggle: { state.toggleSelection($0) }
                )
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}

// MARK: - Toolchain Section

struct ToolchainSectionView: View {
    let toolchain: String
    let items: [StorageItem]
    let selectedIDs: Set<String>
    let onToggle: (StorageItem) -> Void

    @State private var isExpanded = true

    private var totalBytes: UInt64 {
        items.compactMap(\.sizeBytes).reduce(0, +)
    }

    private var selectedCount: Int {
        items.filter { selectedIDs.contains($0.id) }.count
    }

    var body: some View {
        Section(isExpanded: $isExpanded) {
            ForEach(items.filter { $0.status != .missing }) { item in
                StorageItemRowView(
                    item: item,
                    isSelected: selectedIDs.contains(item.id),
                    onToggle: { onToggle(item) }
                )
            }
        } header: {
            HStack(spacing: Spacing.small) {
                Image(systemName: iconName(for: toolchain))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Text(toolchain)
                    .font(.callout)
                    .fontWeight(.semibold)
                Spacer()
                Text(UInt64(totalBytes).formatted(.byteCount(style: .file)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if selectedCount > 0 {
                    Text("· \(selectedCount) selected")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func iconName(for toolchain: String) -> String {
        switch toolchain {
        case "Xcode / iOS":          return "hammer"
        case "Android / Gradle":     return "square.grid.2x2"
        case "Flutter / Dart / FVM": return "wind"
        case "CocoaPods":            return "shippingbox"
        case "Node / pnpm / npm":    return "network"
        case "HarmonyOS / DevEco":   return "square.stack.3d.up"
        default:                     return "folder"
        }
    }
}
