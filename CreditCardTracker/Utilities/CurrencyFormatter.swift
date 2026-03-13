import Foundation

enum CurrencyFormatter {
    private static let fullFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        f.currencyCode = "BRL"
        return f
    }()

    static func format(cents: Int) -> String {
        let value = Double(cents) / 100.0
        return fullFormatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }

    static func formatShort(value: Double) -> String {
        if abs(value) >= 1000 {
            let k = value / 1000.0
            let formatted = String(format: "%.1f", k)
                .replacingOccurrences(of: ".", with: ",")
            return "\(formatted)k"
        }
        return String(format: "%.0f", value)
    }
}
