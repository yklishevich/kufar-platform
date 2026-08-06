import SwiftUI
import AppComposition

/// Весь app-таргет целиком. В @main — только AppComposition.
///
/// Как подключить:
///   1. Xcode → File → New → Project → iOS App (SwiftUI), назвать KufarDemo;
///   2. удалить сгенерированные ContentView.swift и <Имя>App.swift;
///   3. перетащить этот файл в проект;
///   4. File → Add Package Dependencies → Add Local → выбрать папку
///      KufarArchitectureDemo;
///   5. в таргете приложения → Frameworks, Libraries → добавить AppComposition.
///
/// Проверить диплинк:
///   в схеме таргета добавить URL Type со схемой `kufar`, затем в терминале
///   xcrun simctl openurl booted "kufar://item/a-0-2"
///   — откроется экран-прокладка, который резолвит вертикаль и подменит себя
///   карточкой авто.
@main
struct KufarDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AppComposition.rootView()
        }
    }
}
