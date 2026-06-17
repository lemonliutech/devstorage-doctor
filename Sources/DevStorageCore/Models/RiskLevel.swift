public enum RiskLevel: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
    case manualReview
    case protected
    case unsupported
}
