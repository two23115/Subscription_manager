import SwiftUI

struct RootView: View {
    @Bindable var store: SubscriptionStore
    @State private var selectedRoute: AppRoute = .home

    var body: some View {
        rootContent
            .alert("保存エラー", isPresented: persistenceErrorBinding) {
                Button("OK") {
                    store.clearPersistenceError()
                }
            } message: {
                Text(store.persistenceErrorMessage ?? "")
            }
    }

    @ViewBuilder
    private var rootContent: some View {
        #if os(macOS)
        NavigationSplitView {
            List {
                Button(AppRoute.home.title) { selectedRoute = .home }
                Button(AppRoute.list.title) { selectedRoute = .list }
                Button(AppRoute.settings.title) { selectedRoute = .settings }
            }
            .navigationTitle("サブスク管理")
        } detail: {
            NavigationStack {
                routeView
            }
        }
        #else
        TabView(selection: $selectedRoute) {
            NavigationStack {
                HomeView(store: store)
            }
            .tabItem { Label("ホーム", systemImage: "house") }
            .tag(AppRoute.home)

            NavigationStack {
                SubscriptionListView(store: store)
            }
            .tabItem { Label("一覧", systemImage: "list.bullet") }
            .tag(AppRoute.list)

            NavigationStack {
                SettingsView(store: store)
            }
            .tabItem { Label("設定", systemImage: "gearshape") }
            .tag(AppRoute.settings)
        }
        #endif
    }

    @ViewBuilder
    private var routeView: some View {
        switch selectedRoute {
        case .home:
            HomeView(store: store)
        case .list:
            SubscriptionListView(store: store)
        case .settings:
            SettingsView(store: store)
        }
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding {
            store.persistenceErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                store.clearPersistenceError()
            }
        }
    }
}
