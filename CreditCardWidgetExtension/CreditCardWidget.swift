import WidgetKit
import SwiftUI
import Charts

// MARK: - Shared constant

private let appGroupID = "group.creditcardtracker"

// MARK: - Data Models

struct WidgetCategory: Codable, Identifiable {
    let id: String
    let name: String
    let color: String    // hex "#RRGGBB"
    let symbol: String   // Phosphor icon name
    let limitCents: Int?
    let spentCents: Int
    let favorite: Bool?
}

private struct WidgetDashboardResponse: Codable {
    let totalSpentCents: Int
    let categories: [WidgetCategory]
}

// MARK: - Timeline Entry

struct DashboardEntry: TimelineEntry {
    let date: Date
    let month: String
    let totalSpentCents: Int
    let totalBudgetCents: Int
    let categories: [WidgetCategory]

    static let placeholder = DashboardEntry(
        date: Date(),
        month: "2026-03",
        totalSpentCents: 154320,
        totalBudgetCents: 300000,
        categories: [
            WidgetCategory(id: "1", name: "Alimentação",  color: "#FF6B35", symbol: "fork-knife",    limitCents: 80000,  spentCents: 62000, favorite: true),
            WidgetCategory(id: "2", name: "Transporte",   color: "#4ECDC4", symbol: "car",           limitCents: 40000,  spentCents: 28000, favorite: true),
            WidgetCategory(id: "3", name: "Compras",      color: "#45B7D1", symbol: "shopping-cart", limitCents: 60000,  spentCents: 45000, favorite: false),
            WidgetCategory(id: "4", name: "Saúde",        color: "#96CEB4", symbol: "heart",         limitCents: 30000,  spentCents: 18500, favorite: false),
        ]
    )
}

// MARK: - Timeline Provider

struct DashboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> DashboardEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (DashboardEntry) -> Void) {
        Task {
            let entry = (try? await fetchEntry()) ?? .placeholder
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DashboardEntry>) -> Void) {
        Task {
            let entry = (try? await fetchEntry()) ?? .placeholder
            let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    private func selectedMonth() -> String {
        let stored = UserDefaults(suiteName: appGroupID)?.string(forKey: "lastSelectedMonth")
        if let stored { return stored }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        return f.string(from: Date())
    }

    private func fetchEntry() async throws -> DashboardEntry {
        let month = selectedMonth()
        var comps = URLComponents(string: "https://cartao-danilo.vercel.app/api/dashboard")!
        comps.queryItems = [
            URLQueryItem(name: "month",    value: month),
            URLQueryItem(name: "page",     value: "1"),
            URLQueryItem(name: "pageSize", value: "1"),
        ]
        var request = URLRequest(url: comps.url!)
        request.setValue(
            "Bearer 63e30757fbcc466867e7caf3bded14ab07d333edfd30a43a9492a0f6ec01682c",
            forHTTPHeaderField: "Authorization"
        )
        let (data, _) = try await URLSession.shared.data(for: request)
        let response  = try JSONDecoder().decode(WidgetDashboardResponse.self, from: data)

        let budget = response.categories.compactMap(\.limitCents).reduce(0, +)
        let sorted = response.categories
            .filter { $0.spentCents > 0 }
            .sorted {
                let aFav = $0.favorite ?? false
                let bFav = $1.favorite ?? false
                if aFav != bFav { return aFav }
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }

        return DashboardEntry(
            date: Date(), month: month,
            totalSpentCents: response.totalSpentCents,
            totalBudgetCents: budget,
            categories: sorted
        )
    }
}

// MARK: - Widget Definition

@main
struct CreditCardWidget: Widget {
    let kind = "CreditCardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DashboardProvider()) { entry in
            CreditCardWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cartão de Crédito")
        .description("Acompanhe seus gastos mensais por categoria.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View Router

struct CreditCardWidgetEntryView: View {
    let entry: DashboardEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Donut + percentual)

struct SmallWidgetView: View {
    let entry: DashboardEntry

    private var ratio: Double {
        guard entry.totalBudgetCents > 0 else { return 0 }
        return Double(entry.totalSpentCents) / Double(entry.totalBudgetCents)
    }
    private var accentColor: Color {
        if ratio >= 0.9 { return .red }
        if ratio >= 0.7 { return Color(red: 0.96, green: 0.65, blue: 0.14) }
        return .blue
    }
    private struct Slice: Identifiable { let id: String; let value: Double; let color: Color }
    private var slices: [Slice] {
        let hasBudget = entry.totalBudgetCents > 0
        if !hasBudget { return [Slice(id: "s", value: 1, color: .blue)] }
        if ratio >= 1  { return [Slice(id: "s", value: 1, color: accentColor)] }
        return [
            Slice(id: "s", value: Double(entry.totalSpentCents),                           color: accentColor),
            Slice(id: "r", value: Double(entry.totalBudgetCents - entry.totalSpentCents),   color: Color.secondary.opacity(0.2)),
        ]
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(monthLabel(entry.month))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            ZStack {
                Chart(slices) { s in
                    SectorMark(
                        angle: .value("Valor", s.value),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(s.color)
                }

                VStack(spacing: 1) {
                    if entry.totalBudgetCents > 0 {
                        Text("\(Int(ratio * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                        Text("do limite")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("sem\nlimite")
                            .font(.system(size: 10, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 72)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
    }
}

// MARK: - Medium Widget (lista estilo Bolsa, sem donut)

struct MediumWidgetView: View {
    let entry: DashboardEntry

    private var visibleCategories: [WidgetCategory] {
        Array(entry.categories.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho
            Text(monthLabel(entry.month))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            // Linhas de categoria — espaço igual entre elas
            ForEach(Array(visibleCategories.enumerated()), id: \.element.id) { idx, cat in
                if idx > 0 {
                    Divider()
                        .padding(.leading, 52)
                        .opacity(0.35)
                }
                CategoryRow(category: cat)
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: WidgetCategory

    private var ratio: Double {
        guard let limit = category.limitCents, limit > 0 else { return 0 }
        return min(Double(category.spentCents) / Double(limit), 1.0)
    }
    private var hasLimit: Bool {
        (category.limitCents ?? 0) > 0
    }
    private var barColor: Color {
        if ratio >= 0.9 { return .red }
        if ratio >= 0.7 { return Color(red: 0.96, green: 0.65, blue: 0.14) }
        return .green
    }
    private var catColor: Color {
        Color(hex: category.color) ?? .blue
    }

    var body: some View {
        HStack(spacing: 10) {
            // Ícone
            ZStack {
                Circle()
                    .fill(catColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: phosphorToSF(category.symbol))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(catColor)
            }

            // Nome + barra de progresso
            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                if hasLimit {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 3)
                            Capsule()
                                .fill(barColor)
                                .frame(width: geo.size.width * ratio, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }

            Spacer(minLength: 8)

            // Percentual
            if hasLimit {
                Text("\(Int(ratio * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(barColor)
                    .frame(minWidth: 38, alignment: .trailing)
            } else {
                Text("—")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 7)
    }
}

// MARK: - Helpers

private func monthLabel(_ month: String) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM"
    f.locale = Locale(identifier: "pt_BR")
    guard let date = f.date(from: month) else { return month }
    let out = DateFormatter()
    out.dateFormat = "MMMM yyyy"
    out.locale = Locale(identifier: "pt_BR")
    return out.string(from: date).capitalized
}

private func phosphorToSF(_ name: String) -> String {
    let cleaned = name.hasPrefix("phosphor:") ? String(name.dropFirst(9)) : name
    let map: [String: String] = [
        "fork-knife": "fork.knife", "car": "car", "car-simple": "car",
        "shopping-cart": "cart", "cart": "cart", "heart": "heart",
        "credit-card": "creditcard", "house": "house", "buildings": "building.2",
        "airplane": "airplane", "train": "tram", "bus": "bus",
        "coffee": "cup.and.saucer", "wine": "wineglass",
        "device-mobile": "iphone", "laptop": "laptopcomputer",
        "television": "tv", "headphones": "headphones", "camera": "camera",
        "game-controller": "gamecontroller", "shirt": "tshirt", "bag": "bag",
        "stethoscope": "stethoscope", "pill": "pills", "dumbbell": "dumbbell",
        "bicycle": "bicycle", "leaf": "leaf", "sun": "sun.max",
        "music-note": "music.note", "book": "book",
        "graduation-cap": "graduationcap", "gift": "gift",
        "currency-dollar": "dollarsign", "bank": "building.columns",
        "receipt": "receipt", "gas-pump": "fuelpump", "map-pin": "mappin",
        "globe": "globe", "phone": "phone", "envelope": "envelope",
        "shield": "shield", "user": "person", "users": "person.2",
        "paw-print": "pawprint", "dog": "pawprint", "cat": "pawprint",
        "briefcase": "briefcase", "wallet": "wallet.pass",
        "shopping-bag": "bag", "wifi-high": "wifi",
        "tag": "tag", "star": "star", "gear": "gear",
        "calendar": "calendar", "clock": "clock",
        "chart-bar": "chart.bar", "fire": "flame",
        "lightning": "bolt", "drop": "drop",
    ]
    return map[cleaned] ?? "tag"
}

extension Color {
    init?(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6, let v = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >>  8) & 0xFF) / 255,
            blue:  Double( v        & 0xFF) / 255
        )
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    CreditCardWidget()
} timeline: {
    DashboardEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    CreditCardWidget()
} timeline: {
    DashboardEntry.placeholder
}
