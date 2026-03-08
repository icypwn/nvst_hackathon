import SwiftUI

struct AssetHolding: Identifiable, Codable {
    let id: String
    let ticker: String
    let company: String
    let initial: String
    let iconClass: String
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
}

struct ActivityGroup: Identifiable, Codable {
    var id: String { return group }
    let group: String
    let items: [ActivityEntry]
}


struct PortfolioAPIResponse: Codable {
    let total_auto_invested_string: String
    let total_gain_string: String
    let total_time_string: String
    let total_converted_hrs: Double?
    let top_engine: String?
    let holdings: [AssetHolding]
    let activities: [ActivityGroup]
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

class PortfolioViewModel: ObservableObject {
    @Published var portfolioValue: Double = 0.0
    @Published var totalGainString: String = "+$0.00"
    @Published var historicalEquity: [Double] = []
    @Published var totalConvertedHrs: Double = 0.0
    @Published var topEngine: String = "None"
    @Published var holdings: [AssetHolding] = []
    @Published var recentActivity: [ActivityGroup] = []
    
    var formattedPortfolioValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$\(formatter.string(from: NSNumber(value: portfolioValue)) ?? "0.00")"
    }
    
    func fetchPortfolio() {
        guard let url = URL(string: "http://127.0.0.1:8000/api/portfolio") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(PortfolioAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.portfolioValue = decoded.raw_alpaca_data.portfolio_value
                    self?.totalGainString = decoded.total_gain_string
                    self?.totalConvertedHrs = decoded.total_converted_hrs ?? 0.0
                    self?.topEngine = decoded.top_engine ?? "None"
                    self?.holdings = decoded.holdings
                    self?.recentActivity = decoded.activities
                }
            } catch {
                print("Failed to decode portfolio: \(error)")
            }
        }.resume()
    }
    
    func fetchHistory(period: String = "1M") {
        guard let url = URL(string: "http://127.0.0.1:8000/api/history?period=\(period)") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(PortfolioHistoryResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.historicalEquity = decoded.equity.compactMap { $0 }
                }
            } catch {
                print("Failed to decode history: \(error)")
            }
        }.resume()
    }
}

