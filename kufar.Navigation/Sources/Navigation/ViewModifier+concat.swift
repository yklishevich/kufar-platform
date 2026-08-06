import SwiftUI

public extension ViewModifier {
    /// Склейка destinations разных фич.
    ///
    /// Результат — ModifiedContent<Self, Other>, который сам ViewModifier.
    /// Добавилась вертикаль — ещё один .concat. Никакого AnyView и никакого
    /// реестра: navigationDestination строит ветки статически.
    func concat<Other: ViewModifier>(_ other: Other) -> ModifiedContent<Self, Other> {
        ModifiedContent(content: self, modifier: other)
    }
}
