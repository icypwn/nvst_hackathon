//
//  TimeSelectionView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct TimeSelectionView: View {
    @ObservedObject var manager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes = 15
    @State private var didUnlock = false
    @State private var isProcessing = false
    @State private var isCompleted = false
    @State private var orderStatus: String? = nil
    @State private var stockPrice: Double? = nil
    private let minimumMinutes = 1
    private let maximumMinutes = 180
    private let minuteStep = 1
    private let rulesKey = "savedRules"
    private let sharedDefaults = UserDefaults(suiteName: appGroupID)

    private var matchedRule: Rule? {
        let activeRules = loadActiveRulesWithTokens()
        if let encodedToken = sharedDefaults?.string(forKey: "lastBlockedToken"),
           let rule = activeRules.first(where: { encodeToken($0.applicationToken) == encodedToken }) {
            return rule
        }
        return activeRules.first
    }

    var body: some View {
        ZStack {
            Color(white: 0.1).ignoresSafeArea()

            if isProcessing || isCompleted {
                completionView
            } else {
                selectionView
            }
        }
        .onAppear {
            if let rule = matchedRule, !rule.ticker.isEmpty {
                fetchPrice(ticker: rule.ticker)
            }
        }
    }

    private var selectionView: some View {
        VStack(spacing: 28) {
            Text("Select your time")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 70)

            // Dynamic time picker
            HStack(spacing: 16) {
                Button {
                    selectedMinutes = max(minimumMinutes, selectedMinutes - minuteStep)
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color(white: 0.12))
                        )
                }
                .disabled(selectedMinutes <= minimumMinutes)

                VStack(spacing: 4) {
                    Text(formattedDuration(selectedMinutes))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.1))
                )

                Button {
                    selectedMinutes = min(maximumMinutes, selectedMinutes + minuteStep)
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color(white: 0.12))
                        )
                }
                .disabled(selectedMinutes >= maximumMinutes)
            }

            // App → Stock connection
            if let rule = matchedRule, !rule.ticker.isEmpty {
                HStack(spacing: 0) {
                    // Left: App icon + time + name
                    VStack(spacing: 8) {
                        if let token = rule.applicationToken {
                            Label(token)
                                .labelStyle(.iconOnly)
                                .scaleEffect(3.7)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(white: 0.15))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                )
                        }

                        Text(formattedDuration(selectedMinutes))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        if let token = rule.applicationToken {
                            Label(token)
                                .labelStyle(.titleOnly)
                                .foregroundColor(.gray)
                                .opacity(0.6)
                                .scaleEffect(0.8)
                                .lineLimit(1)
                                .padding(.top, -6)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(white: 0.35))
                        .padding(.horizontal, 4)

                    // Right: Stock logo + amount + ticker
                    VStack(spacing: 8) {
                        AsyncImage(url: URL(string: "https://api.elbstream.com/logos/symbol/\(rule.ticker)?format=png&size=200")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fit)
                            default:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(white: 0.15))
                                    .overlay(
                                        Text(rule.ticker)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        )

                        Text("$\(investmentAmount, specifier: "%.2f")")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.green)

                        Text(rule.ticker)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, -4)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)

                if let shares = estimatedShares, let price = stockPrice {
                    Text("\(shares, specifier: "%.3f") shares @ $\(price, specifier: "%.2f")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.top, -4)
                }
            }

            Spacer()

            if exceedsLimit {
                Text("Exceeds daily limit ($\(String(format: "%.0f", TradingLimits.dailyLimit))). $\(String(format: "%.2f", TradingLimits.remaining)) remaining.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Unlock button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isProcessing = true
                }
                unlock()
            } label: {
                Text(exceedsLimit ? "Over Daily Limit" : "Invest & Unlock")
                    .font(.headline)
                    .foregroundColor(exceedsLimit ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule().fill(exceedsLimit ? Color(white: 0.2) : .green)
                    )
            }
            .disabled(exceedsLimit)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))

                Text("Completed")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                if let rule = matchedRule {
                    let sharesText = estimatedShares.map { String(format: "%.3f", $0) } ?? ""
                    Text("Your purchase of \(sharesText) \(rule.ticker) has been completed and your app has been unlocked")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Processing...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var investmentAmount: Double {
        Double(selectedMinutes) * 0.10
    }

    private var exceedsLimit: Bool {
        investmentAmount > TradingLimits.remaining
    }

    private var estimatedShares: Double? {
        guard let price = stockPrice, price > 0 else { return nil }
        return investmentAmount / price
    }

    private func fetchPrice(ticker: String) {
        guard let url = URL(string: "http://149.125.202.134:8000/api/price/\(ticker)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let price = json["price"] as? Double else { return }
            DispatchQueue.main.async {
                stockPrice = price
            }
        }.resume()
    }

    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours == 0 { return "\(minutes) min" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }

    private func unlock() {
        manager.unlockAndScheduleReblock(minutes: selectedMinutes)
        didUnlock = true

        // Submit order through backend for tracked apps
        submitTrackUsage(minutes: Double(selectedMinutes))

        // Notify home page to refresh
        NotificationCenter.default.post(name: Notification.Name("com.nvst.usageRecorded"), object: nil)

        // Show processing, then completed, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isCompleted = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            dismiss()
        }
    }

    private func submitTrackUsage(minutes: Double) {
        let activeRules = loadActiveRulesWithTokens()
        guard !activeRules.isEmpty else { return }

        // Primary path: use the exact app token that triggered unlock.
        if let encodedToken = sharedDefaults?.string(forKey: "lastBlockedToken"),
           let matchedRule = activeRules.first(where: { encodeToken($0.applicationToken) == encodedToken }) {
            trackAppUsage(appName: encodedToken, minutes: minutes)
            ScreenTimeStore.record(ruleId: matchedRule.id, minutes: minutes, rate: matchedRule.rate)
            return
        }

        // Fallback when unlock wasn't triggered from a specific blocked token.
        let minutesPerRule = minutes / Double(activeRules.count)
        for rule in activeRules {
            guard let encodedToken = encodeToken(rule.applicationToken) else { continue }
            trackAppUsage(appName: encodedToken, minutes: minutesPerRule)
            ScreenTimeStore.record(ruleId: rule.id, minutes: minutesPerRule, rate: rule.rate)
        }
    }

    private func trackAppUsage(appName: String, minutes: Double) {
        guard let url = URL(string: "http://149.125.202.134:8000/api/track-usage") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "app_name": appName,
            "usage_minutes": minutes
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data,
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = result["status"] as? String {
                DispatchQueue.main.async {
                    orderStatus = status == "success" ? "Order placed" : nil
                }
            }
        }.resume()
    }

    private func loadActiveRulesWithTokens() -> [Rule] {
        guard let data = UserDefaults.standard.data(forKey: rulesKey),
              let rules = try? JSONDecoder().decode([Rule].self, from: data) else {
            return []
        }
        return rules.filter { $0.isActive && $0.applicationToken != nil && !$0.ticker.isEmpty }
    }

    private func encodeToken(_ token: ApplicationToken?) -> String? {
        guard let token,
              let data = try? JSONEncoder().encode(token) else { return nil }
        return data.base64EncodedString()
    }
}
