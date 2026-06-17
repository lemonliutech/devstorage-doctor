import Foundation
import DevStorageCore
import AppKit

// MARK: - Sidebar Navigation

enum SidebarItem: String, CaseIterable, Identifiable {
    case overview    = "Overview"
    case xcodeIOS    = "Xcode / iOS"
    case android     = "Android / Gradle"
    case flutter     = "Flutter / Dart / FVM"
    case cocoapods   = "CocoaPods"
    case node        = "Node / pnpm / npm"
    case harmonyos   = "HarmonyOS / DevEco"
    case manual      = "Manual Review"
    case exceptions  = "Exceptions"
    case reports     = "Reports"
    case settings    = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .overview:   return "gauge.with.dots.needle.bottom.50percent"
        case .xcodeIOS:   return "hammer"
        case .android:    return "square.grid.2x2"
        case .flutter:    return "wind"
        case .cocoapods:  return "shippingbox"
        case .node:       return "network"
        case .harmonyos:  return "cpu"
        case .manual:      return "questionmark.folder"
        case .exceptions:  return "exclamationmark.triangle"
        case .reports:     return "doc.text"
        case .settings:    return "gearshape"
        }
    }

    var toolchainKey: String? {
        switch self {
        case .xcodeIOS:  return "Xcode / iOS"
        case .android:   return "Android / Gradle"
        case .flutter:   return "Flutter / Dart / FVM"
        case .cocoapods: return "CocoaPods"
        case .node:      return "Node / pnpm / npm"
        case .harmonyos: return "HarmonyOS / DevEco"
        default:         return nil
        }
    }
}

// MARK: - Scan State

enum ScanPhase: Equatable {
    case idle
    case scanning
    case done
    case failed(String)
}

enum CleanupPhase: Equatable {
    case idle
    case executing
    case done
}

enum SubPathSelectionState {
    case none, partial, all
}

// MARK: - App State

@MainActor
@Observable
final class AppState {
    var scanPhase: ScanPhase = .idle
    var results: [StorageItem] = []
    var selectedItemIDs: Set<String> = []
    /// For aggregated items: tracks which sub-paths are individually selected.
    /// Key = StorageItem.id, Value = set of selected sub-path paths.
    var selectedSubPaths: [String: Set<String>] = [:]
    var lastScanDate: Date?
    var showingCleanupPlan = false

    // Persisted settings
    var projectRoots: [URL] = AppState.loadURLs(key: "projectRoots") {
        didSet { AppState.saveURLs(projectRoots, key: "projectRoots") }
    }
    var excludedPaths: [String] = (UserDefaults.standard.stringArray(forKey: "excludedPaths") ?? []) {
        didSet { UserDefaults.standard.set(excludedPaths, forKey: "excludedPaths") }
    }

    // Cleanup execution
    var cleanupPhase: CleanupPhase = .idle
    var cleanupProgressCurrent: Int = 0
    var cleanupProgressTotal: Int = 0
    var cleanupCurrentItemName: String = ""
    var cleanupReport: CleanupReport?

    var cleanupProgress: Double {
        cleanupProgressTotal > 0
            ? Double(cleanupProgressCurrent) / Double(cleanupProgressTotal) : 0
    }

    // Scan progress
    var scanProgressCurrent: Int = 0
    var scanProgressTotal: Int = 0
    var scanningRuleName: String = ""

    var scanProgress: Double {
        scanProgressTotal > 0 ? Double(scanProgressCurrent) / Double(scanProgressTotal) : 0
    }

    var selectedItems: [StorageItem] {
        results.filter { selectedItemIDs.contains($0.id) }
    }

    var estimatedRecoveryBytes: UInt64 {
        var total: UInt64 = 0
        for item in selectedItems {
            if item.subPaths.isEmpty {
                total += item.sizeBytes ?? 0
            } else {
                let selected = selectedSubPaths[item.id] ?? []
                total += item.subPaths
                    .filter { selected.contains($0.path) }
                    .compactMap(\.sizeBytes)
                    .reduce(0, +)
            }
        }
        return total
    }

    var exceptions: [StorageItem] {
        results.filter { $0.status == .failed }
    }

    func toggleSelection(_ item: StorageItem) {
        guard item.status == .found,
              item.riskLevel != .protected,
              item.riskLevel != .unsupported,
              item.category != .packageOutput else { return }

        if item.subPaths.isEmpty {
            // Simple item: plain toggle
            if selectedItemIDs.contains(item.id) {
                selectedItemIDs.remove(item.id)
            } else {
                selectedItemIDs.insert(item.id)
            }
        } else {
            // Aggregated item: none → all → none
            let current = selectedSubPaths[item.id] ?? []
            if current.isEmpty {
                selectedSubPaths[item.id] = Set(item.subPaths.map(\.path))
                selectedItemIDs.insert(item.id)
            } else {
                selectedItemIDs.remove(item.id)
                selectedSubPaths.removeValue(forKey: item.id)
            }
        }
    }

    func toggleSubPath(_ subPath: StorageSubPath, in item: StorageItem) {
        var selected = selectedSubPaths[item.id] ?? []
        if selected.contains(subPath.path) {
            selected.remove(subPath.path)
        } else {
            selected.insert(subPath.path)
        }
        selectedSubPaths[item.id] = selected

        if selected.isEmpty {
            selectedItemIDs.remove(item.id)
            selectedSubPaths.removeValue(forKey: item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }


    func subPathSelectionState(for item: StorageItem) -> SubPathSelectionState {
        guard !item.subPaths.isEmpty else { return .none }
        let selected = selectedSubPaths[item.id] ?? []
        if selected.isEmpty { return .none }
        if selected.count == item.subPaths.count { return .all }
        return .partial
    }

    /// Build a flat list of paths to actually delete, respecting sub-path selections.
    func resolvedCleanupPaths(for item: StorageItem) -> [String] {
        if item.subPaths.isEmpty { return [item.path] }
        let selected = selectedSubPaths[item.id] ?? []
        return item.subPaths.filter { selected.contains($0.path) }.map(\.path)
    }

    func runScan() {
        scanPhase = .scanning
        results = []
        selectedItemIDs = []
        selectedSubPaths = [:]
        scanProgressCurrent = 0
        scanProgressTotal = 0
        scanningRuleName = ""

        Task {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let rules = DefaultRuleFactory.defaultRules(
                homeDirectory: home,
                projectRoots: projectRoots
            )

            scanProgressTotal = rules.count

            for (index, rule) in rules.enumerated() {
                scanningRuleName = rule.displayName
                scanProgressCurrent = index

                // Run file I/O on background thread, yield back to main actor
                let items = await Task.detached(priority: .userInitiated) {
                    rule.scan(measurer: FileSizeMeasurer())
                }.value

                let filtered = items.filter { item in
                    !excludedPaths.contains { item.path.hasPrefix($0) }
                }
                results.append(contentsOf: filtered)
                for item in filtered where item.defaultSelected && item.status == .found {
                    selectedItemIDs.insert(item.id)
                }
                scanProgressCurrent = index + 1
            }

            scanningRuleName = ""
            lastScanDate = Date()
            scanPhase = .done
        }
    }

    func runCleanup() {
        // Expand aggregated items into individual sub-path items for the executor
        let itemsToClean: [StorageItem] = selectedItems.flatMap { item -> [StorageItem] in
            let paths = resolvedCleanupPaths(for: item)
            if paths.count == 1 && paths[0] == item.path {
                return [item]
            }
            // Create synthetic StorageItems for each resolved sub-path
            return paths.map { path in
                StorageItem(
                    id: "\(item.id)|\(path)",
                    displayName: "\(item.displayName) (\(URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent))",
                    path: path,
                    category: item.category,
                    toolchain: item.toolchain,
                    sizeBytes: item.subPaths.first(where: { $0.path == path })?.sizeBytes,
                    riskLevel: item.riskLevel,
                    status: item.status,
                    defaultSelected: item.defaultSelected,
                    explanation: item.explanation,
                    exception: item.exception
                )
            }
        }
        guard !itemsToClean.isEmpty else { return }

        cleanupPhase = .executing
        cleanupProgressCurrent = 0
        cleanupProgressTotal = itemsToClean.count
        cleanupCurrentItemName = ""
        cleanupReport = nil

        Task.detached(priority: .userInitiated) {
            let executor = CleanupExecutor()
            let report = executor.execute(items: itemsToClean) { current, total, name in
                Task { @MainActor [weak self] in
                    self?.cleanupProgressCurrent = current
                    self?.cleanupProgressTotal = total
                    self?.cleanupCurrentItemName = name
                }
            }
            await MainActor.run { [weak self] in
                self?.cleanupReport = report
                self?.cleanupPhase = .done
                // Remove successfully cleaned items from results
                let removedPaths = Set(
                    report.succeeded.map { $0.item.path }
                )
                self?.results.removeAll { removedPaths.contains($0.path) }
                self?.selectedItemIDs.removeAll()
                self?.selectedSubPaths.removeAll()
            }
        }
    }

    // MARK: - Persistence helpers

    private static func loadURLs(key: String) -> [URL] {
        (UserDefaults.standard.stringArray(forKey: key) ?? [])
            .map { URL(fileURLWithPath: $0) }
    }

    private static func saveURLs(_ urls: [URL], key: String) {
        UserDefaults.standard.set(urls.map(\.path), forKey: key)
    }

    func items(for toolchain: String) -> [StorageItem] {
        results.filter { $0.toolchain == toolchain }
    }

    func totalSize(for toolchain: String) -> UInt64 {
        items(for: toolchain).compactMap(\.sizeBytes).reduce(0, +)
    }
}
