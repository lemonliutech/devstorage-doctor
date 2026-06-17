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
