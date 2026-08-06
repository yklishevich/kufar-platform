import XCTest

/// Проверки границ на уровне воркспейса.
///
/// Таргет не импортирует ни одного модуля — читает манифесты и исходники
/// по #filePath. Поэтому он ничего не «знает» и ничего не тянет за собой.
///
/// Часть правил здесь дублирует Tools/deplint.py намеренно: линтер живёт
/// в CI, а эти тесты запускаются вместе с обычными в Xcode.
final class BoundaryTests: XCTestCase {

    /// .../platform_team/kufar.AppComposition/Tests/ArchitectureTests/файл.swift → воркспейс
    private var workspace: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ArchitectureTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // kufar.AppComposition
            .deletingLastPathComponent()   // platform_team
    }

    private let scope = "kufar"
    private let verticals = ["Search", "Posting", "Goods", "Auto", "Profile", "Auth"]

    private struct Manifest {
        /// Идентичность пакета — имя папки (`kufar.Foundation`), а НЕ поле
        /// `name:` из манифеста. С переходом на реестр SE-0292 адрес перестал
        /// быть идентичностью, а `name:` ею никогда и не был: он остался
        /// отображаемым именем и ни на что не влияет.
        let identity: String
        let url: URL
        let text: String

        var products: [String] { text.quoted(after: ".library(name: \"") }

        /// Зависимости адресуются идентичностью реестра.
        var dependencies: [String] { text.quoted(after: ".package(id: \"") }
    }

    private func manifests() throws -> [Manifest] {
        var result: [Manifest] = []
        let walker = FileManager.default.enumerator(at: workspace, includingPropertiesForKeys: nil)
        while case let url as URL = walker?.nextObject() {
            guard url.lastPathComponent == "Package.swift" else { continue }
            guard !url.path().contains("/.attic/"), !url.path().contains("/.build/") else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            let identity = url.deletingLastPathComponent().lastPathComponent
            result.append(Manifest(identity: identity, url: url, text: text))
        }
        return result
    }

    private func swiftFiles(under directory: URL) -> [(URL, String)] {
        guard let walker = FileManager.default.enumerator(at: directory,
                                                          includingPropertiesForKeys: nil)
        else { return [] }
        var result: [(URL, String)] = []
        while case let url as URL = walker.nextObject() {
            guard url.pathExtension == "swift",
                  !url.path().contains("/.attic/"),
                  let text = try? String(contentsOf: url, encoding: .utf8)
            else { continue }
            result.append((url, text))
        }
        return result
    }

    private func imports(in text: String) -> [String] {
        text.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("import ") else { return nil }
            return String(trimmed.dropFirst("import ".count)).trimmingCharacters(in: .whitespaces)
        }
    }

    private func target(of url: URL) -> String? {
        let parts = url.pathComponents
        guard let index = parts.lastIndex(where: { $0 == "Sources" || $0 == "Tests" }),
              index + 1 < parts.count
        else { return nil }
        return parts[index + 1]
    }

    /// Интерфейс перестал быть data-only — самый частый способ незаметно
    /// утянуть SwiftUI-граф в превью и тесты чужих команд.
    func testInterfacesAreFoundationOnly() throws {
        for (url, text) in swiftFiles(under: workspace) {
            guard let target = target(of: url), target.hasSuffix("Interface"),
                  !target.hasSuffix("InterfaceTesting")
            else { continue }
            XCTAssertFalse(imports(in: text).contains("SwiftUI"),
                           "\(url.lastPathComponent): import SwiftUI в контракте \(target)")
        }
    }

    /// Вертикаль не видит вертикаль. Ходить можно только через *Interface,
    /// который лежит уровнем ниже и в отдельном пакете.
    func testVerticalsDoNotSeeEachOther() throws {
        for (url, text) in swiftFiles(under: workspace) {
            guard let target = target(of: url),
                  let own = verticals.first(where: { target == $0 || target.hasPrefix($0) })
            else { continue }
            for module in imports(in: text) {
                guard let foreign = verticals.first(where: { module == $0 || module.hasPrefix($0) }),
                      foreign != own
                else { continue }
                XCTAssertTrue(module.hasSuffix("Interface"),
                              "\(url.lastPathComponent): \(target) импортирует \(module) — "
                              + "горизонтальная зависимость, нужен \(foreign)Interface")
            }
        }
    }

    /// Главная страховка многопакетной схемы: внутренние таргеты вертикали
    /// не объявлены продуктами, поэтому импортировать их извне
    /// не даст SwiftPM — правило перестаёт быть договорённостью.
    func testInternalTargetsAreNotExported() throws {
        let mustStayInternal = ["SearchUI", "SearchData", "SearchDomain",
                                "PostingUI", "PostingData", "PostingDomain",
                                "GoodsUI", "GoodsData", "GoodsDomain",
                                "AutoUI", "AutoData", "AutoDomain",
                                "ProfileUI", "AuthUI", "AuthData"]
        for manifest in try manifests() {
            for product in manifest.products where mustStayInternal.contains(product) {
                XCTFail("\(manifest.identity): \(product) объявлен продуктом — "
                        + "внутренний таргет стал публичным API репозитория")
            }
        }
    }

    /// Контрактный пакет должен оставаться дешёвым для подключения: кто берёт
    /// маршруты чужой вертикали, не должен резолвить её дизайн-систему,
    /// аналитику и SwiftUI-граф.
    ///
    /// Контракту разрешено ядро и другие контракты — граф остаётся плоским.
    func testContractPackagesStayCheap() throws {
        let allowed = Set(["\(scope).Foundation"]
                          + try manifests().map(\.identity).filter { $0.hasSuffix("Contracts") })

        for manifest in try manifests() where manifest.identity.hasSuffix("Contracts") {
            let extra = manifest.dependencies.filter { !allowed.contains($0) }
            XCTAssertTrue(extra.isEmpty,
                          "\(manifest.identity) тянет лишнее: \(extra)")
        }
    }

    /// Идентичность пакета — имя его папки, и Xcode подменяет
    /// registry-зависимость локальной копией, сопоставляя именно их:
    ///
    ///   unable to override package 'Foundation' because its identity
    ///   'kufar.foundation' doesn't match override's identity
    ///   (directory name) 'foundation'
    ///
    /// Отсюда два требования: формат `scope.Name` у каждой папки и наличие
    /// папки под каждую объявленную зависимость. Поле `name:` из манифеста
    /// здесь ни при чём — оно давно не идентичность.
    func testPackageIdentityMatchesFolder() throws {
        let all = try manifests()
        let folders = Set(all.map(\.identity))

        for manifest in all {
            XCTAssertTrue(manifest.identity.hasPrefix("\(scope)."),
                          "папка \(manifest.identity) не в формате \(scope).Name — "
                          + "Xcode не подменит registry-зависимость локальной копией")

            for dependency in manifest.dependencies {
                XCTAssertTrue(folders.contains(dependency),
                              "\(manifest.identity) зависит от \(dependency), "
                              + "но папки с таким именем в воркспейсе нет")
            }
        }
    }

    /// Композиционный корень не знает ни одного экрана: assembly возвращают
    /// непрозрачные типы, поэтому import *UI ему не нужен.
    func testCompositionRootDoesNotImportUI() throws {
        let root = workspace.appending(path: "platform_team/\(scope).AppComposition/Sources")
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.path()),
                      "корень не найден по \(root.path()) — тест проверял бы пустоту")

        for (url, text) in swiftFiles(under: root) {
            for module in imports(in: text) where module.hasSuffix("UI") && module != "SwiftUI" {
                XCTFail("\(url.lastPathComponent): корень импортирует \(module)")
            }
        }
    }
}

private extension String {
    /// Все строковые литералы, идущие сразу за указанным префиксом.
    /// Проще регулярки и не зависит от форматирования манифеста.
    func quoted(after prefix: String) -> [String] {
        var result: [String] = []
        var rest = Substring(self)
        while let start = rest.range(of: prefix) {
            let tail = rest[start.upperBound...]
            guard let end = tail.firstIndex(of: "\"") else { break }
            result.append(String(tail[..<end]))
            rest = tail[end...]
        }
        return result
    }
}
