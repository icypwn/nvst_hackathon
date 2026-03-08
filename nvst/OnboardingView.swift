//
//  OnboardingView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import UserNotifications
import FamilyControls
import ManagedSettings

struct OnboardingView: View {
    @ObservedObject var manager: ScreenTimeManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // 0 = Welcome, 1 = Track, 2 = Buy Stock, 3 = Permissions
    // 4 = Select App, 5 = Select Ticker, 6 = Investment Settings
    @State private var step = 0
    @State private var isRequesting = false
    @State private var showError = false
    
    @State private var animatePulse = false
    
    
    // Setup state
    @State private var showActivityPicker = false
    @State private var appSelection = FamilyActivitySelection()
    @State private var tickerText = ""
    @State private var selectedTicker: TickerSearchResult? = nil
    @State private var tickerSearchResults: [TickerSearchResult] = []
    @State private var isSearchingTicker = false
    @State private var tickerSearchTask: Task<Void, Never>? = nil
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
            
            // Background effects
            Color.clear.ignoresSafeArea()
                .overlay(
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .blur(radius: 60)
                        .frame(width: 400, height: 400)
                        .offset(x: bgOffsetX, y: bgOffsetY)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: step),
                    alignment: .center
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 2)
                        .frame(width: 600, height: 600)
                        .scaleEffect(animatePulse ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animatePulse),
                    alignment: .center
                )
                .clipped()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("nvst.")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(step + 1)/\(totalSteps)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
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
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Bottom button
                bottomButton
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
            }
        }
        .onAppear { animatePulse = true }
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
    
    // MARK: - Background offset helper
    
    private var bgOffsetX: CGFloat {
        switch step {
        case 0: return 100
        case 1: return -150
        case 2: return 0
        case 3: return -80
        case 4: return 120
        case 5: return -100
        default: return 60
        }
    }
    
    private var bgOffsetY: CGFloat {
        switch step {
        case 0: return -200
        case 1: return 0
        case 2: return 200
        case 3: return -50
        case 4: return -120
        case 5: return 80
        default: return -60
        }
    }
    
    // MARK: - Bottom Button
    
    @ViewBuilder
    private var bottomButton: some View {
        switch step {
        case 0, 1, 2:
            continueButton {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { step += 1 }
            }
        case 3:
            Button {
                authorize()
            } label: {
                HStack {
                    if isRequesting {
                        ProgressView().tint(.black)
                    } else {
                        Text("ENABLE ACCESS")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.green)
                .cornerRadius(14)
            }
            .disabled(isRequesting)
        case 4:
            VStack(spacing: 12) {
                if hasApp {
                    continueButton(label: "NEXT", icon: "arrow.right", color: .green) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { step = 5 }
                    }
                }
                skipButton {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { step = 5 }
                }
            }
        case 5:
            VStack(spacing: 12) {
                if hasTicker {
                    continueButton(label: "NEXT", icon: "arrow.right", color: .green) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { step = 6 }
                    }
                }
                skipButton {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { step = 6 }
                }
            }
        default:
            continueButton(
                label: hasApp && hasTicker ? "LET'S GO" : "SKIP FOR NOW",
                icon: hasApp && hasTicker ? "checkmark.circle.fill" : "arrow.right",
                color: hasApp && hasTicker ? .green : .white
            ) {
                finishOnboarding()
            }
        }
    }
    
    private func continueButton(label: String = "CONTINUE", icon: String = "arrow.right", color: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(color)
            .cornerRadius(14)
        }
    }
    
    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Skip")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Color(white: 0.5))
        }
    }
    
    // MARK: - Slide 1: Welcome
    
    private var slide1: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("INVEST")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("WHILE")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("YOU SCROLL.")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("Every minute you waste on social media is now a financial investment into your future.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 2: Track
    
    private var slide2: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WE TRACK")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("YOUR APPS.")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("Secure, local monitoring of your screen time ensures we know exactly how much time you spend.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .padding(.top, 4)
            
            HStack(spacing: 12) {
                AppBadge(name: "META", color: .pink)
                AppBadge(name: "GOOGL", color: .red)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 3: Invest
    
    private var slide3: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WE BUY")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 0) {
                Text("THEIR ")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("STOCK.")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.green)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            
            Text("Scroll Instagram for an hour? We automatically market-buy fractional shares of META.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .padding(.top, 4)
            
            Text("META +$0.50")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(10)
                .rotationEffect(.degrees(-3))
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 4: Permissions
    
    private var slide4: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LET'S")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("GET TO")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("WORK.")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("We need two things from you to make this happen:")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            VStack(spacing: 12) {
                permissionPlate(title: "SCREEN TIME", desc: "Allows us to track your usage locally.")
                permissionPlate(title: "NOTIFICATIONS", desc: "Alerts you when we buy stock.")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 5: Select App
    
    private var slideSelectApp: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("PICK AN")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("APP")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Text("Choose the app you want to track. Every minute you spend on it will automatically invest into a stock of your choice.")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            // App selector button
            Button {
                showActivityPicker = true
            } label: {
                HStack(spacing: 14) {
                    if !hasApp {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(white: 0.25), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .frame(width: 56, height: 56)
                            Image(systemName: "plus.app.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color(white: 0.4))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tap to choose an app")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                            Text("e.g. Instagram, TikTok, YouTube")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.3))
                        }
                    } else if let token = appSelection.applicationTokens.first {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .scaleEffect(2.6)
                            .frame(width: 56, height: 56)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label(token)
                                .labelStyle(.titleOnly)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                            Text("Tap to change")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.4))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(white: 0.3))
                }
                .padding(18)
                .background(Color(white: 0.08))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(hasApp ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Slide 6: Select Ticker
    
    private var slideSelectTicker: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHOOSE THE")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("TICKER")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                // Ticker explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's a ticker?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("A **ticker** is a short code that represents a company on the stock market. For example, **META** is Meta (Instagram & Facebook), **GOOGL** is Google (YouTube), and **AAPL** is Apple.")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.55))
                        .lineSpacing(4)
                }
                .padding(16)
                .background(Color(white: 0.08))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

                // Search field
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        if let ticker = selectedTicker {
                            HStack(spacing: 6) {
                                Text(ticker.symbol)
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.green)
                                Text(ticker.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(white: 0.6))
                                    .lineLimit(1)
                                Spacer()
                                Button {
                                    selectedTicker = nil
                                    tickerText = ""
                                    tickerSearchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(white: 0.4))
                                        .font(.system(size: 18))
                                }
                            }
                        } else {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color(white: 0.4))
                                .font(.system(size: 16))
                            TextField("Search ticker (e.g. AAPL)", text: $tickerText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .onChange(of: tickerText) { newValue in
                                    performTickerSearch(query: newValue)
                                }
                            if isSearchingTicker {
                                ProgressView()
                                    .tint(.green)
                                    .scaleEffect(0.8)
                            } else if !tickerText.isEmpty {
                                Button {
                                    tickerText = ""
                                    tickerSearchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(white: 0.4))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(white: 0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedTicker != nil ? Color.green.opacity(0.5) : hasTicker ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                    )
                }

                // Search results
                if !tickerSearchResults.isEmpty && selectedTicker == nil {
                    VStack(spacing: 0) {
                        ForEach(tickerSearchResults) { result in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTicker = result
                                    tickerText = result.symbol
                                    tickerSearchResults = []
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(result.symbol)
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundColor(.green)
                                        .frame(width: 60, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            Text(result.exchange)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(Color(white: 0.4))
                                            if result.fractionable {
                                                Text("Fractional")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(.green.opacity(0.8))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 1)
                                                    .background(Color.green.opacity(0.1))
                                                    .cornerRadius(3)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(white: 0.3))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            if result.id != tickerSearchResults.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.leading, 88)
                            }
                        }
                    }
                    .background(Color(white: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Popular tickers
                VStack(alignment: .leading, spacing: 10) {
                    Text("POPULAR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(white: 0.35))
                        .tracking(1.5)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                        ForEach(tickerSuggestions, id: \.self) { ticker in
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedTicker = TickerSearchResult(symbol: ticker, name: ticker, exchange: "", fractionable: true)
                                    tickerText = ticker
                                    tickerSearchResults = []
                                }
                            } label: {
                                Text(ticker)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(tickerText == ticker ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(tickerText == ticker ? Color.green : Color(white: 0.12))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func performTickerSearch(query: String) {
        tickerSearchTask?.cancel()

        guard query.count >= 1 else {
            tickerSearchResults = []
            isSearchingTicker = false
            return
        }

        isSearchingTicker = true

        tickerSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }

            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "http://149.125.114.140:8000/api/search-ticker?q=\(encoded)") else {
                await MainActor.run { isSearchingTicker = false }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(TickerSearchResponse.self, from: data)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        tickerSearchResults = decoded.results
                        isSearchingTicker = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { isSearchingTicker = false }
                }
            }
        }
    }
    
    // MARK: - Slide 7: Investment Settings
    
    private var slideInvestmentSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SET YOUR")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("RATE")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Text("How much should we invest per minute of screen time?")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            // Summary card
            if hasApp && hasTicker {
                HStack(spacing: 12) {
                    if let token = appSelection.applicationTokens.first {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .scaleEffect(2.0)
                            .frame(width: 44, height: 44)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let token = appSelection.applicationTokens.first {
                            Label(token)
                                .labelStyle(.titleOnly)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("→ \(tickerText)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", investRate))/min")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(14)
                .background(Color.green.opacity(0.08))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Rate slider
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Investment rate")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$\(String(format: "%.2f", investRate))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                            Text("/ min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    Slider(value: $investRate, in: 0.01...1.00, step: 0.01)
                        .accentColor(.green)
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Daily cap")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$\(Int(dailyCap)).00")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                            Text("/ day")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(capOptions, id: \.self) { amount in
                            Button {
                                dailyCap = amount
                            } label: {
                                Text("$\(Int(amount))")
                                    .font(.system(size: 14, weight: dailyCap == amount ? .bold : .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(dailyCap == amount ? Color.green : Color(white: 0.12))
                                    .foregroundColor(dailyCap == amount ? .black : .white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(white: 0.08))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helpers
    
    private func permissionPlate(title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func authorize() {
        isRequesting = true
        Task {
            do {
                try await manager.requestAuthorization()
                try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
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
            let ticker = selectedTicker?.symbol ?? tickerText.uppercased()
            let rule = Rule(
                id: UUID().uuidString,
                appName: selectedTicker?.name ?? "",
                appInitial: String(ticker.prefix(1)),
                ticker: ticker,
                rate: investRate,
                timeSpan: 1,
                cap: dailyCap,
                todaySpent: 0,
                isActive: true,
                applicationToken: token
            )
            NotificationCenter.default.post(name: .onboardingRuleCreated, object: rule)
            if let encodedToken = encodeToken(token) {
                savePreference(appName: encodedToken, ticker: ticker, ratePerMinute: investRate)
            }
        }
        withAnimation {
            hasCompletedOnboarding = true
        }
    }

    private func savePreference(appName: String, ticker: String, ratePerMinute: Double) {
        guard let url = URL(string: "http://149.125.114.140:8000/api/preferences") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "app_name": appName,
            "investment_rate_per_hour": ratePerMinute * 60,
            "ticker": ticker
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    private func encodeToken(_ token: ApplicationToken) -> String? {
        guard let data = try? JSONEncoder().encode(token) else { return nil }
        return data.base64EncodedString()
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
