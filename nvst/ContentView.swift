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
    let ticker: String
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
    @State private var localUsage: [DailyUsage] = []
    @State private var selectedTab = 0
    let tabs = ["Today", "This Week", "All Time"]
    private static let rulesKey = "savedRules"

    private var filteredUsage: [DailyUsage] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        switch selectedTab {
        case 0: // Today
            return localUsage.filter { $0.date == today }
        case 1: // This Week
            let calendar = Calendar.current
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return localUsage }
            return localUsage.filter {
                guard let date = formatter.date(from: $0.date) else { return false }
                return date >= weekStart
            }
        default: // All Time
            return localUsage
        }
    }

    private var filteredTotals: (minutes: Double, invested: Double) {
        let activeRuleIds = Set(rules.filter { $0.isActive }.map { $0.id })
        let relevant = filteredUsage.filter { activeRuleIds.contains($0.ruleId) }
        return (
            relevant.reduce(0) { $0 + $1.minutes },
            relevant.reduce(0) { $0 + $1.invested }
        )
    }

    private var shares: [AppShare] {
        let activeRules = rules.filter { $0.isActive && $0.applicationToken != nil }
        guard !activeRules.isEmpty else { return [] }

        // Aggregate filtered usage by rule ID
        var aggregated: [String: (minutes: Double, invested: Double)] = [:]
        for entry in filteredUsage {
            let existing = aggregated[entry.ruleId] ?? (0, 0)
            aggregated[entry.ruleId] = (existing.minutes + entry.minutes, existing.invested + entry.invested)
        }

        let ringColors: [Color] = [.green, .blue, .pink, .orange, .cyan, .yellow, .purple, .red, .mint, .indigo]

        var items: [(rule: Rule, minutes: Double, invested: Double)] = []
        for rule in activeRules {
            let agg = aggregated[rule.id] ?? (0, 0)
            items.append((rule, agg.minutes, agg.invested))
        }

        let totalInvested = items.reduce(0) { $0 + $1.invested }

        return items.enumerated().map { index, item in
            let hrs = Int(item.minutes) / 60
            let mins = Int(item.minutes) % 60
            let timeStr = hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
            let pct = totalInvested > 0 ? item.invested / totalInvested : 1.0 / Double(items.count)

            return AppShare(
                name: item.rule.appName,
                ticker: item.rule.ticker,
                applicationToken: item.rule.applicationToken,
                screenTime: timeStr,
                invested: "$\(String(format: "%.2f", item.invested))",
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
            localUsage = ScreenTimeStore.load()
            viewModel.fetchPortfolio()
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingRuleCreated)) { _ in
            loadRules()
            localUsage = ScreenTimeStore.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            loadRules()
            localUsage = ScreenTimeStore.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .usageRecorded)) { _ in
            loadRules()
            localUsage = ScreenTimeStore.load()
            viewModel.fetchPortfolio()
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
            Text("nvst")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.green)
            Spacer()
        }
    }

    // MARK: - Ring Chart

    private var ringChartSection: some View {
        ZStack {
            DonutChart(shares: shares)
                .frame(width: 300, height: 300)

            VStack(spacing: 6) {
                Text("Total Invested")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("$\(String(format: "%.2f", filteredTotals.invested))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    let hrs = Int(filteredTotals.minutes) / 60
                    let mins = Int(filteredTotals.minutes) % 60
                    let suffix = selectedTab == 0 ? "today" : selectedTab == 1 ? "this week" : "all time"
                    Text(hrs > 0 ? "\(hrs)h \(mins)m \(suffix)" : "\(mins)m \(suffix)")
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
                HStack(spacing: 6) {
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
                    if !share.ticker.isEmpty {
                        Text("→ \(share.ticker)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
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
        .overlay(
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(share.ringColor)
                    .frame(width: 4)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        )
    }

    private func stockLogo(ticker: String, size: CGFloat) -> some View {
        AsyncImage(url: URL(string: "https://api.elbstream.com/logos/symbol/\(ticker)?format=png&size=200")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            default:
                Text(ticker)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
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

    private var visibleShares: [AppShare] {
        shares.filter { $0.percentage > 0 }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerRadius = size / 2
            let innerRadius = outerRadius - thickness

            ZStack {
                if visibleShares.isEmpty {
                    // Empty state: full gray ring
                    Circle()
                        .stroke(Color(white: 0.15), lineWidth: thickness)
                        .frame(width: size - thickness, height: size - thickness)
                } else if visibleShares.count == 1 {
                    // Single segment: use a plain circle to avoid rounded-corner gap
                    Circle()
                        .stroke(visibleShares[0].ringColor, lineWidth: thickness)
                        .frame(width: size - thickness, height: size - thickness)
                } else {
                    let totalGap = gapDegrees * Double(visibleShares.count)
                    let usableDegrees = 360.0 - totalGap

                    ForEach(0..<visibleShares.count, id: \.self) { index in
                        let startDeg = segmentStart(index: index, usableDegrees: usableDegrees)
                        let endDeg = startDeg + visibleShares[index].percentage * usableDegrees

                        RoundedArcSegment(
                            startAngle: .degrees(startDeg),
                            endAngle: .degrees(endDeg),
                            innerRadius: innerRadius,
                            outerRadius: outerRadius,
                            cornerRadius: cornerRadius
                        )
                        .fill(visibleShares[index].ringColor)
                    }
                }
            }
            .frame(width: size, height: size)
        }
    }

    private func segmentStart(index: Int, usableDegrees: Double) -> Double {
        var deg = -90.0
        for i in 0..<index {
            deg += visibleShares[i].percentage * usableDegrees + gapDegrees
        }
        return deg
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let showTimeSelection = Notification.Name("com.nvst.showTimeSelection")
    static let usageRecorded = Notification.Name("com.nvst.usageRecorded")
}

// MARK: - Preview

#Preview {
    ContentView()
}
