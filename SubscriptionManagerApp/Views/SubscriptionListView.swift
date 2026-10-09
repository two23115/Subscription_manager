import SwiftUI

struct SubscriptionListView: View {
    @Bindable var store: SubscriptionStore
    @State private var sort: SubscriptionSort = .nextBillingDate
    @State private var isShowingForm = false

    var body: some View {
        List {
            Picker("並び替え", selection: $sort) {
                ForEach(SubscriptionSort.allCases) { sort in
                    Text(sort.label).tag(sort)
                }
            }

            ForEach(store.sortedSubscriptions(by: sort)) { subscription in
                NavigationLink(value: subscription.id) {
                    SubscriptionRow(subscription: subscription)
                }
            }
            .onDelete { offsets in
                let sortedSubscriptions = store.sortedSubscriptions(by: sort)
                for offset in offsets {
                    store.delete(sortedSubscriptions[offset])
                }
            }
        }
        .navigationTitle("サブスク一覧")
        .navigationDestination(for: Subscription.ID.self) { id in
            if let subscription = store.subscription(id: id) {
                SubscriptionDetailView(store: store, subscription: subscription)
            } else {
                ContentUnavailableView("見つかりません", systemImage: "exclamationmark.triangle")
            }
        }
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
