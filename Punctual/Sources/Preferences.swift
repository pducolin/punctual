import Foundation

enum Preferences {
    static var defaults: UserDefaults = .standard

    private static let warningMinutesListKey = "warningMinutesList"
    private static let disabledCalendarIDsKey = "disabledCalendarIDs"
    private static let soundEnabledKey = "soundEnabled"

    static var warningMinutesList: Set<Int> {
        get {
            guard let arr = defaults.array(forKey: warningMinutesListKey) as? [Int],
                  !arr.isEmpty else { return [2] }
            return Set(arr)
        }
        set {
            defaults.set(Array(newValue), forKey: warningMinutesListKey)
        }
    }

    static func toggleWarningMinutes(_ minutes: Int) {
        var list = warningMinutesList
        if list.contains(minutes) {
            guard list.count > 1 else { return } // always keep at least one active
            list.remove(minutes)
        } else {
            list.insert(minutes)
        }
        warningMinutesList = list
    }

    static var disabledCalendarIDs: Set<String> {
        get {
            let arr = defaults.stringArray(forKey: disabledCalendarIDsKey) ?? []
            return Set(arr)
        }
        set {
            defaults.set(Array(newValue), forKey: disabledCalendarIDsKey)
        }
    }

    static func toggleCalendar(id: String) {
        var ids = disabledCalendarIDs
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        disabledCalendarIDs = ids
    }

    // Defaults to true — use object(forKey:) so we can distinguish unset from explicit false
    static var soundEnabled: Bool {
        get { defaults.object(forKey: soundEnabledKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: soundEnabledKey) }
    }
}
