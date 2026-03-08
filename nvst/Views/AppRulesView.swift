import SwiftUI
import FamilyControls

struct AppRulesView: View {
    @State private var rules: [Rule] = []
    
    @State private var showActivityPicker = false
    @State private var showAddModal = false
    @State private var newSelection = FamilyActivitySelection()

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            if rules.isEmpty {
                emptyState
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach($rules) { $rule in
                        RuleCardView(rule: $rule)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 84)
                .padding(.bottom, 120)
            }
            .opacity(rules.isEmpty ? 0 : 1)
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
            
            // FAB - Add Rule
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        newSelection = FamilyActivitySelection()
                        showActivityPicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 56, height: 56)
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .shadow(color: .green.opacity(0.4), radius: 10, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
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
        .sheet(isPresented: $showActivityPicker, onDismiss: {
            if !newSelection.applicationTokens.isEmpty {
                showAddModal = true
            }
        }) {
            ActivityPickerView(selection: $newSelection) {
                showActivityPicker = false
            }
        }
        .sheet(isPresented: $showAddModal) {
            AddRuleModalView(isPresented: $showAddModal, selection: $newSelection) { newRule in
                rules.append(newRule)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingRuleCreated)) { notification in
            if let rule = notification.object as? Rule {
                rules.append(rule)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            HStack(spacing: 32) {
                FloatingAppIcon(name: "YouTube", delay: 0)
                    .rotationEffect(.degrees(-10))
                FloatingAppIcon(name: "Snapchat", delay: 0.3)
                    .offset(y: -20)
                FloatingAppIcon(name: "Instagram", delay: 0.6)
                    .rotationEffect(.degrees(10))
            }
            .offset(y: -8)

            Text("No apps yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text("Tap + to select an app")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(white: 0.4))

            Spacer()
        }
        .frame(maxWidth: .infinity)
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
        }
    }
}

struct FloatingAppIcon: View {
    let name: String
    let delay: Double
    @State private var floating = false

    var body: some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
            )
            .offset(y: floating ? -8 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(delay)) {
                    floating = true
                }
            }
    }
}
