import AppKit
import EventKit
import SwiftUI

class OverlayWindowController: NSObject {
    private let window: OverlayWindow

    override init() {
        window = OverlayWindow()
        super.init()
    }

    func show(event: EKEvent, onSnooze: @escaping () -> Void) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.screens[0]

        let view = OverlayView(
            event: event,
            onDismiss: { [weak self] in self?.window.orderOut(nil) },
            onSnooze: { [weak self] in self?.window.orderOut(nil); onSnooze() }
        )

        window.contentView = NSHostingView(rootView: view)

        let windowSize = CGSize(width: 440, height: 180)
        let origin = CGPoint(
            x: screen.visibleFrame.midX - windowSize.width / 2,
            y: screen.visibleFrame.midY - windowSize.height / 2
        )
        window.setFrame(CGRect(origin: origin, size: windowSize), display: true)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

class OverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hasShadow = true
        isMovableByWindowBackground = true
    }
}
