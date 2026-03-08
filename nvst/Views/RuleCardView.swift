import SwiftUI
import FamilyControls

struct RuleCardView: View {
    @Binding var rule: Rule
    @State private var showDetailSheet = false
    @State private var editSelection = FamilyActivitySelection()
    
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

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(white: 0.3))
            }
            .padding(.bottom, 8)
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
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .onTapGesture {
            if let token = rule.applicationToken {
                editSelection = FamilyActivitySelection()
                editSelection.applicationTokens.insert(token)
            }
            showDetailSheet = true
        }
        .opacity(rule.isActive ? 1 : 0.6)
        .grayscale(rule.isActive ? 0 : 0.8)
        .sheet(isPresented: $showDetailSheet) {
            AddRuleModalView(isPresented: $showDetailSheet, selection: $editSelection) { updatedRule in
                rule.rate = updatedRule.rate
                rule.cap = updatedRule.cap
            }
        }
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
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes == 60 { return "1 hr" }
        return "\(minutes) min"
    }
    
}
