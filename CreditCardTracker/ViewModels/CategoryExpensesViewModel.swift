import Foundation
import Observation

@Observable class CategoryExpensesViewModel {
    let category: CategoryData
    let month: String

    var expenses: [ExpenseData] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String? = nil
    var hasMorePages: Bool = false

    private var currentPage: Int = 1

    init(category: CategoryData, month: String) {
        self.category = category
        self.month = month
    }

    func loadExpenses() async {
        currentPage = 1
        expenses = []
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.fetchDashboard(
                month: month, page: 1, categoryId: category.id
            )
            expenses = response.expenses
            hasMorePages = response.pagination.hasMorePages
            currentPage = response.pagination.page
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await APIClient.shared.fetchDashboard(
                month: month, page: currentPage + 1, categoryId: category.id
            )
            expenses.append(contentsOf: response.expenses)
            hasMorePages = response.pagination.hasMorePages
            currentPage = response.pagination.page
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
