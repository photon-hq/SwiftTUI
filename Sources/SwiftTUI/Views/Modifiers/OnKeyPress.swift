import Foundation

// MARK: - Key Press Handler Environment Key

private struct KeyPressHandlerKey: EnvironmentKey {
    static var defaultValue: ((Character) -> Bool)? = nil
}

extension EnvironmentValues {
    var keyPressHandler: ((Character) -> Bool)? {
        get { self[KeyPressHandlerKey.self] }
        set { self[KeyPressHandlerKey.self] = newValue }
    }
}

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
        OnKeyPressView(content: self, key: key, action: action)
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
        OnKeyPressAnyView(content: self, action: action)
    }
}

// MARK: - OnKeyPress View (Specific Key)

struct OnKeyPressView<Content: View>: View, PrimitiveView {
    let content: Content
    let key: Character
    let action: () -> Void
    
    static var size: Int? { 1 }
    
    func buildNode(_ node: Node) {
        node.addNode(at: 0, Node(view: content))
        node.control = OnKeyPressControl(
            content: node.children[0].control(at: 0),
            handler: { char in
                if char == self.key {
                    self.action()
                    return true
                }
                return false
            }
        )
    }
    
    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: content)
    }
}

// MARK: - OnKeyPress View (Any Key)

struct OnKeyPressAnyView<Content: View>: View, PrimitiveView {
    let content: Content
    let action: (Character) -> Bool
    
    static var size: Int? { 1 }
    
    func buildNode(_ node: Node) {
        node.addNode(at: 0, Node(view: content))
        node.control = OnKeyPressControl(
            content: node.children[0].control(at: 0),
            handler: action
        )
    }
    
    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: content)
    }
}

// MARK: - OnKeyPress Control

private class OnKeyPressControl: Control {
    var contentControl: Control
    var handler: (Character) -> Bool
    
    init(content: Control, handler: @escaping (Character) -> Bool) {
        self.contentControl = content
        self.handler = handler
        super.init()
        addSubview(content, at: 0)
    }
    
    override func size(proposedSize: Size) -> Size {
        contentControl.size(proposedSize: proposedSize)
    }
    
    override func layout(size: Size) {
        super.layout(size: size)
        contentControl.layout(size: size)
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
