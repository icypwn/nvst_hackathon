import SwiftUI

struct AddRuleModalView: View {
    @Binding var isPresented: Bool
    var onAdd: (Rule) -> Void
    
    @State private var selectedApp: AppOption?
    @State private var rate: Double = 0.10
    @State private var frequency: Int = 1
    @State private var cap: Double = 5
    
    let availableApps = [
        AppOption(id: "nflx", name: "Netflix", initial: "N", color: .red, ticker: "NFLX", stockName: "Netflix Inc."),
        AppOption(id: "x", name: "X", initial: "𝕏", color: .black, ticker: "TSLA", stockName: "Tesla"),
        AppOption(id: "rdt", name: "Reddit", initial: "R", color: .orange, ticker: "RDDT", stockName: "Reddit Inc."),
        AppOption(id: "spt", name: "Spotify", initial: "S", color: .green, ticker: "SPOT", stockName: "Spotify")
    ]
    
    let frequencies = [1, 5, 15, 30, 60]
    let caps = [5.0, 10.0, 20.0, 50.0]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            // Modal Sheet
            VStack(spacing: 0) {
                pullHandle
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        modalHeader
                        
                        bridgeVisualizer
                        
                        sectionTitle("1. SELECT TRIGGER APP")
                        appGrid
                        
                        if selectedApp != nil {
                            VStack(alignment: .leading, spacing: 24) {
                                sectionTitle("2. BASE CONFIGURATION")
                                configBox
                                activateButton
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.85)
            .background(Color(white: 0.08))
            .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
            .overlay(
                RoundedCorner(radius: 40, corners: [.topLeft, .topRight])
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.8), radius: 30, y: -20)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private var pullHandle: some View {
        Capsule()
            .fill(Color(white: 0.3))
            .frame(width: 48, height: 6)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    private var modalHeader: some View {
        HStack {
            Text("New Engine")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                withAnimation { isPresented = false }
            } label: {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.gray))
            }
        }
        .padding(.vertical, 8)
    }
    
    private var bridgeVisualizer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.5))
            
            if selectedApp != nil {
                LinearGradient(colors: [.green.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            
            HStack(spacing: 16) {
                // Source
                VStack(spacing: 12) {
                    ZStack {
                        if let app = selectedApp {
                            app.color
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Text(app.initial)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color(white: 0.2), style: StrokeStyle(lineWidth: 2, dash: [4]))
                            Image(systemName: "smartphone")
                                .font(.system(size: 24))
                                .foregroundColor(Color(white: 0.3))
                        }
                    }
                    .frame(width: 64, height: 64)
                    
                    Text(selectedApp?.name ?? "Select App")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(selectedApp == nil ? Color(white: 0.3) : .gray)
                }
                
                // Flow Line
                ZStack {
                    Capsule()
                        .fill(Color(white: 0.1))
                    
                    if selectedApp != nil {
                        FlowingLine()
                            .mask(Capsule())
                    }
                }
                .frame(height: 6)
                
                // Destination
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selectedApp == nil ? Color(white: 0.2) : Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4]))
                        
                        if let app = selectedApp {
                            VStack(spacing: 2) {
                                Text(app.ticker)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Image(systemName: "line.chart.pro.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                        } else {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 24))
                                .foregroundColor(Color(white: 0.3))
                        }
                    }
                    .frame(width: 64, height: 64)
                    
                    Text(selectedApp?.stockName ?? "Auto-Matched")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(selectedApp == nil ? Color(white: 0.3) : .gray)
                }
            }
            .padding(24)
        }
        .frame(height: 140)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    private var appGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(availableApps) { app in
                Button {
                    withAnimation(.spring()) {
                        selectedApp = app
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            app.color
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Text(app.initial)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        
                        Text(app.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedApp?.id == app.id ? Color.green.opacity(0.1) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedApp?.id == app.id ? Color.green : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(selectedApp?.id == app.id ? 0.95 : 1.0)
                }
            }
        }
    }
    
    private var configBox: some View {
        VStack(spacing: 20) {
            // Rate Slider
            VStack(spacing: 12) {
                HStack {
                    Text("Investment Rate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                    HStack(spacing: 2) {
                        Text("$\(String(format: "%.2f", rate))")
                            .foregroundColor(.white)
                        Text("/ 1 min")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 16, weight: .bold))
                }
                Slider(value: $rate, in: 0.01...1.00, step: 0.01)
                    .accentColor(.green)
            }
            
            Divider().background(Color.white.opacity(0.05))
            
            // Frequency
            VStack(alignment: .leading, spacing: 12) {
                Text("Frequency")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.6))
                
                HStack(spacing: 8) {
                    ForEach(frequencies, id: \.self) { freq in
                        Button {
                            frequency = freq
                        } label: {
                            Text(freq == 60 ? "1h" : "\(freq)m")
                                .font(.system(size: 13, weight: frequency == freq ? .bold : .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(frequency == freq ? Color(white: 0.25) : Color(white: 0.12))
                                .foregroundColor(frequency == freq ? .white : Color(white: 0.5))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.05))
            
            // Daily Limit
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Daily Limit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                    Text("$\(Int(cap)).00")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 8) {
                    ForEach(caps, id: \.self) { amount in
                        Button {
                            cap = amount
                        } label: {
                            Text("$\(Int(amount))")
                                .font(.system(size: 14, weight: cap == amount ? .bold : .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(cap == amount ? Color.green : Color(white: 0.12))
                                .foregroundColor(cap == amount ? .black : .white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    private var activateButton: some View {
        Button {
            if let app = selectedApp {
                let newRule = Rule(
                    id: app.id,
                    appName: app.name,
                    appInitial: app.initial,
                    gradientColors: [app.color],
                    ticker: app.ticker,
                    rate: rate,
                    timeSpan: frequency,
                    cap: cap,
                    todaySpent: 0,
                    isActive: true
                )
                onAdd(newRule)
                withAnimation { isPresented = false }
            }
        } label: {
            Text("Initialize Engine")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.3), radius: 10, y: 4)
        }
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color(white: 0.4))
            .tracking(1.5)
    }
}

// Helper Views
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct FlowingLine: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(Color(white: 0.1))
                
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .green, location: 0.5),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.5 + (geo.size.width * 1.5 * phase))
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
