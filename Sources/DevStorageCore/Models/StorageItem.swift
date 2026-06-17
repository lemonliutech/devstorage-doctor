public struct StorageSubPath: Codable, Sendable, Equatable {
    public let path: String
    public let sizeBytes: UInt64?

    public init(path: String, sizeBytes: UInt64?) {
        self.path = path
        self.sizeBytes = sizeBytes
    }
}

public struct StorageItem: Codable, Sendable, Equatable, Identifiable {
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
    public let subPaths: [StorageSubPath]

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
        exception: ScanException?,
        subPaths: [StorageSubPath] = []
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
        self.subPaths = subPaths
    }
}
