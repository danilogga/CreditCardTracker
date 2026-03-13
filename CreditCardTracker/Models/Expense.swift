import Foundation

struct MerchantData: Codable {
    let name: String
    let nickname: String?
}

struct ExpenseCategoryData: Codable {
    let id: String
    let name: String
    let color: String
    let symbol: String
}

struct ExpenseData: Codable, Identifiable {
    let id: String
    let merchant: MerchantData
    let amountCents: Int
    let installmentCurrent: Int?
    let installmentTotal: Int?
    let ignored: Bool
    let category: ExpenseCategoryData?
    let date: String

    enum CodingKeys: String, CodingKey {
        case id, merchant, amountCents, installmentCurrent, installmentTotal, ignored, category
        case date = "expenseDate"
    }

    var displayName: String { merchant.nickname ?? merchant.name }
    var isRefund: Bool { amountCents < 0 }
}
