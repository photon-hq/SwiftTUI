import Foundation

public struct Button<Label: View>: View, PrimitiveView {
    let label: VStack<Label>
    let hover: () -> Void
    let action: () -> Void
    let selected: Binding<Bool>?

    @Environment(\.buttonHighlightStyle) private var highlightStyle

    /// Creates a button with a custom label.
    public init(selected: Binding<Bool>? = nil, action: @escaping () -> Void, hover: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.label = VStack(content: label())
        self.action = action
        self.hover = hover
        self.selected = selected
    }

    /// Creates a button with a text label.
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
        
        if let control = node.control as? ButtonControl {
            control.action = action
            control.hover = hover
            control.highlightStyle = highlightStyle
            control.buttonLayer?.highlightStyle = highlightStyle
            control.selectedBinding = selected
            control.syncSelectedBinding()
        }
    }

    private class ButtonControl: Control {
        var action: () -> Void
        var hover: () -> Void
        var label: Control!
        weak var buttonLayer: ButtonLayer?
        var highlightStyle: ButtonHighlightStyle
        var selectedBinding: Binding<Bool>? {
            didSet {
                syncSelectedBinding()
            }
        }
        
        var isHighlighted = false {
            didSet {
                FileHandle.standardError.write("[ButtonControl.isHighlighted] self=\(ObjectIdentifier(self)) oldValue=\(oldValue) newValue=\(isHighlighted)\n".data(using: .utf8)!)
                guard isHighlighted != oldValue else {
                    FileHandle.standardError.write("[ButtonControl.isHighlighted] No change, returning\n".data(using: .utf8)!)
                    return
                }
                FileHandle.standardError.write("[ButtonControl.isHighlighted] buttonLayer=\(buttonLayer.map { String(describing: ObjectIdentifier($0)) } ?? "nil"), calling invalidate\n".data(using: .utf8)!)
                buttonLayer?.highlighted = isHighlighted
                selectedBinding?.wrappedValue = isHighlighted
                layer.invalidate()
            }
        }

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
        }

        func syncSelectedBinding() {
            let isCurrentlyHighlighted = isHighlighted
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
            FileHandle.standardError.write("[ButtonControl.becomeFirstResponder] self=\(ObjectIdentifier(self))\n".data(using: .utf8)!)
            super.becomeFirstResponder()
            isHighlighted = true
            hover()
        }

        override func resignFirstResponder() {
            FileHandle.standardError.write("[ButtonControl.resignFirstResponder] self=\(ObjectIdentifier(self))\n".data(using: .utf8)!)
            super.resignFirstResponder()
            isHighlighted = false
        }

        override func makeLayer() -> Layer {
            let layer = ButtonLayer(highlightStyle: highlightStyle)
            layer.highlighted = isHighlighted
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
