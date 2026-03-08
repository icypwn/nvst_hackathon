//
//  ContentView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings

// MARK: - Ring Data

struct AppShare: Identifiable {
    let id = UUID()
    let name: String
    let applicationToken: ApplicationToken?
    let screenTime: String
    let invested: String
    let ringColor: Color
    let percentage: Double
}

// MARK: - Tab Item

enum NavTab: Int, CaseIterable {
    case home, appPicker, portfolio, settings

    var label: String {
        switch self {
        case .home: return "Home"
        case .appPicker: return "Apps"
        case .portfolio: return "Portfolio"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .appPicker: return "square.grid.2x2"
        case .portfolio: return "chart.pie.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Root Shell

struct ContentView: View {
    @StateObject private var manager = ScreenTimeManager.shared
    @State private var activeTab: NavTab = .home
    @State private var showTimeSelection = false
    @Namespace private var tabAnimation

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if !hasCompletedOnboarding {
                OnboardingView(manager: manager)
                    .transition(.opacity)
                    .zIndex(100)
            } else {
                Color.black.ignoresSafeArea()

                switch activeTab {
                case .home:
                    HomeView(manager: manager, showTimeSelection: $showTimeSelection)
                case .appPicker:
                    AppRulesView()
                case .portfolio:
                    PortfolioView()
                case .settings:
                    SettingsView()
                }

                floatingTabBar
            }
        }
        .sheet(isPresented: $showTimeSelection) {
            TimeSelectionView(manager: manager)
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .showTimeSelection)) { _ in
            showTimeSelection = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if manager.checkForUnlockRequest() {
                showTimeSelection = true
            }
        }
    }

    private var floatingTabBar: some View {
        #if swift(>=6.1)
        // iOS 26+ with liquid glass
        GlassEffectContainer {
            HStack(spacing: 8) {
                ForEach(NavTab.allCases, id: \.rawValue) { tab in
                    let isActive = activeTab == tab
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                            activeTab = tab
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: isActive ? 22 : 20, weight: .medium))
                                .foregroundColor(isActive ? .green : Color(white: 0.7))

                            Text(tab.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isActive ? .green : Color(white: 0.45))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .glassEffect(
                            isActive ? .standard.tint(.green).interactive() : .clear,
                            in: .capsule
                        )
                        .glassEffectID(tab.rawValue, in: tabAnimation)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .glassEffect(GlassMaterial.regular, in: .capsule)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        #else
        // Fallback for older toolchains
        fallbackTabBar
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        #endif
    }

    private var fallbackTabBar: some View {
        HStack(spacing: 8) {
            ForEach(NavTab.allCases, id: \.rawValue) { tab in
                let isActive = activeTab == tab
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: isActive ? 22 : 20, weight: .medium))
                            .foregroundColor(isActive ? .green : Color(white: 0.7))

                        Text(tab.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isActive ? .green : Color(white: 0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Group {
                            if isActive {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.25),
                                                        Color.white.opacity(0.05)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                                    .matchedGeometryEffect(id: "indicator", in: tabAnimation)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        )
    }
}

// MARK: - Home View

struct HomeView: View {
    @ObservedObject var manager: ScreenTimeManager
    @Binding var showTimeSelection: Bool
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var rules: [Rule] = []
    @State private var selectedTab = 0
    let tabs = ["Today", "This Week", "All Time"]
    private static let rulesKey = "savedRules"

    private var shares: [AppShare] {
        let activeRules = rules.filter { $0.isActive && $0.applicationToken != nil }
        let rulesByTicker = Dictionary(grouping: activeRules, by: { $0.ticker.uppercased() })

        var cardRows: [(holding: AssetHolding, rule: Rule?)] = []
        for holding in viewModel.holdings {
            let matchedRules = rulesByTicker[holding.ticker.uppercased()] ?? []
            if matchedRules.isEmpty {
                cardRows.append((holding, nil))
            } else {
                for rule in matchedRules {
                    cardRows.append((holding, rule))
                }
            }
        }

        let totalValue = cardRows.reduce(0.0) { partial, row in
            let splitCount = Double(max((rulesByTicker[row.holding.ticker.uppercased()] ?? []).count, 1))
            return partial + (row.holding.value / splitCount)
        }
        guard totalValue > 0 else { return [] }

        let ringColors: [Color] = [.green, .blue, .pink, .orange, .cyan, .yellow, .purple, .red, .mint, .indigo]

        return cardRows.enumerated().map { index, row in
            let matchedCount = Double(max((rulesByTicker[row.holding.ticker.uppercased()] ?? []).count, 1))
            let perTokenValue = row.holding.value / matchedCount
            let perTokenInvested = row.holding.totalInvested / matchedCount
            let pct = perTokenValue / totalValue

            return AppShare(
                name: row.rule?.appName.isEmpty == false ? (row.rule?.appName ?? row.holding.appName) : row.holding.appName,
                applicationToken: row.rule?.applicationToken,
                screenTime: row.holding.formattedTime,
                invested: "$\(String(format: "%.2f", perTokenInvested))",
                ringColor: ringColors[index % ringColors.count],
                percentage: pct
            )
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                ringChartSection
                tabPicker
                sharesSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .onAppear {
            loadRules()
            viewModel.fetchPortfolio()
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingRuleCreated)) { _ in
            loadRules()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            loadRules()
        }
    }

    private func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: Self.rulesKey),
              let decoded = try? JSONDecoder().decode([Rule].self, from: data) else {
            rules = []
            return
        }
        rules = decoded
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("nvst.")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.green)
            Spacer()
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
        }
    }

    // MARK: - Ring Chart

    private var ringChartSection: some View {
        ZStack {
            DonutChart(shares: shares)
                .frame(width: 300, height: 300)

            VStack(spacing: 6) {
                Text("Total Auto-Invested")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(viewModel.totalAutoInvestedString)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.totalTimeString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                    Text(viewModel.totalGainString)
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                .foregroundColor(viewModel.totalGainString.hasPrefix("-") ? .red : .green)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill((viewModel.totalGainString.hasPrefix("-") ? Color.red : Color.green).opacity(0.15))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tabs[index])
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == index ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == index
                                ? Capsule().fill(Color(white: 0.2))
                                : Capsule().fill(Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule().fill(Color(white: 0.1))
        )
    }

    // MARK: - Shares List

    private var sharesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Screen Time Shares")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if shares.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 32))
                        .foregroundColor(Color(white: 0.25))
                    Text("No investments yet")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.4))
                    Text("Set up an app rule to start investing")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(shares) { share in
                    shareCard(share)
                }
            }
        }
    }

    private func shareCard(_ share: AppShare) -> some View {
        HStack(spacing: 14) {
            Group {
                if let token = share.applicationToken {
                    Label(token)
                        .labelStyle(.iconOnly)
                        .scaleEffect(2.2)
                        .frame(width: 50, height: 50)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(white: 0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(share.name.prefix(1)).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let token = share.applicationToken {
                    Label(token)
                        .labelStyle(.titleOnly)
                        .font(.headline)
                        .foregroundColor(.white)
                } else {
                    Text(share.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text(share.screenTime)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                Text(share.invested)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.1))
        )
    }
}

// MARK: - Rounded Arc Shape

struct RoundedArcSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let thickness = outerRadius - innerRadius
        let cr = min(cornerRadius, thickness / 2)

        // Angular insets so corners don't exceed the arc length
        let outerInset = cr > 0 ? Angle.radians(Double(cr / outerRadius)) : .zero
        let innerInset = cr > 0 ? Angle.radians(Double(cr / innerRadius)) : .zero

        var path = Path()

        // 1. Move to outer arc start (after start corner)
        path.move(to: pt(center, outerRadius, startAngle + outerInset))

        // 2. Outer arc
        path.addArc(center: center, radius: outerRadius,
                     startAngle: startAngle + outerInset,
                     endAngle: endAngle - outerInset,
                     clockwise: false)

        // 3. Corner: outer-end → inner-end (quad curve through the sharp corner)
        path.addQuadCurve(
            to: pt(center, innerRadius + cr, endAngle),
            control: pt(center, outerRadius, endAngle)
        )
        path.addQuadCurve(
            to: pt(center, innerRadius, endAngle - innerInset),
            control: pt(center, innerRadius, endAngle)
        )

        // 4. Inner arc (reverse)
        path.addArc(center: center, radius: innerRadius,
                     startAngle: endAngle - innerInset,
                     endAngle: startAngle + innerInset,
                     clockwise: true)

        // 5. Corner: inner-start → outer-start (quad curve through the sharp corner)
        path.addQuadCurve(
            to: pt(center, innerRadius + cr, startAngle),
            control: pt(center, innerRadius, startAngle)
        )
        path.addQuadCurve(
            to: pt(center, outerRadius, startAngle + outerInset),
            control: pt(center, outerRadius, startAngle)
        )

        path.closeSubpath()
        return path
    }

    private func pt(_ center: CGPoint, _ radius: CGFloat, _ angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle.radians)),
            y: center.y + radius * CGFloat(sin(angle.radians))
        )
    }
}

// MARK: - Donut Chart

struct DonutChart: View {
    let shares: [AppShare]
    let thickness: CGFloat = 28
    let gapDegrees: Double = 2
    let cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerRadius = size / 2
            let innerRadius = outerRadius - thickness

            ZStack {
                if shares.isEmpty {
                    // Empty state: full gray ring
                    Circle()
                        .stroke(Color(white: 0.15), lineWidth: thickness)
                        .frame(width: size - thickness, height: size - thickness)
                } else if shares.count == 1 {
                    // Single segment: use a plain circle to avoid rounded-corner gap
                    Circle()
                        .stroke(shares[0].ringColor, lineWidth: thickness)
                        .frame(width: size - thickness, height: size - thickness)
                } else {
                    let totalGap = gapDegrees * Double(shares.count)
                    let usableDegrees = 360.0 - totalGap

                    ForEach(0..<shares.count, id: \.self) { index in
                        let startDeg = segmentStart(index: index, usableDegrees: usableDegrees)
                        let endDeg = startDeg + shares[index].percentage * usableDegrees

                        RoundedArcSegment(
                            startAngle: .degrees(startDeg),
                            endAngle: .degrees(endDeg),
                            innerRadius: innerRadius,
                            outerRadius: outerRadius,
                            cornerRadius: cornerRadius
                        )
                        .fill(shares[index].ringColor)
                    }
                }
            }
            .frame(width: size, height: size)
        }
    }

    private func segmentStart(index: Int, usableDegrees: Double) -> Double {
        var deg = -90.0
        for i in 0..<index {
            deg += shares[i].percentage * usableDegrees + gapDegrees
        }
        return deg
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let showTimeSelection = Notification.Name("com.nvst.showTimeSelection")
}

// MARK: - Preview

#Preview {
    ContentView()
}
