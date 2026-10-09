import Foundation

struct SubscriptionSummary {
    var monthlyPaymentTotal: Double
    var monthlyEquivalentTotal: Double
    var yearlyEquivalentTotal: Double
    var upcomingBilling: [Subscription]
    var upcomingCancellation: [Subscription]
    var categoryBreakdown: [CategorySpending]

    static let empty = SubscriptionSummary(
        monthlyPaymentTotal: 0,
        monthlyEquivalentTotal: 0,
        yearlyEquivalentTotal: 0,
        upcomingBilling: [],
        upcomingCancellation: [],
        categoryBreakdown: []
    )
}
