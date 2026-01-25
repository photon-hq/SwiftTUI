import Foundation

// MARK: - Button Highlight Style

/// Defines how a button appears when focused/highlighted
public enum ButtonHighlightStyle: Equatable {
    /// Default behavior - inverts foreground and background colors
    case inverted
    /// Only changes the text color when focused (no background change)
    case textColor(Color)
    /// No visual change when focused
    case none
}

// MARK: - Environment Key

private struct ButtonHighlightStyleKey: EnvironmentKey {
    static var defaultValue: ButtonHighlightStyle = .inverted
}

extension EnvironmentValues {
    public var buttonHighlightStyle: ButtonHighlightStyle {
        get { self[ButtonHighlightStyleKey.self] }
        set { self[ButtonHighlightStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Sets the highlight style for buttons within this view hierarchy
    ///
    /// Use this modifier to customize how buttons appear when they receive focus.
    ///
    /// Example:
    /// ```swift
    /// Button("Click Me") {
    ///     print("Pressed!")
    /// }
    /// .buttonHighlightStyle(.textColor(.cyan))
    /// ```
    ///
    /// - Parameter style: The highlight style to apply
    /// - Returns: A view with the specified button highlight style
    func buttonHighlightStyle(_ style: ButtonHighlightStyle) -> some View {
        environment(\.buttonHighlightStyle, style)
    }
}
