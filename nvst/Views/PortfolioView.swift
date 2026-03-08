import SwiftUI

struct PortfolioView: View {
    @State private var selectedTimeRange = 2
    @State private var showAllHoldings = false
    @State private var showAllActivity = false
    @State private var selectedAsset: AssetHolding?
    @Namespace private var portfolioAnimation
    @State private var rules: [Rule] = []
    @State private var localUsage: [DailyUsage] = []

    @StateObject private var viewModel = PortfolioViewModel()

    let timeRanges = ["D", "W", "M"]
    let timeRangeAPICodes = ["1D", "1W", "1M"]
    private static let rulesKey = "savedRules"

    private var filteredUsage: [DailyUsage] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        switch selectedTimeRange {
        case 0: // Day
            return localUsage.filter { $0.date == today }
        case 1: // Week
            let calendar = Calendar.current
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return localUsage }
            return localUsage.filter {
                guard let date = formatter.date(from: $0.date) else { return false }
                return date >= weekStart
            }
        default: // Month
            return localUsage
        }
    }

    private var convertedHours: Double {
        let totalMinutes = filteredUsage.reduce(0) { $0 + $1.minutes }
        return totalMinutes / 60.0
    }

    private var topAppRule: Rule? {
        let activeRules = rules.filter { $0.isActive }
        guard !activeRules.isEmpty, !filteredUsage.isEmpty else { return nil }

        var minutesByRule: [String: Double] = [:]
        for entry in filteredUsage {
            minutesByRule[entry.ruleId, default: 0] += entry.minutes
        }

        guard let topRuleId = minutesByRule.max(by: { $0.value < $1.value })?.key,
              let topRule = activeRules.first(where: { $0.id == topRuleId }) else {
            return nil
        }
        return topRule
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: stickyHeader) {
                        VStack(spacing: 0) {
                            balanceSection
                            chartSection
                            timeControlSection
                            holdingsSection
                            statWidgetsSection
                            activitySection
                        }
                    }
                }
                .padding(.bottom, 100)
            }

            if showAllHoldings {
                AllHoldingsView(isVisible: $showAllHoldings, holdings: viewModel.holdings, onSelect: { asset in
                    selectedAsset = asset
                })
                .transition(.move(edge: .trailing))
                .zIndex(10)
            }

            if showAllActivity {
                AllActivityView(isVisible: $showAllActivity, activities: viewModel.recentActivity)
                .transition(.move(edge: .trailing))
                .zIndex(20)
            }
        }
        .sheet(item: $selectedAsset) { asset in
            PortfolioDetailView(asset: asset)
        }
        .onAppear {
            viewModel.fetchPortfolio()
            viewModel.fetchHistory(period: timeRangeAPICodes[selectedTimeRange])
            localUsage = ScreenTimeStore.load()
            if let data = UserDefaults.standard.data(forKey: Self.rulesKey),
               let decoded = try? JSONDecoder().decode([Rule].self, from: data) {
                rules = decoded
            }
        }
    }

    private var stickyHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Portfolio")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(
                ZStack {
                    Color.black.opacity(0.4)
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.04), location: 0),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.top, -200)
                .ignoresSafeArea()
            )
            .overlay(
                VStack {
                    Spacer()
                    Divider()
                        .background(Color.white.opacity(0.08))
                }
            )

            LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 10)
        }
    }

    private var balanceSection: some View {
        VStack(spacing: 4) {
            Text("PORTFOLIO VALUE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.2)

            Text(viewModel.displayTotal == 0 ? "$0.00" : viewModel.formattedPortfolioValue)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.white)

            if viewModel.pendingValue > 0 {
                Text("Includes $\(String(format: "%.2f", viewModel.pendingValue)) pending")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange.opacity(0.7))
                    .padding(.bottom, 2)
            }

            HStack(spacing: 6) {
                Image(systemName: viewModel.totalGainString.hasPrefix("-") ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                Text(viewModel.totalGainString)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(viewModel.totalGainString.hasPrefix("-") ? .red : Color(red: 0.19, green: 0.82, blue: 0.35))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((viewModel.totalGainString.hasPrefix("-") ? Color.red : Color(red: 0.19, green: 0.82, blue: 0.35)).opacity(0.1))
                    .overlay(Capsule().stroke((viewModel.totalGainString.hasPrefix("-") ? Color.red : Color(red: 0.19, green: 0.82, blue: 0.35)).opacity(0.2), lineWidth: 1))
            )
            .padding(.top, 8)
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var chartSection: some View {
        GeometryReader { geo in
            ZStack {
                if !viewModel.historicalEquity.isEmpty {
                    let minVal = viewModel.historicalEquity.min() ?? 0
                    let maxVal = viewModel.historicalEquity.max() ?? (minVal + 1)
                    let range = max(maxVal - minVal, 1.0)
                    let stepX = geo.size.width / CGFloat(max(viewModel.historicalEquity.count - 1, 1))

                    Path { path in
                        for (index, value) in viewModel.historicalEquity.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height - CGFloat((value - minVal) / range) * geo.size.height

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        if viewModel.historicalEquity.count == 1 {
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                        }
                    }
                    .stroke(Color(red: 0.19, green: 0.82, blue: 0.35), lineWidth: 3)

                    LinearGradient(colors: [Color(red: 0.19, green: 0.82, blue: 0.35).opacity(0.4), .clear],
                                   startPoint: .top, endPoint: .bottom)
                    .mask(
                        Path { path in
                            for (index, value) in viewModel.historicalEquity.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = geo.size.height - CGFloat((value - minVal) / range) * geo.size.height

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }

                            if viewModel.historicalEquity.count == 1 {
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                            }

                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                            path.closeSubpath()
                        }
                    )
                } else {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                }
            }
        }
        .frame(height: 220)
        .padding(.top, 8)
    }

    private var timeControlSection: some View {
        HStack(spacing: 0) {
            ForEach(0..<timeRanges.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        selectedTimeRange = index
                        viewModel.fetchHistory(period: timeRangeAPICodes[index])
                    }
                } label: {
                    Text(timeRanges[index])
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedTimeRange == index ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if selectedTimeRange == index {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(white: 0.23))
                                        .shadow(color: .black.opacity(0.3), radius: 5)
                                        .matchedGeometryEffect(id: "rangeHighlight", in: portfolioAnimation)
                                }
                            }
                        )
                }
            }
        }
        .padding(3)
        .background(Color(white: 0.11).cornerRadius(12))
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    private var statWidgetsSection: some View {
        HStack(spacing: 16) {
            statWidget(icon: "clock.arrow.2.circlepath", color: .blue, label: "Converted", value: String(format: "%.1f", convertedHours), unit: "HRS")
            topAppWidget
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var topAppWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let rule = topAppRule, let token = rule.applicationToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(2.0)
                    .frame(width: 40, height: 40)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "flame.fill")
                        .foregroundColor(.purple)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("TOP APP")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)

                if let rule = topAppRule, let token = rule.applicationToken {
                    Label(token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else {
                    Text("None")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05).cornerRadius(24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func statWidget(icon: String, color: Color, label: String, value: String, unit: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    if let unit = unit {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05).cornerRadius(24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Holdings")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation { showAllHoldings = true }
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1).cornerRadius(15))
                }
            }

            if viewModel.holdings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No Holdings")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Time tracked on your apps will be invested into fractional shares here.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.03).cornerRadius(20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.holdings.prefix(4)) { asset in
                        assetRow(asset)
                        if asset.id != viewModel.holdings.prefix(4).last?.id {
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 70)
                        }
                    }
                }
                .background(Color(white: 0.1).cornerRadius(18))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private func assetRow(_ asset: AssetHolding) -> some View {
        Button {
            selectedAsset = asset
        } label: {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: "https://api.elbstream.com/logos/symbol/\(asset.ticker)?format=png&size=200")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(colors: asset.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            Text(asset.appInitial)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(asset.ticker)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                        if asset.isPending {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    Text(asset.company)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.2f", asset.value))")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(asset.isPositive ? "+" : "")\(String(format: "%.1f", asset.returnPct))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(asset.isPositive ? .green : .red)
                }
            }
            .padding(16)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation { showAllActivity = true }
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1).cornerRadius(15))
                }
            }

            if viewModel.recentActivity.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No Recent Activity")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your automated investments will appear here.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.03).cornerRadius(20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
            } else {
                VStack(spacing: 20) {
                    ForEach(viewModel.recentActivity.first?.items.prefix(4) ?? []) { activity in
                        activityRow(activity)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func activityRow(_ activity: ActivityEntry) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 44, height: 44)
                Image(systemName: activity.icon)
                    .foregroundColor(activity.iconColor)
            }
            .shadow(color: .black.opacity(0.3), radius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                Text(activity.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.amount)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(activity.time)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
    }

}

struct SparklineView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard data.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(data.count - 1)
                let range = (data.max() ?? 0) - (data.min() ?? 0)
                let stepY = range == 0 ? 0 : geo.size.height / CGFloat(range)

                let points = data.enumerated().map { index, value in
                    CGPoint(x: CGFloat(index) * stepX,
                            y: geo.size.height - CGFloat(value - (data.min() ?? 0)) * stepY)
                }

                path.move(to: points[0])
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

struct AllHoldingsView: View {
    @Binding var isVisible: Bool
    let holdings: [AssetHolding]
    let onSelect: (AssetHolding) -> Void
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            assetList
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation { isVisible = false }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.05).cornerRadius(20))
            }

            Text("All Assets")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 36)
        .background(
            VStack(spacing: 0) {
                ZStack {
                    Color.black.opacity(0.4)
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.04), location: 0),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .background(.ultraThinMaterial)
                        .mask(
                            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                        )
                    LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                }
                .frame(height: 30)
            }
            .padding(.top, -150)
            .padding(.bottom, -30)
        )
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search your portfolio...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05).cornerRadius(16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private var assetList: some View {
        ScrollView(showsIndicators: false) {
            Group {
                if holdings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "briefcase")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Portfolio Empty")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("You don't own any assets yet. Start tracking time to auto-invest.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 0) {
                        ForEach(holdings) { asset in
                            Button {
                                onSelect(asset)
                            } label: {
                                assetRow(asset)
                            }
                            if asset.id != holdings.last?.id {
                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 70)
                            }
                        }
                    }
                    .background(Color(white: 0.1).cornerRadius(18))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func assetRow(_ asset: AssetHolding) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: "https://api.elbstream.com/logos/symbol/\(asset.ticker)?format=png&size=200")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: asset.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text(asset.appInitial)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.ticker)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                Text(asset.company)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", asset.value))")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("\(asset.isPositive ? "+" : "")\(String(format: "%.1f", asset.returnPct))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(asset.isPositive ? .green : .red)
            }
        }
        .padding(16)
    }
}

struct AllActivityView: View {
    @Binding var isVisible: Bool
    let activities: [ActivityGroup]

    var body: some View {
        VStack(spacing: 0) {
            header
            activityFeed
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation { isVisible = false }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.05).cornerRadius(20))
            }

            Text("Activity History")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 36)
        .background(
            VStack(spacing: 0) {
                ZStack {
                    Color.black.opacity(0.4)
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.04), location: 0),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .background(.ultraThinMaterial)
                        .mask(
                            LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                        )
                    LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                }
                .frame(height: 30)
            }
            .padding(.top, -150)
            .padding(.bottom, -30)
        )
    }

    private var activityFeed: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                if activities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Activity Yet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Start using your tracked apps to automatically invest your time into fractional shares.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 80)
                } else {
                    ForEach(activities) { group in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(group.group.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .tracking(1.5)
                                .padding(.leading, 4)

                            VStack(spacing: 24) {
                                ForEach(group.items) { activity in
                                    activityRow(activity)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.03).cornerRadius(28))
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private func activityRow(_ activity: ActivityEntry) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 44, height: 44)
                Image(systemName: activity.icon)
                    .foregroundColor(activity.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                Text(activity.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.amount)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(activity.time)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
    }
}
