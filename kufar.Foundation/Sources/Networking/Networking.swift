import Foundation
import NetworkingInterface

/// Конформит `HTTPPerforming` из соседнего таргета: адаптеры вертикалей
/// держат протокол, а конкретный тип называет только composition root.
public struct APIClient: HTTPPerforming {
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
