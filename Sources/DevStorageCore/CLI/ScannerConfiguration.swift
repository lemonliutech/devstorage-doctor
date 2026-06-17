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
