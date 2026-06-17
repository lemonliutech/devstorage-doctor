import SwiftUI

struct OverviewView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            if state.scanPhase == .scanning {
                ScanProgressBarView()
            }

            switch state.scanPhase {
            case .idle:
                idleState
            case .scanning where state.results.isEmpty:
                scanStartingState
            case .scanning, .done:
                VStack(spacing: 0) {
                    DiskPressureSummaryView(results: state.results, lastScanDate: state.lastScanDate)
                        .padding(Spacing.medium)
                    ScanResultListView()
                }
            case .failed(let msg):
                failedState(msg)
            }
        }
        .navigationTitle("DevStorage Doctor")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { state.runScan() } label: {
                    Label(toolbarScanLabel, systemImage: "arrow.clockwise")
                }
                .disabled(state.scanPhase == .scanning)
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private var toolbarScanLabel: String {
        switch state.scanPhase {
        case .idle:    return "Scan"
        case .scanning: return "Scanning…"
        case .done:    return "Rescan"
        case .failed:  return "Retry"
        }
    }

    // MARK: - States

    private var idleState: some View {
        ContentUnavailableView {
            Label("Ready to Scan", systemImage: "magnifyingglass.circle")
        } description: {
            Text("Measure your development storage.\nNothing is deleted until you confirm.")
        } actions: {
            Button("Scan Now") { state.runScan() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
        }
    }

    private var scanStartingState: some View {
        VStack {
            Spacer()
            VStack(spacing: Spacing.small) {
                Text(state.scanningRuleName.isEmpty ? "Preparing…" : "Scanning \(state.scanningRuleName)…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func failedState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Scan Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") { state.runScan() }
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Scan Progress Bar

struct ScanProgressBarView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: Spacing.tight) {
            ProgressView(value: state.scanProgress)
                .progressViewStyle(.linear)
                .animation(.standard, value: state.scanProgress)

            HStack {
                if !state.scanningRuleName.isEmpty {
                    Text("Scanning \(state.scanningRuleName)…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(state.scanProgressCurrent) / \(state.scanProgressTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(.bar)
    }
}
