import Foundation
import DevStorageCore

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
        case .manual:     return "questionmark.folder"
        case .reports:    return "doc.text"
        case .settings:   return "gearshape"
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

// MARK: - App State

@MainActor
@Observable
final class AppState {
    var scanPhase: ScanPhase = .idle
    var results: [StorageItem] = []
    var selectedItemIDs: Set<String> = []
    var projectRoots: [URL] = []
    var lastScanDate: Date?
    var showingCleanupPlan = false

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
        selectedItems.compactMap(\.sizeBytes).reduce(0, +)
    }

    var exceptions: [StorageItem] {
        results.filter { $0.status == .failed }
    }

    func toggleSelection(_ item: StorageItem) {
        guard item.status == .found,
              item.riskLevel != .protected,
              item.riskLevel != .unsupported,
              item.category != .packageOutput else { return }
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    func runScan() {
        scanPhase = .scanning
        results = []
        selectedItemIDs = []
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

                results.append(contentsOf: items)
                for item in items where item.defaultSelected && item.status == .found {
                    selectedItemIDs.insert(item.id)
                }
                scanProgressCurrent = index + 1
            }

            scanningRuleName = ""
            lastScanDate = Date()
            scanPhase = .done
        }
    }

    func items(for toolchain: String) -> [StorageItem] {
        results.filter { $0.toolchain == toolchain }
    }

    func totalSize(for toolchain: String) -> UInt64 {
        items(for: toolchain).compactMap(\.sizeBytes).reduce(0, +)
    }
}
