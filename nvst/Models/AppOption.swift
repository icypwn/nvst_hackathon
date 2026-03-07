import SwiftUI

struct AppOption: Identifiable {
    let id: String
    let name: String
    let initial: String
    let color: Color
    let ticker: String
    let stockName: String
    var gradientColors: [Color]? = nil
}
