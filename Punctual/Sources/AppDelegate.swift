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

        calendarMonitor?.onUpcomingEvent = { [weak self] event in
            self?.overlayWindowController?.show(event: event)
        }

        calendarMonitor?.requestAccessAndStart()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
