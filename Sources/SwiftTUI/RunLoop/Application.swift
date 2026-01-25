import Foundation
#if os(macOS)
import AppKit
#endif

/// The result of handling an interrupt signal (Ctrl+C)
public enum InterruptResult {
    /// Quit the application
    case quit
    /// Do nothing, continue running
    case none
}

public class Application {
    private let node: Node
    private let window: Window
    private let control: Control
    private let renderer: Renderer

    private let runLoopType: RunLoopType

    private var arrowKeyParser = ArrowKeyParser()

    private var invalidatedNodes: [Node] = []
    private var updateScheduled = false
    private var isUpdating = false

    /// Called when the user presses Ctrl+C.
    /// Return `.quit` to exit the application, or `.none` to ignore the interrupt.
    /// If not set, the default behavior is to quit immediately.
    public var onInterrupt: (() -> InterruptResult)?

    public init<I: View>(rootView: I, runLoopType: RunLoopType = .dispatch) {
        self.runLoopType = runLoopType

        node = Node(view: VStack(content: rootView).view)
        node.build()

        control = node.control!

        window = Window()
        window.addControl(control)

        renderer = Renderer(layer: window.layer)
        window.layer.renderer = renderer

        // Set application references AFTER all stored properties are initialized
        node.application = self
        renderer.application = self

        // Now set up first responder - application context is available
        window.firstResponder = control.firstSelectableElement
        window.firstResponder?.becomeFirstResponder()
    }

    var stdInSource: DispatchSourceRead?

    public enum RunLoopType {
        /// The default option, using Dispatch for the main run loop.
        case dispatch

        #if os(macOS)
        /// This creates and runs an NSApplication with an associated run loop. This allows you
        /// e.g. to open NSWindows running simultaneously to the terminal app. This requires macOS
        /// and AppKit.
        case cocoa
        #endif
    }

    public func start() {
        setInputMode()
        updateWindowSize()
        control.layout(size: window.layer.frame.size)
        renderer.draw()

        let stdInSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
        stdInSource.setEventHandler(qos: .default, flags: [], handler: self.handleInput)
        stdInSource.resume()
        self.stdInSource = stdInSource

        let sigWinChSource = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
        sigWinChSource.setEventHandler(qos: .default, flags: [], handler: self.handleWindowSizeChange)
        sigWinChSource.resume()

        signal(SIGINT, SIG_IGN)
        let sigIntSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigIntSource.setEventHandler(qos: .default, flags: [], handler: self.handleInterrupt)
        sigIntSource.resume()

        switch runLoopType {
        case .dispatch:
            dispatchMain()
        #if os(macOS)
        case .cocoa:
            NSApplication.shared.setActivationPolicy(.accessory)
            NSApplication.shared.run()
        #endif
        }
    }

    private func setInputMode() {
        var tattr = termios()
        tcgetattr(STDIN_FILENO, &tattr)
        tattr.c_lflag &= ~tcflag_t(ECHO | ICANON)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr);
    }

    private func handleInput() {
        let data = FileHandle.standardInput.availableData

        guard let string = String(data: data, encoding: .utf8) else {
            FileHandle.standardError.write("[Application.handleInput] Failed to decode input\n".data(using: .utf8)!)
            return
        }

        FileHandle.standardError.write("[Application.handleInput] Received input: \(string.debugDescription), firstResponder=\(window.firstResponder.map { String(describing: type(of: $0)) } ?? "nil")\n".data(using: .utf8)!)

        for char in string {
            if arrowKeyParser.parse(character: char) {
                guard let key = arrowKeyParser.arrowKey else { continue }
                arrowKeyParser.arrowKey = nil
                FileHandle.standardError.write("[Application.handleInput] Arrow key: \(key), firstResponder: \(window.firstResponder.map { String(describing: type(of: $0)) } ?? "nil")\n".data(using: .utf8)!)
                if key == .down {
                    let next = window.firstResponder?.selectableElement(below: 0)
                    FileHandle.standardError.write("[Application.handleInput] down: next=\(next.map { String(describing: type(of: $0)) } ?? "nil")\n".data(using: .utf8)!)
                    if let next = next {
                        window.firstResponder?.resignFirstResponder()
                        window.firstResponder = next
                        window.firstResponder?.becomeFirstResponder()
                    }
                } else if key == .up {
                    let next = window.firstResponder?.selectableElement(above: 0)
                    FileHandle.standardError.write("[Application.handleInput] up: next=\(next.map { String(describing: type(of: $0)) } ?? "nil")\n".data(using: .utf8)!)
                    if let next = next {
                        window.firstResponder?.resignFirstResponder()
                        window.firstResponder = next
                        window.firstResponder?.becomeFirstResponder()
                    }
                } else if key == .right {
                    let next = window.firstResponder?.selectableElement(rightOf: 0)
                    FileHandle.standardError.write("[Application.handleInput] right: next=\(next.map { String(describing: type(of: $0)) } ?? "nil")\n".data(using: .utf8)!)
                    if let next = next {
                        window.firstResponder?.resignFirstResponder()
                        window.firstResponder = next
                        window.firstResponder?.becomeFirstResponder()
                    }
                } else if key == .left {
                    let next = window.firstResponder?.selectableElement(leftOf: 0)
                    FileHandle.standardError.write("[Application.handleInput] left: next=\(next.map { String(describing: type(of: $0)) } ?? "nil")\n".data(using: .utf8)!)
                    if let next = next {
                        window.firstResponder?.resignFirstResponder()
                        window.firstResponder = next
                        window.firstResponder?.becomeFirstResponder()
                    }
                }
            } else if char == ASCII.EOT {
                stop()
            } else {
                window.firstResponder?.handleEvent(char)
            }
        }
    }

    private func handleInterrupt() {
        if let handler = onInterrupt {
            let result = handler()
            switch result {
            case .quit:
                stop()
            case .none:
                // Do nothing, continue running
                break
            }
        } else {
            // Default behavior: quit
            stop()
        }
    }

    func invalidateNode(_ node: Node) {
        invalidatedNodes.append(node)
        scheduleUpdate()
    }

    func scheduleUpdate() {
        FileHandle.standardError.write("[Application.scheduleUpdate] isUpdating=\(isUpdating) updateScheduled=\(updateScheduled)\n".data(using: .utf8)!)
        // If we're currently in the middle of an update, just mark that another update is needed
        // The update() method will check this flag at the end and schedule another update if needed
        if isUpdating {
            updateScheduled = true
            return
        }
        
        if !updateScheduled {
            FileHandle.standardError.write("[Application.scheduleUpdate] Scheduling async update\n".data(using: .utf8)!)
            DispatchQueue.main.async { self.update() }
            updateScheduled = true
        }
    }

    private func update() {
        FileHandle.standardError.write("[Application.update] Starting update, invalidatedNodes.count=\(invalidatedNodes.count)\n".data(using: .utf8)!)
        isUpdating = true

        // Process all invalidated nodes, including any that get added during the update
        while !invalidatedNodes.isEmpty {
            let nodesToUpdate = invalidatedNodes
            invalidatedNodes = []
            
            for node in nodesToUpdate {
                node.update(using: node.view)
            }
        }

        isUpdating = false

        control.layout(size: window.layer.frame.size)
        FileHandle.standardError.write("[Application.update] Calling renderer.update()\n".data(using: .utf8)!)
        renderer.update()
        
        // Reset updateScheduled at the END of update, so any scheduleUpdate() calls
        // that happened during update will properly schedule a new update next time
        updateScheduled = false
    }

    private func handleWindowSizeChange() {
        updateWindowSize()
        control.layer.invalidate()
        update()
    }

    private func updateWindowSize() {
        var size = winsize()
        guard ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0,
              size.ws_col > 0, size.ws_row > 0 else {
            assertionFailure("Could not get window size")
            return
        }
        window.layer.frame.size = Size(width: Extended(Int(size.ws_col)), height: Extended(Int(size.ws_row)))
        renderer.setCache()
    }

    private func stop() {
        renderer.stop()
        resetInputMode() // Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
        exit(0)
    }

    /// Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
    private func resetInputMode() {
        // Reset ECHO and ICANON values:
        var tattr = termios()
        tcgetattr(STDIN_FILENO, &tattr)
        tattr.c_lflag |= tcflag_t(ECHO | ICANON)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr);
    }

}
