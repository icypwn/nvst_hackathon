//
//  OnboardingView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import UserNotifications
import FamilyControls

struct OnboardingView: View {
    @ObservedObject var manager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    
    // 0 = Welcome, 1 = Track, 2 = Buy Stock, 3 = Permissions
    // 4 = Select App, 5 = Select Ticker, 6 = Investment Settings
    @State private var step = 0
    @State private var isRequesting = false
    @State private var showError = false
    
    // Setup state
    @State private var showActivityPicker = false
    @State private var appSelection = FamilyActivitySelection()
    @State private var tickerText = ""
    @State private var investRate: Double = 0.10
    @State private var dailyCap: Double = 5
    
    private let totalSteps = 7
    private let capOptions = [5.0, 10.0, 20.0, 50.0]
    private let tickerSuggestions = ["META", "GOOGL", "AAPL", "TSLA", "SNAP", "AMZN", "NVDA", "MSFT"]
    
    private var hasApp: Bool { !appSelection.applicationTokens.isEmpty }
    private var hasTicker: Bool { !tickerText.isEmpty }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("nvst")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(step + 1)/\(totalSteps)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(white: 0.15))
                        Capsule()
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: step)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Slide content
                Spacer()
                
                ZStack {
                    if step == 0 { slide1.transition(.opacity) }
                    if step == 1 { slide2.transition(.opacity) }
                    if step == 2 { slide3.transition(.opacity) }
                    if step == 3 { slide4.transition(.opacity) }
                    if step == 4 { slideSelectApp.transition(.opacity) }
                    if step == 5 { slideSelectTicker.transition(.opacity) }
                    if step == 6 { slideInvestmentSettings.transition(.opacity) }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Bottom button
                bottomButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
            }
        }
        .onAppear {}
        .sheet(isPresented: $showActivityPicker) {
            ActivityPickerView(selection: $appSelection) {
                showActivityPicker = false
            }
        }
        .alert("Permission Required", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text("We need Screen Time access to track your usage. Please enable it in Settings.")
        }
    }
    
    // MARK: - Bottom Button
    
    @ViewBuilder
    private var bottomButton: some View {
        switch step {
        case 0, 1, 2:
            primaryButton(label: "Continue", icon: "arrow.right") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step += 1 }
            }
        case 3:
            Button {
                authorize()
            } label: {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView().tint(.black)
                    } else {
                        Text("Enable Access")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.green)
                .cornerRadius(16)
            }
            .disabled(isRequesting)
        case 4:
            VStack(spacing: 12) {
                if hasApp {
                    primaryButton(label: "Next", icon: "arrow.right") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 5 }
                    }
                }
                secondaryButton(label: hasApp ? "" : "Skip") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 5 }
                }
                .opacity(hasApp ? 0 : 1)
            }
        case 5:
            VStack(spacing: 12) {
                if hasTicker {
                    primaryButton(label: "Next", icon: "arrow.right") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 6 }
                    }
                }
                secondaryButton(label: hasTicker ? "" : "Skip") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 6 }
                }
                .opacity(hasTicker ? 0 : 1)
            }
        default:
            primaryButton(
                label: hasApp && hasTicker ? "Let's Go" : "Skip for Now",
                icon: hasApp && hasTicker ? "checkmark" : "arrow.right"
            ) {
                finishOnboarding()
            }
        }
    }
    
    private func primaryButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.green)
            .cornerRadius(16)
        }
    }
    
    private func secondaryButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
        }
    }
    
    // MARK: - Slide 1: Welcome
    
    private var slide1: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Invest\nwhile you\nscroll.")
                .font(.system(size: 46, weight: .black))
                .foregroundColor(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            
            Text("Every minute on social media automatically invests into your future.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 2: Track
    
    private var slide2: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("We track\nyour apps.")
                .font(.system(size: 46, weight: .black))
                .foregroundColor(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            
            Text("Secure, local monitoring of your screen time. We know exactly how much time you spend — nothing leaves your device.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 3: Invest
    
    private var slide3: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                Text("We buy")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.white)
                HStack(spacing: 0) {
                    Text("their ")
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(.white)
                    Text("stock.")
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(.green)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            
            Text("Scroll Instagram for an hour? We automatically buy fractional shares of META with your money.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(4)
            
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .bold))
                Text("META +$0.50")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.12))
                    .overlay(Capsule().stroke(Color.green.opacity(0.2), lineWidth: 1))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 4: Permissions
    
    private var slide4: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Let's get\nto work.")
                .font(.system(size: 46, weight: .black))
                .foregroundColor(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            
            Text("We need access to two things to make this happen:")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(4)
            
            VStack(spacing: 0) {
                permissionRow(icon: "hourglass", color: Color(hex: "34C759"), title: "Screen Time", desc: "Track your app usage locally")
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                permissionRow(icon: "bell.fill", color: Color(hex: "FF9500"), title: "Notifications", desc: "Get alerts when we buy stock")
            }
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 5: Select App
    
    private var slideSelectApp: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Pick an")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.white)
                Text("app.")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.green)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            
            Text("Choose the app you want to track. Every minute you spend on it will automatically invest into a stock.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(4)
            
            Button {
                showActivityPicker = true
            } label: {
                HStack(spacing: 14) {
                    if !hasApp {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(white: 0.2), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                .frame(width: 48, height: 48)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Select an app")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("e.g. Instagram, TikTok, YouTube")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    } else if let token = appSelection.applicationTokens.first {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .scaleEffect(2.4)
                            .frame(width: 48, height: 48)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Label(token)
                                .labelStyle(.titleOnly)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Tap to change")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(16)
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(hasApp ? Color.green.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 6: Select Ticker
    
    private var slideSelectTicker: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Choose a")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.white)
                Text("ticker.")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.green)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            
            // Explanation
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("What's a ticker?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("A ticker is a short code for a company on the stock market. For example, **META** is Instagram's parent company, **GOOGL** is Google, and **AAPL** is Apple.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .lineSpacing(3)
            }
            .padding(14)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: "8E8E93"))
                    .font(.system(size: 16))
                TextField("Type a ticker (e.g. AAPL)", text: $tickerText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                
                if !tickerText.isEmpty {
                    Button {
                        tickerText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
            }
            .padding(14)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasTicker ? Color.green.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Popular tickers grid
            VStack(alignment: .leading, spacing: 8) {
                Text("POPULAR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .tracking(1.2)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                    ForEach(tickerSuggestions, id: \.self) { ticker in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                tickerText = ticker
                            }
                        } label: {
                            Text(ticker)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(tickerText == ticker ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(tickerText == ticker ? Color.green : Color(hex: "1C1C1E"))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(tickerText == ticker ? Color.clear : Color.white.opacity(0.06), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 7: Investment Settings
    
    private var slideInvestmentSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Set your")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.white)
                Text("rate.")
                    .font(.system(size: 46, weight: .black))
                    .foregroundColor(.green)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            
            Text("How much should we invest per minute of screen time?")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(4)
            
            // Summary badge
            if hasApp && hasTicker {
                HStack(spacing: 10) {
                    if let token = appSelection.applicationTokens.first {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .scaleEffect(1.8)
                            .frame(width: 36, height: 36)
                    }
                    
                    if let token = appSelection.applicationTokens.first {
                        Label(token)
                            .labelStyle(.titleOnly)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("→ \(tickerText)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", investRate))/min")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(6)
                }
                .padding(14)
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Rate + Cap config
            VStack(spacing: 20) {
                // Rate slider
                VStack(spacing: 12) {
                    HStack {
                        Text("Investment Rate")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$\(String(format: "%.2f", investRate))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                            Text("/ min")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    Slider(value: $investRate, in: 0.01...1.00, step: 0.01)
                        .accentColor(.green)
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Daily cap
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Daily Cap")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$\(Int(dailyCap)).00")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                            Text("/ day")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(capOptions, id: \.self) { amount in
                            Button {
                                dailyCap = amount
                            } label: {
                                Text("$\(Int(amount))")
                                    .font(.system(size: 14, weight: dailyCap == amount ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(dailyCap == amount ? Color.green : Color(white: 0.12))
                                    .foregroundColor(dailyCap == amount ? .black : .white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helpers
    
    private func permissionRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                color
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
            .frame(width: 30, height: 30)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private func authorize() {
        isRequesting = true
        Task {
            do {
                try await manager.requestAuthorization()
                try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        step = 4
                    }
                }
            } catch {
                await MainActor.run { showError = true }
            }
            await MainActor.run { isRequesting = false }
        }
    }
    
    private func finishOnboarding() {
        if hasApp && hasTicker,
           let token = appSelection.applicationTokens.first {
            let rule = Rule(
                id: UUID().uuidString,
                appName: "",
                appInitial: "",
                ticker: tickerText,
                rate: investRate,
                timeSpan: 1,
                cap: dailyCap,
                todaySpent: 0,
                isActive: true,
                applicationToken: token
            )
            NotificationCenter.default.post(name: .onboardingRuleCreated, object: rule)
        }
        dismiss()
    }
}

struct AppBadge: View {
    let name: String
    let color: Color
    var body: some View {
        Text(name)
            .font(.system(size: 18, weight: .black, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color)
            .cornerRadius(10)
            .rotationEffect(.degrees(Double.random(in: -5...5)))
    }
}

extension Notification.Name {
    static let onboardingRuleCreated = Notification.Name("com.nvst.onboardingRuleCreated")
}
