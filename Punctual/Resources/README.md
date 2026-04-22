# Resources

Static configuration files bundled with the app.

## Files

### `Info.plist`
Standard macOS app metadata. Two entries matter most:

- **`LSUIElement = true`** — marks the app as an agent (background-only) process. This suppresses the Dock icon and the application menu bar. Combined with the `.accessory` activation policy set in `AppDelegate`, the app lives entirely in the status bar.
- **`NSCalendarsFullAccessUsageDescription`** — the string macOS displays in the calendar permission dialog on first launch. This key is required; omitting it causes a crash when the app calls `requestFullAccessToEvents`.

### `Punctual.entitlements`
Currently empty — no App Sandbox or special entitlements are needed. Calendar access is obtained at runtime through the standard `requestFullAccessToEvents` API, gated by the usage description above.

## Build note
`project.yml` (at the repo root) is the [XcodeGen](https://github.com/yonaskolb/XcodeGen) template that generates `Punctual.xcodeproj`. Edit `project.yml` to change build settings, add targets, or modify entitlements — then run `xcodegen generate` to regenerate the project file. The `.xcodeproj` is committed so contributors without XcodeGen can still open the project directly.
