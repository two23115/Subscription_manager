import Foundation

struct Subscription: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var price: Double
    var billingCycle: BillingCycle
    var nextBillingDate: Date
    var cancelDeadlineDate: Date?
    var category: String
    var memo: String
    var notificationType: NotificationType
    var status: SubscriptionStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        price: Double = 0,
        billingCycle: BillingCycle = .monthly,
        nextBillingDate: Date = .now,
        cancelDeadlineDate: Date? = nil,
        category: String = "",
        memo: String = "",
        notificationType: NotificationType = .none,
        status: SubscriptionStatus = .active,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.billingCycle = billingCycle
        self.nextBillingDate = nextBillingDate
        self.cancelDeadlineDate = cancelDeadlineDate
        self.category = category
        self.memo = memo
        self.notificationType = notificationType
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var monthlyAmount: Double {
        billingCycle.monthlyAmount(for: price)
    }

    var yearlyAmount: Double {
        billingCycle.yearlyAmount(for: price)
    }
}

enum BillingCycle: String, CaseIterable, Codable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var monthsPerCycle: Double {
        switch self {
        case .monthly:
            1
        case .yearly:
            12
        }
    }

    func monthlyAmount(for price: Double) -> Double {
        price / monthsPerCycle
    }

    func yearlyAmount(for price: Double) -> Double {
        monthlyAmount(for: price) * 12
    }

    var label: String {
        switch self {
        case .monthly:
            "月額"
        case .yearly:
            "年額"
        }
    }

    var shortLabel: String {
        switch self {
        case .monthly:
            "月"
        case .yearly:
            "年"
        }
    }
}

enum NotificationType: String, CaseIterable, Codable, Identifiable {
    case none
    case billingDate
    case cancelDeadline
    case both

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:
            "通知なし"
        case .billingDate:
            "支払い日の1日前"
        case .cancelDeadline:
            "解約期限日の1日前"
        case .both:
            "両方通知"
        }
    }
}

enum SubscriptionStatus: String, CaseIterable, Codable, Identifiable {
    case active
    case trial
    case scheduledToCancel
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active:
            "契約中"
        case .trial:
            "無料体験中"
        case .scheduledToCancel:
            "解約予定"
        case .cancelled:
            "停止済み"
        }
    }
}

enum SubscriptionSort: String, CaseIterable, Identifiable {
    case nextBillingDate
    case cancelDeadlineDate
    case priceDescending
    case name

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nextBillingDate:
            "支払日が近い順"
        case .cancelDeadlineDate:
            "解約期限が近い順"
        case .priceDescending:
            "金額が高い順"
        case .name:
            "サービス名順"
        }
    }
}
