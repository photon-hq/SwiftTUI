import Foundation

public struct Button<Label: View>: View, PrimitiveView {
    let label: VStack<Label>
    let hover: () -> Void
    let action: () -> Void
    let selected: Binding<Bool>?

    @Environment(\.buttonHighlightStyle) private var highlightStyle

    /// Creates a button with a custom label.
    ///
    /// - Parameters:
    ///   - selected: A binding to a Boolean value that indicates whether the button is currently focused/selected.
    ///   - action: The action to perform when the user triggers the button.
    ///   - hover: An optional action to perform when the button becomes focused.
    ///   - label: A view builder that creates the button's label.
    public init(selected: Binding<Bool>? = nil, action: @escaping () -> Void, hover: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.label = VStack(content: label())
        self.action = action
        self.hover = hover
        self.selected = selected
    }

    /// Creates a button with a text label.
    ///
    /// - Parameters:
    ///   - text: The text to display on the button.
    ///   - selected: A binding to a Boolean value that indicates whether the button is currently focused/selected.
    ///   - hover: An optional action to perform when the button becomes focused.
    ///   - action: The action to perform when the user triggers the button.
    public init(_ text: String, selected: Binding<Bool>? = nil, hover: @escaping () -> Void = {}, action: @escaping () -> Void) where Label == Text {
        self.label = VStack(content: Text(text))
        self.action = action
        self.hover = hover
        self.selected = selected
    }

    static var size: Int? { 1 }

    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        
        node.addNode(at: 0, Node(view: label.view))
        let control = ButtonControl(
            action: action,
            hover: hover,
            highlightStyle: highlightStyle,
            selectedBinding: selected
        )
        control.label = node.children[0].control(at: 0)
        control.addSubview(control.label, at: 0)
        node.control = control
    }

    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        node.children[0].update(using: label.view)
        
        // Update highlight style and selected binding if changed
        if let control = node.control as? ButtonControl {
            control.highlightStyle = highlightStyle
            control.buttonLayer?.highlightStyle = highlightStyle
            control.selectedBinding = selected
        }
    }

    private class ButtonControl: Control {
        var action: () -> Void
        var hover: () -> Void
        var label: Control!
        weak var buttonLayer: ButtonLayer?
        var highlightStyle: ButtonHighlightStyle
        var selectedBinding: Binding<Bool>?
        private var hasSyncedInitialState = false
        
        // Track highlighted state directly since becomeFirstResponder is called
        // before the binding is set up in some cases
        private var isHighlighted = false

        init(action: @escaping () -> Void, hover: @escaping () -> Void, highlightStyle: ButtonHighlightStyle, selectedBinding: Binding<Bool>?) {
            self.action = action
            self.hover = hover
            self.highlightStyle = highlightStyle
            self.selectedBinding = selectedBinding
        }

        override func size(proposedSize: Size) -> Size {
            return label.size(proposedSize: proposedSize)
        }

        override func layout(size: Size) {
            super.layout(size: size)
            self.label.layout(size: size)
            
            // Sync initial state after first layout
            // Use async to avoid modifying state during layout cycle
            if !hasSyncedInitialState {
                hasSyncedInitialState = true
                DispatchQueue.main.async { [weak self] in
                    self?.syncSelectedBinding()
                }
            }
        }

        func syncSelectedBinding() {
            // Use our tracked highlighted state which is set by becomeFirstResponder
            let isCurrentlyHighlighted = isHighlighted
            
            // Update binding to match
            if let binding = selectedBinding, binding.wrappedValue != isCurrentlyHighlighted {
                binding.wrappedValue = isCurrentlyHighlighted
            }
        }

        override func handleEvent(_ char: Character) {
            if char == "\n" || char == " " {
                action()
            }
        }

        override var selectable: Bool { true }

        override func becomeFirstResponder() {
            super.becomeFirstResponder()
            isHighlighted = true
            buttonLayer?.highlighted = true
            selectedBinding?.wrappedValue = true
            hover()
            layer.invalidate()
        }

        override func resignFirstResponder() {
            super.resignFirstResponder()
            isHighlighted = false
            buttonLayer?.highlighted = false
            selectedBinding?.wrappedValue = false
            layer.invalidate()
        }

        override func makeLayer() -> Layer {
            let layer = ButtonLayer(highlightStyle: highlightStyle)
            self.buttonLayer = layer
            return layer
        }
    }

    private class ButtonLayer: Layer {
        var highlighted = false
        var highlightStyle: ButtonHighlightStyle

        init(highlightStyle: ButtonHighlightStyle) {
            self.highlightStyle = highlightStyle
        }

        override func cell(at position: Position) -> Cell? {
            var cell = super.cell(at: position)
            if highlighted {
                switch highlightStyle {
                case .inverted:
                    cell?.attributes.inverted.toggle()
                case .textColor(let color):
                    cell?.foregroundColor = color
                case .none:
                    break
                }
            }
            return cell
        }
    }
}
