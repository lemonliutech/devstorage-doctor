import SwiftUI
import DevStorageCore

struct CleanupExecutionView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        switch state.cleanupPhase {
        case .idle:
            EmptyView()
        case .executing:
            executingView
        case .done:
            if let report = state.cleanupReport {
                CleanupReportView(report: report)
                    .environment(state)
            }
        }
    }

    private var executingView: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            VStack(spacing: Spacing.medium) {
                ProgressView(value: state.cleanupProgress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 380)
                    .animation(.easeInOut(duration: 0.2), value: state.cleanupProgress)

                HStack {
                    if !state.cleanupCurrentItemName.isEmpty {
                        Text("Cleaning \(state.cleanupCurrentItemName)…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(state.cleanupProgressCurrent) / \(state.cleanupProgressTotal)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: 380)
            }

            Spacer()
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Cleaning…")
    }
}
