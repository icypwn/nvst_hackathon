//
//  ContentView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI

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

// MARK: - Home View

struct ContentView: View {
    @State private var selectedTab = 0
    let tabs = ["Today", "This Week", "All Time"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    ringChartSection
                    tabPicker
                    sharesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
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
        let midR = (innerRadius + outerRadius) / 2
        let angularInset = cr > 0 ? Angle.radians(Double(cr / midR)) : .zero

        let adjustedStart = startAngle + angularInset
        let adjustedEnd = endAngle - angularInset

        guard adjustedEnd > adjustedStart else {
            var path = Path()
            let pt = pointOnCircle(center: center, radius: midR, angle: startAngle)
            path.addEllipse(in: CGRect(x: pt.x - cr, y: pt.y - cr, width: cr * 2, height: cr * 2))
            return path
        }

        var path = Path()

        let outerStart = pointOnCircle(center: center, radius: outerRadius, angle: adjustedStart)
        path.move(to: outerStart)

        path.addArc(center: center, radius: outerRadius, startAngle: adjustedStart, endAngle: adjustedEnd, clockwise: false)

        let endCapCenter = pointOnCircle(center: center, radius: midR, angle: adjustedEnd)
        path.addArc(center: endCapCenter, radius: cr, startAngle: adjustedEnd, endAngle: adjustedEnd + .degrees(180), clockwise: false)

        path.addArc(center: center, radius: innerRadius, startAngle: adjustedEnd, endAngle: adjustedStart, clockwise: true)

        let startCapCenter = pointOnCircle(center: center, radius: midR, angle: adjustedStart)
        path.addArc(center: startCapCenter, radius: cr, startAngle: adjustedStart + .degrees(180), endAngle: adjustedStart, clockwise: false)

        path.closeSubpath()
        return path
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
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
    let gapDegrees: Double = 4
    /// Adjust this to control endpoint roundness: 0 = flat, thickness/2 = fully round
    let cornerRadius: CGFloat = 0

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

// MARK: - Preview

#Preview {
    ContentView()
}
