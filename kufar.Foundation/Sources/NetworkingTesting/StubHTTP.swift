#if DEBUG
import Foundation
import NetworkingInterface

/// #if DEBUG вокруг ВСЕГО содержимого — намеренно, ровно как в
/// `SessionInterfaceTesting`.
///
/// В SPM нет `.when(configuration: .debug)`: условия работают по платформам
/// и трейтам, поэтому этот таргет линкуется и в релиз. В релизе от него
/// остаётся пустой модуль.
///
/// Гарантия от утечки в прод: правило на ревью — `import *Testing`
/// вне тестов и вне `#if DEBUG` есть красный флаг.
public final class StubHTTP: HTTPPerforming, @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [String: Result<Data, any Error>]
    private var recorded: [String] = []

    /// Ключ — путь целиком, как его передаёт репозиторий: `goods/42`.
    public init(_ responses: [String: Result<Data, any Error>] = [:]) {
        self.responses = responses
    }

    /// Пути в порядке вызова. Проверять стоит и их: репозиторий, собравший
    /// неверный URL, вернёт правильно разобранную заглушку и тест пройдёт.
    public var requestedPaths: [String] {
        lock.lock(); defer { lock.unlock() }
        return recorded
    }

    public func stub(_ path: String, with result: Result<Data, any Error>) {
        lock.lock(); defer { lock.unlock() }
        responses[path] = result
    }

    public func get(_ path: String) async throws -> Data {
        lock.lock()
        recorded.append(path)
        let response = responses[path]
        lock.unlock()

        switch response {
        case let .success(data): return data
        case let .failure(error): throw error
        // Молчаливый пустой ответ прятал бы опечатку в пути: репозиторий
        // спросил не то, декодер получил ноль байт, тест упал бы позже
        // и не там. Лучше сказать прямо, чего не хватает.
        case nil: throw StubHTTPError.noStub(path: path)
        }
    }
}

public enum StubHTTPError: Error, CustomStringConvertible {
    case noStub(path: String)

    public var description: String {
        switch self {
        case let .noStub(path):
            return "StubHTTP: нет заглушки для пути \"\(path)\""
        }
    }
}
#endif
