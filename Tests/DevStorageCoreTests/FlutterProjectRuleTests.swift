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
