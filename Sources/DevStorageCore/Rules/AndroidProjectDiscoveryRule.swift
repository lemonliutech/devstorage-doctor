import Foundation

/// Walks the home directory for Android projects (build.gradle / build.gradle.kts),
/// then aggregates artifact sizes by type across all discovered projects.
public struct AndroidProjectDiscoveryRule: ScanRule {
    public let id = "android-project-discovery"
    public let displayName = "Android projects (scanning home directory…)"
    public let toolchain = "Android / Gradle"

    private let homeDirectory: URL

    private static let skipDirs: Set<String> = [
        "build", ".gradle", ".git", "node_modules",
        "Library", "Applications", "System", ".Trash",
        ".lima", ".docker", ".colima",
        ".pub-cache", "DerivedData", "Pods",
    ]

    private static let maxDepth = 8

    // Markers that identify an Android project root
    private static let projectMarkers = ["build.gradle", "build.gradle.kts"]

    private static let artifactTypes: [(id: String, name: String, rel: String, category: StorageCategory, risk: RiskLevel)] = [
        ("android-app-build",   "Android app/build/",   "app/build",   .buildArtifact,   .medium),
        ("android-root-build",  "Android build/",       "build",       .buildArtifact,   .medium),
        ("android-gradle-dir",  "Android .gradle/",     ".gradle",     .buildArtifact,   .medium),
        ("android-captures",    "Android captures/",    "captures",    .packageOutput,   .manualReview),
    ]

    public init(homeDirectory: URL) {
        self.homeDirectory = homeDirectory
    }

    public func scan(measurer: FileSizeMeasurer) -> [StorageItem] {
        var projectRoots: [URL] = []
        discoverAndroidProjects(in: homeDirectory, depth: 0, fm: FileManager.default, result: &projectRoots)
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

            subPaths.sort { ($0.sizeBytes ?? 0) > ($1.sizeBytes ?? 0) }

            let count = subPaths.count
            results.append(StorageItem(
                id: "android-discovery:\(type.id)",
                displayName: type.name,
                path: subPaths[0].path,
                category: type.category,
                toolchain: toolchain,
                sizeBytes: totalBytes,
                riskLevel: type.risk,
                status: .found,
                defaultSelected: false,
                explanation: count == 1 ? "1 project" : "\(count) projects",
                exception: nil,
                subPaths: subPaths
            ))
        }

        return results
    }

    private func discoverAndroidProjects(
        in directory: URL,
        depth: Int,
        fm: FileManager,
        result: inout [URL]
    ) {
        guard depth < Self.maxDepth else { return }

        let hasMarker = Self.projectMarkers.contains {
            fm.fileExists(atPath: directory.appendingPathComponent($0).path)
        }
        if hasMarker {
            result.append(directory)
            return
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
            discoverAndroidProjects(in: entry, depth: depth + 1, fm: fm, result: &result)
        }
    }
}
