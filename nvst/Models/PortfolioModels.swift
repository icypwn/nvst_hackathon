import SwiftUI

struct AssetHolding: Identifiable {
    let id: String
    let ticker: String
    let company: String
    let initial: String
    let iconClass: String // For color/gradient mapping
    let value: Double
    let returnPct: Double
    let shares: Double
    let avgCost: Double
    let totalInvested: Double
    let rate: String
    var sparklineData: [Double]
    
    var isPositive: Bool { return returnPct >= 0 }
    
    var iconColors: [Color] {
        switch iconClass {
        case "icon-meta": return [Color(red: 0.02, green: 0.41, blue: 0.88), Color(red: 0.0, green: 0.78, blue: 1.0)]
        case "icon-bdnce": return [.black, Color(white: 0.2)]
        case "icon-googl": return [.red, .yellow, .green, .blue]
        case "icon-nflx": return [Color(red: 0.9, green: 0.04, blue: 0.08)]
        case "icon-spt": return [Color(red: 0.11, green: 0.73, blue: 0.33)]
        case "icon-amzn": return [Color(red: 1.0, green: 0.6, blue: 0.0)]
        default: return [.gray]
        }
    }
}

struct ActivityEntry: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let amount: String
    let time: String
    let icon: String
    let color: Color
}

struct ActivityGroup: Identifiable {
    let id = UUID()
    let group: String
    let items: [ActivityEntry]
}

struct PortfolioData {
    static let holdings: [AssetHolding] = [
        AssetHolding(id: "meta", ticker: "META", company: "Meta Platforms", initial: "M", iconClass: "icon-meta", value: 840.20, returnPct: 12.4, shares: 1.7314, avgCost: 485.30, totalInvested: 747.70, rate: "$0.10 / min", sparklineData: [10, 12, 11, 14, 13, 16, 15, 18]),
        AssetHolding(id: "bdnce", ticker: "BDNCE", company: "ByteDance", initial: "B", iconClass: "icon-bdnce", value: 410.80, returnPct: 4.2, shares: 8.2160, avgCost: 50.00, totalInvested: 394.20, rate: "$0.25 / min", sparklineData: [5, 7, 6, 8, 7, 9, 8, 10]),
        AssetHolding(id: "googl", ticker: "GOOGL", company: "Alphabet Inc.", initial: "G", iconClass: "icon-googl", value: 125.00, returnPct: -1.5, shares: 0.8802, avgCost: 142.10, totalInvested: 126.90, rate: "$0.05 / min", sparklineData: [15, 14, 14.5, 13, 13.5, 12, 12.5, 11]),
        AssetHolding(id: "nflx", ticker: "NFLX", company: "Netflix", initial: "N", iconClass: "icon-nflx", value: 52.50, returnPct: 8.9, shares: 0.0815, avgCost: 644.17, totalInvested: 48.20, rate: "$0.10 / min", sparklineData: [8, 9, 8.5, 10, 9.5, 11, 10.5, 12]),
        AssetHolding(id: "spt", ticker: "SPOT", company: "Spotify", initial: "S", iconClass: "icon-spt", value: 38.40, returnPct: 15.2, shares: 0.12, avgCost: 320.00, totalInvested: 33.30, rate: "$0.05 / min", sparklineData: [12, 13, 14, 15, 16, 17, 18, 19]),
        AssetHolding(id: "amzn", ticker: "AMZN", company: "Amazon", initial: "A", iconClass: "icon-amzn", value: 12.00, returnPct: 2.1, shares: 0.06, avgCost: 190.00, totalInvested: 11.75, rate: "$0.10 / min", sparklineData: [10, 10.5, 10.2, 10.8, 10.5, 11, 10.8, 11.2])
    ]
    
    static let activities: [ActivityGroup] = [
        ActivityGroup(group: "Today", items: [
            ActivityEntry(title: "Auto-Invest BDNCE", description: "From 45m TikTok", amount: "+$11.25", time: "Just Now", icon: "zap", color: .purple),
            ActivityEntry(title: "Auto-Invest META", description: "From 30m Instagram", amount: "+$3.00", time: "2:14 PM", icon: "zap", color: .green),
            ActivityEntry(title: "SPOT Dividend", description: "Cash yield payout", amount: "+$0.14", time: "9:05 AM", icon: "arrow.up.right", color: .green)
        ]),
        ActivityGroup(group: "Yesterday", items: [
            ActivityEntry(title: "Bank Deposit", description: "Chase •••• 4210", amount: "+$500.00", time: "4:20 PM", icon: "plus.circle", color: .blue),
            ActivityEntry(title: "Auto-Invest META", description: "From 12m Instagram", amount: "+$1.20", time: "11:15 AM", icon: "zap", color: .green),
            ActivityEntry(title: "Auto-Invest GOOGL", description: "From 1h YouTube", amount: "+$6.00", time: "8:30 AM", icon: "zap", color: .red)
        ])
    ]
}
