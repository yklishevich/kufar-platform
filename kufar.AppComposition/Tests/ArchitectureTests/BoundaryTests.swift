import XCTest

/// Проверки границ на уровне воркспейса.
///
/// Таргет не импортирует ни одного модуля — читает манифесты и исходники
/// по #filePath. Поэтому он ничего не «знает» и ничего не тянет за собой.
///
/// Часть правил здесь дублирует Tools/deplint.py намеренно: линтер живёт
/// в CI, а эти тесты запускаются вместе с обычными в Xcode.
final class BoundaryTests: XCTestCase {

    /// .../app/KufarAppComposition/Tests/ArchitectureTests/файл.swift → воркспейс
    private var workspace: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ArchitectureTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // KufarAppComposition
            .deletingLastPathComponent()   // platform_team
    }

    private let verticals = ["Search", "Goods", "Auto", "Profile", "Auth"]

    private struct Manifest {
        let name: String
        let url: URL
        let text: String

        var products: [String] { text.quoted(after: ".library(name: \"") }
        /// Зависимости объявлены по URL; имя пакета — последний компонент.
        var dependencyNames: [String] {
            text.quoted(after: ".package(url: \"").map {
                var name = ($0 as NSString).lastPathComponent
                if name.hasSuffix(".git") { name.removeLast(4) }
                return name
            }
        }
    }

    private func manifests() throws -> [Manifest] {
        var result: [Manifest] = []
        let walker = FileManager.default.enumerator(at: workspace, includingPropertiesForKeys: nil)
        while case let url as URL = walker?.nextObject() {
            guard url.lastPathComponent == "Package.swift" else { continue }
            guard !url.path().contains("/.attic/"), !url.path().contains("/.build/") else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            let name = text.quoted(after: "name: \"").first ?? "?"
            result.append(Manifest(name: name, url: url, text: text))
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
                                "GoodsUI", "GoodsData", "GoodsDomain",
                                "AutoUI", "AutoData", "AutoDomain",
                                "ProfileUI", "AuthUI", "AuthData"]
        for manifest in try manifests() {
            for product in manifest.products where mustStayInternal.contains(product) {
                XCTFail("\(manifest.name): \(product) объявлен продуктом — "
                        + "внутренний таргет стал публичным API репозитория")
            }
        }
    }

    /// Контрактный пакет должен оставаться дешёвым для подключения:
    /// кто берёт маршруты чужой вертикали, не должен резолвить её
    /// дизайн-систему, аналитику и SwiftUI-граф.
    func testContractPackagesStayCheap() throws {
        let contracts = ["KufarSearchContracts", "KufarGoodsContracts",
                         "KufarAutoContracts", "KufarIdentityContracts"]
        for manifest in try manifests() where contracts.contains(manifest.name) {
            let deps = manifest.dependencyNames
            XCTAssertEqual(deps, ["KufarFoundation"],
                           "\(manifest.name) тянет лишнее: \(deps)")
        }
    }

    /// Repo == package == folder. Локальная подмена в воркспейсе работает
    /// по identity, а identity — это имя папки. Разъедутся — Xcode пойдёт
    /// в сеть за версией, которой ещё нет.
    func testPackageNameMatchesFolderName() throws {
        for manifest in try manifests() {
            let folder = manifest.url.deletingLastPathComponent().lastPathComponent
            XCTAssertEqual(manifest.name, folder,
                           "пакет \(manifest.name) лежит в папке \(folder)")
        }
    }

    /// Композиционный корень не знает ни одного экрана: assembly возвращают
    /// непрозрачные типы, поэтому import *UI ему не нужен.
    func testCompositionRootDoesNotImportUI() throws {
        let root = workspace.appending(path: "platform_team/KufarAppComposition/Sources")
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
