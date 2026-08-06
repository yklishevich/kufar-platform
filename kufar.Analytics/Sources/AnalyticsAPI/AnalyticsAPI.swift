import Foundation
import SharedKernel

/// Контракт без единой зависимости от вендора.
/// Строка `import AnalyticsImpl` существует ровно в одном файле — в AppComposition.
public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

public struct AnalyticsEvent: Hashable, Sendable {
    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }

    public static func listingOpened(id: ListingID, vertical: Vertical) -> AnalyticsEvent {
        AnalyticsEvent(name: "listing_opened",
                       parameters: ["id": id.rawValue, "vertical": vertical.rawValue])
    }

    public static func contactRequested(id: ListingID) -> AnalyticsEvent {
        AnalyticsEvent(name: "contact_requested", parameters: ["id": id.rawValue])
    }

    /// Деградация — не молчание. Карточка выживает без блока атрибутов,
    /// но сломанная схема обязана быть видна в мониторинге, иначе о ней
    /// узнают из отзывов в App Store.
    public static func schemaDecodeFailed(id: ListingID, vertical: Vertical) -> AnalyticsEvent {
        AnalyticsEvent(name: "schema_decode_failed",
                       parameters: ["id": id.rawValue, "vertical": vertical.rawValue])
    }
}

/// Стаб для тестов и превью. Ни сети, ни SDK, ни диска.
public final class SpyTracker: AnalyticsTracking, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AnalyticsEvent] = []

    public init() {}

    public var events: [AnalyticsEvent] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    public func track(_ event: AnalyticsEvent) {
        lock.lock(); defer { lock.unlock() }
        storage.append(event)
    }
}
