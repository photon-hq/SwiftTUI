# SwiftTUI

![swift 5.6](https://user-images.githubusercontent.com/13484323/184016525-cb42a72c-1e2e-4d8d-8777-e7481386377c.svg)
![platform macos](https://user-images.githubusercontent.com/13484323/184016156-817e14dc-24b5-4b46-a4d4-0de9391a37a4.svg)
![platform linux](https://user-images.githubusercontent.com/13484323/184016263-afa5dd0c-8d9a-4fba-91fe-23e892d64cca.svg)

An innovative, exceptionally simple way to build text-based user interfaces.

SwiftTUI brings SwiftUI to the terminal. It provides an API similar to SwiftUI to build terminal applications with a text-based user interface.

![](screenshot.png)

### What is working

Many features from SwiftUI are already working:

✓ Property wrappers `@State`, `@Binding`, `@Environment` and `@ObservedObject`<br>
✓ Stacks, `.frame()`, `.padding()`, `GeometryReader`, `@ViewBuilder`, `ForEach`, `Group`<br>
✓ Structural identity like in SwiftUI<br>
✓ Scrollable lists with `ScrollView`<br>
✓ `Button`, `TextField` and moving focus with the arrow keys<br>
✓ `Color` with ANSI, xterm and TrueColor support<br>
✓ `Text` with bold, italic, underscore and strikethrough variants<br>
✓ `.onAppear()`, `.border()`, `.foregroundColor()`, `.backgroundColor`<br>
✓ `.buttonHighlightStyle()` for customizing button focus appearance<br>
✓ `.onKeyPress()` for detecting keyboard input<br>
✓ `onInterrupt` for handling Ctrl+C<br>
✓ Modifiers applied to all views in a collection like in SwiftUI

### Getting started

To use SwiftTUI, you need to add the SwiftTUI package dependency. Import SwiftTUI in your files, and write your views like SwiftUI views with the supported features. Then, start the terminal application using one of your views as the root view. This is the simplest SwiftTUI app you can write:

```swift
import SwiftTUI

struct MyTerminalView: View {
  var body: some View {
    Text("Hello, world!")
  }
}

Application(rootView: MyTerminalView()).start()
```

To run your app, change to your package's directory and run it from the terminal:

```
swift run
```

For more, and to see the supported functionality, check out the [documentation](https://rensbreur.github.io/SwiftTUI/documentation/swifttui/).

### Handling Ctrl+C (Interrupt Signal)

By default, pressing Ctrl+C will quit the application. You can override this behavior using the `onInterrupt` callback:

```swift
let app = Application(rootView: MyView())

app.onInterrupt = {
    // Return .quit to exit, or .none to ignore
    return .none  // Ignore Ctrl+C
}

app.start()
```

#### InterruptResult Options

| Result | Description |
|--------|-------------|
| `.quit` | Exit the application |
| `.none` | Ignore the interrupt and continue running |

#### Example: Confirmation Before Quit

```swift
import SwiftTUI

struct MyView: View {
    @State var showQuitConfirmation = false
    
    var body: some View {
        VStack {
            Text("Press Ctrl+C to quit")
            if showQuitConfirmation {
                Text("Are you sure? Press 'y' to confirm, 'n' to cancel")
            }
        }
    }
}

let app = Application(rootView: MyView())

app.onInterrupt = {
    print("Ctrl+C pressed!")
    // Add your confirmation logic here
    return .none  // Don't quit immediately
}

app.start()
```

### Keyboard Input

SwiftTUI provides the `.onKeyPress()` modifier to detect keyboard input outside of text fields.

#### Detect a Specific Key

```swift
VStack {
    Text("Press 'q' to quit")
    Button("Click Me") { }
}
.onKeyPress("q") {
    print("Q was pressed!")
    exit(0)
}
```

#### Detect Any Key

```swift
VStack {
    Text("Press any key")
}
.onKeyPress { char in
    print("Key pressed: \(char)")
    return true  // Return true if handled, false to propagate
}
```

#### Multiple Key Handlers

```swift
VStack {
    Text("Press 'q' to quit, 'r' to refresh")
}
.onKeyPress("q") {
    exit(0)
}
.onKeyPress("r") {
    refresh()
}
```

### Button Highlight Styles

SwiftTUI provides customizable button highlight styles. By default, buttons invert their colors when focused. You can customize this behavior using the `.buttonHighlightStyle()` modifier.

#### Available Styles

| Style | Description |
|-------|-------------|
| `.inverted` | Default behavior - swaps foreground and background colors |
| `.textColor(Color)` | Only changes text color when focused (no background change) |
| `.none` | No visual change when focused |

#### Usage Examples

**Change text color only (no background):**
```swift
Button("Click Me") {
    print("Pressed!")
}
.buttonHighlightStyle(.textColor(.cyan))
```

**No highlight effect:**
```swift
Button("Click Me") {
    print("Pressed!")
}
.buttonHighlightStyle(.none)
```

**Apply to multiple buttons:**
```swift
VStack {
    Button("Button 1") { }
    Button("Button 2") { }
    Button("Button 3") { }
}
.buttonHighlightStyle(.textColor(.green))
```

**Different styles for different buttons:**
```swift
VStack {
    Button("Cyan Highlight") { }
        .buttonHighlightStyle(.textColor(.cyan))
    
    Button("No Highlight") { }
        .buttonHighlightStyle(.none)
    
    Button("Default Inverted") { }
        // Uses default .inverted style
}
```

### Examples

These example projects are included in the repository.

#### ToDoList ([Examples/ToDoList](Examples/ToDoList))

![](Examples/ToDoList/screenshot.png)

This is a very simple to-do list application. Use the arrow keys to move around. To complete a to-do item, select it, and then press the enter key or space bar. To add a new to-do item, move to the text field, enter a description, and press the enter key to add it to the list. Completed items are automatically removed from the list after half a second.

#### Flags ([Examples/Flags](Examples/Flags))

![](Examples/Flags/screenshot.png)

This is a flag editor, which you will agree to if you come from a country which has a simple flag consisting of colors stacked horizontally or vertically. Select one of the colors of the flag to change it. Use the options on the right to change the number of colors or the flag orientation.

### Showcase

Are you working on a project that's using SwiftTUI? Get in touch with me if you'd like to have it featured here.

#### soundcld

![](https://github.com/rensbreur/SwiftTUI/assets/13484323/b585708c-3606-495e-a96e-3eba92f39916)

This is a TUI application for SoundCloud. It's not (yet) available publicly.

### More

See a screen recording of SwiftTUI [in action](https://www.reddit.com/r/SwiftUI/comments/wlabyn/im_making_a_version_of_swiftui_for_terminal/) on Reddit.

Learn how [the diffing works](https://rensbr.eu/blog/swiftui-diffing/) on my blog.

### Documentation

You can find generated documentation [here](https://rensbreur.github.io/SwiftTUI/documentation/swifttui/).

### Contributing

This is an open-source project, contributions are welcome! The goal of SwiftTUI is to resemble SwiftUI when it comes to both API and   inner workings, unless those don't make sense for terminal applications. Features that SwiftUI lacks but that would be useful for terminal applications might better live in a seperate project.
