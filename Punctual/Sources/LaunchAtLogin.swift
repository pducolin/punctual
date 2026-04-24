import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func enable() -> Error? {
        do { try SMAppService.mainApp.register(); return nil }
        catch { return error }
    }

    @discardableResult
    static func disable() -> Error? {
        do { try SMAppService.mainApp.unregister(); return nil }
        catch { return error }
    }

    static func toggle() {
        if isEnabled { disable() } else { enable() }
    }
}
