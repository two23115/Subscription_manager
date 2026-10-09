import SwiftUI

@main
@MainActor
struct SubscriptionManagerApp: App {
    @State private var store = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}
