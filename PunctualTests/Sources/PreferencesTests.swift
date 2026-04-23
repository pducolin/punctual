import XCTest
@testable import Punctual

final class PreferencesTests: XCTestCase {
    private let suiteName = "com.pducolin.PunctualTests"

    override func setUp() {
        super.setUp()
        Preferences.defaults = UserDefaults(suiteName: suiteName)!
        Preferences.defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        Preferences.defaults.removePersistentDomain(forName: suiteName)
        Preferences.defaults = .standard
        super.tearDown()
    }

    // MARK: - warningMinutesList

    func testWarningMinutesListDefaultWhenNotSet() {
        XCTAssertEqual(Preferences.warningMinutesList, [2])
    }

    func testWarningMinutesListDefaultWhenStoredEmpty() {
        Preferences.warningMinutesList = []
        XCTAssertEqual(Preferences.warningMinutesList, [2])
    }

    func testSetWarningMinutesList() {
        Preferences.warningMinutesList = [5, 10]
        XCTAssertEqual(Preferences.warningMinutesList, [5, 10])
    }

    func testToggleWarningMinutesAddsValue() {
        Preferences.warningMinutesList = [2]
        Preferences.toggleWarningMinutes(5)
        XCTAssertEqual(Preferences.warningMinutesList, [2, 5])
    }

    func testToggleWarningMinutesRemovesValue() {
        Preferences.warningMinutesList = [2, 5]
        Preferences.toggleWarningMinutes(5)
        XCTAssertEqual(Preferences.warningMinutesList, [2])
    }

    func testToggleWarningMinutesCannotRemoveLastValue() {
        Preferences.warningMinutesList = [2]
        Preferences.toggleWarningMinutes(2)
        XCTAssertEqual(Preferences.warningMinutesList, [2], "Must keep at least one active threshold")
    }

    func testToggleWarningMinutesCanRemoveFromMultiple() {
        Preferences.warningMinutesList = [1, 2, 5]
        Preferences.toggleWarningMinutes(1)
        XCTAssertFalse(Preferences.warningMinutesList.contains(1))
        XCTAssertTrue(Preferences.warningMinutesList.contains(2))
        XCTAssertTrue(Preferences.warningMinutesList.contains(5))
    }

    // MARK: - disabledCalendarIDs

    func testDisabledCalendarIDsDefaultIsEmpty() {
        XCTAssertTrue(Preferences.disabledCalendarIDs.isEmpty)
    }

    func testSetDisabledCalendarIDs() {
        Preferences.disabledCalendarIDs = ["cal-1", "cal-2"]
        XCTAssertEqual(Preferences.disabledCalendarIDs, ["cal-1", "cal-2"])
    }

    func testToggleCalendarDisablesCalendar() {
        Preferences.toggleCalendar(id: "cal-abc")
        XCTAssertTrue(Preferences.disabledCalendarIDs.contains("cal-abc"))
    }

    func testToggleCalendarEnablesCalendar() {
        Preferences.disabledCalendarIDs = ["cal-abc"]
        Preferences.toggleCalendar(id: "cal-abc")
        XCTAssertFalse(Preferences.disabledCalendarIDs.contains("cal-abc"))
    }

    func testToggleCalendarDoesNotAffectOtherCalendars() {
        Preferences.disabledCalendarIDs = ["cal-abc", "cal-xyz"]
        Preferences.toggleCalendar(id: "cal-abc")
        XCTAssertFalse(Preferences.disabledCalendarIDs.contains("cal-abc"))
        XCTAssertTrue(Preferences.disabledCalendarIDs.contains("cal-xyz"))
    }

    func testDisabledCalendarIDsRoundTrips() {
        let ids: Set<String> = ["A1B2C3D4-0000-0000-0000-000000000001",
                                "A1B2C3D4-0000-0000-0000-000000000002"]
        Preferences.disabledCalendarIDs = ids
        XCTAssertEqual(Preferences.disabledCalendarIDs, ids)
    }

    // MARK: - soundEnabled

    func testSoundEnabledDefaultIsTrue() {
        XCTAssertTrue(Preferences.soundEnabled)
    }

    func testSetSoundEnabledFalse() {
        Preferences.soundEnabled = false
        XCTAssertFalse(Preferences.soundEnabled)
    }

    func testSetSoundEnabledTrue() {
        Preferences.soundEnabled = false
        Preferences.soundEnabled = true
        XCTAssertTrue(Preferences.soundEnabled)
    }

    func testSoundEnabledPersists() {
        Preferences.soundEnabled = false
        // Re-read from the same suite to verify persistence
        let reread = Preferences.defaults.object(forKey: "soundEnabled") as? Bool
        XCTAssertEqual(reread, false)
    }
}
