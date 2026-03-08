import SwiftUI
import ManagedSettings
import FamilyControls

struct AddRuleModalView: View {
    @Binding var isPresented: Bool
    @Binding var selection: FamilyActivitySelection
    var onAdd: (Rule) -> Void
    var existingRule: Rule? = nil

    @State private var rate: Double = 0.10
    @State private var cap: Double = 5
    @State private var tickerSearch: String = ""
    @State private var selectedTicker: TickerSearchResult? = nil
    @State private var searchResults: [TickerSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>? = nil

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
                    Text("Configure your app")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("SETUP")
                        bridgeVisualizer
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("STOCK TICKER")
                        tickerSearchField
                        if !searchResults.isEmpty && selectedTicker == nil {
                            tickerResultsList
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("CONFIGURATION")
                        configBox
                    }
                    activateButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(white: 0.08).ignoresSafeArea())
        .onAppear {
            if let rule = existingRule {
                rate = rule.rate
                cap = rule.cap
                if !rule.ticker.isEmpty {
                    tickerSearch = rule.ticker
                    selectedTicker = TickerSearchResult(
                        symbol: rule.ticker,
                        name: rule.appName,
                        exchange: "",
                        fractionable: true
                    )
                }
            }
        }
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
                FlowingLine()
                    .frame(height: 6)

                // Destination
                VStack(spacing: 12) {
                    if let ticker = selectedTicker {
                        AsyncImage(url: URL(string: "https://api.elbstream.com/logos/symbol/\(ticker.symbol)?format=png&size=200")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            default:
                                ZStack {
                                    Color.green.opacity(0.15)
                                    Text(ticker.symbol)
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                        )

                        Text(ticker.symbol)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    } else {
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
            }
            .padding(24)
        }
        .frame(height: 140)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    private var tickerSearchField: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let ticker = selectedTicker {
                    // Show selected ticker chip
                    HStack(spacing: 6) {
                        Text(ticker.symbol)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.green)
                        Text(ticker.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                            .lineLimit(1)
                        Spacer()
                        Button {
                            selectedTicker = nil
                            tickerSearch = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(white: 0.4))
                                .font(.system(size: 18))
                        }
                    }
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(white: 0.4))
                        .font(.system(size: 16))
                    TextField("Search ticker (e.g. AAPL)", text: $tickerSearch)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: tickerSearch) { newValue in
                            performSearch(query: newValue)
                        }
                    if isSearching {
                        ProgressView()
                            .tint(.green)
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding(16)
            .background(Color(white: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedTicker != nil ? Color.green.opacity(0.4) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private var tickerResultsList: some View {
        VStack(spacing: 0) {
            ForEach(searchResults) { result in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTicker = result
                        tickerSearch = result.symbol
                        searchResults = []
                    }
                } label: {
                    HStack(spacing: 12) {
                        // Ticker badge
                        Text(result.symbol)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.green)
                            .frame(width: 60, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text(result.exchange)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(white: 0.4))
                                if result.fractionable {
                                    Text("Fractional")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.green.opacity(0.8))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(3)
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: "plus.circle")
                            .font(.system(size: 18))
                            .foregroundColor(Color(white: 0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if result.id != searchResults.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.05))
                        .padding(.leading, 88)
                }
            }
        }
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .transition(.opacity)
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
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$\(String(format: "%.2f", rate))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                        Text("/ min")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                Slider(value: $rate, in: 0.01...1.00, step: 0.01)
                    .accentColor(.green)
            }

            Divider().background(Color.white.opacity(0.05))

            // Daily Limit
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Limit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$\(Int(cap)).00")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                        Text("/ day")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
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
                let ticker = selectedTicker?.symbol ?? tickerSearch.uppercased()
                let encodedToken = encodeToken(token)
                let newRule = Rule(
                    id: UUID().uuidString,
                    appName: selectedTicker?.name ?? "",
                    appInitial: String(ticker.prefix(1)),
                    ticker: ticker,
                    rate: rate,
                    timeSpan: 1,
                    cap: cap,
                    todaySpent: 0,
                    isActive: true,
                    applicationToken: token
                )
                onAdd(newRule)
                if let encodedToken {
                    savePreference(appName: encodedToken, ticker: ticker)
                }
            }
            isPresented = false
        } label: {
            Text("Confirm App")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(selectedTicker != nil ? .black : Color(white: 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: selectedTicker != nil
                            ? [Color.green, Color.green.opacity(0.8)]
                            : [Color(white: 0.15), Color(white: 0.12)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: selectedTicker != nil ? .green.opacity(0.3) : .clear, radius: 10, y: 4)
        }
        .disabled(selectedTicker == nil && tickerSearch.isEmpty)
    }

    // MARK: - Networking

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard query.count >= 1 else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            // Debounce 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }

            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "http://149.125.202.134:8000/api/search-ticker?q=\(encoded)") else {
                await MainActor.run { isSearching = false }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(TickerSearchResponse.self, from: data)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        searchResults = decoded.results
                        isSearching = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { isSearching = false }
                }
            }
        }
    }

    private func savePreference(appName: String, ticker: String) {
        guard let url = URL(string: "http://149.125.202.134:8000/api/preferences") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "app_name": appName,
            "investment_rate_per_hour": rate * 60,
            "ticker": ticker
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Failed to save preference: \(error)")
            }
        }.resume()
    }

    private func encodeToken(_ token: ApplicationToken) -> String? {
        guard let data = try? JSONEncoder().encode(token) else { return nil }
        return data.base64EncodedString()
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
                                .init(color: .green.opacity(0.3), location: 0.3),
                                .init(color: .green.opacity(0.7), location: 0.5),
                                .init(color: .green.opacity(0.3), location: 0.7),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: -geo.size.width * 0.7 + (geo.size.width * 1.8 * phase))
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
