import Foundation

public struct Button<Label: View>: View, PrimitiveView {
    let label: VStack<Label>
    let hover: () -> Void
    let action: () -> Void

    @Environment(\.buttonHighlightStyle) private var highlightStyle

    public init(action: @escaping () -> Void, hover: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.label = VStack(content: label())
        self.action = action
        self.hover = hover
    }

    public init(_ text: String, hover: @escaping () -> Void = {}, action: @escaping () -> Void) where Label == Text {
        self.label = VStack(content: Text(text))
        self.action = action
        self.hover = hover
    }

    static var size: Int? { 1 }

    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        
        node.addNode(at: 0, Node(view: label.view))
        let control = ButtonControl(action: action, hover: hover, highlightStyle: highlightStyle)
        control.label = node.children[0].control(at: 0)
        control.addSubview(control.label, at: 0)
        node.control = control
    }

    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        node.children[0].update(using: label.view)
        
        // Update highlight style if changed
        if let control = node.control as? ButtonControl {
            control.highlightStyle = highlightStyle
            control.buttonLayer?.highlightStyle = highlightStyle
        }
    }

    private class ButtonControl: Control {
        var action: () -> Void
        var hover: () -> Void
        var label: Control!
        weak var buttonLayer: ButtonLayer?
        var highlightStyle: ButtonHighlightStyle

        init(action: @escaping () -> Void, hover: @escaping () -> Void, highlightStyle: ButtonHighlightStyle) {
            self.action = action
            self.hover = hover
            self.highlightStyle = highlightStyle
        }

        override func size(proposedSize: Size) -> Size {
            return label.size(proposedSize: proposedSize)
        }

        override func layout(size: Size) {
            super.layout(size: size)
            self.label.layout(size: size)
        }

        override func handleEvent(_ char: Character) {
            if char == "\n" || char == " " {
                action()
            }
        }

        override var selectable: Bool { true }

        override func becomeFirstResponder() {
            super.becomeFirstResponder()
            buttonLayer?.highlighted = true
            hover()
            layer.invalidate()
        }

        override func resignFirstResponder() {
            super.resignFirstResponder()
            buttonLayer?.highlighted = false
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
