import SwiftUI
import Observation

/// Табы — это НЕ вертикали.
///
/// Вертикаль на классифайде выбирается категорией в фильтре, а не вкладкой:
/// лента одна, в ней вперемешку товары и авто. Поэтому вкладки отражают
/// режимы работы пользователя, а не структуру каталога — и добавление
/// вертикали не трогает таб-бар вообще.
public enum AppTab: String, Hashable, CaseIterable, Codable, Sendable {
    // AppTab, а не Tab: с iOS 18 имя занято SwiftUI.
    case search
    case posting
    case favorites
    case profile

    public var title: String {
        switch self {
        case .search: "Поиск"
        case .posting: "Подать"
        case .favorites: "Избранное"
        case .profile: "Профиль"
        }
    }

    public var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .posting: "plus.circle.fill"
        case .favorites: "heart"
        case .profile: "person.crop.circle"
        }
    }
}

/// Один Router на приложение — самая частая ошибка в табах:
/// push из первого таба уезжает во второй. Поэтому роутер на таб.
@MainActor
@Observable
public final class AppRouter {
    public var selected: AppTab

    private let routers: [AppTab: Router]

    public init(selected: AppTab = .search) {
        self.selected = selected
        // Создаём заранее: ленивое создание в body даёт
        // "Modifying state during view update".
        self.routers = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, Router()) })
    }

    public func router(for tab: AppTab) -> Router {
        guard let router = routers[tab] else {
            preconditionFailure("Роутер таба \(tab) не создан в init")
        }
        return router
    }

    public func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.router(for: tab).path },
            set: { self.router(for: tab).path = $0 }
        )
    }

    /// Диплинк: выбрать таб и открыть в нём экран.
    public func open(_ route: some Hashable, in tab: AppTab) {
        selected = tab
        router(for: tab).push(route)
    }

    /// При логауте — обязательно. Иначе следующий пользователь увидит
    /// стек предыдущего, включая экраны с его данными.
    public func resetAll() {
        for tab in AppTab.allCases {
            router(for: tab).popToRoot()
        }
        selected = .search
    }

    /// Для тестов и диагностики.
    public func depth(of tab: AppTab) -> Int {
        router(for: tab).path.count
    }
}
