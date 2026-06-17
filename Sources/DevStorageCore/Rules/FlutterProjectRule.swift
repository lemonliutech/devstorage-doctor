import Foundation

public struct FlutterProjectRule: ScanRule {
    public let id: String
    public let displayName: String
    public let toolchain: String
    private let projectRoot: URL

    public init(projectRoot: URL) {
        self.id = "flutter-project:\(projectRoot.path)"
        self.displayName = projectRoot.lastPathComponent
        self.toolchain = "Flutter / Dart / FVM"
        self.projectRoot = projectRoot
    }

    public func scan(measurer: FileSizeMeasurer) -> [StorageItem] {
        guard FileManager.default.fileExists(atPath: projectRoot.appendingPathComponent("pubspec.yaml").path) else {
            return []   // Discovery rule already filters non-Flutter dirs; skip silently
        }

        let candidates: [(name: String, url: URL, category: StorageCategory, risk: RiskLevel)] = [
            ("build",              projectRoot.appendingPathComponent("build"),              .buildArtifact,   .medium),
            (".dart_tool",         projectRoot.appendingPathComponent(".dart_tool"),         .buildArtifact,   .medium),
            ("ios/Pods",           projectRoot.appendingPathComponent("ios/Pods"),           .dependencyStore, .medium),
            ("android/.gradle",    projectRoot.appendingPathComponent("android/.gradle"),    .buildArtifact,   .medium),
            ("android/app/build",  projectRoot.appendingPathComponent("android/app/build"), .buildArtifact,   .medium),
            ("ohos/build",         projectRoot.appendingPathComponent("ohos/build"),         .buildArtifact,   .medium),
            ("harmonyos/build",    projectRoot.appendingPathComponent("harmonyos/build"),    .buildArtifact,   .medium),
            ("build/app/outputs",  projectRoot.appendingPathComponent("build/app/outputs"), .packageOutput,   .manualReview),
        ]

        var totalBytes: UInt64 = 0
        var foundNames: [String] = []
        var highestRisk: RiskLevel = .low
        var hasPackageOutput = false

        for candidate in candidates {
            if case .success(let size) = measurer.measure(url: candidate.url) {
                totalBytes += size
                foundNames.append(candidate.name)
                if candidate.risk == .manualReview { hasPackageOutput = true }
                else if highestRisk == .low { highestRisk = candidate.risk }
            }
        }

        guard !foundNames.isEmpty else { return [] }

        let riskLevel: RiskLevel = hasPackageOutput && foundNames.count == 1 ? .manualReview : highestRisk
        let artifactList = foundNames.joined(separator: " · ")

        return [StorageItem(
            id: "flutter-project:\(projectRoot.path)",
            displayName: projectRoot.lastPathComponent,
            path: projectRoot.path,
            category: hasPackageOutput && foundNames.count == 1 ? .packageOutput : .buildArtifact,
            toolchain: toolchain,
            sizeBytes: totalBytes,
            riskLevel: riskLevel,
            status: .found,
            defaultSelected: false,
            explanation: artifactList,
            exception: nil
        )]
    }
}
