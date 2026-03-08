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
                        HStack(spacing: 6) {
                            Label(token)
                                .labelStyle(.titleOnly)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            if !rule.ticker.isEmpty {
                                Text("→ \(rule.ticker)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text(rule.appName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            if !rule.ticker.isEmpty {
                                Text("→ \(rule.ticker)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    summaryBadge
                }
                
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(white: 0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.1))
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
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
            AddRuleModalView(isPresented: $showDetailSheet, selection: $editSelection, onAdd: { updatedRule in
                rule.rate = updatedRule.rate
                rule.cap = updatedRule.cap
                rule.ticker = updatedRule.ticker
                rule.appName = updatedRule.appName
            }, existingRule: rule)
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
            stockLogo(ticker: rule.ticker, size: 40)
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
