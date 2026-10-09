import Foundation
import Testing
@testable import SubscriptionManagerApp

struct SubscriptionValidationTests {
    @Test func rejectsEmptyNameAndInvalidPrice() {
        let subscription = Subscription(name: "   ", price: 0)

        let errors = subscription.validationErrors()

        #expect(errors.contains(.emptyName))
        #expect(errors.contains(.invalidPrice))
    }

    @Test func rejectsCancelDeadlineAfterBillingDate() throws {
        let calendar = Calendar(identifier: .gregorian)
        let nextBillingDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 20)))
        let cancelDeadlineDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 21)))
        let subscription = Subscription(
            name: "動画サービス",
            price: 1200,
            nextBillingDate: nextBillingDate,
            cancelDeadlineDate: cancelDeadlineDate
        )

        #expect(subscription.validationErrors(calendar: calendar) == [.cancelDeadlineAfterBillingDate])
    }

    @Test func normalizesTextFieldsBeforeSaving() {
        let subscription = Subscription(
            name: "  ChatGPT  ",
            price: 3000,
            category: "  AI / 仕事  ",
            memo: "  Webから確認  "
        )

        let normalized = subscription.normalizedForSave

        #expect(normalized.name == "ChatGPT")
        #expect(normalized.category == "AI / 仕事")
        #expect(normalized.memo == "Webから確認")
    }
}
