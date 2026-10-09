import SwiftUI

struct SubscriptionFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Subscription
    @State private var hasCancelDeadline: Bool
    @State private var validationErrors: [SubscriptionValidationError] = []

    private let onSave: (Subscription) -> Void

    init(
        subscription: Subscription?,
        defaultNotificationType: NotificationType,
        onSave: @escaping (Subscription) -> Void
    ) {
        let initialDraft = subscription ?? Subscription(notificationType: defaultNotificationType)
        _draft = State(initialValue: initialDraft)
        _hasCancelDeadline = State(initialValue: initialDraft.cancelDeadlineDate != nil)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("サービス名", text: $draft.name)
                TextField("金額", value: $draft.price, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                Picker("支払い周期", selection: $draft.billingCycle) {
                    ForEach(BillingCycle.allCases) { cycle in
                        Text(cycle.label).tag(cycle)
                    }
                }
                Picker("ステータス", selection: $draft.status) {
                    ForEach(SubscriptionStatus.allCases) { status in
                        Text(status.label).tag(status)
                    }
                }
            }

            Section("期限") {
                DatePicker("次回支払日", selection: $draft.nextBillingDate, displayedComponents: .date)
                Toggle("解約期限日を設定", isOn: $hasCancelDeadline)
                if hasCancelDeadline {
                    DatePicker(
                        "解約期限日",
                        selection: cancelDeadlineBinding,
                        displayedComponents: .date
                    )
                }
            }

            if !validationErrors.isEmpty {
                Section("入力エラー") {
                    ForEach(validationErrors, id: \.self) { error in
                        Text(error.errorDescription ?? "入力内容を確認してください。")
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("通知") {
                Picker("通知設定", selection: $draft.notificationType) {
                    ForEach(NotificationType.allCases) { notificationType in
                        Text(notificationType.label).tag(notificationType)
                    }
                }
            }

            Section("補足") {
                TextField("カテゴリ", text: $draft.category)
                TextField("メモ", text: $draft.memo, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(draft.name.isEmpty ? "サブスク追加" : "サブスク編集")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(!draft.isValidForSave)
            }
        }
        .onChange(of: hasCancelDeadline) { _, newValue in
            if newValue, draft.cancelDeadlineDate == nil {
                draft.cancelDeadlineDate = draft.nextBillingDate
            } else if !newValue {
                draft.cancelDeadlineDate = nil
            }
        }
    }

    private var cancelDeadlineBinding: Binding<Date> {
        Binding {
            draft.cancelDeadlineDate ?? draft.nextBillingDate
        } set: { newValue in
            draft.cancelDeadlineDate = newValue
        }
    }

    private func save() {
        if !hasCancelDeadline {
            draft.cancelDeadlineDate = nil
        }

        let normalizedDraft = draft.normalizedForSave
        let errors = normalizedDraft.validationErrors()
        guard errors.isEmpty else {
            validationErrors = errors
            return
        }

        onSave(normalizedDraft)
        dismiss()
    }
}
