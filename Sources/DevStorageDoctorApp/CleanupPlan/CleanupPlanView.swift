import SwiftUI
import DevStorageCore

// MARK: - Cleanup method helper

private extension StorageItem {
    var cleanupCommand: String {
        switch category {
        case .dependencyStore:
            switch toolchain {
            case "Flutter / Dart / FVM":
                return "flutter pub cache clean"
            case "CocoaPods":
                return "pod cache clean --all"
            case "Node / pnpm / npm":
                return "rm -rf \"\(path)\""
            default:
                return "rm -rf \"\(path)\""
            }
        case .sdkRuntime:
            return "xcrun simctl delete unavailable  # or manage in Xcode"
        case .cache, .buildArtifact:
            return "rm -rf \"\(path)\""
        case .packageOutput, .manualReview:
            return "# Review manually before deleting"
        }
    }

    var riskLabel: String {
        switch riskLevel {
        case .low:         return "Low"
        case .medium:      return "Medium"
        case .high:        return "High"
        case .manualReview: return "Manual Review"
        case .protected:   return "Protected"
        case .unsupported: return "Unsupported"
        }
    }

    var categoryLabel: String {
        switch category {
        case .cache:          return "Cache"
        case .dependencyStore: return "Dependency store"
        case .sdkRuntime:     return "SDK / Runtime"
        case .buildArtifact:  return "Build artifact"
        case .packageOutput:  return "Package output"
        case .manualReview:   return "Manual review"
        }
    }
}

// MARK: - CleanupPlanView

struct CleanupPlanView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private var actionItems: [StorageItem] {
        state.selectedItems.filter {
            $0.riskLevel != .protected && $0.category != .packageOutput
        }
    }

    private var manualItems: [StorageItem] {
        state.results.filter {
            $0.category == .packageOutput && $0.status == .found
        }
    }

    private var protectedItems: [StorageItem] {
        state.results.filter { $0.riskLevel == .protected }
    }

    private var toolchains: [String] {
        Array(Set(actionItems.map(\.toolchain))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    summarySection
                    if !actionItems.isEmpty { actionsSection }
                    if !manualItems.isEmpty { manualReviewSection }
                    if !protectedItems.isEmpty { excludedSection }
                }
                .padding(Spacing.large)
            }
            Divider()
            footer
        }
        .frame(minWidth: 560, minHeight: 480)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cleanup Plan")
                    .font(.headline)
                Text("Review before execution — nothing is deleted yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Close") { dismiss() }
                .keyboardShortcut(.escape)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
    }

    // MARK: - Summary

    private var summarySection: some View {
        GroupBox("Summary") {
            VStack(spacing: Spacing.tight) {
                planRow("Actions", value: "\(actionItems.count) items")
                Divider()
                planRow("Estimated recovery") {
                    Text(state.estimatedRecoveryBytes.formatted(.byteCount(style: .file)))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                let highCount = actionItems.filter { $0.riskLevel == .high }.count
                if highCount > 0 {
                    Divider()
                    planRow("High-risk actions") {
                        Text("\(highCount)")
                            .foregroundStyle(.red)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            Text("Actions")
                .font(.headline)

            ForEach(toolchains, id: \.self) { tc in
                let items = actionItems.filter { $0.toolchain == tc }
                GroupBox(tc) {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                            actionRow(item)
                            if idx < items.count - 1 { Divider() }
                        }
                    }
                }
            }
        }
    }

    private func actionRow(_ item: StorageItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                    Text(item.categoryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                RiskBadgeView(riskLevel: item.riskLevel)
                if let bytes = item.sizeBytes {
                    Text(bytes.formatted(.byteCount(style: .file)))
                        .font(.callout)
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                }
            }
            Text(item.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(1)
            Text(item.cleanupCommand)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.blue)
                .textSelection(.enabled)
                .lineLimit(2)
            if !item.explanation.isEmpty {
                Text(item.explanation)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding(.vertical, Spacing.small)
    }

    // MARK: - Manual review

    private var manualReviewSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.tight) {
                Label("Manual Review Required", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                Text("These items may contain release artifacts, symbolication data, or QA builds. Review in Finder before deleting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                ForEach(manualItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(item.path)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if let bytes = item.sizeBytes {
                            Text(bytes.formatted(.byteCount(style: .file)))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Excluded

    private var excludedSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.tight) {
                Label("Excluded (Protected)", systemImage: "lock.fill")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Divider()
                ForEach(protectedItems) { item in
                    HStack {
                        Text(item.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Protected")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(markdownReport, forType: .string)
            } label: {
                Label("Copy as Markdown", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Back to Selection") { dismiss() }
                .buttonStyle(.bordered)

            Button("Proceed to Execution") {
                dismiss()
                state.showingCleanupPlan = false
                state.runCleanup()
            }
            .buttonStyle(.borderedProminent)
            .disabled(actionItems.isEmpty)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
    }

    // MARK: - Markdown export

    private var markdownReport: String {
        var lines: [String] = []
        lines.append("# DevStorage Doctor — Cleanup Plan")
        lines.append("")
        lines.append("**Date:** \(Date().formatted(date: .abbreviated, time: .shortened))")
        lines.append("**Actions:** \(actionItems.count) items")
        lines.append("**Estimated recovery:** \(state.estimatedRecoveryBytes.formatted(.byteCount(style: .file)))")
        lines.append("")

        for tc in toolchains {
            let items = actionItems.filter { $0.toolchain == tc }
            lines.append("## \(tc)")
            lines.append("")
            for item in items {
                lines.append("### \(item.displayName)")
                lines.append("- **Category:** \(item.categoryLabel)")
                lines.append("- **Risk:** \(item.riskLabel)")
                if let bytes = item.sizeBytes {
                    lines.append("- **Size:** \(bytes.formatted(.byteCount(style: .file)))")
                }
                lines.append("- **Path:** `\(item.path)`")
                lines.append("- **Command:** `\(item.cleanupCommand)`")
                lines.append("- **Impact:** \(item.explanation)")
                lines.append("")
            }
        }

        if !manualItems.isEmpty {
            lines.append("## Manual Review")
            lines.append("")
            lines.append("The following items require manual review before deletion:")
            lines.append("")
            for item in manualItems {
                lines.append("- **\(item.displayName)** — `\(item.path)`")
            }
            lines.append("")
        }

        if !protectedItems.isEmpty {
            lines.append("## Excluded (Protected)")
            lines.append("")
            for item in protectedItems {
                lines.append("- \(item.displayName)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func planRow(_ label: String, value: String) -> some View {
        planRow(label) {
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func planRow<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            content()
                .font(.callout)
                .monospacedDigit()
        }
    }
}
