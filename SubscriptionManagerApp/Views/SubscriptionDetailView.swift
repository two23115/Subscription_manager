import SwiftUI

struct SubscriptionDetailView: View {
    @Bindable var store: SubscriptionStore
    let subscription: Subscription

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditForm = false
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                LabeledContent("ステータス", value: subscription.status.label)
                LabeledContent("金額", value: "\(subscription.price.yenText) / \(subscription.billingCycle.shortLabel)")
                LabeledContent("月額換算", value: subscription.monthlyAmount.yenText)
                LabeledContent("年額換算", value: subscription.yearlyAmount.yenText)
            }

            Section("期限") {
                LabeledContent("次回支払日", value: subscription.nextBillingDate.fullDateText)
                LabeledContent("解約期限日", value: subscription.cancelDeadlineDate?.fullDateText ?? "未設定")
                LabeledContent("通知設定", value: subscription.notificationType.label)
            }

            Section("補足") {
                LabeledContent("カテゴリ", value: subscription.category.isEmpty ? "未設定" : subscription.category)
                if subscription.memo.isEmpty {
                    Text("メモなし")
                        .foregroundStyle(.secondary)
                } else {
                    Text(subscription.memo)
                }
            }
        }
        .navigationTitle(subscription.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    isShowingEditForm = true
                } label: {
                    Label("編集", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $isShowingEditForm) {
            NavigationStack {
                SubscriptionFormView(subscription: subscription, defaultNotificationType: store.defaultNotificationType) { updatedSubscription in
                    store.upsert(updatedSubscription)
                }
            }
        }
        .confirmationDialog("このサブスクを削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                store.delete(subscription)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}
