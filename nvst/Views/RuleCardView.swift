import SwiftUI
import FamilyControls

struct RuleCardView: View {
    @Binding var rule: Rule
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                appIcon
                
                VStack(alignment: .leading, spacing: 6) {
                    if let token = rule.applicationToken {
                        Label(token)
                            .labelStyle(.titleOnly)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        HStack(spacing: 4) {
                            Text(rule.appName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("→ \(rule.ticker)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(white: 0.4))
                        }
                    }

                    summaryBadge
                }
                
                Spacer()

                // Expand chevron
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isExpanded ? .green : Color(white: 0.3))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(.bottom, 8)
            
            // Expanded Panel
            if isExpanded {
                VStack(spacing: 16) {
                    // Today's Investment Progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Today's Investment")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.5))
                            Spacer()
                            HStack(spacing: 2) {
                                Text("$\(String(format: "%.2f", rule.todaySpent))")
                                    .foregroundColor(.green)
                                Text("/ $\(String(format: "%.2f", rule.cap))")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 11, weight: .bold))
                        }
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(white: 0.15))
                                Capsule()
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * CGFloat(rule.progressPercent / 100))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.bottom, 8)
                    // Rate Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Investment Amount")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            Spacer()
                            Text("$\(String(format: "%.2f", rule.rate))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Slider(value: $rule.rate, in: 0.01...1.00, step: 0.01)
                            .accentColor(.green)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
                    
                    // Daily Limit
                    VStack(spacing: 8) {
                        Text("DAILY LIMIT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(white: 0.4))
                            .tracking(1)

                        HStack {
                            stepperButton(systemName: "minus") {
                                if rule.cap > 1 { rule.cap -= 1 }
                            }
                            Text("$\(Int(rule.cap))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                                .frame(width: 45)
                            stepperButton(systemName: "plus") {
                                rule.cap += 1
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .background(
            ZStack {
                Color(white: 0.08).opacity(0.5)
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .opacity(rule.isActive ? 1 : 0.6)
        .grayscale(rule.isActive ? 0 : 0.8)
    }
    
    @ViewBuilder
    private var appIcon: some View {
        if let token = rule.applicationToken {
            Label(token)
                .labelStyle(.iconOnly)
                .scaleEffect(1.8)
                .frame(width: 40, height: 40)
        } else {
            ZStack {
                if rule.gradientColors.count > 1 {
                    LinearGradient(colors: rule.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    rule.gradientColors.first ?? .clear
                }
            }
            .frame(width: 40, height: 40)
            .cornerRadius(12)
            .overlay(
                Text(rule.appInitial)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            )
        }
    }
    
    private var summaryBadge: some View {
        HStack(spacing: 4) {
            Text("$\(String(format: "%.2f", rule.rate))")
            Text("/")
            Text(formatTime(rule.timeSpan))
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.green)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.green.opacity(0.1))
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }
    
    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: systemName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes == 60 { return "1 hr" }
        return "\(minutes) min"
    }
    
}
