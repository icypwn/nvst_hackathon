import SwiftUI

struct PortfolioDetailView: View {
    let asset: AssetHolding
    @Environment(\.dismiss) var dismiss
    @State private var showActionAlert = false
    @State private var actionAlertText = ""
    @State private var isSubmittingAction = false
    @State private var liveCurrentPrice: Double? = nil

    private var averageCostPerShare: Double {
        max(asset.avgCost, 0)
    }

    private var fallbackCurrentPricePerShare: Double {
        guard averageCostPerShare > 0, asset.totalInvested > 0 else { return 0 }
        let estimatedShares = asset.totalInvested / averageCostPerShare
        guard estimatedShares > 0 else { return 0 }
        return asset.value / estimatedShares
    }

    private var currentPricePerShare: Double {
        if let liveCurrentPrice, liveCurrentPrice > 0 {
            return liveCurrentPrice
        }
        return fallbackCurrentPricePerShare
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    handleBar
                    headerSection
                    marketValueSection
                    statsGrid
                    accumulationLogSection
                    orderActionSection
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Order Action", isPresented: $showActionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(actionAlertText)
        }
        .task(id: asset.ticker) {
            fetchCurrentPrice()
        }
    }
    
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.5))
            .frame(width: 48, height: 6)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: "https://api.elbstream.com/logos/symbol/\(asset.ticker)?format=png&size=200")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(colors: asset.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text(asset.appInitial)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.4), radius: 15)

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.ticker)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(asset.company)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
    
    private var marketValueSection: some View {
        VStack(spacing: 4) {
            Text("MARKET VALUE")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.gray)
                .tracking(1.5)
            
            Text("$\(String(format: "%.2f", asset.value))")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text("\(asset.isPositive ? "↑" : "↓") \(String(format: "%.1f", asset.returnPct))%")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(asset.isPositive ? .green : .red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(asset.isPositive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
        }
        .padding(.bottom, 40)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statItem(label: "Screen Time", value: asset.formattedTime)
            statItem(label: "Average Cost", value: "$\(String(format: "%.2f", averageCostPerShare))")
            statItem(label: "Invested", value: "$\(String(format: "%.2f", asset.totalInvested))")
            statItem(label: "Current Price", value: "$\(String(format: "%.2f", currentPricePerShare))")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private func statItem(label: String, value: String, valueColor: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(valueColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05).cornerRadius(16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    private var accumulationLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accumulation Log")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                // Mock log entry
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Instagram Converted")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("3 min usage • 14m ago")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+$0.30")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.green)
                        Text("@ $485.32")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.03).cornerRadius(16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var orderActionSection: some View {
        VStack(spacing: 12) {
            if asset.isPending {
                Button {
                    cancelPendingOrders()
                } label: {
                    Text(isSubmittingAction ? "Canceling..." : "Cancel Order")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.cornerRadius(16))
                }
                .disabled(isSubmittingAction)
            } else {
                Button {
                    submitSellOrder()
                } label: {
                    Text(isSubmittingAction ? "Submitting..." : "Sell")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.15, green: 0.75, blue: 0.30).cornerRadius(16))
                }
                .disabled(isSubmittingAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private func cancelPendingOrders() {
        guard !isSubmittingAction else { return }
        isSubmittingAction = true

        guard let url = URL(string: "http://149.125.202.134:8000/api/orders/cancel") else {
            actionAlertText = "Invalid cancel endpoint URL."
            showActionAlert = true
            isSubmittingAction = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["symbol": asset.ticker])

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmittingAction = false

                if let error {
                    actionAlertText = "Cancel failed: \(error.localizedDescription)"
                    showActionAlert = true
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    actionAlertText = "Cancel failed: no response from server."
                    showActionAlert = true
                    return
                }

                if (200...299).contains(http.statusCode) {
                    actionAlertText = "Pending orders for \(asset.ticker) canceled."
                    showActionAlert = true
                    NotificationCenter.default.post(name: Notification.Name("com.nvst.usageRecorded"), object: nil)
                } else {
                    let message = serverErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
                    actionAlertText = "Cancel failed: \(message)"
                    showActionAlert = true
                }
            }
        }.resume()
    }

    private func submitSellOrder() {
        guard !isSubmittingAction else { return }
        isSubmittingAction = true

        guard let url = URL(string: "http://149.125.202.134:8000/api/orders/sell") else {
            actionAlertText = "Invalid sell endpoint URL."
            showActionAlert = true
            isSubmittingAction = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["symbol": asset.ticker])

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmittingAction = false

                if let error {
                    actionAlertText = "Sell failed: \(error.localizedDescription)"
                    showActionAlert = true
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    actionAlertText = "Sell failed: no response from server."
                    showActionAlert = true
                    return
                }

                if (200...299).contains(http.statusCode) {
                    actionAlertText = "Sell order submitted for \(asset.ticker)."
                    showActionAlert = true
                    NotificationCenter.default.post(name: Notification.Name("com.nvst.usageRecorded"), object: nil)
                } else {
                    let message = serverErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
                    actionAlertText = "Sell failed: \(message)"
                    showActionAlert = true
                }
            }
        }.resume()
    }

    private func fetchCurrentPrice() {
        guard let url = URL(string: "http://149.125.202.134:8000/api/price/\(asset.ticker)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let price = json["price"] as? Double,
                  price > 0 else { return }
            DispatchQueue.main.async {
                liveCurrentPrice = price
            }
        }.resume()
    }

    private func serverErrorMessage(from data: Data?) -> String? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let detail = json["detail"] as? String {
            return detail
        }
        if let error = json["error"] as? String {
            return error
        }
        return nil
    }
}
