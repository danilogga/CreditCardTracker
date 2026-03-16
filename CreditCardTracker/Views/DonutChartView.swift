import SwiftUI
import Charts

struct DonutChartView: View {
    let totalSpentCents: Int
    let totalBudgetCents: Int

    private var ratio: Double {
        guard totalBudgetCents > 0 else { return 0 }
        return Double(totalSpentCents) / Double(totalBudgetCents)
    }

    private var hasBudget: Bool {
        totalBudgetCents > 0
    }

    private var spentColor: Color {
        if ratio >= 0.9 { return .red }
        if ratio >= 0.7 { return Color(red: 0.96, green: 0.65, blue: 0.14) }
        return .blue
    }

    private struct ChartSlice: Identifiable {
        let id: String
        let value: Double
        let color: Color
    }

    private var slices: [ChartSlice] {
        if !hasBudget {
            return [ChartSlice(id: "spent", value: 1, color: .blue)]
        }
        if ratio >= 1.0 {
            return [ChartSlice(id: "spent", value: 1, color: spentColor)]
        }
        let spent = Double(totalSpentCents)
        let remaining = Double(totalBudgetCents - totalSpentCents)
        return [
            ChartSlice(id: "spent", value: spent, color: spentColor),
            ChartSlice(id: "remaining", value: remaining, color: Color.secondary.opacity(0.25))
        ]
    }

    var body: some View {
        ZStack {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Value", slice.value),
                    innerRadius: .ratio(0.62),
                    angularInset: 2
                )
                .foregroundStyle(slice.color)
            }
            .frame(width: 200, height: 200)

            VStack(spacing: 2) {
                Text(CurrencyFormatter.format(cents: totalSpentCents))
                    .font(.title3)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if hasBudget {
                    Text("de \(CurrencyFormatter.format(cents: totalBudgetCents))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .frame(width: 110)
        }
        .frame(width: 200, height: 200)
    }
}
