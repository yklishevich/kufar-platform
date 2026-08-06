import SwiftUI
import AppFeature
import Navigation
import SharedKernel
import SessionInterface
import Networking
import AnalyticsAPI
import AnalyticsImpl
import ListingKit
import CatalogContracts
import PostingInterface
import Search
import Posting
import Goods
import Auto
import Profile
import Auth

/// Композиционный корень: единственное место во всём приложении,
/// где встречаются конкретные реализации.
///
/// Обрати внимание, чего здесь НЕТ: ни одного `import *UI`.
/// Assembly возвращают непрозрачные типы, поэтому корень не знает
/// ни одного экрана — только как их собрать. Более того, SearchUI,
/// GoodsUI и AutoUI даже не объявлены продуктами своих пакетов:
/// импортировать их не даст SwiftPM.
@MainActor
public enum AppComposition {

    /// Состав сборки. Убери отсюда вертикаль — её маршруты не зарегистрируются,
    /// а диплинк на неё откроет веб-фолбэк вместо тишины.
    public static let verticals: Set<Vertical> = [.goods, .auto]

    public static func rootView() -> some View {
        // Бутстрап-клиент без интерсепторов: сессии нужен транспорт,
        // а транспорту — токен из сессии. Разрываем узел здесь, в корне.
        let session = AuthAssembly.makeSession(client: APIClient(baseURL: .production))

        // Боевой клиент один на приложение: общий пул соединений
        // и один интерсептор с токеном.
        let client = APIClient(
            baseURL: .production,
            interceptors: [
                AuthAssembly.makeInterceptor { session.state.userID.map { "token-\($0)" } }
            ]
        )

        let analytics: any AnalyticsTracking = BatchingTracker(client: client)
        let searchRepo = SearchAssembly.makeRepository(client: client)
        let postingRepo = PostingAssembly.makeRepository(client: client)
        let drafts = PostingAssembly.makeDraftStore()
        let goodsRepo = GoodsAssembly.makeRepository(client: client)
        let autoRepo = AutoAssembly.makeRepository(client: client)
        let resolver = RemoteListingResolver()

        // Третья точка схождения графа — строка общей ленты.
        //
        // Лента гетерогенна: в одном ForEach лежат товары и авто, а Content
        // у ForEach один на всю коллекцию. Значит строка обязана быть одного
        // типа, и различаться может только слот. Слот собирается здесь,
        // потому что корень — единственный модуль, которому позволено назвать
        // все реализации сразу.
        //
        // switch внутри @ViewBuilder даёт _ConditionalContent<EmptyView, …>,
        // то есть конкретный тип: AnyView появляется на уровень глубже, внутри
        // ListingRowAccessory, и только вокруг акцессорной строки.
        // Добавится вертикаль — компилятор придёт ровно сюда.
        let rowAccessory = ListingRowAccessory { ref in
            switch ref.vertical {
            case .goods: GoodsAssembly.rowAccessory(for: ref)
            case .auto:  AutoAssembly.rowAccessory(for: ref)
            }
        }

        // Цепочка destinations. Добавилась вертикаль — ещё один .concat.
        let destinations = SearchAssembly.makeDestinations(repo: searchRepo,
                                                           analytics: analytics,
                                                           rowAccessory: rowAccessory)
            // Четвёртая точка схождения — шаг вертикали в форме подачи.
            //
            // Здесь, в отличие от строки ленты, стирания нет вообще: точка
            // входа одна, поэтому дженерик `Step` прячется за `some ViewModifier`
            // и наружу не течёт. У товаров шаг пустой — заводить ради этого
            // публичный метод в GoodsAssembly и тащить в пакет два контрактных
            // репозитория значило бы платить зависимостью за слово «ничего».
            .concat(PostingAssembly.makeDestinations(repo: postingRepo,
                                                     drafts: drafts,
                                                     analytics: analytics) { category, draft in
                switch category.vertical {
                case .auto:  AutoAssembly.postingStep(category, draft: draft)
                case .goods: EmptyView()
                }
            })
            .concat(GoodsAssembly.makeDestinations(repo: goodsRepo, analytics: analytics))
            .concat(AutoAssembly.makeDestinations(repo: autoRepo, analytics: analytics))
            .concat(ProfileAssembly.makeDestinations(session: session))
            .concat(AuthAssembly.makeDestinations(session: session))
            .concat(AppDestinations(resolver: resolver))

        return RootView(
            session: session,
            parser: RouteParser(availableVerticals: verticals),
            destinations: destinations
        ) {
            AuthAssembly.makeLoginScreen(session: session)
        } tabContent: { tab, userID in
            switch tab {
            case .search:
                SearchAssembly.makeSearchScreen(repo: searchRepo,
                                                analytics: analytics,
                                                rowAccessory: rowAccessory)
            case .posting:
                PostingAssembly.makeEntryScreen(repo: postingRepo,
                                                drafts: drafts,
                                                analytics: analytics)
            case .favorites:
                SearchAssembly.makeFavoritesScreen(repo: searchRepo, rowAccessory: rowAccessory)
            case .profile:
                ProfileAssembly.makeProfileScreen(userID: userID, session: session)
            }
        }
    }
}

/// Реализация протокола, объявленного в AppFeature.
/// Резолв вертикали по id — единственное, что клиент не может решить сам.
struct RemoteListingResolver: ListingResolving {
    func vertical(for id: ListingID) async throws -> Vertical {
        try? await Task.sleep(for: .milliseconds(500))
        // Демо: в настоящем проекте — GET /listing/{id}/meta.
        return id.rawValue.hasPrefix("a-") ? .auto : .goods
    }
}
