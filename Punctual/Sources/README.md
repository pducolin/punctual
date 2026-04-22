# Sources

Swift source files for Punctual. The app uses an **AppKit + SwiftUI hybrid**: AppKit handles the menu bar and window lifecycle (things that need direct OS integration), SwiftUI handles the overlay UI (declarative, easy to iterate on).

## Files

### `PunctualApp.swift`
The `@main` entry point. Uses `@NSApplicationDelegateAdaptor` to bridge SwiftUI's app lifecycle into `AppDelegate`. The `Settings` scene is intentionally empty — all UI is managed by AppKit controllers, not SwiftUI windows.

### `AppDelegate.swift`
Wires the three main components together on launch and sets the activation policy to `.accessory` (suppresses the Dock icon). Owns the lifetime of `StatusBarController`, `CalendarMonitor`, and `OverlayWindowController`.

### `CalendarMonitor.swift`
Monitors the system calendar via EventKit using two complementary mechanisms:

- **30-second polling** — catches the initial state at launch and acts as a safety net
- **`EKEventStoreChanged` notifications** — reacts to edits the user makes in Calendar in real time, without waiting for the next poll cycle

Tracks `shownEventIDs` so each event triggers at most one alert per app session. The `warningMinutes` property (default 2) controls how far ahead to look.

### `StatusBarController.swift`
Creates the persistent menu bar icon via `NSStatusBar`. The icon is the only UI visible between alerts. The menu provides a Quit action.

### `OverlayView.swift`
SwiftUI view that renders the alert card. Uses `.regularMaterial` background (system translucency blur) so it reads clearly over any content beneath it. Urgency is color-coded: orange when the meeting is minutes away, red when it is starting now.

### `OverlayWindowController.swift`
Manages the `NSWindow` that hosts the overlay. Key window configuration:

- **`.popUpMenu` level** — floats above virtually everything, including other app windows
- **`.canJoinAllSpaces` + `.fullScreenAuxiliary`** — visible on all Spaces and when the active app is fullscreen
- Window is centered on the screen that contains the cursor, so it always appears on the display the user is looking at
