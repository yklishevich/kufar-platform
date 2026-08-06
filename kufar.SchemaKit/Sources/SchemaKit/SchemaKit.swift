import SwiftUI
import SharedKernel
import DesignComponents
import DesignTokens

/// Рендерер декларативных схем.
///
/// Одна и та же схема описывает и «по чему ищем», и «что показываем»:
/// `SchemaForm` рисует редактируемый экран фильтров, `SchemaSection` —
/// блок атрибутов в карточке. Поэтому вид поля (`kind`) и его значение
/// (`value`) разведены: в фильтре значение приходит от пользователя,
/// в карточке — с бэкенда.
///
/// Ключевая тонкость: server-driven UI ≠ AnyView. Сервер выбирает из каталога
/// примитивов, которые клиент уже умеет рисовать, а не присылает код. Значит
/// набор типов известен на компиляции, значит это enum + switch.

public enum FieldKind: Hashable, Sendable {
    case text
    case number(unit: String?)
    case toggle
    case reference(options: [String])
    /// Поле из будущей версии схемы. Скрывается, не роняет экран.
    case unknown
}

public struct SchemaField: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let title: String
    public let kind: FieldKind
    /// Значение из карточки. В фильтре не используется — там значения
    /// живут в состоянии экрана.
    public let value: AttributeValue?

    public init(id: String, title: String, kind: FieldKind, value: AttributeValue? = nil) {
        self.id = id
        self.title = title
        self.kind = kind
        self.value = value
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, type, value, unit, options
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)

        switch try container.decode(String.self, forKey: .type) {
        case "text":
            kind = .text
            value = try container.decodeIfPresent(String.self, forKey: .value).map(AttributeValue.text)
        case "number":
            kind = .number(unit: try container.decodeIfPresent(String.self, forKey: .unit))
            value = try container.decodeIfPresent(Double.self, forKey: .value).map(AttributeValue.number)
        case "toggle":
            kind = .toggle
            value = try container.decodeIfPresent(Bool.self, forKey: .value).map(AttributeValue.flag)
        case "reference":
            kind = .reference(options: try container.decodeIfPresent([String].self, forKey: .options) ?? [])
            value = try container.decodeIfPresent(String.self, forKey: .value).map(AttributeValue.reference)
        default:
            // Фолбэк на неизвестный тип — обязательная часть контракта.
            // Без него новое поле на бэке роняет старые сборки.
            kind = .unknown
            value = nil
        }
    }
}

// MARK: - Только чтение: блок атрибутов в карточке

public struct SchemaSection: View {
    private let fields: [SchemaField]

    public init(fields: [SchemaField]) {
        self.fields = fields
    }

    public var body: some View {
        SectionCard {
            ForEach(fields) { field in
                SchemaRow(field: field)
            }
        }
    }
}

/// Конкретный тип, не AnyView. switch в body даёт _ConditionalContent,
/// type identity сохраняется, поддерево не пересоздаётся.
struct SchemaRow: View {
    let field: SchemaField

    var body: some View {
        switch field.kind {
        case .unknown:
            EmptyView()
        case .number(let unit):
            LabeledRow(title: field.title, value: numberText(unit: unit))
        case .text, .toggle, .reference:
            LabeledRow(title: field.title, value: field.value?.displayString ?? "—")
        }
    }

    private func numberText(unit: String?) -> String {
        let base = field.value?.displayString ?? "—"
        guard let unit else { return base }
        return "\(base) \(unit)"
    }
}

// MARK: - Редактирование: экран фильтров

/// Тот же каталог примитивов, но с привязкой к состоянию.
/// Экран фильтров любой вертикали — это вызов SchemaForm со схемой,
/// пришедшей для выбранной категории.
public struct SchemaForm: View {
    private let fields: [SchemaField]
    @Binding private var values: [String: AttributeValue]

    public init(fields: [SchemaField], values: Binding<[String: AttributeValue]>) {
        self.fields = fields
        self._values = values
    }

    public var body: some View {
        ForEach(fields) { field in
            SchemaFieldEditor(field: field, value: binding(for: field))
        }
    }

    private func binding(for field: SchemaField) -> Binding<AttributeValue?> {
        Binding(
            get: { values[field.id] },
            set: { new in
                if let new { values[field.id] = new } else { values.removeValue(forKey: field.id) }
            }
        )
    }
}

struct SchemaFieldEditor: View {
    let field: SchemaField
    @Binding var value: AttributeValue?

    var body: some View {
        switch field.kind {
        case .text:
            TextField(field.title, text: textBinding)
        case .number(let unit):
            TextField(unit.map { "\(field.title), \($0)" } ?? field.title, text: numberBinding)
        case .toggle:
            Toggle(field.title, isOn: flagBinding)
        case .reference(let options):
            Picker(field.title, selection: referenceBinding) {
                Text("Любой").tag("")
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        case .unknown:
            EmptyView()
        }
    }

    private var textBinding: Binding<String> {
        Binding(get: { value?.displayString ?? "" },
                set: { value = $0.isEmpty ? nil : .text($0) })
    }

    private var numberBinding: Binding<String> {
        Binding(get: { value?.displayString ?? "" },
                set: { value = Double($0).map(AttributeValue.number) })
    }

    private var flagBinding: Binding<Bool> {
        Binding(get: { if case .flag(let on) = value { return on } else { return false } },
                set: { value = $0 ? .flag(true) : nil })
    }

    private var referenceBinding: Binding<String> {
        Binding(get: { value?.displayString ?? "" },
                set: { value = $0.isEmpty ? nil : .reference($0) })
    }
}
