import SwiftUI

struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.isLoadingDashboard {
                SkeletonView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadDashboard() }
                }
            } else {
                contentView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MonthSelectorView()
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Invoice status badge
                HStack {
                    Spacer()
                    InvoiceBadge(isClosed: viewModel.invoiceClosed)
                    Spacer()
                }
                .padding(.top, 4)

                // Donut chart
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        DonutChartView(
                            totalSpentCents: viewModel.totalSpentCents,
                            totalBudgetCents: viewModel.totalBudgetCents
                        )
                        Spacer()
                    }

                    if viewModel.totalIgnoredCents > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.slash")
                                .font(.caption2)
                            Text("\(CurrencyFormatter.format(cents: viewModel.totalIgnoredCents)) ignorados")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Categories section
                if !viewModel.sortedCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Por categoria")
                            .font(.headline)
                            .padding(.horizontal, 16)

                        CategoryBarChartView(categories: viewModel.sortedCategories)
                            .padding(.horizontal, 16)
                    }
                }

                // Expenses section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Despesas")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    ExpensesListView()
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
        .navigationDestination(for: CategoryData.self) { category in
            CategoryExpensesView(category: category, month: viewModel.month)
        }
    }
}

private struct InvoiceBadge: View {
    let isClosed: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isClosed ? "lock.fill" : "lock.open.fill")
                .font(.caption)
            Text(isClosed ? "Fatura fechada" : "Fatura aberta")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(isClosed ? .orange : .green)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background((isClosed ? Color.orange : Color.green).opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct SkeletonView: View {
    @State private var opacity: Double = 0.4

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 140, height: 28)

                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 200, height: 200)

                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16)
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 80, height: 10)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 60, height: 12)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollDisabled(true)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: opacity)
        .onAppear { opacity = 1.0 }
    }
}

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Erro ao carregar")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Tentar novamente", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
