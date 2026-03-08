import SwiftUI
import ManagedSettings
import FamilyControls

// MARK: - Daily Usage Tracking

struct DailyUsage: Codable {
    let ruleId: String
    let date: String  // "yyyy-MM-dd"
    var minutes: Double
    var invested: Double
}

enum ScreenTimeStore {
    private static let key = "dailyScreenTimeUsage"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func load() -> [DailyUsage] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let usage = try? JSONDecoder().decode([DailyUsage].self, from: data) else {
            return []
        }
        return usage
    }

    static func record(ruleId: String, minutes: Double, rate: Double) {
        let dateStr = dateFormatter.string(from: Date())
        let invested = minutes * rate

        var all = load()
        if let idx = all.firstIndex(where: { $0.ruleId == ruleId && $0.date == dateStr }) {
            all[idx].minutes += minutes
            all[idx].invested += invested
        } else {
            all.append(DailyUsage(ruleId: ruleId, date: dateStr, minutes: minutes, invested: invested))
        }

        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func filtered(tab: Int) -> [DailyUsage] {
        let all = load()
        let today = dateFormatter.string(from: Date())

        switch tab {
        case 0: // Today
            return all.filter { $0.date == today }
        case 1: // This Week
            let calendar = Calendar.current
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return all }
            return all.filter {
                guard let date = dateFormatter.date(from: $0.date) else { return false }
                return date >= weekStart
            }
        default: // All Time
            return all
        }
    }

    static func todayTotal() -> Double {
        let today = dateFormatter.string(from: Date())
        return load().filter { $0.date == today }.reduce(0) { $0 + $1.invested }
    }
}

// MARK: - Global Trading Limit

enum TradingLimits {
    private static let key = "globalDailyTradeLimit"

    static var dailyLimit: Double {
        get {
            let val = UserDefaults.standard.double(forKey: key)
            return val > 0 ? val : 50.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    static var remaining: Double {
        max(dailyLimit - ScreenTimeStore.todayTotal(), 0)
    }
}

// MARK: - Rule

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

    // Gray isn't persisted
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
