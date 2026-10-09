import Foundation
import Observation

@MainActor
@Observable
final class SubscriptionStore {
    private(set) var subscriptions: [Subscription] = []
    var defaultNotificationType: NotificationType = .none
    var persistenceErrorMessage: String?

    private let storageURL: URL
    private let calendar: Calendar
    private let notificationRefresher: ([Subscription]) -> Void

    init(
        storageURL: URL? = nil,
        calendar: Calendar = .current,
        notificationRefresher: @escaping ([Subscription]) -> Void = { subscriptions in
            Task {
                await NotificationScheduler.shared.rescheduleNotifications(for: subscriptions)
            }
        }
    ) {
        self.storageURL = storageURL ?? SubscriptionStore.defaultStorageURL
        self.calendar = calendar
        self.notificationRefresher = notificationRefresher
        load()
    }

    var summary: SubscriptionSummary {
        let activeSubscriptions = subscriptions.filter { $0.status != .cancelled }
        let now = Date()

        let monthlyPaymentTotal = activeSubscriptions.reduce(0) { total, subscription in
            guard calendar.isDate(subscription.nextBillingDate, equalTo: now, toGranularity: .month) else {
                return total
            }
            return total + subscription.price
        }

        let upcomingBilling = activeSubscriptions
            .filter { $0.nextBillingDate >= calendar.startOfDay(for: now) }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .prefix(3)

        let upcomingCancellation = activeSubscriptions
            .filter { subscription in
                guard let deadline = subscription.cancelDeadlineDate else { return false }
                return deadline >= calendar.startOfDay(for: now)
            }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.cancelDeadlineDate, let rhsDate = rhs.cancelDeadlineDate else { return false }
                return lhsDate < rhsDate
            }
            .prefix(3)

        return SubscriptionSummary(
            monthlyPaymentTotal: monthlyPaymentTotal,
            monthlyEquivalentTotal: activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount },
            yearlyEquivalentTotal: activeSubscriptions.reduce(0) { $0 + $1.yearlyAmount },
            upcomingBilling: Array(upcomingBilling),
            upcomingCancellation: Array(upcomingCancellation),
            categoryBreakdown: categoryBreakdown(for: activeSubscriptions)
        )
    }

    func sortedSubscriptions(by sort: SubscriptionSort) -> [Subscription] {
        switch sort {
        case .nextBillingDate:
            subscriptions.sorted { $0.nextBillingDate < $1.nextBillingDate }
        case .cancelDeadlineDate:
            subscriptions.sorted { lhs, rhs in
                switch (lhs.cancelDeadlineDate, rhs.cancelDeadlineDate) {
                case let (lhsDate?, rhsDate?):
                    lhsDate < rhsDate
                case (.some, .none):
                    true
                case (.none, .some):
                    false
                case (.none, .none):
                    lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
            }
        case .priceDescending:
            subscriptions.sorted { $0.price > $1.price }
        case .name:
            subscriptions.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    func subscription(id: Subscription.ID) -> Subscription? {
        subscriptions.first { $0.id == id }
    }

    @discardableResult
    func upsert(_ subscription: Subscription) -> Bool {
        var updatedSubscription = subscription.normalizedForSave
        guard updatedSubscription.validationErrors(calendar: calendar).isEmpty else {
            return false
        }

        updatedSubscription.updatedAt = .now

        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = updatedSubscription
        } else {
            subscriptions.append(updatedSubscription)
        }

        return persistAndRefreshNotifications()
    }

    @discardableResult
    func delete(_ subscription: Subscription) -> Bool {
        subscriptions.removeAll { $0.id == subscription.id }
        return persistAndRefreshNotifications()
    }

    func clearPersistenceError() {
        persistenceErrorMessage = nil
    }

    func loadSampleDataIfNeeded() {
        guard subscriptions.isEmpty else { return }
        let now = Date()
        let nextBillingDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let cancelDeadlineDate = calendar.date(byAdding: .day, value: 2, to: now)

        subscriptions = [
            Subscription(
                name: "ChatGPT",
                price: 3000,
                billingCycle: .monthly,
                nextBillingDate: nextBillingDate,
                cancelDeadlineDate: nil,
                category: "AI / 仕事",
                memo: "Webから契約内容を確認",
                notificationType: .billingDate,
                status: .active
            ),
            Subscription(
                name: "動画サービス",
                price: 1490,
                billingCycle: .monthly,
                nextBillingDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
                cancelDeadlineDate: cancelDeadlineDate,
                category: "動画",
                memo: "無料体験終了前に確認",
                notificationType: .cancelDeadline,
                status: .trial
            )
        ]
        _ = persistAndRefreshNotifications()
    }

    private func categoryBreakdown(for subscriptions: [Subscription]) -> [CategorySpending] {
        let groupedSubscriptions = Dictionary(grouping: subscriptions) { subscription in
            subscription.category.subscriptionCategoryName
        }

        return groupedSubscriptions.map { category, subscriptions in
            CategorySpending(
                category: category,
                monthlyEquivalentTotal: subscriptions.reduce(0) { $0 + $1.monthlyAmount },
                yearlyEquivalentTotal: subscriptions.reduce(0) { $0 + $1.yearlyAmount },
                subscriptionCount: subscriptions.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.monthlyEquivalentTotal == rhs.monthlyEquivalentTotal {
                return lhs.category.localizedStandardCompare(rhs.category) == .orderedAscending
            }
            return lhs.monthlyEquivalentTotal > rhs.monthlyEquivalentTotal
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            subscriptions = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            subscriptions = try JSONDecoder().decode([Subscription].self, from: data)
            persistenceErrorMessage = nil
        } catch {
            subscriptions = []
            persistenceErrorMessage = "保存データを読み込めませんでした。必要に応じてデータファイルを確認してください。"
        }
    }

    private func persistAndRefreshNotifications() -> Bool {
        guard save() else { return false }
        notificationRefresher(subscriptions)
        return true
    }

    private func save() -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(subscriptions)
            try data.write(to: storageURL, options: [.atomic])
            persistenceErrorMessage = nil
            return true
        } catch {
            persistenceErrorMessage = "サブスク情報を保存できませんでした。保存先の空き容量や権限を確認してください。"
            return false
        }
    }

    private static var defaultStorageURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("SubscriptionManager", isDirectory: true)
            .appendingPathComponent("subscriptions.json")
    }
}
