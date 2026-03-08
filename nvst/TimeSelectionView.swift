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
    @State private var orderStatus: String? = nil
    private let minimumMinutes = 5
    private let maximumMinutes = 180
    private let minuteStep = 5
    private let rulesKey = "savedRules"
    private let sharedDefaults = UserDefaults(suiteName: appGroupID)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 44))
                        .foregroundColor(.green)

                    Text("How much time?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Choose how long to unlock your apps.\nYou'll invest based on the time you pick.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

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
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.35), lineWidth: 1)
                            )
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

                Spacer()

                // Investment summary
                VStack(spacing: 6) {
                    Text("You'll invest")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("$\(investmentAmount, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("for \(formattedDuration(selectedMinutes)) of screen time")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .transition(.opacity)

                // Unlock button
                Button {
                    unlock()
                } label: {
                    Text(didUnlock ? "Unlocked!" : "Invest & Unlock")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            Capsule().fill(didUnlock ? Color(white: 0.2) : .green)
                        )
                }
                .disabled(didUnlock)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }

    private var investmentAmount: Double {
        Double(selectedMinutes) * 0.10
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

        // Auto-dismiss after a beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private func submitTrackUsage(minutes: Double) {
        let activeRules = loadActiveRulesWithTokens()
        guard !activeRules.isEmpty else { return }

        // Primary path: use the exact app token that triggered unlock.
        if let encodedToken = sharedDefaults?.string(forKey: "lastBlockedToken"),
           activeRules.contains(where: { encodeToken($0.applicationToken) == encodedToken }) {
            trackAppUsage(appName: encodedToken, minutes: minutes)
            return
        }

        // Fallback when unlock wasn't triggered from a specific blocked token.
        let minutesPerRule = minutes / Double(activeRules.count)
        for rule in activeRules {
            guard let encodedToken = encodeToken(rule.applicationToken) else { continue }
            trackAppUsage(appName: encodedToken, minutes: minutesPerRule)
        }
    }

    private func trackAppUsage(appName: String, minutes: Double) {
        guard let url = URL(string: "http://149.125.114.140:8000/api/track-usage") else { return }
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
