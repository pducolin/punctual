import EventKit
import Foundation

class CalendarMonitor {
    private let store = EKEventStore()
    private var timer: Timer?
    private var dismissedEventIDs: Set<String> = []
    private var snoozedEvents: [String: Date] = [:]
    private(set) var isAuthorized = false

    var onUpcomingEvent: ((EKEvent) -> Void)?

    func snooze(eventID: String, for duration: TimeInterval = 5 * 60) {
        snoozedEvents[eventID] = Date().addingTimeInterval(duration)
        dismissedEventIDs.remove(eventID)
    }

    func availableCalendars() -> [EKCalendar] {
        guard isAuthorized else { return [] }
        return store.calendars(for: .event).sorted { $0.title < $1.title }
    }

    func upcomingEvents(withinHours hours: Int = 2) -> [EKEvent] {
        guard isAuthorized else { return [] }
        let disabled = Preferences.disabledCalendarIDs
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(hours * 3600))
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && !disabled.contains($0.calendar?.calendarIdentifier ?? "") }
            .sorted { $0.startDate < $1.startDate }
    }

    func requestAccessAndStart() {
        store.requestFullAccessToEvents { [weak self] granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.isAuthorized = true
                self?.startPolling()
                NotificationCenter.default.addObserver(
                    self as Any,
                    selector: #selector(CalendarMonitor.storeChanged),
                    name: .EKEventStoreChanged,
                    object: self?.store
                )
            }
        }
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkUpcomingEvents()
        }
        timer?.fire()
    }

    @objc private func storeChanged() {
        checkUpcomingEvents()
    }

    private func checkUpcomingEvents() {
        let now = Date()
        let lookAheadSeconds = TimeInterval(Preferences.warningMinutes * 60)
        let windowEnd = now.addingTimeInterval(lookAheadSeconds + 60)

        let predicate = store.predicateForEvents(withStart: now, end: windowEnd, calendars: nil)
        let events = store.events(matching: predicate)

        snoozedEvents = snoozedEvents.filter { $0.value > now }

        let disabledCalendars = Preferences.disabledCalendarIDs
        for event in events where !event.isAllDay {
            guard let id = event.eventIdentifier else { continue }
            guard !dismissedEventIDs.contains(id) else { continue }
            guard snoozedEvents[id] == nil else { continue }
            guard !disabledCalendars.contains(event.calendar?.calendarIdentifier ?? "") else { continue }
            let secondsUntil = event.startDate.timeIntervalSinceNow
            guard secondsUntil <= lookAheadSeconds else { continue }
            dismissedEventIDs.insert(id)
            onUpcomingEvent?(event)
        }
    }
}
