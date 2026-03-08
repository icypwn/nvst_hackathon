import SwiftUI
import FamilyControls

struct AddRuleModalView: View {
    @Binding var isPresented: Bool
    var selection: FamilyActivitySelection
    var onAdd: (Rule) -> Void

    @State private var rate: Double = 0.10
    @State private var cap: Double = 5

    let caps = [5.0, 10.0, 20.0, 50.0]

    var body: some View {
        VStack(spacing: 0) {
            // Notch
            Capsule()
                .fill(Color(white: 0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    bridgeVisualizer

                    sectionTitle("CONFIGURATION")
                    configBox
                    activateButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(white: 0.08).ignoresSafeArea())
    }

    private var bridgeVisualizer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.5))

            HStack(spacing: 16) {
                // Source
                VStack(spacing: 6) {
                    if let token = selection.applicationTokens.first {
                        Label(token)
                            .labelStyle(.iconOnly)
                            .scaleEffect(2.6)
                            .frame(width: 64, height: 64)
                            .offset(y: 6)

                        Label(token)
                            .labelStyle(.titleOnly)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }

                // Flow Line
                ZStack {
                    Capsule()
                        .fill(Color(white: 0.1))
                }
                .frame(height: 6)

                // Destination
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(white: 0.2), style: StrokeStyle(lineWidth: 2, dash: [4]))
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(Color(white: 0.3))
                    }
                    .frame(width: 64, height: 64)

                    Text("Select Stock")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(white: 0.3))
                }
            }
            .padding(24)
        }
        .frame(height: 140)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.05), lineWidth: 1))
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
                            .foregroundColor(.green)
                        Text("/ 1 min")
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 16, weight: .bold))
                }
                Slider(value: $rate, in: 0.01...1.00, step: 0.01)
                    .accentColor(.green)
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
            if let token = selection.applicationTokens.first {
                let newRule = Rule(
                    id: UUID().uuidString,
                    appName: "",
                    appInitial: "",
                    gradientColors: [.gray],
                    ticker: "",
                    rate: rate,
                    timeSpan: 1,
                    cap: cap,
                    todaySpent: 0,
                    isActive: true,
                    applicationToken: token
                )
                onAdd(newRule)
            }
            isPresented = false
        } label: {
            Text("Add App")
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
