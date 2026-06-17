public enum StorageCategory: String, Codable, Sendable, Equatable {
    case cache
    case dependencyStore
    case sdkRuntime
    case buildArtifact
    case packageOutput
    case manualReview
}
