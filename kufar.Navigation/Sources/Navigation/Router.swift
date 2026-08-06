import SwiftUI
import Observation

/// Общий примитив навигации на 20 строк.
///
/// NavigationPath принимает любой Hashable, поэтому Router не знает
/// ни одного маршрута конкретной фичи — и ни от чего не зависит.
///
/// @Observable, а не ObservableObject: второй перерисовывает всех подписчиков
/// на каждое изменение path, включая экраны, которые путь не читают.
@MainActor
@Observable
public final class Router {
    public var path = NavigationPath()

    public init() {}

    public func push(_ route: some Hashable) {
        path.append(route)
    }

    public func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    public func popToRoot() {
        path = NavigationPath()
    }

    /// Замена последнего элемента: экран-прокладка резолвит объявление
    /// и подменяет себя настоящей карточкой.
    ///
    /// Не push — иначе кнопка «назад» из карточки возвращает на скелетон.
    public func replaceLast(with route: some Hashable) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }
}
