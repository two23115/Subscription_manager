import SwiftUI

struct HomeView: View {
    let store: SubscriptionStore
    @State private var isShowingForm = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("今月の支払い予定")
                        .font(.headline)
                    Text(store.summary.monthlyPaymentTotal.yenText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    HStack {
                        SummaryItem(title: "月額換算", value: store.summary.monthlyEquivalentTotal.yenText)
                        SummaryItem(title: "年額換算", value: store.summary.yearlyEquivalentTotal.yenText)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("カテゴリ別集計") {
                if store.summary.categoryBreakdown.isEmpty {
                    ContentUnavailableView("対象なし", systemImage: "chart.pie")
                } else {
                    ForEach(store.summary.categoryBreakdown.prefix(5)) { categorySpending in
                        CategorySpendingRow(categorySpending: categorySpending)
                    }
                }
            }

            Section("解約期限が近い") {
                if store.summary.upcomingCancellation.isEmpty {
                    ContentUnavailableView("対象なし", systemImage: "checkmark.circle")
                } else {
                    ForEach(store.summary.upcomingCancellation) { subscription in
                        SubscriptionRow(subscription: subscription, dateKind: .cancelDeadline)
                    }
                }
            }

            Section("まもなく支払い") {
                if store.summary.upcomingBilling.isEmpty {
                    ContentUnavailableView("対象なし", systemImage: "checkmark.circle")
                } else {
                    ForEach(store.summary.upcomingBilling) { subscription in
                        SubscriptionRow(subscription: subscription, dateKind: .billing)
                    }
                }
            }
        }
        .navigationTitle("サブスク管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingForm = true
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingForm) {
            NavigationStack {
                SubscriptionFormView(subscription: nil, defaultNotificationType: store.defaultNotificationType) { subscription in
                    store.upsert(subscription)
                }
            }
        }
    }
}

private struct SummaryItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CategorySpendingRow: View {
    let categorySpending: CategorySpending

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(categorySpending.category)
                    .font(.headline)
                Spacer()
                Text("\(categorySpending.subscriptionCount)件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("月額換算 \(categorySpending.monthlyEquivalentTotal.yenText)")
                Spacer()
                Text("年額換算 \(categorySpending.yearlyEquivalentTotal.yenText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
