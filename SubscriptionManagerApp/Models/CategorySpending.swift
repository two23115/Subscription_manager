import Foundation

struct CategorySpending: Identifiable, Equatable {
    var category: String
    var monthlyEquivalentTotal: Double
    var yearlyEquivalentTotal: Double
    var subscriptionCount: Int

    var id: String { category }
}

extension String {
    var subscriptionCategoryName: String {
        let trimmedValue = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "未分類" : trimmedValue
    }
}
