import Foundation

enum Preferences {
    private static let warningMinutesKey = "warningMinutes"
    private static let disabledCalendarIDsKey = "disabledCalendarIDs"

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
}
