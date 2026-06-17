import SwiftUI

struct ContentView: View {
    @State private var sidebarSelection: SidebarItem? = .overview
    @Environment(AppState.self) private var state

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } content: {
            detailView
                .navigationSplitViewColumnWidth(min: 460, ideal: 620)
        } detail: {
            CleanupPlanPanelView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        }
        .frame(minWidth: 800, minHeight: 520)
    }

    @ViewBuilder
    private var detailView: some View {
        // Execution and report take over the content column
        if state.cleanupPhase == .executing || state.cleanupPhase == .done {
            CleanupExecutionView()
        } else {
            switch sidebarSelection ?? .overview {
            case .overview:
                OverviewView()
            case .exceptions:
                ExceptionsView()
            case .settings:
                SettingsView()
            case .reports:
                ReportsPlaceholderView()
            default:
                if let toolchain = sidebarSelection?.toolchainKey {
                    ToolchainDetailView(toolchain: toolchain)
                } else {
                    OverviewView()
                }
            }
        }
    }
}

// MARK: - Toolchain detail

struct ToolchainDetailView: View {
    let toolchain: String
    @Environment(AppState.self) private var state

    var body: some View {
        let items = state.items(for: toolchain)
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No \(toolchain) Storage",
                    systemImage: "tray",
                    description: Text("No storage detected for this toolchain.")
                )
            } else {
                List {
                    ForEach(items) { item in
                        StorageItemRowView(
                            item: item,
                            isSelected: state.selectedItemIDs.contains(item.id),
                            onToggle: { state.toggleSelection(item) }
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(toolchain)
    }
}

// MARK: - Placeholders

struct ReportsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Reports",
            systemImage: "doc.text",
            description: Text("Run a scan to generate a report.")
        )
        .navigationTitle("Reports")
    }
}
