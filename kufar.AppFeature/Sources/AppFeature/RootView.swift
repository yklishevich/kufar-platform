import SwiftUI
import SharedKernel
import SessionInterface
import Navigation
import DesignTokens

/// Корневой флоу. Знает только контракты, поэтому собирается без Networking,
/// без единого *Data и без единой вертикали — и превьюится с заглушками.
///
/// Дженерики плюс @ViewBuilder на параметрах init дают _ConditionalContent:
/// тип выводится на месте вызова, стирания нет. Тот же приём, что в слотах
/// каркаса карточки, только на другой границе.
public struct RootView<Tabs: View, Login: View, Destinations: ViewModifier>: View {
    @State private var app = AppRouter()
    @State private var state: SessionState = .unknown

    private let session: any SessionStore
    private let parser: RouteParser
    private let destinations: Destinations
    private let login: () -> Login
    private let tabContent: (AppTab, User.ID) -> Tabs

    public init(
        session: any SessionStore,
        parser: RouteParser,
        destinations: Destinations,
        @ViewBuilder login: @escaping () -> Login,
        @ViewBuilder tabContent: @escaping (AppTab, User.ID) -> Tabs
    ) {
        self.session = session
        self.parser = parser
        self.destinations = destinations
        self.login = login
        self.tabContent = tabContent
    }

    public var body: some View {
        Group {
            switch state {
            case .unknown:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .signedOut:
                login()
            case .signedIn(let userID):
                tabs(userID: userID)
            }
        }
        .animation(.default, value: state)
        .task {
            // Поток создан в init стора, поэтому событие restore()
            // не теряется при любом порядке.
            Task { await session.restore() }
            for await new in session.updates {
                if case .signedOut = new {
                    // Не косметика: иначе следующий пользователь увидит
                    // стек предыдущего, включая экраны с его данными.
                    app.resetAll()
                }
                state = new
            }
        }
        .onOpenURL(perform: handle)
    }

    private func tabs(userID: User.ID) -> some View {
        TabView(selection: selection) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                NavigationStack(path: app.path(for: tab)) {
                    tabContent(tab, userID)
                        // Все destinations в каждом табе — намеренно.
                        // Из ленты тапнул продавца → профиль пушится ВНУТРИ
                        // таба «Поиск». Так работают все нативные приложения.
                        .modifier(destinations)
                }
                .environment(app.router(for: tab))
                .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                .tag(tab)
            }
        }
    }

    /// Повторный тап по активному табу — pop to root (системное поведение iOS).
    private var selection: Binding<AppTab> {
        Binding(
            get: { app.selected },
            set: { new in
                if new == app.selected {
                    app.router(for: new).popToRoot()
                }
                app.selected = new
            }
        )
    }

    /// Карточка любой вертикали открывается в табе «Поиск»: пользователь
    /// пришёл смотреть объявление, а не переключать раздел.
    private func handle(_ url: URL) {
        switch parser.parse(url) {
        case .search(let route):
            app.open(route, in: .search)
        case .posting(let route):
            app.open(route, in: .posting)
        case .goods(let route):
            app.open(route, in: .search)
        case .auto(let route):
            app.open(route, in: .search)
        case .profile(let route):
            app.open(route, in: .profile)
        case .resolveListing(let id):
            app.open(ListingResolveRoute(id: id), in: .search)
        case .web(let url):
            app.open(WebFallbackRoute(url: url), in: app.selected)
        }
    }
}
