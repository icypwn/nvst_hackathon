import SwiftUI

struct AssetHolding: Identifiable, Codable {
    let id: String
    let ticker: String
    let company: String
    let initial: String
    let iconClass: String
    let value: Double
    let returnPct: Double
    let timeMinutes: Double
    let avgCost: Double
    let totalInvested: Double
    let appName: String
    let appInitial: String
    var sparklineData: [Double]
    var isPending: Bool = false

    var isPositive: Bool { return returnPct >= 0 }

    var formattedTime: String {
        let hrs = Int(timeMinutes) / 60
        let mins = Int(timeMinutes) % 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        }
        return "\(mins)m"
    }

    enum CodingKeys: String, CodingKey {
        case id, ticker, company, initial, iconClass, value, returnPct, timeMinutes, avgCost, totalInvested, appName, appInitial, sparklineData
    }
    
    var iconColors: [Color] {
        switch iconClass {
        case "icon-meta": return [Color(red: 0.02, green: 0.41, blue: 0.88), Color(red: 0.0, green: 0.78, blue: 1.0)]
        case "icon-bdnce": return [.black, Color(white: 0.2)]
        case "icon-tiktok": return [.black, Color(white: 0.2)]
        case "icon-twitter": return [.black, Color(white: 0.2)]
        case "icon-x": return [.black, Color(white: 0.2)]
        case "icon-instagram": return [Color(red: 0.8, green: 0.2, blue: 0.5), Color(red: 0.9, green: 0.5, blue: 0.2)]
        case "icon-youtube": return [Color(red: 0.9, green: 0.04, blue: 0.08)]
        case "icon-googl": return [.red, .yellow, .green, .blue]
        case "icon-nflx": return [Color(red: 0.9, green: 0.04, blue: 0.08)]
        case "icon-spt": return [Color(red: 0.11, green: 0.73, blue: 0.33)]
        case "icon-amzn": return [Color(red: 1.0, green: 0.6, blue: 0.0)]
        default: return [.gray, .black]
        }
    }
}

struct ActivityEntry: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let amount: String
    let time: String
    let icon: String
    let color: String
    
    var iconColor: Color {
        switch color.lowercased() {
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "red": return .red
        default: return .gray
        }
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Activity" }

        if trimmed.localizedCaseInsensitiveContains("Auto-Invest") {
            return trimmed.replacingOccurrences(of: "Auto-Invest", with: "Invested")
        }
        return trimmed
    }

    var tickerSymbol: String? {
        let source = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return nil }
        let words = source.split(whereSeparator: \.isWhitespace)
        guard let last = words.last else { return nil }
        let cleaned = last.trimmingCharacters(in: .punctuationCharacters).uppercased()
        guard cleaned.count >= 1, cleaned.count <= 6, cleaned.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return nil
        }
        return cleaned
    }

    var displayDescription: String {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Automated investment" }
        if trimmed.contains("{") && trimmed.contains("}") {
            return "Automated investment"
        }

        let words = trimmed.split(whereSeparator: \.isWhitespace).map(String.init)
        let cleanedWords = words.map { word -> String in
            let token = word.trimmingCharacters(in: .punctuationCharacters)
            let isLikelyEncodedToken = token.count >= 24 && token.allSatisfy { $0.isLetter || $0.isNumber }
            return isLikelyEncodedToken ? "tracked app" : word
        }

        let cleaned = cleanedWords.joined(separator: " ")
        return cleaned.replacingOccurrences(of: "tracked app tracked app", with: "tracked app")
    }

    var displayAmount: String {
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "--" : trimmed
    }

    var displayTime: String {
        let trimmed = time.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Now" : trimmed
    }
}

struct ActivityGroup: Identifiable, Codable {
    var id: String { return group }
    let group: String
    let items: [ActivityEntry]
}


struct PendingOrder: Identifiable, Codable {
    let id: String
    let symbol: String
    let company: String?
    let notional: Double
    let status: String
    let submitted_at: String
}

struct PortfolioAPIResponse: Codable {
    let total_auto_invested_string: String
    let total_gain_string: String
    let total_time_string: String
    let total_converted_hrs: Double?
    let top_engine: String?
    let holdings: [AssetHolding]
    let activities: [ActivityGroup]
    let pending_orders: [PendingOrder]?
    let pending_value: Double?
    let raw_alpaca_data: RawAlpacaData
}

struct RawAlpacaData: Codable {
    let portfolio_value: Double
    let buying_power: Double
    let cash: Double
}

struct PortfolioHistoryResponse: Codable {
    let equity: [Double?]
    let timestamp: [Int]
    let base_value: Double
}

// MARK: - Ticker Search

struct TickerSearchResult: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let exchange: String
    let fractionable: Bool
}

struct TickerSearchResponse: Codable {
    let results: [TickerSearchResult]
}

// MARK: - Track Usage

struct TrackUsageRequest: Codable {
    let app_name: String
    let usage_minutes: Double
}

// MARK: - View Models

class PortfolioViewModel: ObservableObject {
    @Published var portfolioValue: Double = 0.0
    @Published var totalAutoInvestedString: String = "$0.00"
    @Published var totalGainString: String = "+$0.00"
    @Published var totalTimeString: String = "0m today"
    @Published var historicalEquity: [Double] = []
    @Published var totalConvertedHrs: Double = 0.0
    @Published var topEngine: String = "None"
    @Published var holdings: [AssetHolding] = []
    @Published var recentActivity: [ActivityGroup] = []
    @Published var pendingValue: Double = 0.0
    @Published var pendingOrders: [PendingOrder] = []
    
    private static let cacheKey = "portfolioViewModelCache"
    
    private struct PortfolioCacheSnapshot: Codable {
        let portfolioValue: Double
        let totalAutoInvestedString: String
        let totalGainString: String
        let totalTimeString: String
        let totalConvertedHrs: Double
        let topEngine: String
        let holdings: [AssetHolding]
        let recentActivity: [ActivityGroup]
        let pendingValue: Double
        let pendingOrders: [PendingOrder]
        let historicalEquity: [Double]
    }

    init() {
        loadCachedSnapshot()
    }

    var holdingsTotal: Double {
        holdings.reduce(0) { $0 + $1.value }
    }

    var displayTotal: Double {
        let base = holdingsTotal > 0 ? max(portfolioValue, holdingsTotal) : portfolioValue
        return base + pendingValue
    }

    var formattedPortfolioValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$\(formatter.string(from: NSNumber(value: displayTotal)) ?? "0.00")"
    }

    var formattedPortfolioValueRaw: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: displayTotal)) ?? "0.00"
    }

    func fetchPortfolio() {
        guard let url = URL(string: "http://149.125.202.134:8000/api/portfolio") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PortfolioAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.portfolioValue = decoded.raw_alpaca_data.portfolio_value
                    self?.totalAutoInvestedString = decoded.total_auto_invested_string
                    self?.totalGainString = decoded.total_gain_string
                    self?.totalTimeString = decoded.total_time_string
                    self?.totalConvertedHrs = decoded.total_converted_hrs ?? 0.0
                    self?.topEngine = decoded.top_engine ?? "None"
                    var allHoldings = decoded.holdings
                    self?.pendingValue = decoded.pending_value ?? 0.0
                    self?.pendingOrders = decoded.pending_orders ?? []

                    // Merge pending orders into holdings for visibility
                    for order in decoded.pending_orders ?? [] {
                        let symbol = order.symbol
                        if let idx = allHoldings.firstIndex(where: { $0.ticker == symbol }) {
                            // Mark as pending as result of tx
                            let existing = allHoldings[idx]
                            allHoldings[idx] = AssetHolding(
                                id: existing.id,
                                ticker: existing.ticker,
                                company: existing.company,
                                initial: existing.initial,
                                iconClass: existing.iconClass,
                                value: existing.value + order.notional,
                                returnPct: existing.returnPct,
                                timeMinutes: existing.timeMinutes,
                                avgCost: existing.avgCost,
                                totalInvested: existing.totalInvested + order.notional,
                                appName: existing.appName,
                                appInitial: existing.appInitial,
                                sparklineData: existing.sparklineData,
                                isPending: true
                            )
                        } else {
                            // No holding yet — create one from the pending order
                            let companyName = order.company ?? symbol
                            allHoldings.append(AssetHolding(
                                id: "pending-\(order.id)",
                                ticker: symbol,
                                company: companyName,
                                initial: String(symbol.prefix(1)),
                                iconClass: "icon-\(symbol.lowercased())",
                                value: order.notional,
                                returnPct: 0,
                                timeMinutes: 0,
                                avgCost: 0,
                                totalInvested: order.notional,
                                appName: companyName,
                                appInitial: String(symbol.prefix(1)),
                                sparklineData: [0, 0],
                                isPending: true
                            ))
                        }
                    }

                    self?.holdings = allHoldings
                    self?.recentActivity = decoded.activities
                    self?.saveCachedSnapshot()
                }
            } catch {
                print("Failed to decode portfolio: \(error)")
            }
        }.resume()
    }
    
    func fetchHistory(period: String = "1M") {
        guard let url = URL(string: "http://149.125.202.134:8000/api/history?period=\(period)") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(PortfolioHistoryResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.historicalEquity = decoded.equity.compactMap { value in
                        guard let value, value.isFinite else { return nil }
                        return value
                    }
                    self?.saveCachedSnapshot()
                }
            } catch {
                print("Failed to decode history: \(error)")
            }
        }.resume()
    }

    private func loadCachedSnapshot() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let snapshot = try? JSONDecoder().decode(PortfolioCacheSnapshot.self, from: data) else { return }
        portfolioValue = snapshot.portfolioValue
        totalAutoInvestedString = snapshot.totalAutoInvestedString
        totalGainString = snapshot.totalGainString
        totalTimeString = snapshot.totalTimeString
        totalConvertedHrs = snapshot.totalConvertedHrs
        topEngine = snapshot.topEngine
        holdings = snapshot.holdings
        recentActivity = snapshot.recentActivity
        pendingValue = snapshot.pendingValue
        pendingOrders = snapshot.pendingOrders
        historicalEquity = snapshot.historicalEquity
    }

    private func saveCachedSnapshot() {
        let snapshot = PortfolioCacheSnapshot(
            portfolioValue: portfolioValue,
            totalAutoInvestedString: totalAutoInvestedString,
            totalGainString: totalGainString,
            totalTimeString: totalTimeString,
            totalConvertedHrs: totalConvertedHrs,
            topEngine: topEngine,
            holdings: holdings,
            recentActivity: recentActivity,
            pendingValue: pendingValue,
            pendingOrders: pendingOrders,
            historicalEquity: historicalEquity
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }
}
