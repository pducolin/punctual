import EventKit
import Foundation

class CalendarMonitor {
    private let store = EKEventStore()
    private var timer: Timer?
    private var dismissedEventIDs: Set<String> = []
    private var snoozedEvents: [String: Date] = [:]

    var onUpcomingEvent: ((EKEvent) -> Void)?
    var warningMinutes = 2

    func snooze(eventID: String, for duration: TimeInterval = 5 * 60) {
        snoozedEvents[eventID] = Date().addingTimeInterval(duration)
        dismissedEventIDs.remove(eventID)
    }

    func requestAccessAndStart() {
        store.requestFullAccessToEvents { [weak self] granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
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
        let lookAheadSeconds = TimeInterval(warningMinutes * 60)
        let windowEnd = now.addingTimeInterval(lookAheadSeconds + 60)

        let predicate = store.predicateForEvents(withStart: now, end: windowEnd, calendars: nil)
        let events = store.events(matching: predicate)

        snoozedEvents = snoozedEvents.filter { $0.value > now }

        for event in events where !event.isAllDay {
            guard let id = event.eventIdentifier else { continue }
            guard !dismissedEventIDs.contains(id) else { continue }
            guard snoozedEvents[id] == nil else { continue }
            let secondsUntil = event.startDate.timeIntervalSinceNow
            guard secondsUntil <= lookAheadSeconds else { continue }
            dismissedEventIDs.insert(id)
            onUpcomingEvent?(event)
        }
    }
}
