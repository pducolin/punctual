import Foundation

enum Preferences {
    private static let warningMinutesKey = "warningMinutes"

    static var warningMinutes: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: warningMinutesKey)
            return v > 0 ? v : 2
        }
        set {
            UserDefaults.standard.set(newValue, forKey: warningMinutesKey)
        }
    }
}
