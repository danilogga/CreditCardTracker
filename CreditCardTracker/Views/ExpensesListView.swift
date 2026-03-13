import SwiftUI

struct ExpensesListView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    private let inputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let outputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    private func formattedDate(_ dateString: String) -> String {
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.expenses.enumerated()), id: \.element.id) { index, expense in
                ExpenseRowView(expense: expense, formattedDate: formattedDate(expense.date))

                if index < viewModel.expenses.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.hasMorePages {
                Button {
                    Task { await viewModel.loadNextPage() }
                } label: {
                    Text("Carregar mais")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
    }
}

private struct ExpenseRowView: View {
    let expense: ExpenseData
    let formattedDate: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((Color(hex: expense.category?.color ?? "#888888") ?? .gray).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: PhosphorToSFSymbol.map(expense.category?.symbol ?? "tag"))
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: expense.category?.color ?? "#888888") ?? .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(expense.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    Text(CurrencyFormatter.format(cents: abs(expense.amountCents)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(expense.isRefund ? .green : .primary)
                }

                HStack {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if expense.ignored {
                        Text("Ignorado")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.15))
                            .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.04))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if let current = expense.installmentCurrent,
                       let total = expense.installmentTotal {
                        Text("\(current)/\(total)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .opacity(expense.ignored ? 0.5 : 1)
    }
}
