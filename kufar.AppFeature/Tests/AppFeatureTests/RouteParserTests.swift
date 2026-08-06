import XCTest
@testable import AppFeature
import SharedKernel
import SearchInterface
import PostingInterface
import GoodsInterface
import AutoInterface
import ProfileInterface

final class RouteParserTests: XCTestCase {

    private let full = RouteParser(availableVerticals: Set(Vertical.allCases))

    func testSearchLinkCarriesQueryAndCategory() {
        let url = URL(string: "https://kufar.by/search?q=%D0%BF%D1%8B%D0%BB%D0%B5%D1%81%D0%BE%D1%81&cat=goods.electronics")!
        guard case .search(.results(let state)) = full.parse(url) else {
            return XCTFail("ожидали маршрут поиска")
        }
        XCTAssertEqual(state.query, "пылесос")
        XCTAssertEqual(state.categoryID, "goods.electronics")
        XCTAssertEqual(state.activeCount, 1)
    }

    func testPostingLinkCarriesCategory() {
        let url = URL(string: "https://kufar.by/post?cat=auto.cars")!
        XCTAssertEqual(full.parse(url), .posting(.form("auto.cars")))
        XCTAssertEqual(full.parse(URL(string: "https://kufar.by/post")!), .posting(.category))
    }

    func testVerticalLinksParse() {
        XCTAssertEqual(full.parse(URL(string: "https://kufar.by/goods/g-7")!),
                       .goods(.details(ListingID("g-7"))))
        XCTAssertEqual(full.parse(URL(string: "https://kufar.by/auto/a-3")!),
                       .auto(.details(ListingID("a-3"))))
        XCTAssertEqual(full.parse(URL(string: "https://kufar.by/user/u-77")!),
                       .profile(.profile("u-77")))
    }

    func testItemLinkNeedsResolve() {
        // kufar.by/item/12345 — вертикали в ссылке нет, знает её только бэк.
        XCTAssertEqual(full.parse(URL(string: "https://kufar.by/item/12345")!),
                       .resolveListing(ListingID("12345")))
    }

    func testMissingVerticalFallsBackToWeb() {
        // Сборка без Auto: маршрут не зарегистрирован. Без этой проверки
        // тап по ссылке молча ничего не делает.
        let limited = RouteParser(availableVerticals: [.goods])
        let url = URL(string: "https://kufar.by/auto/a-3")!
        XCTAssertEqual(limited.parse(url), .web(url))
    }

    func testUnknownPathFallsBackToWeb() {
        let url = URL(string: "https://kufar.by/help/rules")!
        XCTAssertEqual(full.parse(url), .web(url))
    }
}
