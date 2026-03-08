import SwiftUI
import ManagedSettings
import FamilyControls

struct Rule: Identifiable, Codable, Equatable {
    static func == (lhs: Rule, rhs: Rule) -> Bool {
        lhs.id == rhs.id && lhs.appName == rhs.appName && lhs.ticker == rhs.ticker &&
        lhs.rate == rhs.rate && lhs.timeSpan == rhs.timeSpan && lhs.cap == rhs.cap &&
        lhs.todaySpent == rhs.todaySpent && lhs.isActive == rhs.isActive
    }

    let id: String
    var appName: String
    let appInitial: String
    var ticker: String
    var rate: Double
    var timeSpan: Int
    var cap: Double
    var todaySpent: Double
    var isActive: Bool
    var applicationToken: ApplicationToken?

    // Not persisted — always defaults to [.gray]
    var gradientColors: [Color] {
        [.gray]
    }

    var progressPercent: Double {
        let progress = (todaySpent / cap) * 100
        return min(progress, 100)
    }

    enum CodingKeys: String, CodingKey {
        case id, appName, appInitial, ticker, rate, timeSpan, cap, todaySpent, isActive, applicationToken
    }
}
