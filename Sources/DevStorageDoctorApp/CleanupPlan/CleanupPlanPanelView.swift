import SwiftUI
import DevStorageCore

struct CleanupPlanPanelView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            if state.selectedItems.isEmpty {
                emptyState
            } else {
                planContent
            }
        }
        .frame(minWidth: 200, idealWidth: 220)
    }

    // MARK: - Empty

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Items Selected", systemImage: "tray")
        } description: {
            Text("Check items in the results list to build a cleanup plan.")
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Plan

    private var planContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {

                    // Recovery estimate
                    GroupBox("Recovery Estimate") {
                        VStack(spacing: Spacing.tight) {
                            HStack {
                                Text("Items selected")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(state.selectedItems.count)")
                                    .font(.callout)
                                    .monospacedDigit()
                            }
                            Divider()
                            HStack {
                                Text("Recoverable space")
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

                    // Risk breakdown
                    let low    = state.selectedItems.filter { $0.riskLevel == .low }.count
                    let medium = state.selectedItems.filter { $0.riskLevel == .medium }.count
                    let high   = state.selectedItems.filter { $0.riskLevel == .high }.count

                    if low > 0 || medium > 0 || high > 0 {
                        GroupBox("Risk Breakdown") {
                            VStack(spacing: Spacing.tight) {
                                if low > 0    { riskRow(label: "Low",    count: low,    color: .riskLow) }
                                if medium > 0 { riskRow(label: "Medium", count: medium, color: .riskMedium) }
                                if high > 0   { riskRow(label: "High",   count: high,   color: .riskHigh) }
                            }
                        }
                    }

                    // Excluded items note
                    let excluded = state.results.filter {
                        $0.riskLevel == .protected || $0.category == .packageOutput
                    }.count

                    if excluded > 0 {
                        Label(
                            "\(excluded) item\(excluded == 1 ? "" : "s") excluded (protected)",
                            systemImage: "lock"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.tight)
                    }
                }
                .padding(Spacing.medium)
            }

            Divider()

            // Generate Plan — always visible at the bottom
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

    private func riskRow(label: String, count: Int, color: Color) -> some View {
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
}
