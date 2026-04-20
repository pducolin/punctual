import AppKit

class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    init() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clock.badge.checkmark", accessibilityDescription: "Punctual")
        }

        let title = NSMenuItem(title: "Punctual", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Punctual", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }
}
