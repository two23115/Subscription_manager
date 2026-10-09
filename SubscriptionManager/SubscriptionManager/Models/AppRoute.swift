import Foundation

enum AppRoute: Hashable {
    case home
    case list
    case settings

    var title: String {
        switch self {
        case .home:
            "ホーム"
        case .list:
            "サブスク一覧"
        case .settings:
            "設定"
        }
    }
}
