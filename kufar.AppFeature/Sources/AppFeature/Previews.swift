#if DEBUG
import SwiftUI
import SessionInterface
import SessionInterfaceTesting
import SharedKernel
import Navigation
import DesignComponents

/// Что даёт разделение AppFeature и AppComposition: корневой флоу
/// превьюится и тестируется без сети, без *Data и без единой вертикали.
/// EmptyModifier — штатный тип SwiftUI, заглушку писать не надо.
#Preview("Корень с заглушкой сессии") {
    RootView(
        session: StubSession(.signedIn("42")),
        parser: RouteParser(availableVerticals: Set(Vertical.allCases)),
        destinations: EmptyModifier()
    ) {
        Text("Экран логина")
    } tabContent: { tab, userID in
        SectionCard {
            Text("Таб \(tab.title), пользователь \(userID)")
        }
        .padding()
    }
}
#endif
