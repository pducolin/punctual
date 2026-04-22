import Foundation

enum Preferences {
    private static let warningMinutesKey = "warningMinutes"
    private static let disabledCalendarIDsKey = "disabledCalendarIDs"
    private static let soundEnabledKey = "soundEnabled"

    static var warningMinutes: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: warningMinutesKey)
            return v > 0 ? v : 2
        }
        set {
            UserDefaults.standard.set(newValue, forKey: warningMinutesKey)
        }
    }

    static var disabledCalendarIDs: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: disabledCalendarIDsKey) ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: disabledCalendarIDsKey)
        }
    }

    static func toggleCalendar(id: String) {
        var ids = disabledCalendarIDs
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        disabledCalendarIDs = ids
    }

    // Defaults to true — use object(forKey:) so we can distinguish unset from explicit false
    static var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: soundEnabledKey) }
    }
}
