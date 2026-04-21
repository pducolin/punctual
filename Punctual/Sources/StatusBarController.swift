import AppKit

class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var reminderMenuItems: [NSMenuItem] = []

    override init() {
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clock.badge.checkmark", accessibilityDescription: "Punctual")
        }

        let title = NSMenuItem(title: "Punctual", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        let remindItem = NSMenuItem(title: "Remind me", action: nil, keyEquivalent: "")
        let remindMenu = NSMenu()
        for minutes in [1, 2, 5, 10] {
            let label = minutes == 1 ? "1 minute before" : "\(minutes) minutes before"
            let item = NSMenuItem(title: label, action: #selector(setWarningTime(_:)), keyEquivalent: "")
            item.tag = minutes
            item.target = self
            remindMenu.addItem(item)
            reminderMenuItems.append(item)
        }
        remindItem.submenu = remindMenu
        menu.addItem(remindItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Punctual", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        let current = Preferences.warningMinutes
        reminderMenuItems.forEach { $0.state = $0.tag == current ? .on : .off }
    }

    @objc private func setWarningTime(_ sender: NSMenuItem) {
        Preferences.warningMinutes = sender.tag
    }
}
