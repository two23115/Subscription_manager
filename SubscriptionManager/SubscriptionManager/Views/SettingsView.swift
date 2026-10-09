import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    let store: SubscriptionStore
    @Environment(\.openURL) private var openURL
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section("通知") {
                LabeledContent("通知許可", value: authorizationStatus.displayText)

                if authorizationStatus == .notDetermined {
                    NotificationGuidanceView(
                        title: "通知が未設定です",
                        message: "支払い日や解約期限日の1日前に通知するには通知を許可してください。",
                        systemImage: "bell.badge"
                    )
                    Button("通知を許可") {
                        Task {
                            _ = await NotificationScheduler.shared.requestAuthorization()
                            await refreshAuthorizationStatus()
                        }
                    }
                } else if authorizationStatus == .denied {
                    NotificationGuidanceView(
                        title: "通知が拒否されています",
                        message: "通知を使うにはシステム設定から通知を許可してください。",
                        systemImage: "bell.slash"
                    )
                    Button("システム設定を開く") {
                        openNotificationSettings()
                    }
                }

                Picker("デフォルト通知設定", selection: defaultNotificationBinding) {
                    ForEach(NotificationType.allCases) { notificationType in
                        Text(notificationType.label).tag(notificationType)
                    }
                }
            }

            Section("アプリ") {
                LabeledContent("通貨", value: "日本円")
                LabeledContent("保存方式", value: "端末内JSON保存")
                LabeledContent("同期", value: "iCloud同期なし")
            }

            Section("開発") {
                Button("サンプルデータを追加") {
                    store.loadSampleDataIfNeeded()
                }
            }
        }
        .navigationTitle("設定")
        .task {
            await refreshAuthorizationStatus()
        }
    }

    private var defaultNotificationBinding: Binding<NotificationType> {
        Binding {
            store.defaultNotificationType
        } set: { newValue in
            store.defaultNotificationType = newValue
        }
    }

    @MainActor
    private func refreshAuthorizationStatus() async {
        let settings = await NotificationScheduler.shared.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    private func openNotificationSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            openURL(url)
        }
        #endif
    }
}

private struct NotificationGuidanceView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .padding(.vertical, 4)
    }
}

private extension UNAuthorizationStatus {
    var displayText: String {
        switch self {
        case .notDetermined:
            "未設定"
        case .denied:
            "拒否"
        case .authorized:
            "許可済み"
        case .provisional:
            "暫定許可"
        case .ephemeral:
            "一時許可"
        @unknown default:
            "不明"
        }
    }
}
