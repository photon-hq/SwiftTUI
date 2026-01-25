import Foundation

public struct VStack<Content: View>: View, PrimitiveView, LayoutRootView {
    public let content: Content
    let alignment: HorizontalAlignment
    let spacing: Extended?

    /// Horizontally aligns content to the leading edge by default.
    public init(alignment: HorizontalAlignment = .leading, spacing: Extended? = nil, @ViewBuilder _ content: () -> Content) {
        self.content = content()
        self.alignment = alignment
        self.spacing = spacing
    }
    
    init(content: Content, alignment: HorizontalAlignment = .leading, spacing: Extended? = nil) {
        self.content = content
        self.alignment = alignment
        self.spacing = spacing
    }
    
    static var size: Int? { 1 }
    
    func loadData(node: Node) {
        for i in 0 ..< node.children[0].size {
            (node.control as! VStackControl).addSubview(node.children[0].control(at: i), at: i)
        }
    }
    
    func buildNode(_ node: Node) {
        node.addNode(at: 0, Node(view: content.view))
        node.control = VStackControl(alignment: alignment, spacing: spacing ?? 0)
        node.environment = { $0.stackOrientation = .vertical }
    }
    
    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: content.view)
        let control = node.control as! VStackControl
        control.alignment = alignment
        control.spacing = spacing ?? 0
    }
    
    func insertControl(at index: Int, node: Node) {
        (node.control as! VStackControl).addSubview(node.children[0].control(at: index), at: index)
    }
    
    func removeControl(at index: Int, node: Node) {
        (node.control as! VStackControl).removeSubview(at: index)
    }
    
    private class VStackControl: Control {
        var alignment: HorizontalAlignment
        var spacing: Extended

        init(alignment: HorizontalAlignment, spacing: Extended) {
            self.alignment = alignment
            self.spacing = spacing
        }
        
        // MARK: - Layout
        
        override func size(proposedSize: Size) -> Size {
            var size: Size = .zero
            var remainingItems = children.count
            
            // Calculate total spacing needed
            let totalSpacing = remainingItems > 1 ? spacing * Extended(remainingItems - 1) : 0
            
            for control in children.sorted(by: { $0.verticalFlexibility(width: proposedSize.width) < $1.verticalFlexibility(width: proposedSize.width) }) {
                // For size calculation, give each child a fair share of remaining height
                // When proposedSize.height is 0, this gives 0 to each child which is fine
                let usedHeight = size.height
                let remainingHeight = proposedSize.height > usedHeight ? proposedSize.height - usedHeight - totalSpacing : 0
                let heightPerItem = remainingItems > 0 ? remainingHeight / Extended(remainingItems) : 0
                
                let childSize = control.size(proposedSize: Size(width: proposedSize.width, height: heightPerItem))
                size.height += childSize.height
                size.width = max(size.width, childSize.width)
                remainingItems -= 1
            }
            
            // Add total spacing to final height
            size.height += totalSpacing
            return size
        }
        
        override func layout(size: Size) {
            super.layout(size: size)
            var remainingItems = children.count
            
            // Calculate total spacing needed
            let totalSpacing = remainingItems > 1 ? spacing * Extended(remainingItems - 1) : 0
            
            // Available height for content (excluding spacing)
            var remainingHeight = size.height > totalSpacing ? size.height - totalSpacing : 0
            
            for control in children.sorted(by: { $0.verticalFlexibility(width: size.width) < $1.verticalFlexibility(width: size.width) }) {
                let heightPerItem = remainingItems > 0 ? remainingHeight / Extended(remainingItems) : 0
                let childSize = control.size(proposedSize: Size(width: size.width, height: heightPerItem))
                control.layout(size: childSize)
                remainingHeight = remainingHeight > childSize.height ? remainingHeight - childSize.height : 0
                remainingItems -= 1
            }
            
            var line: Extended = 0
            for control in children {
                control.layer.frame.position.line = line
                line += control.layer.frame.size.height
                line += spacing
                switch alignment {
                case .leading: control.layer.frame.position.column = 0
                case .center: control.layer.frame.position.column = (size.width - control.layer.frame.size.width) / 2
                case .trailing: control.layer.frame.position.column = size.width - control.layer.frame.size.width
                }
            }
        }
        
        // MARK: - Selection
        
        override func selectableElement(below index: Int) -> Control? {
            var index = index + 1
            while index < children.count {
                if let element = children[index].firstSelectableElement {
                    return element
                }
                index += 1
            }
            return super.selectableElement(below: index)
        }
        
        override func selectableElement(above index: Int) -> Control? {
            var index = index - 1
            while index >= 0 {
                if let element = children[index].firstSelectableElement {
                    return element
                }
                index -= 1
            }
            return super.selectableElement(above: index)
        }
    }
}
