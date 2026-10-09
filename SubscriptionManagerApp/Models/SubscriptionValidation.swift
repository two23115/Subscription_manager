import Foundation

enum SubscriptionValidationError: LocalizedError, Equatable {
    case emptyName
    case invalidPrice
    case cancelDeadlineAfterBillingDate

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "サービス名を入力してください。"
        case .invalidPrice:
            "金額は0より大きい数値で入力してください。"
        case .cancelDeadlineAfterBillingDate:
            "解約期限日は次回支払日以前の日付にしてください。"
        }
    }
}

extension Subscription {
    var normalizedForSave: Subscription {
        var subscription = self
        subscription.name = subscription.name.trimmingCharacters(in: .whitespacesAndNewlines)
        subscription.category = subscription.category.trimmingCharacters(in: .whitespacesAndNewlines)
        subscription.memo = subscription.memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return subscription
    }

    func validationErrors(calendar: Calendar = .current) -> [SubscriptionValidationError] {
        let normalizedSubscription = normalizedForSave
        var errors: [SubscriptionValidationError] = []

        if normalizedSubscription.name.isEmpty {
            errors.append(.emptyName)
        }

        if !normalizedSubscription.price.isFinite || normalizedSubscription.price <= 0 {
            errors.append(.invalidPrice)
        }

        if let cancelDeadlineDate = normalizedSubscription.cancelDeadlineDate,
           calendar.startOfDay(for: cancelDeadlineDate) > calendar.startOfDay(for: normalizedSubscription.nextBillingDate) {
            errors.append(.cancelDeadlineAfterBillingDate)
        }

        return errors
    }

    var isValidForSave: Bool {
        validationErrors().isEmpty
    }
}
