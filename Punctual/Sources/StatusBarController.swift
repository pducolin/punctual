import AppKit
import EventKit

class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var reminderMenuItems: [NSMenuItem] = []
    private var dynamicMenuItems: [NSMenuItem] = []
    private let upcomingSectionSentinel = NSMenuItem.separator()
    private var calendarsMenuItem = NSMenuItem(title: "Calendars", action: nil, keyEquivalent: "")
    private var soundMenuItem = NSMenuItem(title: "Sound", action: nil, keyEquivalent: "")
    private var launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
    private var countdownTimer: Timer?

    var nextEventsProvider: (() -> [EKEvent])?
    var calendarsProvider: (() -> [EKCalendar])?
    var resyncAction: (() -> Void)?

    override init() {
        super.init()
        setupButton()
        setupMenu()
        startCountdownTimer()
    }

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "clock.badge.checkmark", accessibilityDescription: "Punctual")
        button.imagePosition = .imageLeading
    }

    private func setupMenu() {
        let title = NSMenuItem(title: "Punctual", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        // Dynamic upcoming items are inserted just before this sentinel separator
        menu.addItem(upcomingSectionSentinel)

        let remindItem = NSMenuItem(title: "Remind me", action: nil, keyEquivalent: "")
        let remindMenu = NSMenu()
        for minutes in [1, 2, 5, 10] {
            let label = minutes == 1 ? "1 minute before" : "\(minutes) minutes before"
            let item = NSMenuItem(title: label, action: #selector(toggleWarningTime(_:)), keyEquivalent: "")
            item.tag = minutes
            item.target = self
            remindMenu.addItem(item)
            reminderMenuItems.append(item)
        }
        remindItem.submenu = remindMenu
        menu.addItem(remindItem)

        calendarsMenuItem.submenu = NSMenu()
        menu.addItem(calendarsMenuItem)

        soundMenuItem.action = #selector(toggleSound)
        soundMenuItem.target = self
        menu.addItem(soundMenuItem)

        launchAtLoginMenuItem.action = #selector(toggleLaunchAtLogin)
        launchAtLoginMenuItem.target = self
        menu.addItem(launchAtLoginMenuItem)

        let resyncItem = NSMenuItem(title: "Resync Calendar", action: #selector(performResync), keyEquivalent: "r")
        resyncItem.target = self
        menu.addItem(resyncItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Punctual", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu
    }

    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
        updateCountdown()
    }

    private func updateCountdown() {
        let next = nextEventsProvider?().first
        let minutes = next.map { Int($0.startDate.timeIntervalSinceNow / 60) }
        if let minutes, minutes < 60 {
            statusItem.button?.title = minutes <= 0 ? " now" : " \(minutes)m"
        } else {
            statusItem.button?.title = ""
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        updateUpcomingSection()
        updateCountdown()
        let selected = Preferences.warningMinutesList
        reminderMenuItems.forEach { $0.state = selected.contains($0.tag) ? .on : .off }
        updateCalendarsSubmenu()
        soundMenuItem.state = Preferences.soundEnabled ? .on : .off
        launchAtLoginMenuItem.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    private func updateCalendarsSubmenu() {
        guard let submenu = calendarsMenuItem.submenu else { return }
        submenu.removeAllItems()
        let calendars = calendarsProvider?() ?? []
        let disabled = Preferences.disabledCalendarIDs
        for calendar in calendars {
            let item = NSMenuItem(title: calendar.title, action: #selector(toggleCalendar(_:)), keyEquivalent: "")
            item.representedObject = calendar.calendarIdentifier
            item.state = disabled.contains(calendar.calendarIdentifier) ? .off : .on
            item.target = self
            submenu.addItem(item)
        }
        calendarsMenuItem.isEnabled = !calendars.isEmpty
    }

    @objc private func toggleCalendar(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        Preferences.toggleCalendar(id: id)
    }

    private func updateUpcomingSection() {
        dynamicMenuItems.forEach { menu.removeItem($0) }
        dynamicMenuItems.removeAll()

        let events = nextEventsProvider?() ?? []
        let insertionIndex = menu.index(of: upcomingSectionSentinel)
        guard insertionIndex != -1 else { return }

        if events.isEmpty {
            let item = NSMenuItem(title: "No upcoming meetings", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.insertItem(item, at: insertionIndex)
            dynamicMenuItems.append(item)
        } else {
            for (i, event) in events.prefix(5).enumerated() {
                let item = makeEventMenuItem(event)
                menu.insertItem(item, at: insertionIndex + i)
                dynamicMenuItems.append(item)
            }
        }
    }

    private func makeEventMenuItem(_ event: EKEvent) -> NSMenuItem {
        let minutes = Int(event.startDate.timeIntervalSinceNow / 60)
        let timeStr: String
        if minutes <= 0 {
            timeStr = "now"
        } else if minutes < 60 {
            timeStr = "in \(minutes)m"
        } else {
            timeStr = timeFormatter.string(from: event.startDate)
        }

        let itemTitle = "\(event.title ?? "Untitled") — \(timeStr)"
        let link = MeetingLinkDetector.detect(in: event)
        let item = NSMenuItem(
            title: itemTitle,
            action: link != nil ? #selector(openMeetingLink(_:)) : nil,
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = link?.url
        item.isEnabled = link != nil
        return item
    }

    private lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    @objc private func openMeetingLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func toggleWarningTime(_ sender: NSMenuItem) {
        Preferences.toggleWarningMinutes(sender.tag)
    }

    @objc private func toggleSound() {
        Preferences.soundEnabled.toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.toggle()
    }

    @objc private func performResync() {
        resyncAction?()
        updateCountdown()
    }
}
