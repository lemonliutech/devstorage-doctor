import SwiftUI
import DevStorageCore

struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                projectRootsSection
                excludedPathsSection
            }
            .padding(Spacing.large)
        }
        .navigationTitle("Settings")
    }

    // MARK: - Project roots

    private var projectRootsSection: some View {
        @Bindable var state = state
        return GroupBox("Additional Project Roots") {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Folders added here are scanned as explicit Flutter / Android project roots, in addition to auto-discovery.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                if state.projectRoots.isEmpty {
                    Text("No additional roots configured.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.small)
                } else {
                    ForEach(state.projectRoots, id: \.path) { url in
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                            Text(url.path)
                                .font(.system(.callout, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Button {
                                state.projectRoots.removeAll { $0 == url }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .help("Remove")
                        }
                    }
                }

                Divider()

                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = true
                    panel.prompt = "Add Root"
                    if panel.runModal() == .OK {
                        for url in panel.urls {
                            if !state.projectRoots.contains(url) {
                                state.projectRoots.append(url)
                            }
                        }
                    }
                } label: {
                    Label("Add Folder…", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Excluded paths

    private var excludedPathsSection: some View {
        @Bindable var state = state
        return GroupBox("Excluded Paths") {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Paths listed here are hidden from scan results.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                if state.excludedPaths.isEmpty {
                    Text("No exclusions configured.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.small)
                } else {
                    ForEach(state.excludedPaths, id: \.self) { path in
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundStyle(.secondary)
                            Text(path)
                                .font(.system(.callout, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Button {
                                state.excludedPaths.removeAll { $0 == path }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .help("Remove")
                        }
                    }
                }

                Divider()

                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = true
                    panel.prompt = "Exclude"
                    if panel.runModal() == .OK {
                        for url in panel.urls {
                            if !state.excludedPaths.contains(url.path) {
                                state.excludedPaths.append(url.path)
                            }
                        }
                    }
                } label: {
                    Label("Exclude Folder…", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
