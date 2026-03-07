//
//  ContentView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import FamilyControls

// MARK: - Mock Data

struct AppShare: Identifiable {
    let id = UUID()
    let name: String
    let iconLetter: String
    let iconColors: [Color]
    let timeString: String
    let gainAmount: String
    let stockTicker: String
    let ringColor: Color
    let percentage: Double
}

let mockShares: [AppShare] = [
    AppShare(name: "Instagram", iconLetter: "I", iconColors: [.purple, .pink, .orange, .yellow], timeString: "2h 5m today", gainAmount: "+$12.50", stockTicker: "0.0258 META", ringColor: .pink, percentage: 0.41),
    AppShare(name: "YouTube", iconLetter: "Y", iconColors: [.red], timeString: "1h 24m today", gainAmount: "+$8.40", stockTicker: "0.0591 GOOGL", ringColor: .red, percentage: 0.28),
    AppShare(name: "TikTok", iconLetter: "T", iconColors: [Color(red: 0.0, green: 0.9, blue: 0.8)], timeString: "1h 2m today", gainAmount: "+$6.20", stockTicker: "0.0419 BDNCE", ringColor: .cyan, percentage: 0.20),
    AppShare(name: "Snapchat", iconLetter: "S", iconColors: [.yellow], timeString: "22m today", gainAmount: "+$2.10", stockTicker: "0.0182 SNAP", ringColor: .yellow, percentage: 0.07),
    AppShare(name: "Twitter", iconLetter: "X", iconColors: [.blue], timeString: "8m today", gainAmount: "+$0.90", stockTicker: "0.0031 TWTR", ringColor: .green, percentage: 0.04),
]

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

    @State private var showOnboarding = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            switch activeTab {
            case .home:
                HomeView(manager: manager, showTimeSelection: $showTimeSelection)
            case .appPicker:
                AppRulesView()
            case .portfolio:
                PortfolioView()
            case .settings:
                Text(activeTab.label)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            floatingTabBar
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(manager: manager)
                .interactiveDismissDisabled(!manager.isAuthorized)
        }
        .sheet(isPresented: $showTimeSelection) {
            TimeSelectionView(manager: manager)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !manager.isAuthorized {
                showOnboarding = true
            }
        }
        .onChange(of: manager.isAuthorized) { authorized in
            if authorized { showOnboarding = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTimeSelection)) { _ in
            showTimeSelection = true
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
    @State private var selectedTab = 0
    @State private var showActivityPicker = false
    let tabs = ["Today", "This Week", "All Time"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                ringChartSection
                tabPicker

                // Activity picker button
                Button {
                    showActivityPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(manager.selection.applicationTokens.isEmpty
                             ? "Select Apps to Track"
                             : "Manage Tracked Apps (\(manager.selection.applicationTokens.count))")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(.green))
                }
                .familyActivityPicker(isPresented: $showActivityPicker, selection: $manager.selection)

                sharesSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PORTFOLIO SUMMARY")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .tracking(1)
                HStack(spacing: 0) {
                    Text("Time")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Invest")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
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
            // Ring segments
            DonutChart(shares: mockShares)
                .frame(width: 300, height: 300)

            // Center content
            VStack(spacing: 6) {
                Text("Total Auto-Invested")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("$30.10")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("5h 1m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                    Text("+$4.50")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
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

            ForEach(mockShares) { share in
                shareCard(share)
            }
        }
    }

    private func shareCard(_ share: AppShare) -> some View {
        HStack(spacing: 14) {
            // App Icon
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: share.iconColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(share.iconLetter)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            // Name + Time
            VStack(alignment: .leading, spacing: 4) {
                Text(share.name)
                    .font(.headline)
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(share.timeString)
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }

            Spacer()

            // Gain + Ticker
            VStack(alignment: .trailing, spacing: 4) {
                Text(share.gainAmount)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text(share.stockTicker)
                    .font(.caption)
                    .foregroundColor(.gray)
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
    /// Adjust this to control endpoint roundness: 0 = flat, thickness/2 = fully round
    let cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerRadius = size / 2
            let innerRadius = outerRadius - thickness

            ZStack {
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
