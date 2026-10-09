import Foundation
import Testing
@testable import SubscriptionManagerApp

@MainActor
struct SubscriptionSummaryTests {
    @Test func calculatesTotalsAndCategoryBreakdown() throws {
        let store = SubscriptionStore(storageURL: temporaryStorageURL(), notificationRefresher: { _ in })
        let now = Date()
        let yearlyDate = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now

        store.upsert(Subscription(
            name: "ChatGPT",
            price: 3000,
            billingCycle: .monthly,
            nextBillingDate: now,
            category: "AI / 仕事"
        ))
        store.upsert(Subscription(
            name: "Yearly Tool",
            price: 12000,
            billingCycle: .yearly,
            nextBillingDate: yearlyDate,
            category: "仕事"
        ))
        store.upsert(Subscription(
            name: "Cancelled",
            price: 9999,
            billingCycle: .monthly,
            nextBillingDate: now,
            status: .cancelled
        ))

        let summary = store.summary

        #expect(summary.monthlyPaymentTotal == 15000)
        #expect(summary.monthlyEquivalentTotal == 4000)
        #expect(summary.yearlyEquivalentTotal == 48000)
        #expect(summary.categoryBreakdown.map(\.category) == ["AI / 仕事", "仕事"])
        #expect(summary.categoryBreakdown.first?.monthlyEquivalentTotal == 3000)
    }

    @Test func refusesInvalidSubscriptionInStore() {
        let store = SubscriptionStore(storageURL: temporaryStorageURL(), notificationRefresher: { _ in })
        let didSave = store.upsert(Subscription(name: "", price: -1))

        #expect(didSave == false)
        #expect(store.subscriptions.isEmpty)
    }

    @Test func exposesPersistenceErrorWhenSavingFails() {
        let store = SubscriptionStore(
            storageURL: URL(fileURLWithPath: "/dev/null/subscriptions.json"),
            notificationRefresher: { _ in }
        )

        let didSave = store.upsert(Subscription(name: "ChatGPT", price: 3000))

        #expect(didSave == false)
        #expect(store.persistenceErrorMessage != nil)
    }

    private func temporaryStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("subscriptions.json")
    }
}
