import Foundation

/// Модели, общие для всей площадки. Ничего специфичного для вертикали.
///
/// Внимание: SharedKernel — часть публичного контракта между фичами,
/// потому что попадает в `*Interface`. Менять его свободно уже нельзя.

public enum User {
    public typealias ID = String
}

public struct Money: Hashable, Codable, Sendable {
    public let amount: Decimal
    public let currency: String

    public init(amount: Decimal, currency: String = "BYN") {
        self.amount = amount
        self.currency = currency
    }

    public var formatted: String {
        "\(NSDecimalNumber(decimal: amount).stringValue) \(currency)"
    }
}

/// Идентификатор объявления сквозной: по нему резолвится вертикаль.
public struct ListingID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ value: String) { self.rawValue = value }
}

/// Вертикали площадки. Живёт в ядре, потому что нужна и парсеру ссылок,
/// и резолву объявления, и аналитике — то есть самому нижнему потребителю.
public enum Vertical: String, Hashable, Codable, Sendable, CaseIterable {
    case goods
    case auto

    /// Отображаемое имя. Здесь, а не в компонентах, по той же причине,
    /// что и `AttributeValue.displayString`: показать вертикаль надо и ленте,
    /// и избранному, и каркасу карточки, а они друг о друге не знают.
    ///
    /// Главное — исчерпывающий `switch`. Общий компонент, пишущий
    /// `vertical == .auto ? "Авто" : "Товары"`, во-первых знает вертикали,
    /// хотя не должен, во-вторых молча подписывает новую вертикаль чужим
    /// именем: тернарник компилятор не остановит. Здесь добавление кейса
    /// ломает сборку ровно в одной точке — в том же файле, где вертикаль
    /// и заводят.
    ///
    /// В настоящем проекте — `String(localized:bundle: .module)` со строковым
    /// каталогом в этом же пакете; на ресурсы правило не меняется.
    public var title: String {
        switch self {
        case .goods: "Товары"
        case .auto: "Авто"
        }
    }
}

/// Ссылка на объявление в любой вертикали.
///
/// Нужна, чтобы блок «другие объявления продавца» мог содержать и товары,
/// и авто. Вертикаль здесь — данные; в маршрут её превращает та фича,
/// которая рисует блок, через exhaustive switch.
public struct ListingRef: Identifiable, Hashable, Codable, Sendable {
    public let id: ListingID
    public let vertical: Vertical
    public let title: String
    public let price: Money

    public init(id: ListingID, vertical: Vertical, title: String, price: Money) {
        self.id = id
        self.vertical = vertical
        self.title = title
        self.price = price
    }
}

public struct Seller: Hashable, Codable, Sendable {
    public let id: User.ID
    public let name: String
    public let rating: Double
    public let isCompany: Bool

    public init(id: User.ID, name: String, rating: Double, isCompany: Bool) {
        self.id = id
        self.name = name
        self.rating = rating
        self.isCompany = isCompany
    }
}

/// Значение атрибута объявления или поля фильтра.
///
/// Живёт в ядре, потому что нужно двоим, не знающим друг о друге:
/// рендереру схем (SchemaKit) и контракту поиска (SearchInterface).
/// Протокол — то есть тип — принадлежит самому нижнему потребителю.
public enum AttributeValue: Hashable, Codable, Sendable {
    case text(String)
    case number(Double)
    case flag(Bool)
    case reference(String)

    public var displayString: String {
        switch self {
        case .text(let value): value
        case .number(let value): value.rounded() == value ? String(Int(value))
                                                          : String(format: "%.1f", value)
        case .flag(let value): value ? "Да" : "Нет"
        case .reference(let value): value
        }
    }
}

/// Состояние загрузки экрана. Ошибка — такое же состояние, как данные:
/// `guard try? else { return }` оставляет пользователя наедине с вечным спиннером.
///
/// Три кейса вместо пары `var listing: T?` + `var isLoading: Bool` — чтобы
/// невозможные комбинации («не грузится и данных нет — это ошибка или ещё нет?»)
/// не были представимы в типе.
///
/// Живёт в ядре по той же причине, что AttributeValue: нужен каждой вертикали,
/// а SwiftUI ему не нужен — это чистый Swift.
public enum LoadState<Value: Sendable>: Sendable {
    case loading
    case loaded(Value)
    /// В демо классы ошибок не различаются. В проде здесь минимум два кейса:
    /// retryable (сеть, таймаут) и терминальный (объявление снято с публикации) —
    /// у них разные экраны и разное поведение кнопки «Повторить».
    case failed

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
extension LoadState: Hashable where Value: Hashable {}
