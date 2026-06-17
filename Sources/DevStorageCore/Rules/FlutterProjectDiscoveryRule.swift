import Foundation

/// Walks the home directory for Flutter projects (pubspec.yaml), then aggregates
/// artifact sizes by type across all discovered projects — one StorageItem per
/// artifact kind (build/, .dart_tool/, ios/Pods/, …), not one per project.
public struct FlutterProjectDiscoveryRule: ScanRule {
    public let id = "flutter-project-discovery"
    public let displayName = "Flutter projects (scanning home directory…)"
    public let toolchain = "Flutter / Dart / FVM"

    private let homeDirectory: URL

    // Directories to skip while walking
    private static let skipDirs: Set<String> = [
        "build", ".dart_tool", ".pub-cache", ".gradle", "DerivedData", "Pods",
        ".git", "node_modules",
        "Library", "Applications", "System", ".Trash",
        ".lima", ".docker", ".colima",
    ]

    private static let maxDepth = 8

    // Artifact types to measure inside each project, in display order
    private static let artifactTypes: [(id: String, name: String, rel: String, category: StorageCategory, risk: RiskLevel)] = [
        ("flutter-build",          "Flutter build/",           "build",             .buildArtifact,   .medium),
        ("flutter-dart-tool",      "Flutter .dart_tool/",      ".dart_tool",        .buildArtifact,   .medium),
        ("flutter-ios-pods",       "Flutter ios/Pods/",        "ios/Pods",          .dependencyStore, .medium),
        ("flutter-android-gradle", "Flutter android/.gradle/", "android/.gradle",   .buildArtifact,   .medium),
        ("flutter-android-build",  "Flutter android/app/build/","android/app/build",.buildArtifact,   .medium),
        ("flutter-ohos-build",     "Flutter ohos/build/",      "ohos/build",        .buildArtifact,   .medium),
        ("flutter-pkg-outputs",    "Flutter package outputs",  "build/app/outputs", .packageOutput,   .manualReview),
    ]

    public init(homeDirectory: URL) {
        self.homeDirectory = homeDirectory
    }

    public func scan(measurer: FileSizeMeasurer) -> [StorageItem] {
        var projectRoots: [URL] = []
        discoverFlutterProjects(in: homeDirectory, depth: 0, fm: FileManager.default, result: &projectRoots)
        guard !projectRoots.isEmpty else { return [] }

        var results: [StorageItem] = []

        for type in Self.artifactTypes {
            var totalBytes: UInt64 = 0
            var subPaths: [StorageSubPath] = []

            for root in projectRoots {
                let url = root.appendingPathComponent(type.rel)
                if case .success(let size) = measurer.measure(url: url) {
                    totalBytes += size
                    subPaths.append(StorageSubPath(path: url.path, sizeBytes: size))
                }
            }

            guard !subPaths.isEmpty else { continue }

            // Sort largest first for display
            subPaths.sort { ($0.sizeBytes ?? 0) > ($1.sizeBytes ?? 0) }

            let count = subPaths.count
            let suffix = count == 1 ? "1 project" : "\(count) projects"

            results.append(StorageItem(
                id: "flutter-discovery:\(type.id)",
                displayName: type.name,
                path: subPaths[0].path,
                category: type.category,
                toolchain: toolchain,
                sizeBytes: totalBytes,
                riskLevel: type.risk,
                status: .found,
                defaultSelected: false,
                explanation: suffix,
                exception: nil,
                subPaths: subPaths
            ))
        }

        return results
    }

    private func discoverFlutterProjects(
        in directory: URL,
        depth: Int,
        fm: FileManager,
        result: inout [URL]
    ) {
        guard depth < Self.maxDepth else { return }

        if fm.fileExists(atPath: directory.appendingPathComponent("pubspec.yaml").path) {
            result.append(directory)
            return  // don't descend further once a root is found
        }

        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for entry in entries {
            guard !Self.skipDirs.contains(entry.lastPathComponent) else { continue }
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue else { continue }
            discoverFlutterProjects(in: entry, depth: depth + 1, fm: fm, result: &result)
        }
    }
}
