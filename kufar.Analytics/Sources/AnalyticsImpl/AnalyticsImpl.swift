import Foundation
import AnalyticsAPI
import NetworkingInterface

/// Здесь жил бы `import Amplitude`. Вендорский SDK не попадает в граф
/// ни одной вертикали: они знают только AnalyticsAPI.
public final class BatchingTracker: AnalyticsTracking, @unchecked Sendable {
    private let client: any HTTPPerforming
    private let lock = NSLock()
    private var queue: [AnalyticsEvent] = []
    private let batchSize: Int

    public init(client: any HTTPPerforming, batchSize: Int = 20) {
        self.client = client
        self.batchSize = batchSize
    }

    public func track(_ event: AnalyticsEvent) {
        lock.lock()
        queue.append(event)
        let shouldFlush = queue.count >= batchSize
        lock.unlock()
        if shouldFlush { flush() }
    }

    public func flush() {
        lock.lock()
        let batch = queue
        queue.removeAll()
        lock.unlock()
        guard !batch.isEmpty else { return }
        // Отправка батча. Замена вендора переписывает только этот класс.
    }
}
