import Foundation

struct PaginationData: Codable {
    let page: Int
    let pageSize: Int
    let totalExpenses: Int
    let totalPages: Int

    var hasMorePages: Bool { page < totalPages }
}
