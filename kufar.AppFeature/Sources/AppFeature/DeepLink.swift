import Foundation
import SharedKernel
import SearchInterface
import PostingInterface
import GoodsInterface
import AutoInterface
import ProfileInterface

/// Внешняя ссылка и внутренний переход упираются в один механизм.
/// Для классифайда это критично: трафик из поисковой выдачи, пушей
/// и шеринга в мессенджеры — фактически второй главный вход в приложение.
public enum DeepLinkDestination: Hashable, Sendable {
    case search(SearchRoute)
    case posting(PostingRoute)
    case goods(GoodsRoute)
    case auto(AutoRoute)
    case profile(ProfileRoute)
    /// Вертикаль в ссылке не указана — знает её только бэкенд.
    case resolveListing(ListingID)
    /// Вертикали нет в этой сборке либо ссылку не разобрали.
    case web(URL)
}

public struct RouteParser: Sendable {
    /// Состав сборки знает только композиционный корень — он и передаёт список.
    /// Если вертикали нет во флейворе, её маршрут не зарегистрирован,
    /// и приложение не «молча ничего не делает», а открывает веб-фолбэк.
    private let availableVerticals: Set<Vertical>

    public init(availableVerticals: Set<Vertical>) {
        self.availableVerticals = availableVerticals
    }

    public func parse(_ url: URL) -> DeepLinkDestination {
        let parts = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let query = queryItems.first { $0.name == "q" }?.value ?? ""
        let category = queryItems.first { $0.name == "cat" }?.value

        switch parts.first {
        case "search":
            // kufar.by/search?q=пылесос&cat=goods.electronics
            return .search(.results(FilterState(query: query, categoryID: category)))

        case "post":
            // kufar.by/post?cat=auto.cars — вход в подачу из внешней ссылки,
            // например из пуша «продайте то, что не нужно».
            return .posting(category.map(PostingRoute.form) ?? .category)

        case "goods":
            guard let raw = parts.dropFirst().first else { return .web(url) }
            guard availableVerticals.contains(.goods) else { return .web(url) }
            return .goods(.details(ListingID(raw)))

        case "auto":
            guard let raw = parts.dropFirst().first else { return .web(url) }
            guard availableVerticals.contains(.auto) else { return .web(url) }
            return .auto(.details(ListingID(raw)))

        case "user":
            guard let raw = parts.dropFirst().first else { return .web(url) }
            return .profile(.profile(raw))

        case "item":
            // kufar.by/item/12345 — категории в ссылке нет.
            guard let raw = parts.dropFirst().first else { return .web(url) }
            return .resolveListing(ListingID(raw))

        default:
            return .web(url)
        }
    }
}
