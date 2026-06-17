import Foundation

public enum DefaultRuleFactory {
    public static func defaultRules(homeDirectory: URL, projectRoots: [URL]) -> [any ScanRule] {
        var rules: [any ScanRule] = [
            KnownDirectoryRule(
                id: "xcode-derived-data",
                displayName: "Xcode DerivedData",
                toolchain: "Xcode / iOS",
                category: .cache,
                riskLevel: .low,
                defaultSelectedWhenFound: true,
                explanation: "Can be rebuilt automatically. The next Xcode build may be slower.",
                paths: [homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData")]
            ),
            KnownDirectoryRule(
                id: "xcode-new-derived-data",
                displayName: "Xcode NewDerivedData",
                toolchain: "Xcode / iOS",
                category: .cache,
                riskLevel: .low,
                defaultSelectedWhenFound: true,
                explanation: "Can be rebuilt automatically. The next Xcode build may be slower.",
                paths: [homeDirectory.appendingPathComponent("Library/Developer/Xcode/NewDerivedData")]
            ),
            KnownDirectoryRule(
                id: "xcode-archives",
                displayName: "Xcode Archives",
                toolchain: "Xcode / iOS",
                category: .packageOutput,
                riskLevel: .manualReview,
                defaultSelectedWhenFound: false,
                explanation: "Archived builds may be needed for App Store submission or crash symbolication. Review before deleting.",
                paths: [homeDirectory.appendingPathComponent("Library/Developer/Xcode/Archives")]
            ),
            KnownDirectoryRule(
                id: "ios-simulator-runtimes",
                displayName: "iOS Simulator runtimes",
                toolchain: "Xcode / iOS",
                category: .sdkRuntime,
                riskLevel: .high,
                defaultSelectedWhenFound: false,
                explanation: "Simulator runtimes need to be downloaded again from Xcode.",
                paths: [homeDirectory.appendingPathComponent("Library/Developer/CoreSimulator/Cryptex")]
            ),
            KnownDirectoryRule(
                id: "gradle-caches",
                displayName: "Gradle caches",
                toolchain: "Android / Gradle",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Dependencies may need to be downloaded again.",
                paths: [homeDirectory.appendingPathComponent(".gradle/caches")]
            ),
            KnownDirectoryRule(
                id: "dart-pub-hosted",
                displayName: "Dart pub hosted cache",
                toolchain: "Flutter / Dart / FVM",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Dart and Flutter dependencies may need to be downloaded again.",
                paths: [homeDirectory.appendingPathComponent(".pub-cache/hosted")]
            ),
            KnownDirectoryRule(
                id: "dart-pub-git",
                displayName: "Dart pub git cache",
                toolchain: "Flutter / Dart / FVM",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Git dependencies may need to be fetched again.",
                paths: [homeDirectory.appendingPathComponent(".pub-cache/git")]
            ),
            KnownDirectoryRule(
                id: "fvm-versions",
                displayName: "FVM SDK versions",
                toolchain: "Flutter / Dart / FVM",
                category: .sdkRuntime,
                riskLevel: .high,
                defaultSelectedWhenFound: false,
                explanation: "Flutter SDK versions may be required by active projects.",
                paths: [homeDirectory.appendingPathComponent("fvm/versions")]
            ),
            KnownDirectoryRule(
                id: "pnpm-store",
                displayName: "pnpm store",
                toolchain: "Node / pnpm / npm",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Prefer pnpm store prune before deleting the store.",
                paths: [homeDirectory.appendingPathComponent("Library/pnpm/store")]
            ),
            KnownDirectoryRule(
                id: "npm-cache",
                displayName: "npm cache",
                toolchain: "Node / pnpm / npm",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Packages may need to be downloaded again.",
                paths: [homeDirectory.appendingPathComponent(".npm")]
            ),
            KnownDirectoryRule(
                id: "cocoapods-cache",
                displayName: "CocoaPods cache",
                toolchain: "CocoaPods",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Pods may need to be downloaded or reindexed again.",
                paths: [homeDirectory.appendingPathComponent("Library/Caches/CocoaPods")]
            ),
            KnownDirectoryRule(
                id: "ohpm-cache",
                displayName: "ohpm cache",
                toolchain: "HarmonyOS / DevEco",
                category: .dependencyStore,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "HarmonyOS packages may need to be downloaded again.",
                paths: [homeDirectory.appendingPathComponent(".ohpm")]
            ),
            KnownDirectoryRule(
                id: "hvigor-cache",
                displayName: "hvigor cache",
                toolchain: "HarmonyOS / DevEco",
                category: .cache,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "HarmonyOS build cache may need to be regenerated.",
                paths: [homeDirectory.appendingPathComponent(".hvigor")]
            )
        ]

        // Auto-discover Android projects across home directory
        rules.append(AndroidProjectDiscoveryRule(homeDirectory: homeDirectory))

        // Auto-discover Flutter projects across home directory
        rules.append(FlutterProjectDiscoveryRule(homeDirectory: homeDirectory))

        // Also scan any explicitly configured project roots
        rules.append(contentsOf: projectRoots.map { FlutterProjectRule(projectRoot: $0) })

        return rules
    }
}
