import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var calendarMonitor: CalendarMonitor?
    private var overlayWindowController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        overlayWindowController = OverlayWindowController()
        statusBarController = StatusBarController()
        calendarMonitor = CalendarMonitor()

        statusBarController?.nextEventsProvider = { [weak self] in
            self?.calendarMonitor?.upcomingEvents() ?? []
        }

        statusBarController?.calendarsProvider = { [weak self] in
            self?.calendarMonitor?.availableCalendars() ?? []
        }

        calendarMonitor?.onUpcomingEvent = { [weak self] event in
            guard let self else { return }
            self.overlayWindowController?.show(event: event, onSnooze: { [weak self] in
                guard let id = event.eventIdentifier else { return }
                self?.calendarMonitor?.snooze(eventID: id)
            })
        }

        calendarMonitor?.requestAccessAndStart()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
