import SwiftUI
import SharedKernel
import Navigation
import GoodsInterface
import AutoInterface
import DesignComponents
import DesignTokens

/// Протокол объявлен здесь — у потребителя, а не у реализации.
/// Реализуется в композиционном корне, который единственный знает,
/// куда ходить за метаданными объявления.
public protocol ListingResolving: Sendable {
    func vertical(for id: ListingID) async throws -> Vertical
}

/// Экран-прокладка живёт в AppFeature, а не в вертикали: он не принадлежит
/// ни одной из них — это маршрутизация.
public struct ListingResolveRoute: Hashable, Codable, Sendable {
    public let id: ListingID
    public init(id: ListingID) { self.id = id }
}

public struct WebFallbackRoute: Hashable, Codable, Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
}

struct ListingResolveScreen: View {
    @Environment(Router.self) private var router

    let id: ListingID
    let resolver: any ListingResolving

    var body: some View {
        VStack(spacing: Spacing.l) {
            ProgressView()
            Text("Открываем объявление…")
                .foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                let vertical = try await resolver.vertical(for: id)
                // replaceLast, а не push: иначе кнопка «назад» из карточки
                // возвращает пользователя на этот же экран загрузки.
                switch vertical {
                case .goods: router.replaceLast(with: GoodsRoute.details(id))
                case .auto:  router.replaceLast(with: AutoRoute.details(id))
                }
            } catch {
                let url = URL(string: "https://www.kufar.by/item/\(id.rawValue)")!
                router.replaceLast(with: WebFallbackRoute(url: url))
            }
        }
    }
}

struct WebFallbackScreen: View {
    let url: URL

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "safari").font(.largeTitle)
            Text("Этот раздел не входит в текущую сборку")
                .font(Typography.title)
            Link(url.absoluteString, destination: url)
                .font(.footnote)
        }
        .padding(Spacing.xl)
        .navigationTitle("Открыть в вебе")
    }
}

/// Destinations самого корня: резолв объявления и веб-фолбэк.
/// Подмешиваются в общую цепочку наравне с destinations вертикалей.
public struct AppDestinations: ViewModifier {
    private let resolver: any ListingResolving

    public init(resolver: any ListingResolving) {
        self.resolver = resolver
    }

    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: ListingResolveRoute.self) { route in
                ListingResolveScreen(id: route.id, resolver: resolver)
            }
            .navigationDestination(for: WebFallbackRoute.self) { route in
                WebFallbackScreen(url: route.url)
            }
    }
}
