import SwiftUI
import SharedKernel
import DesignComponents
import DesignTokens

/// Каркас карточки объявления.
///
/// Не хранит вью — параметризован их типами. Конкретные типы подставляет
/// вызывающая сторона, поэтому SwiftUI знает форму поддерева на компиляции:
/// узлы аллоцируются один раз, сравнение POD-полей отсекает ветки без вызова body.
///
/// Для карточки авто выводится, например:
///   ListingDetailScaffold<
///       SchemaSection,
///       TupleView<(VINReportCard, OwnersHistory,
///                  _ConditionalContent<DealerWarrantyBanner, EmptyView>)>
///   >
/// Этот тип никто не пишет руками — `some View` в body его прячет.
///
/// С `let extras: AnyView` вместо дженерика поддерево сносилось бы при каждой
/// смене типа внутри коробки: раскрытые секции схлопываются, @State сбрасывается,
/// AsyncImage перезагружается, выбранные даты в календаре исчезают.
///
/// Каркас не знает ни одной вертикали. Переходы наружу — через замыкания,
/// маршрут выбирает та фича, которая его вызывает.
public struct ListingDetailScaffold<Attributes: View, Extras: View>: View {
    private let header: ListingHeader
    private let attributes: Attributes
    private let extras: Extras
    private let onSellerTap: () -> Void
    private let onContact: () -> Void

    public init(
        header: ListingHeader,
        onSellerTap: @escaping () -> Void,
        onContact: @escaping () -> Void,
        @ViewBuilder attributes: () -> Attributes,
        @ViewBuilder extras: () -> Extras
    ) {
        self.header = header
        self.onSellerTap = onSellerTap
        self.onContact = onContact
        self.attributes = attributes()
        self.extras = extras()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Gallery(photoCount: header.photoCount, isPromoted: header.isPromoted)
                PriceBlock(header: header)
                attributes                                  // ← слот вертикали
                SellerBlock(seller: header.seller, onTap: onSellerTap)
                extras                                      // ← слот вертикали
                Color.clear.frame(height: Spacing.xl)
            }
            .padding(.horizontal, Spacing.l)
        }
        .navigationTitle(header.title)
        .compactNavigationTitle()
        .safeAreaInset(edge: .bottom) {
            ContactBar(onContact: onContact)
        }
    }
}
