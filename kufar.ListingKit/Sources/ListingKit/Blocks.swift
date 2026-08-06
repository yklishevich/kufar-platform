import SwiftUI
import SharedKernel
import DesignComponents
import DesignTokens

/// Блоки, общие для всех вертикалей. Появился зум в галерее — один PR здесь,
/// и его получили все вертикали сразу.

public struct Gallery: View {
    private let photoCount: Int
    private let isPromoted: Bool
    @State private var index = 0

    public init(photoCount: Int, isPromoted: Bool) {
        self.photoCount = photoCount
        self.isPromoted = isPromoted
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $index) {
                ForEach(0..<max(photoCount, 1), id: \.self) { i in
                    // В демо вместо фото — заглушка: ресурсы в пакете не нужны.
                    RoundedRectangle(cornerRadius: Radius.card)
                        .fill(Palette.surface)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(Palette.secondaryText)
                        }
                        .tag(i)
                }
            }
            .frame(height: 220)
            #if os(iOS)
            .tabViewStyle(.page)
            #endif

            if isPromoted {
                Badge("Продвинуто")
                    .padding(Spacing.m)
            }
        }
    }
}

public struct PriceBlock: View {
    private let header: ListingHeader

    public init(header: ListingHeader) {
        self.header = header
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(header.price.formatted)
                .font(Typography.price)
            Text(header.title)
                .font(Typography.title)
            Text(header.publishedAt, style: .relative)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)
        }
    }
}

public struct SellerBlock: View {
    private let seller: Seller
    private let onTap: () -> Void

    public init(seller: Seller, onTap: @escaping () -> Void) {
        self.seller = seller
        self.onTap = onTap
    }

    public var body: some View {
        SectionCard {
            Button(action: onTap) {
                HStack(spacing: Spacing.m) {
                    Image(systemName: seller.isCompany ? "building.2" : "person.crop.circle")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(seller.name).font(Typography.title)
                        Text("Рейтинг \(seller.rating, specifier: "%.1f")")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

public struct ContactBar: View {
    private let onContact: () -> Void

    public init(onContact: @escaping () -> Void) {
        self.onContact = onContact
    }

    public var body: some View {
        PrimaryButton("Написать продавцу", systemImage: "message", action: onContact)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(.bar)
    }
}

/// Строка ленты.
///
/// От пересоздания ячейки при обновлении выдачи защищает не тип строки, а `id`
/// в `ForEach`: `ListingRef` идентифицируется по `id`, и `ForEach(items)` берёт
/// именно его. С `id: \.self` идентичностью стало бы всё значение целиком —
/// и появись у объявления счётчик просмотров или «5 минут назад», каждая
/// перезагрузка давала бы новые хеши, то есть удаление и вставку вместо
/// обновления. Сейчас в `ListingRef` изменяемых полей нет, правило на будущее.
///
/// Конкретный тип строки — про другое и от этого не спасает: он сохраняет
/// identity поддерева при смене того, что лежит внутри. Две независимые оси,
/// их легко перепутать.
///
/// Слот `accessory` — дженерик, а не `AnyView`. Каркас стирания не навязывает:
/// решение стереть принимает вызывающая сторона, и в этой схеме она принимает
/// его ровно один раз — см. `ListingRowAccessory` ниже.
public struct ListingRow<Accessory: View>: View {
    private let ref: ListingRef
    private let showsVerticalBadge: Bool
    private let accessory: Accessory

    public init(
        ref: ListingRef,
        showsVerticalBadge: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.ref = ref
        self.showsVerticalBadge = showsVerticalBadge
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            RoundedRectangle(cornerRadius: Radius.thumbnail)
                .fill(Palette.surface)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(Palette.secondaryText)
                }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(ref.title)
                    .font(Typography.title)
                    .lineLimit(2)
                Text(ref.price.formatted)
                    .font(.subheadline.weight(.semibold))
                accessory                       // ← слот вертикали
                if showsVerticalBadge {
                    // Имя вертикали приходит из ядра. Каркас не знает ни одной
                    // вертикали — ни импортом, ни строкой, ни сравнением.
                    Badge(ref.vertical.title, color: Palette.accent)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

public extension ListingRow where Accessory == EmptyView {
    /// Строка без акцессора: превью, снапшот-тесты и демо-приложение
    /// отдельной вертикали, где внедрять некого.
    init(ref: ListingRef, showsVerticalBadge: Bool = false) {
        self.init(ref: ref, showsVerticalBadge: showsVerticalBadge) { EmptyView() }
    }
}

/// Фабрика акцессорной строки. Единственное место в схеме, где тип вью стёрт, —
/// и правило, по которому это решается, сформулировано здесь целиком:
///
/// > Стирай там, где нечего терять,
/// > и держи наготове признак, по которому это перестанет быть правдой.
///
/// Формулировка намеренно не звучит как «`AnyView` — зло, кроме одного случая».
/// Так исключений нет вовсе: есть критерий и записанное условие его пересмотра.
///
/// **Что значит «нечего терять».** Дженерик работал бы и здесь: `switch`
/// в `@ViewBuilder` даёт `_ConditionalContent`, а не `AnyView`. Значит выбор,
/// а не необходимость, и решает то, что лежит внутри коробки. Стирание бьёт
/// по identity, а identity важна ровно там, где есть что терять: `@State`,
/// анимации, фокус ввода, загруженная картинка. Сегодня внутри — `Label`,
/// посчитанный из цены объявления: ни состояния, ни анимации, ни сети.
/// Пересоздавай его хоть каждый кадр, наблюдаемой разницы нет.
///
/// **Тот же критерий объясняет места, где стирания нет.** Слот карточки (5.2)
/// держит раскрытый `VINReportCard` с `@State`, шаг подачи — введённый VIN
/// и флаг загрузки. Стереть их значит терять пользовательский ввод на ровном
/// месте, поэтому там дженерик. Одно правило, три разных ответа.
///
/// **Признак, по которому правило перестаёт действовать.** Как только
/// в акцессор въезжает `@State`, `AsyncImage`, анимация или фокус — коробку
/// снимают и переходят на дженерик: `SearchScreen<Accessory>`,
/// `FavoritesScreen<Accessory>`, `SearchDestinations<Accessory>` плюс три
/// дженериковые функции в `SearchAssembly`. Цена перехода посчитана заранее
/// именно для того, чтобы «дорого» не стало отговоркой: по-настоящему дорого
/// станет позже, когда на слетающее состояние начнут жаловаться пользователи.
///
/// То же предупреждение продублировано в `AutoRowAccessory` — то есть там, где
/// его нарушат. Условие, записанное только у того, кто его соблюдает, бесполезно:
/// `@State` добавит разработчик вертикали, а он этот файл не открывает.
///
/// **Коробка опущена максимально глубоко** (правило из раздела 6): она вокруг
/// акцессорной строки, а не вокруг ячейки. Контейнер, миниатюра, цена, бейдж,
/// свайпы и `@State` самой строки сохраняют identity — теряет только акцессор.
///
/// В Swift 6 mode тип попросит `@MainActor`: замыкание строит вью. В Swift 5
/// изоляция здесь не пересекается — фабрику создаёт composition root, вызывает
/// `body`, оба на главном акторе.
public struct ListingRowAccessory {
    private let make: (ListingRef) -> AnyView

    /// `Content` выводится из замыкания: `switch` по вертикали в composition root
    /// даёт `_ConditionalContent<…>`, то есть один конкретный тип на все вертикали.
    /// Стирание происходит ровно здесь, на один уровень глубже.
    public init<Content: View>(@ViewBuilder make: @escaping (ListingRef) -> Content) {
        self.make = { AnyView(make($0)) }
    }

    /// Ни одна вертикаль не внедрена. Ровно это видит демо-приложение
    /// отдельной вертикали — и лента обязана в нём работать.
    public static var none: ListingRowAccessory {
        ListingRowAccessory { _ in EmptyView() }
    }

    public func view(for ref: ListingRef) -> AnyView { make(ref) }
}
