import SwiftUI

struct AppRulesView: View {
    @State private var rules: [Rule] = [
        Rule(id: "ig", appName: "Instagram", appInitial: "I", gradientColors: [.orange, .pink, .purple], ticker: "META", rate: 0.10, timeSpan: 1, cap: 5.00, todaySpent: 3.50, isActive: true),
        Rule(id: "tt", appName: "TikTok", appInitial: "T", gradientColors: [Color.black], ticker: "BDNCE", rate: 0.25, timeSpan: 5, cap: 10.00, todaySpent: 10.00, isActive: true),
        Rule(id: "yt", appName: "YouTube", appInitial: "Y", gradientColors: [.red], ticker: "GOOGL", rate: 0.05, timeSpan: 15, cap: 2.00, todaySpent: 0.45, isActive: true)
    ]
    
    @State private var showAddModal = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    trackNewAppButton
                    
                    VStack(spacing: 20) {
                        ForEach($rules) { $rule in
                            RuleCardView(rule: $rule)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 84)
                .padding(.bottom, 120)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.08),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            stickyHeader
            
            if showAddModal {
                AddRuleModalView(isPresented: $showAddModal) { newRule in
                    rules.append(newRule)
                }
            }
            
            // Bottom Fade
            VStack {
                Spacer()
                LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 100)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
    
    private var stickyHeader: some View {
        VStack(spacing: 0) {
            headerSection
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
                    .ignoresSafeArea()
                )
                .overlay(
                    VStack {
                        Spacer()
                        Divider()
                            .background(Color.white.opacity(0.08))
                    }
                )
            
            // Sub-header shadow for depth
            LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 10)
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("App Rules")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
            }
            Spacer()
            
            balanceButton
        }
    }
    
    private var balanceButton: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("BALANCE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
                Text("$142.50")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            .shadow(color: .green.opacity(0.3), radius: 6)
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(Color(white: 0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    private var trackNewAppButton: some View {
        Button {
            withAnimation(.spring()) {
                showAddModal = true
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                }
                
                Text("Track New App")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Link an app to a stock ticker")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .background(Color.green.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
        }
    }
}
