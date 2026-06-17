import SwiftUI
import DevStorageCore

struct ExceptionsView: View {
    @Environment(AppState.self) private var state

    private var exceptions: [StorageItem] {
        state.results.filter { $0.exception != nil }
    }

    var body: some View {
        Group {
            if exceptions.isEmpty {
                ContentUnavailableView(
                    "No Exceptions",
                    systemImage: "checkmark.seal",
                    description: Text("All scanned paths were readable.")
                )
            } else {
                List {
                    Section("\(exceptions.count) item\(exceptions.count == 1 ? "" : "s") with issues") {
                        ForEach(exceptions) { item in
                            exceptionRow(item)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Exceptions")
    }

    private func exceptionRow(_ item: StorageItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconName(for: item.exception?.type))
                    .foregroundStyle(color(for: item.exception?.type))
                Text(item.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(item.toolchain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let ex = item.exception {
                Text(ex.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: Spacing.tight) {
                    Image(systemName: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(ex.suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            } label: {
                Text(item.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(
                        FileManager.default.fileExists(atPath: item.path)
                            ? Color.accentColor : .secondary
                    )
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .disabled(!FileManager.default.fileExists(atPath: item.path))
        }
        .padding(.vertical, 4)
    }

    private func iconName(for type: ScanException.ExceptionType?) -> String {
        guard let type else { return "exclamationmark.circle" }
        switch type {
        case .permissionDenied, .activeRuntimeProtected, .fileInUse: return "lock.fill"
        case .pathNotFound:        return "questionmark.folder"
        case .unsupportedCacheRule: return "exclamationmark.triangle"
        default:                   return "exclamationmark.circle"
        }
    }

    private func color(for type: ScanException.ExceptionType?) -> Color {
        guard let type else { return .orange }
        switch type {
        case .permissionDenied, .activeRuntimeProtected, .fileInUse: return .red
        case .pathNotFound:        return .secondary
        case .unsupportedCacheRule: return .orange
        default:                   return .orange
        }
    }
}
