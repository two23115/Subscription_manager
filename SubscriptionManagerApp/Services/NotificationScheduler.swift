import Foundation
import UserNotifications

struct NotificationPlan: Equatable {
    var identifier: String
    var title: String
    var body: String
    var triggerComponents: DateComponents
}

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    private init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.center = center
        self.calendar = calendar
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func notificationSettings() async -> UNNotificationSettings {
        await center.notificationSettings()
    }

    func rescheduleNotifications(for subscriptions: [Subscription]) async {
        let identifiers = subscriptions.flatMap { subscription in
            [Self.billingIdentifier(for: subscription), Self.deadlineIdentifier(for: subscription)]
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for plan in Self.notificationPlans(for: subscriptions, now: .now, calendar: calendar) {
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: plan.identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: plan.triggerComponents, repeats: false)
            )

            try? await center.add(request)
        }
    }

    static func notificationPlans(
        for subscriptions: [Subscription],
        now: Date,
        calendar: Calendar = .current
    ) -> [NotificationPlan] {
        subscriptions
            .filter { $0.status != .cancelled }
            .flatMap { subscription in
                notificationPlans(for: subscription, now: now, calendar: calendar)
            }
    }

    private static func notificationPlans(
        for subscription: Subscription,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        switch subscription.notificationType {
        case .none:
            []
        case .billingDate:
            billingNotificationPlan(for: subscription, now: now, calendar: calendar).map { [$0] } ?? []
        case .cancelDeadline:
            deadlineNotificationPlan(for: subscription, now: now, calendar: calendar).map { [$0] } ?? []
        case .both:
            [
                billingNotificationPlan(for: subscription, now: now, calendar: calendar),
                deadlineNotificationPlan(for: subscription, now: now, calendar: calendar)
            ].compactMap { $0 }
        }
    }

    private static func billingNotificationPlan(
        for subscription: Subscription,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        makeNotificationPlan(
            identifier: billingIdentifier(for: subscription),
            title: "明日は\(subscription.name)の支払い日です。",
            body: "予定金額: \(subscription.price.yenText)",
            sourceDate: subscription.nextBillingDate,
            now: now,
            calendar: calendar
        )
    }

    private static func deadlineNotificationPlan(
        for subscription: Subscription,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        guard let cancelDeadlineDate = subscription.cancelDeadlineDate else { return nil }
        return makeNotificationPlan(
            identifier: deadlineIdentifier(for: subscription),
            title: "明日は\(subscription.name)の解約期限日です。",
            body: "継続するか確認してください。",
            sourceDate: cancelDeadlineDate,
            now: now,
            calendar: calendar
        )
    }

    private static func makeNotificationPlan(
        identifier: String,
        title: String,
        body: String,
        sourceDate: Date,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        guard let triggerDate = calendar.date(byAdding: .day, value: -1, to: sourceDate), triggerDate > now else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 9
        components.minute = 0

        return NotificationPlan(
            identifier: identifier,
            title: title,
            body: body,
            triggerComponents: components
        )
    }

    private static func billingIdentifier(for subscription: Subscription) -> String {
        "subscription.billing.\(subscription.id.uuidString)"
    }

    private static func deadlineIdentifier(for subscription: Subscription) -> String {
        "subscription.deadline.\(subscription.id.uuidString)"
    }
}
