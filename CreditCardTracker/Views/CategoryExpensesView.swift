import SwiftUI

struct CategoryExpensesView: View {
    @State private var viewModel: CategoryExpensesViewModel

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

    init(category: CategoryData, month: String) {
        _viewModel = State(initialValue: CategoryExpensesViewModel(category: category, month: month))
    }

    private func formattedDate(_ dateString: String) -> String {
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Erro ao carregar")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Tentar novamente") {
                        Task { await viewModel.loadExpenses() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.expenses.isEmpty {
                ContentUnavailableView(
                    "Nenhuma despesa",
                    systemImage: "tray",
                    description: Text("Não há despesas nesta categoria para o mês selecionado.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.expenses.enumerated()), id: \.element.id) { index, expense in
                            ExpenseRowView(expense: expense, formattedDate: formattedDate(expense.date))
                            if index < viewModel.expenses.count - 1 {
                                Divider().padding(.leading, 56)
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
                .refreshable {
                    await viewModel.loadExpenses()
                }
            }
        }
        .navigationTitle(viewModel.category.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadExpenses()
        }
    }
}
