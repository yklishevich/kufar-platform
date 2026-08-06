import SwiftUI
import SharedKernel

/// Общая часть любого объявления, одинаковая во всех вертикалях.
/// Всё, что различается, приходит через слоты каркаса.
public struct ListingHeader: Hashable, Sendable, Identifiable {
    public let id: ListingID
    public let title: String
    public let price: Money
    public let photoCount: Int
    public let seller: Seller
    public let isPromoted: Bool
    public let publishedAt: Date

    public init(
        id: ListingID,
        title: String,
        price: Money,
        photoCount: Int,
        seller: Seller,
        isPromoted: Bool = false,
        publishedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.photoCount = photoCount
        self.seller = seller
        self.isPromoted = isPromoted
        self.publishedAt = publishedAt
    }
}
