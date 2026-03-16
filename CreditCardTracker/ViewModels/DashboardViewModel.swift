import Foundation
import Observation
import WidgetKit

@Observable class DashboardViewModel {
    private static let sharedDefaults = UserDefaults(suiteName: "group.creditcardtracker") ?? .standard

    var month: String = (UserDefaults(suiteName: "group.creditcardtracker") ?? .standard).string(forKey: "lastSelectedMonth") ?? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }() {
        didSet {
            DashboardViewModel.sharedDefaults.set(month, forKey: "lastSelectedMonth")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var invoiceClosed: Bool = false
    var totalSpentCents: Int = 0
    var categories: [CategoryData] = []
    var expenses: [ExpenseData] = []
    var pagination: PaginationData? = nil
    var isLoadingDashboard: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String? = nil

    private var currentPage: Int = 1

    var sortedCategories: [CategoryData] {
        categories
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var totalBudgetCents: Int {
        categories.compactMap { $0.limitCents }.reduce(0, +)
    }

    var hasMorePages: Bool {
        pagination?.hasMorePages ?? false
    }

    func loadDashboard() async {
        currentPage = 1
        expenses = []
        errorMessage = nil
        isLoadingDashboard = true
        defer { isLoadingDashboard = false }

        do {
            let response = try await APIClient.shared.fetchDashboard(month: month, page: 1)
            apply(response: response, appending: false)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await APIClient.shared.fetchDashboard(month: month, page: nextPage)
            apply(response: response, appending: true)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func navigateToPreviousMonth() {
        month = offset(month: month, by: -1)
        Task { await loadDashboard() }
    }

    func navigateToNextMonth() {
        month = offset(month: month, by: 1)
        Task { await loadDashboard() }
    }

    private func apply(response: DashboardResponse, appending: Bool) {
        invoiceClosed = response.invoiceClosed
        totalSpentCents = response.totalSpentCents
        categories = response.categories
        pagination = response.pagination
        currentPage = response.pagination.page

        if appending {
            expenses.append(contentsOf: response.expenses)
        } else {
            expenses = response.expenses
        }
    }

    private func offset(month: String, by months: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: month) else { return month }
        var components = Calendar.current.dateComponents([.year, .month], from: date)
        components.month = (components.month ?? 0) + months
        guard let newDate = Calendar.current.date(from: components) else { return month }
        return formatter.string(from: newDate)
    }
}
