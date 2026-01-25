import Foundation

open class Control: LayerDrawing {
    private(set) lazy var layer: Layer = makeLayer()

    private(set) var children: [Control] = []
    private(set) weak var parent: Control?
    private(set) var index: Int = 0

    weak var window: Window?

    var root: Control { parent?.root ?? self }

    // MARK: - Hierarchy

    func addSubview(_ view: Control, at index: Int) {
        self.children.insert(view, at: index)
        layer.addLayer(view.layer, at: index)
        view.parent = self
        view.window = window
        for i in index ..< children.count {
            children[i].index = i
        }
        if let window = root.window, window.firstResponder == nil {
            if let responder = view.firstSelectableElement {
                window.firstResponder = responder
                responder.becomeFirstResponder()
            }
        }
    }

    func removeSubview(at index: Int) {
        let removingFirstResponder = children[index].isFirstResponder || root.window?.firstResponder?.isDescendant(of: children[index]) == true
        
        if removingFirstResponder {
            root.window?.firstResponder?.resignFirstResponder()
            // Set to nil first - new views added after this will become first responder
            root.window?.firstResponder = nil
        }
        
        children[index].window = nil
        children[index].parent = nil
        self.children.remove(at: index)
        layer.removeLayer(at: index)
        for i in index ..< children.count {
            children[i].index = i
        }
        
        // If we removed the first responder, try to find a new one from remaining children
        if removingFirstResponder {
            if let newResponder = selectableElement(above: index) ?? selectableElement(below: index) ?? firstSelectableElement {
                root.window?.firstResponder = newResponder
                newResponder.becomeFirstResponder()
            }
        }
    }

    func isDescendant(of control: Control) -> Bool {
        guard let parent else { return false }
        return control === parent || parent.isDescendant(of: control)
    }

    // MARK: - Size and layout

    func size(proposedSize: Size) -> Size {
        fatalError("Not implemented")
    }

    func layout(size: Size) {
        layer.frame.size = size
    }

    // MARK: - Layer

    func makeLayer() -> Layer {
        let layer = Layer()
        layer.content = self
        return layer
    }

    func cell(at position: Position) -> Cell? {
        nil
    }

    // MARK: - Events

    func handleEvent(_ char: Character) {
        for child in children {
            child.handleEvent(char)
        }
    }

    func becomeFirstResponder() {}

    func resignFirstResponder() {}

    var isFirstResponder: Bool { root.window?.firstResponder === self }

    // MARK: - Selection

    var selectable: Bool { false }

    final var firstSelectableElement: Control? {
        if selectable { return self }
        for control in children {
            if let element = control.firstSelectableElement { return element }
        }
        return nil
    }

    final func selectableElement(above index: Int) -> Control? {
        for i in (0 ..< index).reversed() {
            if let element = children[i].lastSelectableElement { return element }
        }
        return parent?.selectableElement(above: self.index)
    }

    final func selectableElement(below index: Int) -> Control? {
        for i in (index + 1) ..< children.count {
            if let element = children[i].firstSelectableElement { return element }
        }
        return parent?.selectableElement(below: self.index)
    }

    final func selectableElement(leftOf index: Int) -> Control? {
        for i in (0 ..< index).reversed() {
            if let element = children[i].lastSelectableElement { return element }
        }
        return parent?.selectableElement(leftOf: self.index)
    }

    final func selectableElement(rightOf index: Int) -> Control? {
        for i in (index + 1) ..< children.count {
            if let element = children[i].firstSelectableElement { return element }
        }
        return parent?.selectableElement(rightOf: self.index)
    }

    private var lastSelectableElement: Control? {
        if selectable { return self }
        for control in children.reversed() {
            if let element = control.lastSelectableElement { return element }
        }
        return nil
    }
}
