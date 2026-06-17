import Foundation

public enum CleanupItemStatus: Sendable, Equatable {
    case succeeded(bytesRecovered: UInt64)
    case skipped(reason: String)
    case failed(error: String)
}

public struct CleanupItemResult: Sendable {
    public let item: StorageItem
    public let status: CleanupItemStatus

    public init(item: StorageItem, status: CleanupItemStatus) {
        self.item = item
        self.status = status
    }
}

public struct CleanupReport: Sendable {
    public let results: [CleanupItemResult]
    public let startedAt: Date
    public let finishedAt: Date

    public var succeeded: [CleanupItemResult] {
        results.filter {
            if case .succeeded = $0.status { return true }
            return false
        }
    }

    public var failed: [CleanupItemResult] {
        results.filter {
            if case .failed = $0.status { return true }
            return false
        }
    }

    public var skipped: [CleanupItemResult] {
        results.filter {
            if case .skipped = $0.status { return true }
            return false
        }
    }

    public var totalBytesRecovered: UInt64 {
        results.compactMap {
            if case .succeeded(let bytes) = $0.status { return bytes }
            return nil
        }.reduce(0, +)
    }

    public init(results: [CleanupItemResult], startedAt: Date, finishedAt: Date) {
        self.results = results
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}
