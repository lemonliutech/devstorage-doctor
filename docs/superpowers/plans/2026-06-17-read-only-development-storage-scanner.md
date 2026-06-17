# Read-Only Development Storage Scanner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first read-only SwiftPM scanner prototype for DevStorage Doctor that measures development storage without deleting anything.

**Architecture:** Create a package-first Swift implementation with a reusable `DevStorageCore` library and a small `devstorage-scan` CLI. The scanner returns structured `StorageItem` results with category, risk, status, and exceptions; cleanup execution is intentionally out of scope.

**Tech Stack:** Swift 6-compatible SwiftPM, Foundation, XCTest, macOS file system APIs, JSON output through `JSONEncoder`.

---

## Scope

This plan implements GitHub issue #3, with enough model support for #1 and #4 to make scanner output useful.

In scope:

- SwiftPM project skeleton
- Core storage item model
- Named scan exception model
- Read-only directory size measurement
- Rule-based scanner protocol
- Initial rules for selected Xcode, Gradle, Dart/Pub, FVM, pnpm/npm, CocoaPods, HarmonyOS/DevEco, and Flutter project roots
- CLI JSON output
- Unit tests using temporary directories

Out of scope:

- Deleting files
- Cleanup plan generation
- Native SwiftUI app
- Full active-process detection
- Full Docker/Homebrew/language ecosystem expansion

## File Structure

- `Package.swift`: SwiftPM manifest with library, executable, and tests.
- `Sources/DevStorageCore/Models/StorageCategory.swift`: Storage category enum.
- `Sources/DevStorageCore/Models/RiskLevel.swift`: Risk enum.
- `Sources/DevStorageCore/Models/ScanStatus.swift`: Status enum.
- `Sources/DevStorageCore/Models/ScanException.swift`: Named exception model.
- `Sources/DevStorageCore/Models/StorageItem.swift`: Serializable scanner result.
- `Sources/DevStorageCore/Scanning/FileSizeMeasurer.swift`: Read-only size measurement.
- `Sources/DevStorageCore/Scanning/ScanRule.swift`: Rule protocol and result helpers.
- `Sources/DevStorageCore/Scanning/DevelopmentStorageScanner.swift`: Aggregates rules.
- `Sources/DevStorageCore/Rules/KnownDirectoryRule.swift`: Generic path-based rule.
- `Sources/DevStorageCore/Rules/FlutterProjectRule.swift`: Project-root scanning for Flutter artifacts and package outputs.
- `Sources/DevStorageCLI/main.swift`: CLI entrypoint.
- `Tests/DevStorageCoreTests/ModelEncodingTests.swift`: Encoding/model tests.
- `Tests/DevStorageCoreTests/FileSizeMeasurerTests.swift`: Size and permission behavior tests.
- `Tests/DevStorageCoreTests/KnownDirectoryRuleTests.swift`: Generic rule tests.
- `Tests/DevStorageCoreTests/FlutterProjectRuleTests.swift`: Flutter project artifact tests.
- `Tests/DevStorageCoreTests/DevelopmentStorageScannerTests.swift`: Aggregation tests.

## Data Model Decisions

`StorageItem` is the single scanner result type. Every result should be renderable by future UI, cleanup plan, and reports.

Required result fields:

- `id`
- `displayName`
- `path`
- `category`
- `toolchain`
- `sizeBytes`
- `riskLevel`
- `status`
- `defaultSelected`
- `explanation`
- `exception`

Scanner output must include missing paths as structured results, not thrown top-level failures.

---

### Task 1: Create SwiftPM Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/DevStorageCore/DevStorageCore.swift`
- Create: `Sources/DevStorageCLI/main.swift`
- Create: `Tests/DevStorageCoreTests/PackageSmokeTests.swift`

- [ ] **Step 1: Write the failing smoke test**

Create `Tests/DevStorageCoreTests/PackageSmokeTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class PackageSmokeTests: XCTestCase {
    func testLibraryExposesVersionString() {
        XCTAssertEqual(DevStorageCore.version, "0.2.0-scanner")
    }
}
```

- [ ] **Step 2: Create `Package.swift`**

Create `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DevStorageDoctor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "DevStorageCore", targets: ["DevStorageCore"]),
        .executable(name: "devstorage-scan", targets: ["DevStorageCLI"])
    ],
    targets: [
        .target(name: "DevStorageCore"),
        .executableTarget(
            name: "DevStorageCLI",
            dependencies: ["DevStorageCore"]
        ),
        .testTarget(
            name: "DevStorageCoreTests",
            dependencies: ["DevStorageCore"]
        )
    ]
)
```

- [ ] **Step 3: Create minimal library entrypoint**

Create `Sources/DevStorageCore/DevStorageCore.swift`:

```swift
public enum DevStorageCore {
    public static let version = "0.2.0-scanner"
}
```

- [ ] **Step 4: Create minimal CLI entrypoint**

Create `Sources/DevStorageCLI/main.swift`:

```swift
import DevStorageCore

print("DevStorage Doctor scanner \(DevStorageCore.version)")
```

- [ ] **Step 5: Run tests**

Run:

```bash
swift test
```

Expected:

```text
Test Suite 'All tests' passed
```

- [ ] **Step 6: Run CLI**

Run:

```bash
swift run devstorage-scan
```

Expected:

```text
DevStorage Doctor scanner 0.2.0-scanner
```

- [ ] **Step 7: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "Add SwiftPM scanner package skeleton"
```

---

### Task 2: Add Core Models

**Files:**
- Create: `Sources/DevStorageCore/Models/StorageCategory.swift`
- Create: `Sources/DevStorageCore/Models/RiskLevel.swift`
- Create: `Sources/DevStorageCore/Models/ScanStatus.swift`
- Create: `Sources/DevStorageCore/Models/ScanException.swift`
- Create: `Sources/DevStorageCore/Models/StorageItem.swift`
- Create: `Tests/DevStorageCoreTests/ModelEncodingTests.swift`

- [ ] **Step 1: Write model encoding tests**

Create `Tests/DevStorageCoreTests/ModelEncodingTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class ModelEncodingTests: XCTestCase {
    func testStorageItemEncodesStableJSONFields() throws {
        let item = StorageItem(
            id: "flutter-build:/tmp/App/build",
            displayName: "Flutter build artifacts",
            path: "/tmp/App/build",
            category: .buildArtifact,
            toolchain: "Flutter / Dart / FVM",
            sizeBytes: 128,
            riskLevel: .medium,
            status: .found,
            defaultSelected: false,
            explanation: "Can be regenerated by a full Flutter build.",
            exception: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(item)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(json.contains(#""category":"buildArtifact""#))
        XCTAssertTrue(json.contains(#""riskLevel":"medium""#))
        XCTAssertTrue(json.contains(#""status":"found""#))
        XCTAssertTrue(json.contains(#""sizeBytes":128"#))
    }

    func testStorageItemCanCarryNamedException() throws {
        let exception = ScanException(
            type: .permissionDenied,
            operation: "measure",
            message: "The folder could not be read.",
            suggestion: "Grant Full Disk Access or exclude this path."
        )

        let item = StorageItem(
            id: "xcode-derived-data:/restricted",
            displayName: "Xcode DerivedData",
            path: "/restricted",
            category: .cache,
            toolchain: "Xcode / iOS",
            sizeBytes: nil,
            riskLevel: .low,
            status: .failed,
            defaultSelected: false,
            explanation: "Xcode build cache.",
            exception: exception
        )

        XCTAssertEqual(item.exception?.type, .permissionDenied)
        XCTAssertEqual(item.status, .failed)
    }
}
```

- [ ] **Step 2: Implement `StorageCategory`**

Create `Sources/DevStorageCore/Models/StorageCategory.swift`:

```swift
public enum StorageCategory: String, Codable, Sendable, Equatable {
    case cache
    case dependencyStore
    case sdkRuntime
    case buildArtifact
    case packageOutput
    case manualReview
}
```

- [ ] **Step 3: Implement `RiskLevel`**

Create `Sources/DevStorageCore/Models/RiskLevel.swift`:

```swift
public enum RiskLevel: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
    case manualReview
    case protected
    case unsupported
}
```

- [ ] **Step 4: Implement `ScanStatus`**

Create `Sources/DevStorageCore/Models/ScanStatus.swift`:

```swift
public enum ScanStatus: String, Codable, Sendable, Equatable {
    case found
    case missing
    case failed
    case protected
    case unsupported
}
```

- [ ] **Step 5: Implement `ScanException`**

Create `Sources/DevStorageCore/Models/ScanException.swift`:

```swift
public struct ScanException: Codable, Sendable, Equatable {
    public enum ExceptionType: String, Codable, Sendable {
        case permissionDenied = "PermissionDenied"
        case pathNotFound = "PathNotFound"
        case toolMissing = "ToolMissing"
        case toolCommandFailed = "ToolCommandFailed"
        case fileInUse = "FileInUse"
        case activeRuntimeProtected = "ActiveRuntimeProtected"
        case sizeChangedDuringScan = "SizeChangedDuringScan"
        case partialCleanup = "PartialCleanup"
        case networkRebuildRisk = "NetworkRebuildRisk"
        case unsupportedCacheRule = "UnsupportedCacheRule"
    }

    public let type: ExceptionType
    public let operation: String
    public let message: String
    public let suggestion: String

    public init(type: ExceptionType, operation: String, message: String, suggestion: String) {
        self.type = type
        self.operation = operation
        self.message = message
        self.suggestion = suggestion
    }
}
```

- [ ] **Step 6: Implement `StorageItem`**

Create `Sources/DevStorageCore/Models/StorageItem.swift`:

```swift
public struct StorageItem: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let path: String
    public let category: StorageCategory
    public let toolchain: String
    public let sizeBytes: UInt64?
    public let riskLevel: RiskLevel
    public let status: ScanStatus
    public let defaultSelected: Bool
    public let explanation: String
    public let exception: ScanException?

    public init(
        id: String,
        displayName: String,
        path: String,
        category: StorageCategory,
        toolchain: String,
        sizeBytes: UInt64?,
        riskLevel: RiskLevel,
        status: ScanStatus,
        defaultSelected: Bool,
        explanation: String,
        exception: ScanException?
    ) {
        self.id = id
        self.displayName = displayName
        self.path = path
        self.category = category
        self.toolchain = toolchain
        self.sizeBytes = sizeBytes
        self.riskLevel = riskLevel
        self.status = status
        self.defaultSelected = defaultSelected
        self.explanation = explanation
        self.exception = exception
    }
}
```

- [ ] **Step 7: Run model tests**

Run:

```bash
swift test --filter ModelEncodingTests
```

Expected:

```text
Test Suite 'ModelEncodingTests' passed
```

- [ ] **Step 8: Commit**

```bash
git add Sources/DevStorageCore/Models Tests/DevStorageCoreTests/ModelEncodingTests.swift
git commit -m "Add scanner result models"
```

---

### Task 3: Add Read-Only File Size Measurer

**Files:**
- Create: `Sources/DevStorageCore/Scanning/FileSizeMeasurer.swift`
- Create: `Tests/DevStorageCoreTests/FileSizeMeasurerTests.swift`

- [ ] **Step 1: Write file size tests**

Create `Tests/DevStorageCoreTests/FileSizeMeasurerTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class FileSizeMeasurerTests: XCTestCase {
    func testMeasuresNestedDirectorySize() throws {
        let root = try makeTemporaryDirectory()
        try Data(repeating: 1, count: 5).write(to: root.appendingPathComponent("a.bin"))
        let nested = root.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data(repeating: 2, count: 7).write(to: nested.appendingPathComponent("b.bin"))

        let result = FileSizeMeasurer().measure(url: root)

        XCTAssertEqual(result, .success(12))
    }

    func testMissingPathReturnsPathNotFoundException() throws {
        let root = try makeTemporaryDirectory()
        let missing = root.appendingPathComponent("missing")

        let result = FileSizeMeasurer().measure(url: missing)

        guard case .failure(let exception) = result else {
            return XCTFail("Expected missing path failure")
        }
        XCTAssertEqual(exception.type, .pathNotFound)
        XCTAssertEqual(exception.operation, "measure")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DevStorageCoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
```

- [ ] **Step 2: Implement `FileSizeMeasurer`**

Create `Sources/DevStorageCore/Scanning/FileSizeMeasurer.swift`:

```swift
import Foundation

public struct FileSizeMeasurer {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func measure(url: URL) -> Result<UInt64, ScanException> {
        guard fileManager.fileExists(atPath: url.path) else {
            return .failure(ScanException(
                type: .pathNotFound,
                operation: "measure",
                message: "Path does not exist: \(url.path)",
                suggestion: "No action is required if this toolchain is not installed."
            ))
        }

        do {
            let size = try recursiveSize(url: url)
            return .success(size)
        } catch {
            return .failure(ScanException(
                type: .permissionDenied,
                operation: "measure",
                message: "Could not read path: \(url.path). \(error.localizedDescription)",
                suggestion: "Grant Full Disk Access, close the owning app, or exclude this path."
            ))
        }
    }

    private func recursiveSize(url: URL) throws -> UInt64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? NSNumber
            return size?.uint64Value ?? 0
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in false }
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            if values.isRegularFile == true {
                total += UInt64(values.fileSize ?? 0)
            }
        }
        return total
    }
}
```

- [ ] **Step 3: Run tests**

Run:

```bash
swift test --filter FileSizeMeasurerTests
```

Expected:

```text
Test Suite 'FileSizeMeasurerTests' passed
```

- [ ] **Step 4: Commit**

```bash
git add Sources/DevStorageCore/Scanning/FileSizeMeasurer.swift Tests/DevStorageCoreTests/FileSizeMeasurerTests.swift
git commit -m "Add read-only file size measurer"
```

---

### Task 4: Add Generic Known Directory Rule

**Files:**
- Create: `Sources/DevStorageCore/Scanning/ScanRule.swift`
- Create: `Sources/DevStorageCore/Rules/KnownDirectoryRule.swift`
- Create: `Tests/DevStorageCoreTests/KnownDirectoryRuleTests.swift`

- [ ] **Step 1: Write rule tests**

Create `Tests/DevStorageCoreTests/KnownDirectoryRuleTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class KnownDirectoryRuleTests: XCTestCase {
    func testFoundDirectoryProducesStorageItem() throws {
        let root = try makeTemporaryDirectory()
        try Data(repeating: 3, count: 9).write(to: root.appendingPathComponent("cache.bin"))

        let rule = KnownDirectoryRule(
            id: "xcode-derived-data",
            displayName: "Xcode DerivedData",
            toolchain: "Xcode / iOS",
            category: .cache,
            riskLevel: .low,
            defaultSelectedWhenFound: true,
            explanation: "Can be rebuilt automatically. The next build may be slower.",
            paths: [root]
        )

        let results = rule.scan(measurer: FileSizeMeasurer())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .found)
        XCTAssertEqual(results[0].sizeBytes, 9)
        XCTAssertEqual(results[0].defaultSelected, true)
        XCTAssertEqual(results[0].riskLevel, .low)
    }

    func testMissingDirectoryProducesStructuredMissingItem() throws {
        let root = try makeTemporaryDirectory()
        let missing = root.appendingPathComponent("missing-cache")

        let rule = KnownDirectoryRule(
            id: "pub-cache",
            displayName: "Dart pub cache",
            toolchain: "Flutter / Dart / FVM",
            category: .dependencyStore,
            riskLevel: .medium,
            defaultSelectedWhenFound: false,
            explanation: "Dependencies may need to be downloaded again.",
            paths: [missing]
        )

        let results = rule.scan(measurer: FileSizeMeasurer())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .missing)
        XCTAssertEqual(results[0].exception?.type, .pathNotFound)
        XCTAssertEqual(results[0].defaultSelected, false)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("KnownDirectoryRuleTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
```

- [ ] **Step 2: Implement `ScanRule`**

Create `Sources/DevStorageCore/Scanning/ScanRule.swift`:

```swift
public protocol ScanRule {
    var id: String { get }
    var displayName: String { get }
    var toolchain: String { get }
    func scan(measurer: FileSizeMeasurer) -> [StorageItem]
}
```

- [ ] **Step 3: Implement `KnownDirectoryRule`**

Create `Sources/DevStorageCore/Rules/KnownDirectoryRule.swift`:

```swift
import Foundation

public struct KnownDirectoryRule: ScanRule {
    public let id: String
    public let displayName: String
    public let toolchain: String
    public let category: StorageCategory
    public let riskLevel: RiskLevel
    public let defaultSelectedWhenFound: Bool
    public let explanation: String
    public let paths: [URL]

    public init(
        id: String,
        displayName: String,
        toolchain: String,
        category: StorageCategory,
        riskLevel: RiskLevel,
        defaultSelectedWhenFound: Bool,
        explanation: String,
        paths: [URL]
    ) {
        self.id = id
        self.displayName = displayName
        self.toolchain = toolchain
        self.category = category
        self.riskLevel = riskLevel
        self.defaultSelectedWhenFound = defaultSelectedWhenFound
        self.explanation = explanation
        self.paths = paths
    }

    public func scan(measurer: FileSizeMeasurer) -> [StorageItem] {
        paths.map { path in
            switch measurer.measure(url: path) {
            case .success(let size):
                return StorageItem(
                    id: "\(id):\(path.path)",
                    displayName: displayName,
                    path: path.path,
                    category: category,
                    toolchain: toolchain,
                    sizeBytes: size,
                    riskLevel: riskLevel,
                    status: .found,
                    defaultSelected: defaultSelectedWhenFound,
                    explanation: explanation,
                    exception: nil
                )
            case .failure(let exception):
                return StorageItem(
                    id: "\(id):\(path.path)",
                    displayName: displayName,
                    path: path.path,
                    category: category,
                    toolchain: toolchain,
                    sizeBytes: nil,
                    riskLevel: riskLevel,
                    status: exception.type == .pathNotFound ? .missing : .failed,
                    defaultSelected: false,
                    explanation: explanation,
                    exception: exception
                )
            }
        }
    }
}
```

- [ ] **Step 4: Run rule tests**

Run:

```bash
swift test --filter KnownDirectoryRuleTests
```

Expected:

```text
Test Suite 'KnownDirectoryRuleTests' passed
```

- [ ] **Step 5: Commit**

```bash
git add Sources/DevStorageCore/Scanning/ScanRule.swift Sources/DevStorageCore/Rules/KnownDirectoryRule.swift Tests/DevStorageCoreTests/KnownDirectoryRuleTests.swift
git commit -m "Add generic known directory scan rule"
```

---

### Task 5: Add Scanner Aggregator

**Files:**
- Create: `Sources/DevStorageCore/Scanning/DevelopmentStorageScanner.swift`
- Create: `Tests/DevStorageCoreTests/DevelopmentStorageScannerTests.swift`

- [ ] **Step 1: Write scanner aggregation tests**

Create `Tests/DevStorageCoreTests/DevelopmentStorageScannerTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class DevelopmentStorageScannerTests: XCTestCase {
    func testScannerAggregatesRules() throws {
        let first = try makeTemporaryDirectory(named: "first")
        let second = try makeTemporaryDirectory(named: "second")
        try Data(repeating: 1, count: 4).write(to: first.appendingPathComponent("a.bin"))
        try Data(repeating: 2, count: 6).write(to: second.appendingPathComponent("b.bin"))

        let rules: [any ScanRule] = [
            KnownDirectoryRule(
                id: "first-rule",
                displayName: "First",
                toolchain: "Test",
                category: .cache,
                riskLevel: .low,
                defaultSelectedWhenFound: true,
                explanation: "First test rule.",
                paths: [first]
            ),
            KnownDirectoryRule(
                id: "second-rule",
                displayName: "Second",
                toolchain: "Test",
                category: .buildArtifact,
                riskLevel: .medium,
                defaultSelectedWhenFound: false,
                explanation: "Second test rule.",
                paths: [second]
            )
        ]

        let results = DevelopmentStorageScanner(rules: rules).scan()

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.map(\.sizeBytes).compactMap { $0 }.reduce(0, +), 10)
    }

    private func makeTemporaryDirectory(named name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DevelopmentStorageScannerTests")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
```

- [ ] **Step 2: Implement scanner aggregator**

Create `Sources/DevStorageCore/Scanning/DevelopmentStorageScanner.swift`:

```swift
public struct DevelopmentStorageScanner {
    private let rules: [any ScanRule]
    private let measurer: FileSizeMeasurer

    public init(rules: [any ScanRule], measurer: FileSizeMeasurer = FileSizeMeasurer()) {
        self.rules = rules
        self.measurer = measurer
    }

    public func scan() -> [StorageItem] {
        rules.flatMap { rule in
            rule.scan(measurer: measurer)
        }
    }
}
```

- [ ] **Step 3: Run scanner tests**

Run:

```bash
swift test --filter DevelopmentStorageScannerTests
```

Expected:

```text
Test Suite 'DevelopmentStorageScannerTests' passed
```

- [ ] **Step 4: Commit**

```bash
git add Sources/DevStorageCore/Scanning/DevelopmentStorageScanner.swift Tests/DevStorageCoreTests/DevelopmentStorageScannerTests.swift
git commit -m "Add development storage scanner aggregator"
```

---

### Task 6: Add Default Mobile Cross-Platform Rules

**Files:**
- Create: `Sources/DevStorageCore/Rules/DefaultRuleFactory.swift`
- Create: `Tests/DevStorageCoreTests/DefaultRuleFactoryTests.swift`

- [ ] **Step 1: Write default rule factory test**

Create `Tests/DevStorageCoreTests/DefaultRuleFactoryTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class DefaultRuleFactoryTests: XCTestCase {
    func testDefaultRulesIncludeMobileCrossPlatformToolchains() {
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        let rules = DefaultRuleFactory.defaultRules(homeDirectory: home, projectRoots: [])
        let ids = Set(rules.map(\.id))

        XCTAssertTrue(ids.contains("xcode-derived-data"))
        XCTAssertTrue(ids.contains("xcode-new-derived-data"))
        XCTAssertTrue(ids.contains("gradle-caches"))
        XCTAssertTrue(ids.contains("dart-pub-hosted"))
        XCTAssertTrue(ids.contains("dart-pub-git"))
        XCTAssertTrue(ids.contains("fvm-versions"))
        XCTAssertTrue(ids.contains("pnpm-store"))
        XCTAssertTrue(ids.contains("npm-cache"))
        XCTAssertTrue(ids.contains("cocoapods-cache"))
        XCTAssertTrue(ids.contains("ohpm-cache"))
        XCTAssertTrue(ids.contains("hvigor-cache"))
    }
}
```

- [ ] **Step 2: Implement `DefaultRuleFactory`**

Create `Sources/DevStorageCore/Rules/DefaultRuleFactory.swift`:

```swift
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

        rules.append(contentsOf: projectRoots.map { FlutterProjectRule(projectRoot: $0) })
        return rules
    }
}
```

- [ ] **Step 3: Run factory tests**

Run:

```bash
swift test --filter DefaultRuleFactoryTests
```

Expected:

```text
Test Suite 'DefaultRuleFactoryTests' passed
```

- [ ] **Step 4: Commit**

```bash
git add Sources/DevStorageCore/Rules/DefaultRuleFactory.swift Tests/DevStorageCoreTests/DefaultRuleFactoryTests.swift
git commit -m "Add default mobile development storage rules"
```

---

### Task 7: Add Flutter Project Rule

**Files:**
- Create: `Sources/DevStorageCore/Rules/FlutterProjectRule.swift`
- Create: `Tests/DevStorageCoreTests/FlutterProjectRuleTests.swift`

- [ ] **Step 1: Write Flutter project rule tests**

Create `Tests/DevStorageCoreTests/FlutterProjectRuleTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class FlutterProjectRuleTests: XCTestCase {
    func testFlutterProjectRuleFindsBuildArtifactsAndPackageOutputs() throws {
        let project = try makeFlutterProject()
        try writeFile(project.appendingPathComponent("build/app/outputs/flutter-apk/app-debug.apk"), bytes: 11)
        try writeFile(project.appendingPathComponent(".dart_tool/package_config.json"), bytes: 5)
        try writeFile(project.appendingPathComponent("ios/Pods/Manifest.lock"), bytes: 7)

        let results = FlutterProjectRule(projectRoot: project).scan(measurer: FileSizeMeasurer())
        let byDisplayName = Dictionary(uniqueKeysWithValues: results.map { ($0.displayName, $0) })

        XCTAssertEqual(byDisplayName["Flutter build directory"]?.category, .buildArtifact)
        XCTAssertEqual(byDisplayName["Flutter Dart tool directory"]?.category, .buildArtifact)
        XCTAssertEqual(byDisplayName["Flutter iOS Pods"]?.category, .dependencyStore)
        XCTAssertEqual(byDisplayName["Flutter package outputs"]?.category, .packageOutput)
        XCTAssertEqual(byDisplayName["Flutter package outputs"]?.riskLevel, .manualReview)
    }

    func testNonFlutterProjectProducesUnsupportedResult() throws {
        let project = try makeTemporaryDirectory()

        let results = FlutterProjectRule(projectRoot: project).scan(measurer: FileSizeMeasurer())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .unsupported)
        XCTAssertEqual(results[0].exception?.type, .unsupportedCacheRule)
    }

    private func makeFlutterProject() throws -> URL {
        let project = try makeTemporaryDirectory()
        try "name: sample\n".write(
            to: project.appendingPathComponent("pubspec.yaml"),
            atomically: true,
            encoding: .utf8
        )
        return project
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlutterProjectRuleTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeFile(_ url: URL, bytes: Int) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(repeating: 4, count: bytes).write(to: url)
    }
}
```

- [ ] **Step 2: Implement `FlutterProjectRule`**

Create `Sources/DevStorageCore/Rules/FlutterProjectRule.swift`:

```swift
import Foundation

public struct FlutterProjectRule: ScanRule {
    public let id: String
    public let displayName: String
    public let toolchain: String
    private let projectRoot: URL
    private let fileManager: FileManager

    public init(projectRoot: URL, fileManager: FileManager = .default) {
        self.id = "flutter-project"
        self.displayName = "Flutter project storage"
        self.toolchain = "Flutter / Dart / FVM"
        self.projectRoot = projectRoot
        self.fileManager = fileManager
    }

    public func scan(measurer: FileSizeMeasurer) -> [StorageItem] {
        guard fileManager.fileExists(atPath: projectRoot.appendingPathComponent("pubspec.yaml").path) else {
            return [StorageItem(
                id: "flutter-project-unsupported:\(projectRoot.path)",
                displayName: "Flutter project",
                path: projectRoot.path,
                category: .manualReview,
                toolchain: toolchain,
                sizeBytes: nil,
                riskLevel: .unsupported,
                status: .unsupported,
                defaultSelected: false,
                explanation: "No pubspec.yaml was found at this project root.",
                exception: ScanException(
                    type: .unsupportedCacheRule,
                    operation: "scan",
                    message: "The selected folder is not recognized as a Flutter project: \(projectRoot.path)",
                    suggestion: "Select a folder containing pubspec.yaml."
                )
            )]
        }

        let candidates: [(String, URL, StorageCategory, RiskLevel, String)] = [
            (
                "Flutter build directory",
                projectRoot.appendingPathComponent("build"),
                .buildArtifact,
                .medium,
                "Generated build artifacts. Cleanup triggers a full rebuild."
            ),
            (
                "Flutter Dart tool directory",
                projectRoot.appendingPathComponent(".dart_tool"),
                .buildArtifact,
                .medium,
                "Generated Dart tooling state. Cleanup triggers package and build regeneration."
            ),
            (
                "Flutter iOS Pods",
                projectRoot.appendingPathComponent("ios/Pods"),
                .dependencyStore,
                .medium,
                "Native iOS dependencies may need to be installed again."
            ),
            (
                "Flutter Android Gradle",
                projectRoot.appendingPathComponent("android/.gradle"),
                .buildArtifact,
                .medium,
                "Android Gradle state can be regenerated by Gradle."
            ),
            (
                "Flutter Android app build",
                projectRoot.appendingPathComponent("android/app/build"),
                .buildArtifact,
                .medium,
                "Android app build products can be regenerated."
            ),
            (
                "Flutter OHOS build",
                projectRoot.appendingPathComponent("ohos/build"),
                .buildArtifact,
                .medium,
                "HarmonyOS build products can be regenerated."
            ),
            (
                "Flutter HarmonyOS build",
                projectRoot.appendingPathComponent("harmonyos/build"),
                .buildArtifact,
                .medium,
                "HarmonyOS build products can be regenerated."
            ),
            (
                "Flutter package outputs",
                projectRoot.appendingPathComponent("build/app/outputs"),
                .packageOutput,
                .manualReview,
                "Generated package outputs may be needed for QA, upload, or release history."
            )
        ]

        return candidates.map { name, path, category, risk, explanation in
            switch measurer.measure(url: path) {
            case .success(let size):
                return StorageItem(
                    id: "flutter-project:\(path.path)",
                    displayName: name,
                    path: path.path,
                    category: category,
                    toolchain: toolchain,
                    sizeBytes: size,
                    riskLevel: risk,
                    status: .found,
                    defaultSelected: false,
                    explanation: explanation,
                    exception: nil
                )
            case .failure(let exception):
                return StorageItem(
                    id: "flutter-project:\(path.path)",
                    displayName: name,
                    path: path.path,
                    category: category,
                    toolchain: toolchain,
                    sizeBytes: nil,
                    riskLevel: risk,
                    status: exception.type == .pathNotFound ? .missing : .failed,
                    defaultSelected: false,
                    explanation: explanation,
                    exception: exception
                )
            }
        }
    }
}
```

- [ ] **Step 3: Run Flutter rule tests**

Run:

```bash
swift test --filter FlutterProjectRuleTests
```

Expected:

```text
Test Suite 'FlutterProjectRuleTests' passed
```

- [ ] **Step 4: Run all tests**

Run:

```bash
swift test
```

Expected:

```text
Test Suite 'All tests' passed
```

- [ ] **Step 5: Commit**

```bash
git add Sources/DevStorageCore/Rules/FlutterProjectRule.swift Tests/DevStorageCoreTests/FlutterProjectRuleTests.swift
git commit -m "Add Flutter project storage scan rule"
```

---

### Task 8: Add CLI JSON Output

**Files:**
- Modify: `Sources/DevStorageCLI/main.swift`
- Create: `Tests/DevStorageCoreTests/CLIArgumentParsingTests.swift`
- Create: `Sources/DevStorageCore/CLI/ScannerConfiguration.swift`

- [ ] **Step 1: Write configuration parsing tests**

Create `Tests/DevStorageCoreTests/CLIArgumentParsingTests.swift`:

```swift
import XCTest
@testable import DevStorageCore

final class CLIArgumentParsingTests: XCTestCase {
    func testParsesProjectRootArguments() {
        let config = ScannerConfiguration(arguments: [
            "devstorage-scan",
            "--home", "/Users/tester",
            "--project-root", "/repo/app",
            "--project-root", "/repo/another"
        ])

        XCTAssertEqual(config.homeDirectory.path, "/Users/tester")
        XCTAssertEqual(config.projectRoots.map(\.path), ["/repo/app", "/repo/another"])
    }

    func testDefaultsHomeDirectoryWhenNotProvided() {
        let config = ScannerConfiguration(arguments: ["devstorage-scan"])

        XCTAssertFalse(config.homeDirectory.path.isEmpty)
        XCTAssertTrue(config.projectRoots.isEmpty)
    }
}
```

- [ ] **Step 2: Implement `ScannerConfiguration`**

Create `Sources/DevStorageCore/CLI/ScannerConfiguration.swift`:

```swift
import Foundation

public struct ScannerConfiguration {
    public let homeDirectory: URL
    public let projectRoots: [URL]

    public init(arguments: [String], defaultHomeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        var home = defaultHomeDirectory
        var roots: [URL] = []
        var index = 1

        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--home", index + 1 < arguments.count {
                home = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
                index += 2
            } else if argument == "--project-root", index + 1 < arguments.count {
                roots.append(URL(fileURLWithPath: arguments[index + 1], isDirectory: true))
                index += 2
            } else {
                index += 1
            }
        }

        self.homeDirectory = home
        self.projectRoots = roots
    }
}
```

- [ ] **Step 3: Update CLI entrypoint**

Replace `Sources/DevStorageCLI/main.swift`:

```swift
import DevStorageCore
import Foundation

let configuration = ScannerConfiguration(arguments: CommandLine.arguments)
let rules = DefaultRuleFactory.defaultRules(
    homeDirectory: configuration.homeDirectory,
    projectRoots: configuration.projectRoots
)
let scanner = DevelopmentStorageScanner(rules: rules)
let results = scanner.scan()

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(results)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    FileHandle.standardError.write(Data("Failed to encode scan results: \(error.localizedDescription)\n".utf8))
    Foundation.exit(1)
}
```

- [ ] **Step 4: Run configuration tests**

Run:

```bash
swift test --filter CLIArgumentParsingTests
```

Expected:

```text
Test Suite 'CLIArgumentParsingTests' passed
```

- [ ] **Step 5: Run CLI against a temporary home**

Run:

```bash
TEMP_HOME="$(mktemp -d)"
mkdir -p "$TEMP_HOME/.gradle/caches"
printf "abc" > "$TEMP_HOME/.gradle/caches/sample.bin"
swift run devstorage-scan --home "$TEMP_HOME"
```

Expected:

```text
"displayName" : "Gradle caches"
"sizeBytes" : 3
"toolchain" : "Android / Gradle"
```

- [ ] **Step 6: Commit**

```bash
git add Sources/DevStorageCore/CLI/ScannerConfiguration.swift Sources/DevStorageCLI/main.swift Tests/DevStorageCoreTests/CLIArgumentParsingTests.swift
git commit -m "Add scanner CLI JSON output"
```

---

### Task 9: Update Documentation And Roadmap

**Files:**
- Modify: `README.md`
- Modify: `ROADMAP.md`
- Modify: `docs/issues/01-build-read-only-scanner.md`

- [ ] **Step 1: Update README status and usage**

Add this section to `README.md` below `## Core Flow`:

````markdown
## Scanner Prototype

The v0.2 prototype exposes a read-only scanner CLI:

```bash
swift run devstorage-scan --project-root /path/to/flutter/project
```

The scanner prints JSON results. It does not delete files.
````

- [ ] **Step 2: Update ROADMAP v0.2 checked items**

Change the completed v0.2 items in `ROADMAP.md`:

```markdown
## v0.2 Prototype

- [x] Choose macOS implementation stack
- [x] Build read-only scanner prototype
- [x] Detect Xcode and iOS Simulator cache sizes
- [x] Detect Android and Gradle cache sizes
- [x] Detect Flutter, Dart, and FVM cache sizes
- [x] Detect Flutter project build artifacts inside selected project roots
- [x] Detect temporary mobile package outputs inside selected project roots
- [x] Detect Node, pnpm, npm, and CocoaPods cache sizes
- [x] Detect HarmonyOS / DevEco cache candidates
- [x] Produce grouped scan report
```

- [ ] **Step 3: Update local issue draft**

Replace `docs/issues/01-build-read-only-scanner.md` with:

```markdown
# Build read-only development storage scanner

## Goal

Implement the first read-only scanner that measures development storage without deleting anything.

## Scope

- Xcode / iOS Simulator storage
- Android / Gradle storage
- Flutter / Dart / FVM storage
- Flutter project artifacts inside selected roots
- mobile package outputs inside configured roots
- CocoaPods storage
- Node / pnpm / npm storage
- HarmonyOS / DevEco candidates
- manual-review large directories

## Acceptance Criteria

- Scanner returns id, path, size, category, toolchain group, detection source, and status.
- Missing paths are reported as `PathNotFound`.
- Permission failures are reported as `PermissionDenied`.
- No cleanup action is executed.
```

- [ ] **Step 4: Run full verification**

Run:

```bash
swift test
swift run devstorage-scan --home "$(mktemp -d)"
git status --short
```

Expected:

```text
Test Suite 'All tests' passed
```

`git status --short` should show only the documentation files changed before commit.

- [ ] **Step 5: Commit and push**

```bash
git add README.md ROADMAP.md docs/issues/01-build-read-only-scanner.md
git commit -m "Document read-only scanner prototype"
git push
```

---

## Verification Checklist

Before marking issue #3 complete:

- [ ] `swift test` passes.
- [ ] `swift run devstorage-scan` prints valid JSON.
- [ ] Running with a fake `--home` detects known test directories.
- [ ] Running with `--project-root` detects Flutter build artifacts and package outputs.
- [ ] No code path deletes, moves, or modifies scanned files.
- [ ] Missing paths are represented as structured results.
- [ ] Permission failures are represented as named exceptions.
- [ ] README documents that the scanner is read-only.

## Implementation Order

Execute tasks in order. Do not start cleanup plan or SwiftUI work until the scanner CLI produces stable structured results and tests pass.
