import Foundation

// MARK: - View Extension

public extension View {
    /// Adds an action to perform when a specific key is pressed.
    ///
    /// Use this modifier to detect when the user presses a specific key
    /// anywhere in the view hierarchy (not captured by a TextField).
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Text("Press 'q' to quit")
    /// }
    /// .onKeyPress("q") {
    ///     exit(0)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The character to listen for
    ///   - action: The action to perform when the key is pressed
    /// - Returns: A view that triggers the action when the specified key is pressed
    func onKeyPress(_ key: Character, action: @escaping () -> Void) -> some View {
        OnKeyPress(content: self, handler: { char in
            if char == key {
                action()
                return true
            }
            return false
        })
    }
    
    /// Adds an action to perform when any key is pressed.
    ///
    /// Use this modifier to detect any key press anywhere in the view hierarchy
    /// (not captured by a TextField).
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Text("Press any key")
    /// }
    /// .onKeyPress { char in
    ///     print("Key pressed: \(char)")
    ///     return true // Return true if handled, false to propagate
    /// }
    /// ```
    ///
    /// - Parameter action: The action to perform when any key is pressed.
    ///   Return `true` if the key was handled, `false` to allow propagation.
    /// - Returns: A view that triggers the action when any key is pressed
    func onKeyPress(action: @escaping (Character) -> Bool) -> some View {
        OnKeyPress(content: self, handler: action)
    }
}

// MARK: - OnKeyPress View

private struct OnKeyPress<Content: View>: View, PrimitiveView, ModifierView {
    let content: Content
    let handler: (Character) -> Bool
    
    static var size: Int? { Content.size }
    
    func buildNode(_ node: Node) {
        node.addNode(at: 0, Node(view: content.view))
    }
    
    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: content.view)
    }
    
    func passControl(_ control: Control, node: Node) -> Control {
        if let onKeyPressControl = control.parent as? OnKeyPressControl {
            onKeyPressControl.handler = handler
            return onKeyPressControl
        }
        let onKeyPressControl = OnKeyPressControl(handler: handler)
        onKeyPressControl.addSubview(control, at: 0)
        return onKeyPressControl
    }
}

// MARK: - OnKeyPress Control

private class OnKeyPressControl: Control {
    var handler: (Character) -> Bool
    
    init(handler: @escaping (Character) -> Bool) {
        self.handler = handler
    }
    
    override func size(proposedSize: Size) -> Size {
        children[0].size(proposedSize: proposedSize)
    }
    
    override func layout(size: Size) {
        super.layout(size: size)
        children[0].layout(size: size)
    }
    
    override func handleEvent(_ char: Character) {
        // Try to handle the key press
        if handler(char) {
            return // Key was handled, don't propagate
        }
        // Propagate to children if not handled
        super.handleEvent(char)
    }
}
