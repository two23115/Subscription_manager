import Foundation
import Testing
@testable import SubscriptionManagerApp

struct NotificationSchedulerTests {
    @Test func createsBillingAndDeadlinePlansForBothNotificationType() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 18, hour: 10)))
        let nextBillingDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 21)))
        let cancelDeadlineDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 20)))
        let subscription = Subscription(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            name: "ChatGPT",
            price: 3000,
            nextBillingDate: nextBillingDate,
            cancelDeadlineDate: cancelDeadlineDate,
            notificationType: .both
        )

        let plans = NotificationScheduler.notificationPlans(
            for: [subscription],
            now: now,
            calendar: calendar
        )

        #expect(plans.count == 2)
        #expect(plans[0].identifier == "subscription.billing.00000000-0000-0000-0000-000000000001")
        #expect(plans[0].triggerComponents.month == 5)
        #expect(plans[0].triggerComponents.day == 20)
        #expect(plans[0].triggerComponents.hour == 9)
        #expect(plans[1].identifier == "subscription.deadline.00000000-0000-0000-0000-000000000001")
        #expect(plans[1].triggerComponents.day == 19)
    }

    @Test func doesNotCreatePlansForPastOrCancelledSubscriptions() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 20, hour: 10)))
        let pastBillingDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 20)))
        let futureBillingDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 25)))

        let pastSubscription = Subscription(
            name: "Past",
            price: 500,
            nextBillingDate: pastBillingDate,
            notificationType: .billingDate
        )
        let cancelledSubscription = Subscription(
            name: "Cancelled",
            price: 500,
            nextBillingDate: futureBillingDate,
            notificationType: .billingDate,
            status: .cancelled
        )

        let plans = NotificationScheduler.notificationPlans(
            for: [pastSubscription, cancelledSubscription],
            now: now,
            calendar: calendar
        )

        #expect(plans.isEmpty)
    }
}
