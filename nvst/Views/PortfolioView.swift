import SwiftUI

struct PortfolioView: View {
    @State private var selectedTimeRange = 2
    @State private var showAllHoldings = false
    @State private var showAllActivity = false
    @State private var selectedAsset: AssetHolding?
    @Namespace private var portfolioAnimation
    
    let timeRanges = ["1D", "1W", "1M", "3M", "1Y"]
    
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
                            statWidgetsSection
                            holdingsSection
                            activitySection
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            
            if showAllHoldings {
                AllHoldingsView(isVisible: $showAllHoldings, onSelect: { asset in
                    selectedAsset = asset
                })
                .transition(.move(edge: .trailing))
                .zIndex(10)
            }
            
            if showAllActivity {
                AllActivityView(isVisible: $showAllActivity)
                .transition(.move(edge: .trailing))
                .zIndex(20)
            }
        }
        .sheet(item: $selectedAsset) { asset in
            PortfolioDetailView(asset: asset)
        }
    }
    
    // MARK: - Sections
    
    private var stickyHeader: some View {
        HStack {
            Text("Portfolio")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 36)
        .background(
            VStack(spacing: 0) {
                Color.black
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
    
    private var balanceSection: some View {
        VStack(spacing: 4) {
            Text("PORTFOLIO VALUE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.2)
            
            Text("$1,428.50")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 6) {
                Image(systemName: "trending.up")
                    .font(.system(size: 14, weight: .bold))
                Text("+$124.20 (9.5%)")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(Color(red: 0.19, green: 0.82, blue: 0.35))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(red: 0.19, green: 0.82, blue: 0.35).opacity(0.1))
                    .overlay(Capsule().stroke(Color(red: 0.19, green: 0.82, blue: 0.35).opacity(0.2), lineWidth: 1))
            )
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
    
    private var chartSection: some View {
        GeometryReader { geo in
            ZStack {
                // Main Chart Line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 150))
                    path.addCurve(to: CGPoint(x: geo.size.width, y: 50),
                                 control1: CGPoint(x: geo.size.width * 0.375, y: 150),
                                 control2: CGPoint(x: geo.size.width * 0.625, y: 50))
                }
                .stroke(Color(red: 0.19, green: 0.82, blue: 0.35), lineWidth: 3)
                
                // Area Under Chart
                LinearGradient(colors: [Color(red: 0.19, green: 0.82, blue: 0.35).opacity(0.4), .clear],
                               startPoint: .top, endPoint: .bottom)
                .mask(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 150))
                        path.addCurve(to: CGPoint(x: geo.size.width, y: 50),
                                     control1: CGPoint(x: geo.size.width * 0.375, y: 150),
                                     control2: CGPoint(x: geo.size.width * 0.625, y: 50))
                        path.addLine(to: CGPoint(x: geo.size.width, y: 220))
                        path.addLine(to: CGPoint(x: 0, y: 220))
                        path.closeSubpath()
                    }
                )
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
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
    
    private var statWidgetsSection: some View {
        HStack(spacing: 16) {
            statWidget(icon: "clock.arrow.2.circlepath", color: .blue, label: "Converted", value: "142.5", unit: "HRS", progress: 0.75)
            statWidget(icon: "flame.fill", color: .purple, label: "Top Engine", value: "TikTok", badge: "Hot")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    private func statWidget(icon: String, color: Color, label: String, value: String, unit: String? = nil, progress: Double? = nil, badge: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                Spacer()
                if let progress = progress {
                    ZStack {
                        Circle()
                            .stroke(Color(white: 0.15), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 32, height: 32)
                } else if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(color.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2).cornerRadius(6))
                }
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
        .frame(maxWidth: .infinity)
        .glassEffect(GlassMaterial.regular, in: RoundedRectangle(cornerRadius: 24))
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
            
            VStack(spacing: 0) {
                ForEach(PortfolioData.holdings.prefix(4)) { asset in
                    assetRow(asset)
                    if asset.id != PortfolioData.holdings.prefix(4).last?.id {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 70)
                    }
                }
            }
            .glassEffect(GlassMaterial.regular, in: RoundedRectangle(cornerRadius: 28))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private func assetRow(_ asset: AssetHolding) -> some View {
        Button {
            selectedAsset = asset
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: asset.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Text(asset.initial)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.ticker)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                    Text(asset.company)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Sparkline placeholder
                SparklineView(data: asset.sparklineData, color: asset.isPositive ? .green : .red)
                    .frame(width: 56, height: 32)
                    .opacity(0.6)
                
                Spacer().frame(width: 20)
                
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
            
            VStack(spacing: 20) {
                ForEach(PortfolioData.activities.first?.items.prefix(4) ?? []) { activity in
                    activityRow(activity)
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
                    .foregroundColor(activity.color)
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

// MARK: - Subviews

struct AllHoldingsView: View {
    @Binding var isVisible: Bool
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
                Color.black
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
            VStack(spacing: 0) {
                ForEach(PortfolioData.holdings) { asset in
                    Button {
                        onSelect(asset)
                    } label: {
                        assetRow(asset)
                    }
                    if asset.id != PortfolioData.holdings.last?.id {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 70)
                    }
                }
            }
            .glassEffect(GlassMaterial.regular, in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private func assetRow(_ asset: AssetHolding) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: asset.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Text(asset.initial)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.ticker)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                Text(asset.company)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            SparklineView(data: asset.sparklineData, color: asset.isPositive ? .green : .red)
                .frame(width: 56, height: 32)
                .opacity(0.6)
            
            Spacer().frame(width: 20)
            
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
                Color.black
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
                ForEach(PortfolioData.activities) { group in
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
                    .foregroundColor(activity.color)
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
