public enum ScanStatus: String, Codable, Sendable, Equatable {
    case found
    case missing
    case failed
    case protected
    case unsupported
}
