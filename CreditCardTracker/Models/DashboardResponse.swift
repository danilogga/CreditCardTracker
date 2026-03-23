import Foundation

struct DashboardResponse: Codable {
    let month: String
    let invoiceClosed: Bool
    let totalSpentCents: Int
    let totalIgnoredCents: Int
    let categories: [CategoryData]
    let pagination: PaginationData
    let expenses: [ExpenseData]
}
