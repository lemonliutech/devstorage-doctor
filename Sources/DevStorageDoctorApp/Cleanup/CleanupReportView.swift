import SwiftUI
import DevStorageCore

struct CleanupReportView: View {
    @Environment(AppState.self) private var state
    let report: CleanupReport

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    summarySection
                    if !report.succeeded.isEmpty  { resultSection("Cleaned", items: report.succeeded, color: .green,  icon: "checkmark.circle.fill") }
                    if !report.failed.isEmpty     { resultSection("Failed",  items: report.failed,    color: .red,    icon: "xmark.circle.fill") }
                    if !report.skipped.isEmpty    { resultSection("Skipped", items: report.skipped,   color: .secondary, icon: "minus.circle") }
                }
                .padding(Spacing.large)
            }

            Divider()

            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(markdownReport, forType: .string)
                } label: {
                    Label("Copy Report", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Scan Again") {
                    state.cleanupPhase = .idle
                    state.cleanupReport = nil
                    state.runScan()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
        }
        .navigationTitle("Cleanup Report")
    }

    // MARK: - Summary

    private var summarySection: some View {
        GroupBox("Summary") {
            VStack(spacing: Spacing.tight) {
                reportRow("Recovered") {
                    Text(report.totalBytesRecovered.formatted(.byteCount(style: .file)))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                Divider()
                reportRow("Cleaned",  value: "\(report.succeeded.count) items")
                if !report.failed.isEmpty {
                    Divider()
                    reportRow("Failed") {
                        Text("\(report.failed.count) items")
                            .foregroundStyle(.red)
                    }
                }
                if !report.skipped.isEmpty {
                    Divider()
                    reportRow("Skipped", value: "\(report.skipped.count) items")
                }
            }
        }
    }

    // MARK: - Result sections

    private func resultSection(
        _ title: String,
        items: [CleanupItemResult],
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            ForEach(items, id: \.item.id) { result in
                GroupBox {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.item.displayName)
                                .font(.callout)
                                .fontWeight(.medium)
                            Text(result.item.path)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            resultStatusText(result.status)
                        }
                        Spacer()
                        if case .succeeded(let bytes) = result.status {
                            Text(bytes.formatted(.byteCount(style: .file)))
                                .font(.callout)
                                .monospacedDigit()
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func resultStatusText(_ status: CleanupItemStatus) -> some View {
        switch status {
        case .succeeded:
            EmptyView()
        case .skipped(let reason):
            Text("Skipped: \(reason)")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed(let error):
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Helpers

    private func reportRow(_ label: String, value: String) -> some View {
        reportRow(label) { Text(value).foregroundStyle(.secondary) }
    }

    private func reportRow<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(.secondary)
            Spacer()
            content().font(.callout).monospacedDigit()
        }
    }

    // MARK: - Markdown export

    private var markdownReport: String {
        var lines = [
            "# DevStorage Doctor — Cleanup Report",
            "",
            "**Date:** \(report.finishedAt.formatted(date: .abbreviated, time: .shortened))",
            "**Recovered:** \(report.totalBytesRecovered.formatted(.byteCount(style: .file)))",
            "**Cleaned:** \(report.succeeded.count)  |  **Failed:** \(report.failed.count)  |  **Skipped:** \(report.skipped.count)",
            "",
        ]
        if !report.succeeded.isEmpty {
            lines += ["## Cleaned", ""]
            for r in report.succeeded {
                if case .succeeded(let bytes) = r.status {
                    lines.append("- ✓ **\(r.item.displayName)** — \(bytes.formatted(.byteCount(style: .file))) — `\(r.item.path)`")
                }
            }
            lines.append("")
        }
        if !report.failed.isEmpty {
            lines += ["## Failed", ""]
            for r in report.failed {
                if case .failed(let err) = r.status {
                    lines.append("- ✗ **\(r.item.displayName)** — `\(r.item.path)` — \(err)")
                }
            }
            lines.append("")
        }
        if !report.skipped.isEmpty {
            lines += ["## Skipped", ""]
            for r in report.skipped {
                if case .skipped(let reason) = r.status {
                    lines.append("- — **\(r.item.displayName)** — \(reason)")
                }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
