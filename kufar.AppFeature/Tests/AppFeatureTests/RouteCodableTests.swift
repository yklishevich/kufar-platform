import XCTest
import SwiftUI
import SearchInterface
import PostingInterface
import GoodsInterface
import AutoInterface
import ProfileInterface
import SharedKernel
@testable import AppFeature

/// NavigationPath.codable возвращает nil, если ХОТЯ БЫ ОДИН элемент стека
/// не Codable — молча, для всего пути. Отсюда требование держать
/// в *Interface голые enum'ы: этот тест его и охраняет.
@MainActor
final class RouteCodableTests: XCTestCase {

    func testEveryRouteSurvivesPathEncoding() throws {
        var path = NavigationPath()
        for route in SearchRoute.allCases { path.append(route) }
        for route in PostingRoute.allCases { path.append(route) }
        for route in GoodsRoute.allCases { path.append(route) }
        for route in AutoRoute.allCases { path.append(route) }
        for route in ProfileRoute.allCases { path.append(route) }
        path.append(ListingResolveRoute(id: ListingID("12345")))
        path.append(WebFallbackRoute(url: URL(string: "https://kufar.by")!))

        let representation = try XCTUnwrap(
            path.codable,
            "какой-то маршрут не Codable — восстановление стека сломано целиком"
        )

        let data = try JSONEncoder().encode(representation)
        let decoded = try JSONDecoder().decode(
            NavigationPath.CodableRepresentation.self, from: data
        )
        XCTAssertEqual(NavigationPath(decoded).count, path.count)
    }
}
