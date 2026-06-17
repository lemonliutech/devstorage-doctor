import SwiftUI
import DevStorageCore

struct CleanupPlanPanelView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            switch panelState {
            case .noScan:
                noScanState
            case .noneSelected:
                noneSelectedState
            case .hasSelection:
                planContent
            }
        }
        .frame(minWidth: 200, idealWidth: 220)
    }

    private enum PanelState { case noScan, noneSelected, hasSelection }

    private var panelState: PanelState {
        if case .idle = state.scanPhase { return .noScan }
        if state.results.isEmpty { return .noScan }
        return state.selectedItems.isEmpty ? .noneSelected : .hasSelection
    }

    // MARK: - Empty states

    private var noScanState: some View {
        ContentUnavailableView {
            Label("No Scan Yet", systemImage: "magnifyingglass.circle")
        } description: {
            Text("Run a scan to see cleanup options.")
        }
        .frame(maxHeight: .infinity)
    }

    private var noneSelectedState: some View {
        ContentUnavailableView {
            Label("Nothing Selected", systemImage: "checkmark.circle")
        } description: {
            Text("Select items in the results list to build a cleanup plan.")
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Plan

    private var planContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    recoveryGroupBox
                    riskGroupBox
                    excludedNote
                }
                .padding(Spacing.medium)
            }

            Divider()

            Button {
                state.showingCleanupPlan = true
            } label: {
                Label("Generate Plan", systemImage: "list.bullet.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(Spacing.medium)
            .sheet(isPresented: Binding(
                get: { state.showingCleanupPlan },
                set: { state.showingCleanupPlan = $0 }
            )) {
                CleanupPlanView()
                    .environment(state)
            }
        }
    }

    private var recoveryGroupBox: some View {
        GroupBox("Recovery Estimate") {
            VStack(spacing: Spacing.tight) {
                planRow("Selected", value: "\(state.selectedItems.count) items")
                Divider()
                HStack {
                    Text("Recoverable")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(state.estimatedRecoveryBytes.formatted(.byteCount(style: .file)))
                        .font(.callout)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
            }
        }
    }

    @ViewBuilder
    private var riskGroupBox: some View {
        let low    = state.selectedItems.filter { $0.riskLevel == .low }.count
        let medium = state.selectedItems.filter { $0.riskLevel == .medium }.count
        let high   = state.selectedItems.filter { $0.riskLevel == .high }.count

        if low > 0 || medium > 0 || high > 0 {
            GroupBox("Risk Breakdown") {
                VStack(spacing: Spacing.tight) {
                    if low > 0    { riskRow("Low",    low,    .riskLow) }
                    if medium > 0 { riskRow("Medium", medium, .riskMedium) }
                    if high > 0   { riskRow("High",   high,   .riskHigh) }
                }
            }
        }
    }

    @ViewBuilder
    private var excludedNote: some View {
        let count = state.results.filter {
            $0.riskLevel == .protected || $0.category == .packageOutput
        }.count
        if count > 0 {
            Label(
                "\(count) item\(count == 1 ? "" : "s") excluded",
                systemImage: "lock"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func riskRow(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack {
            Label(label, systemImage: "circle.fill")
                .foregroundStyle(color)
                .font(.callout)
            Spacer()
            Text("\(count)")
                .monospacedDigit()
                .foregroundStyle(color)
                .font(.callout)
        }
    }

    private func planRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.callout).monospacedDigit()
        }
    }
}
