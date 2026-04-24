import EventKit
import Foundation

class CalendarMonitor {
    private let store = EKEventStore()
    private var timer: Timer?
    private var shownReminders: [String: Set<Int>] = [:]
    private var snoozedEvents: [String: Date] = [:]
    private(set) var isAuthorized = EKEventStore.authorizationStatus(for: .event) == .fullAccess

    var onUpcomingEvent: ((EKEvent) -> Void)?

    func resync() {
        isAuthorized = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        guard isAuthorized else { return }
        if timer == nil {
            startPolling()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(storeChanged),
                name: .EKEventStoreChanged,
                object: store
            )
        } else {
            checkUpcomingEvents()
        }
    }

    func snooze(eventID: String, for duration: TimeInterval = 5 * 60) {
        snoozedEvents[eventID] = Date().addingTimeInterval(duration)
        shownReminders.removeValue(forKey: eventID)
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
                guard let self else { return }
                self.isAuthorized = true
                self.startPolling()
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(CalendarMonitor.storeChanged),
                    name: .EKEventStoreChanged,
                    object: self.store
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
        let thresholds = Preferences.warningMinutesList.sorted(by: >)
        let maxLookAhead = TimeInterval((thresholds.first ?? 2) * 60)
        let windowEnd = now.addingTimeInterval(maxLookAhead + 60)

        let predicate = store.predicateForEvents(withStart: now, end: windowEnd, calendars: nil)
        let events = store.events(matching: predicate)

        snoozedEvents = snoozedEvents.filter { $0.value > now }

        // Drop reminder state for events no longer in the look-ahead window so the dict doesn't grow forever
        let activeIDs = Set(events.compactMap(\.eventIdentifier))
        shownReminders = shownReminders.filter { activeIDs.contains($0.key) }

        let disabledCalendars = Preferences.disabledCalendarIDs
        for event in events where !event.isAllDay {
            guard let id = event.eventIdentifier else { continue }
            guard snoozedEvents[id] == nil else { continue }
            guard !disabledCalendars.contains(event.calendar?.calendarIdentifier ?? "") else { continue }
            let secondsUntil = event.startDate.timeIntervalSinceNow
            // Fire for the largest threshold not yet shown that this event falls within
            for threshold in thresholds {
                guard secondsUntil <= TimeInterval(threshold * 60) else { continue }
                guard !(shownReminders[id]?.contains(threshold) ?? false) else { continue }
                shownReminders[id, default: []].insert(threshold)
                onUpcomingEvent?(event)
                break
            }
        }
    }
}
