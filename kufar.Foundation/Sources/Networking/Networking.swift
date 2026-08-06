import Foundation

/// Протокол объявлен здесь, а реализован в Auth — уровнем выше.
///
/// Это инверсия зависимостей: зависимость сборки идёт Auth → Networking (вниз),
/// вызов в рантайме — снизу вверх. Положи протокол в Auth — и сети пришлось бы
/// импортировать аутентификацию: цикл.
///
/// Практическая причина именно для классифайда: лента гостю, поиск и просмотр
/// объявления работают до логина. Сеть, умеющая только авторизованные запросы,
/// не переиспользуется для большей части трафика.
public protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
    func retry(_ request: URLRequest, dueTo error: any Error) async -> RetryDecision
}

public enum RetryDecision: Sendable {
    case retry
    case giveUp
}

public struct APIClient: Sendable {
    private let baseURL: URL
    private let interceptors: [any RequestInterceptor]

    public init(baseURL: URL, interceptors: [any RequestInterceptor] = []) {
        self.baseURL = baseURL
        self.interceptors = interceptors
    }

    /// В демо сеть не ходит: клиент существует, чтобы показать место в графе
    /// и единственную точку, где собираются интерсепторы.
    public func get(_ path: String) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }
        return Data()
    }
}

public extension URL {
    static let production = URL(string: "https://api.kufar.by")!
}
