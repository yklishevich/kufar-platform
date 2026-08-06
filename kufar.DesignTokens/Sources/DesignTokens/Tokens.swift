import SwiftUI

/// Чистые значения. В настоящем проекте генерируются из Figma.
///
/// Отдельно от DesignComponents намеренно: правка отступа в кнопке не должна
/// инвалидировать кеш сборки всего, что зависит от компонентов.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
}

public enum Radius {
    public static let card: CGFloat = 12
    public static let thumbnail: CGFloat = 8
}

public enum Palette {
    public static let accent = Color.blue
    public static let promoted = Color.orange
    public static let surface = Color.gray.opacity(0.12)
    public static let secondaryText = Color.secondary
}

public enum Typography {
    public static let price = Font.title2.weight(.semibold)
    public static let title = Font.headline
    public static let caption = Font.caption
}
