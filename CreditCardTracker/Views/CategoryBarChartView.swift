import SwiftUI

struct CategoryBarChartView: View {
    let categories: [CategoryData]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(categories) { category in
                NavigationLink(value: category) {
                    CategoryProgressRow(category: category)
                }
                .buttonStyle(.plain)
                if category.id != categories.last?.id {
                    Divider().padding(.leading, 36)
                }
            }
        }
    }
}

private struct CategoryProgressRow: View {
    let category: CategoryData

    private var progress: Double? {
        guard let limit = category.limitCents, limit > 0 else { return nil }
        return Double(category.spentCents) / Double(limit)
    }

    private var barColor: Color {
        guard let p = progress else { return .secondary.opacity(0.4) }
        if p > 1.1 { return .red }
        return .green
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: PhosphorToSFSymbol.map(category.symbol))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(category.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if let limit = category.limitCents, limit > 0 {
                    Text("\(CurrencyFormatter.format(cents: category.spentCents)) / \(CurrencyFormatter.format(cents: limit))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text(CurrencyFormatter.format(cents: category.spentCents))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.15))
                        .frame(height: 8)

                    if let p = progress, p > 0, geo.size.width > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(width: geo.size.width * min(p, 1.0), height: 8)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}
