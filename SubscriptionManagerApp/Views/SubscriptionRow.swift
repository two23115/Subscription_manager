import SwiftUI

enum SubscriptionRowDateKind {
    case billing
    case cancelDeadline
}

struct SubscriptionRow: View {
    let subscription: Subscription
    var dateKind: SubscriptionRowDateKind = .billing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(subscription.name)
                    .font(.headline)
                Spacer()
                Text(subscription.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(subscription.price.yenText) / \(subscription.billingCycle.shortLabel)")
                .font(.subheadline)

            switch dateKind {
            case .billing:
                Text("次回支払日: \(subscription.nextBillingDate.shortDateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .cancelDeadline:
                if let cancelDeadlineDate = subscription.cancelDeadlineDate {
                    Text("解約期限: \(cancelDeadlineDate.shortDateText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
