import Foundation

struct CategoryData: Codable, Identifiable {
    let id: String
    let name: String
    let color: String   // hex "#RRGGBB"
    let symbol: String  // Phosphor icon name
    let limitCents: Int?
    let spentCents: Int
}
