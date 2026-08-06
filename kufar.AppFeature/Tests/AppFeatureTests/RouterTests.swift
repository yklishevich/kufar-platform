import XCTest
import SwiftUI
@testable import AppFeature
import Navigation
import SessionInterface
import SessionInterfaceTesting
import SharedKernel
import SearchInterface
import PostingInterface
import GoodsInterface
import AutoInterface
import ProfileInterface

/// Эти тесты собираются БЕЗ Networking, без единого *Data и без вертикалей:
/// пакет KufarAppFeature зависит только от контрактных пакетов.
@MainActor
final class RouterTests: XCTestCase {

    func testLogoutResetsEveryTab() {
        let router = AppRouter()
        router.open(GoodsRoute.details(ListingID("g-1")), in: .search)
        router.open(AutoRoute.details(ListingID("a-1")), in: .favorites)
        router.open(PostingRoute.category, in: .posting)
        router.open(ProfileRoute.settings, in: .profile)

        for tab in AppTab.allCases {
            XCTAssertEqual(router.depth(of: tab), 1)
        }

        router.resetAll()

        // Иначе следующий пользователь увидит стек предыдущего,
        // включая экраны с его данными.
        for tab in AppTab.allCases {
            XCTAssertEqual(router.depth(of: tab), 0, "стек таба \(tab) не очищен")
        }
        XCTAssertEqual(router.selected, .search)
    }

    func testPushStaysInsideItsOwnTab() {
        let router = AppRouter()
        router.open(SearchRoute.filters(.empty), in: .search)

        // Классическая ошибка одного роутера на приложение:
        // push из первого таба уезжает во второй.
        XCTAssertEqual(router.depth(of: .search), 1)
        XCTAssertEqual(router.depth(of: .favorites), 0)
        XCTAssertEqual(router.depth(of: .profile), 0)
    }

    func testTabsDoNotMirrorVerticals() {
        // Вертикаль выбирается категорией в фильтре, а не вкладкой.
        // Добавление вертикали не должно трогать таб-бар.
        let titles = AppTab.allCases.map(\.title)
        XCTAssertEqual(titles, ["Поиск", "Подать", "Избранное", "Профиль"])
    }

    func testReplaceLastKeepsDepth() {
        let router = Router()
        router.push(ListingResolveRoute(id: ListingID("12345")))
        XCTAssertEqual(router.path.count, 1)

        // Экран-прокладка подменяет себя карточкой: «назад» ведёт туда,
        // откуда пришли, а не на скелетон загрузки.
        router.replaceLast(with: GoodsRoute.details(ListingID("12345")))
        XCTAssertEqual(router.path.count, 1)
    }
}
