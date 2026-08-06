import SwiftUI
import DesignTokens

/// Компоненты знают про токены, но не про вертикали и не про домен.
/// Снапшот-тесты этого таргета не поднимают приложение.

public struct SectionCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            content
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
    }
}

public struct LabeledRow: View {
    private let title: String
    private let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(Palette.secondaryText)
            Spacer(minLength: Spacing.m)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, Spacing.xs)
    }
}

public struct Badge: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color = Palette.promoted) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(Typography.caption.weight(.semibold))
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}

public struct PrimaryButton: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.m)
        }
        .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.card))
        .foregroundStyle(.white)
    }
}

/// Полноэкранная заглушка ошибки с ретраем.
/// Знает про токены, не знает про домен: текст и действие приходят снаружи.
public struct ErrorStateView: View {
    private let message: String
    private let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(Palette.secondaryText)
            Text(message)
                .font(Typography.title)
                .multilineTextAlignment(.center)
            Button("Повторить", action: retry)
                .buttonStyle(.bordered)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public extension View {
    /// navigationBarTitleDisplayMode есть только на iOS.
    /// Пакет собирается и под macOS, чтобы тесты гонялись на My Mac без симулятора.
    func compactNavigationTitle() -> some View {
        #if os(iOS)
        return navigationBarTitleDisplayMode(.inline)
        #else
        return self
        #endif
    }
}
