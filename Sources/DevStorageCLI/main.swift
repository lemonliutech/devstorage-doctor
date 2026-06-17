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
