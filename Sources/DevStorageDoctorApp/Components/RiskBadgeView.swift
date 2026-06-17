import SwiftUI
import DevStorageCore

struct RiskBadgeView: View {
    let riskLevel: RiskLevel

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var label: String {
        switch riskLevel {
        case .low:          return "Low"
        case .medium:       return "Medium"
        case .high:         return "High"
        case .manualReview: return "Review"
        case .protected:    return "Protected"
        case .unsupported:  return "N/A"
        }
    }

    private var color: Color {
        switch riskLevel {
        case .low:          return .riskLow
        case .medium:       return .riskMedium
        case .high:         return .riskHigh
        case .manualReview: return .riskManual
        case .protected:    return .riskProtected
        case .unsupported:  return .riskUnsupported
        }
    }
}
