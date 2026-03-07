import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct SettingsView: View {
    @State private var showLogoutModal = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Settings")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(-0.5)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 16)
                        .padding(.bottom, -8)
                        
                        NavigationLink(destination: ProfileEditView()) {
                            ProfileCard()
                        }
                        
                        SettingsGroup {
                            NavigationLink(destination: NotificationsView()) {
                                SettingsRow(icon: "bell.fill", color: Color(hex: "FF3B30"), title: "Notifications")
                            }
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                            SettingsRow(icon: "moon.fill", color: Color(hex: "5E5CE6"), title: "Display & Appearance", value: "Dark", showChevron: true)
                        }
                        
                        SettingsGroup {
                            NavigationLink(destination: LinkedFundingView()) {
                                SettingsRow(icon: "building.columns.fill", color: Color(hex: "34C759"), title: "Linked Funding", value: "Chase Bank")
                            }
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                            SettingsRow(icon: "chart.pie.fill", color: Color(hex: "FF9500"), title: "Trading Limits", showChevron: true)
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                            SettingsRow(icon: "doc.text.fill", color: Color(hex: "007AFF"), title: "Tax Documents", showChevron: true)
                        }
                        
                        SettingsGroup {
                            SettingsRow(icon: "faceid", color: Color(hex: "32ADE6"), title: "Face ID & Passcode", showChevron: true)
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                            SettingsRow(icon: "checkmark.shield.fill", color: Color(hex: "8E8E93"), title: "Privacy Settings", showChevron: true)
                        }
                        
                        SettingsGroup {
                            NavigationLink(destination: LegalView(title: "Privacy Policy")) {
                                SettingsRow(icon: "lock.fill", color: Color(hex: "AF52DE"), title: "Privacy Policy")
                            }
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                            NavigationLink(destination: LegalView(title: "Terms & Conditions")) {
                                SettingsRow(icon: "book.fill", color: Color(hex: "AF52DE"), title: "Terms & Conditions")
                            }
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 54)
                            SettingsRow(icon: "questionmark.circle.fill", color: Color(hex: "FF2D55"), title: "Help Center", showChevron: true)
                        }
                        
                        SettingsGroup {
                            Button {
                                showLogoutModal = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Log Out")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "FF3B30"))
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        
                        Text("TimeInvest v2.4.0 (102)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.top, 6)
                            .padding(.bottom, 120)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("", isPresented: $showLogoutModal) {
                Button("Log Out", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?\nBackground investing engines will remain active.")
            }
        }
    }
}

struct SettingsGroup<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    var icon: String
    var color: Color
    var title: String
    var value: String? = nil
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                color
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
            .frame(width: 30, height: 30)
            .cornerRadius(8)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "8E8E93"))
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct ProfileCard: View {
    var body: some View {
        SettingsGroup {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "A855F7"), Color(hex: "EC4899")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    AsyncImage(url: URL(string: "https://api.dicebear.com/7.x/notionists/png?seed=Alex&backgroundColor=transparent")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color(hex: "1C1C1E")
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alex Rivera")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("alex.riv@email.com")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "8E8E93"))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "Alex Rivera"
    @State private var email: String = "alex.riv@email.com"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        ZStack {
                            AsyncImage(url: URL(string: "https://api.dicebear.com/7.x/notionists/png?seed=Alex&backgroundColor=transparent")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color(hex: "1C1C1E")
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        Button {
                            
                        } label: {
                            Text("Edit Picture")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "0A84FF"))
                        }
                    }
                    .padding(.top, 24)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SettingsGroup {
                            HStack {
                                Text("Name")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .frame(width: 100, alignment: .leading)
                                TextField("", text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.white)
                                    .tint(.white)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            
                            Divider().background(Color.white.opacity(0.05))
                            
                            HStack {
                                Text("Email")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .frame(width: 100, alignment: .leading)
                                TextField("", text: $email)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .tint(.white)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        
                        Text("Your personal information is securely stored.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                    .foregroundColor(Color(hex: "0A84FF"))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "0A84FF"))
                }
            }
        }
    }
}

struct LinkedFundingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("CONNECTED ACCOUNTS")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .padding(.leading, 16)
                        .padding(.top, 24)
                        .padding(.bottom, -8)
                    
                    SettingsGroup {
                        HStack(spacing: 16) {
                            ZStack {
                                Color.white
                                    .cornerRadius(4)
                                Rectangle()
                                    .fill(Color(hex: "117ACA"))
                                    .frame(width: 24, height: 24)
                                    .cornerRadius(2)
                                    .rotationEffect(.degrees(45))
                            }
                            .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("JPMorgan Chase")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Checking •••• 4210")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: "30D158"))
                                .font(.system(size: 20, weight: .medium))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    
                    SettingsGroup {
                        Button {
                            
                        } label: {
                            HStack {
                                Spacer()
                                Text("Add New Account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "0A84FF"))
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Secured by Plaid")
                        Spacer()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.top, 16)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Linked Funding")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                    .foregroundColor(Color(hex: "0A84FF"))
                }
            }
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var push1 = true
    @State private var push2 = true
    @State private var push3 = true
    @State private var email1 = false
    @State private var email2 = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INVESTMENT ACTIVITY")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.leading, 16)
                        
                        SettingsGroup {
                            ToggleRow(title: "Auto-Invest Executed", isOn: $push1)
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
                            ToggleRow(title: "Daily Limit Reached", isOn: $push2)
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
                            ToggleRow(title: "Dividends Received", isOn: $push3)
                        }
                    }
                    .padding(.top, 24)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SUMMARIES & NEWS")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.leading, 16)
                        
                        SettingsGroup {
                            ToggleRow(title: "Daily Portfolio Summary", isOn: $email1)
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
                            ToggleRow(title: "Weekly Time Report", isOn: $email2)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                    .foregroundColor(Color(hex: "0A84FF"))
                }
            }
        }
    }
}

struct ToggleRow: View {
    var title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "30D158"))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    var title: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Last Updated: March 2024")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Acceptance of Terms")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("By utilizing the TimeInvest platform and linking your device's screen-time data API, you agree to the automated purchase of fractional shares based on your configured activity triggers.")
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. Brokerage Services")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("All trading and custodial services are provided by our partner brokerage API. TimeInvest acts as a technology intermediary between your device activity logs and your linked brokerage account.")
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3. Risk Disclosure")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("All investments involve risk, including the possible loss of principal. Past performance of any security, market, or financial product does not guarantee future results. Automated investing does not protect against loss in a declining market.")
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("4. Data Privacy")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("We securely process your application usage tokens to execute trades. We do not sell your screen time data or personal identifying information to third parties.")
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                }
                .foregroundColor(Color(hex: "EBEBF5").opacity(0.6))
                .padding(.horizontal, 24)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                    .foregroundColor(Color(hex: "0A84FF"))
                }
            }
        }
    }
}
