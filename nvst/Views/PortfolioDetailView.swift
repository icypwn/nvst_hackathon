import SwiftUI

struct PortfolioDetailView: View {
    let asset: AssetHolding
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    handleBar
                    headerSection
                    marketValueSection
                    statsGrid
                    accumulationLogSection
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.5))
            .frame(width: 48, height: 6)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: asset.iconColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.4), radius: 15)
                Text(asset.appInitial)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.appName)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("\(asset.ticker) · \(asset.company)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1).cornerRadius(20))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
    
    private var marketValueSection: some View {
        VStack(spacing: 4) {
            Text("MARKET VALUE")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.gray)
                .tracking(1.5)
            
            Text("$\(String(format: "%.2f", asset.value))")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text("\(asset.isPositive ? "↑" : "↓") \(String(format: "%.1f", asset.returnPct))%")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(asset.isPositive ? .green : .red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(asset.isPositive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
        }
        .padding(.bottom, 40)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statItem(label: "Screen Time", value: asset.formattedTime)
            statItem(label: "Avg Cost", value: "$\(String(format: "%.2f", asset.avgCost))")
            statItem(label: "Invested", value: "$\(String(format: "%.2f", asset.totalInvested))")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private func statItem(label: String, value: String, valueColor: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(valueColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05).cornerRadius(16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    private var accumulationLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accumulation Log")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                // Mock log entry
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Instagram Converted")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("3 min usage • 14m ago")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+$0.30")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.green)
                        Text("@ $485.32")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.3))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.03).cornerRadius(16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
            .padding(.horizontal, 24)
        }
    }
}
