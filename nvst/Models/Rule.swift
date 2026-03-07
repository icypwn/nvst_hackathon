import SwiftUI

struct Rule: Identifiable {
    let id: String
    let appName: String
    let appInitial: String
    let gradientColors: [Color]
    let ticker: String
    var rate: Double
    var timeSpan: Int
    var cap: Double
    var todaySpent: Double
    var isActive: Bool
    
    var progressPercent: Double {
        let progress = (todaySpent / cap) * 100
        return min(progress, 100)
    }
}
