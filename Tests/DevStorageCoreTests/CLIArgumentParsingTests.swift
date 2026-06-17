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
