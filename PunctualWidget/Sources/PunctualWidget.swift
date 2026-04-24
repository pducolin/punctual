import EventKit
import SwiftUI
import WidgetKit

// MARK: - Data model

struct UpcomingEntry: TimelineEntry {
    let date: Date
    let events: [EventSnapshot]
}

struct EventSnapshot: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let calendarTitle: String?
    let hasVideoLink: Bool
}

// MARK: - Timeline provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingEntry {
        UpcomingEntry(date: Date(), events: [
            EventSnapshot(id: "1", title: "Team Standup", startDate: Date().addingTimeInterval(12 * 60), calendarTitle: "Work", hasVideoLink: true),
            EventSnapshot(id: "2", title: "Design Review", startDate: Date().addingTimeInterval(90 * 60), calendarTitle: "Work", hasVideoLink: false),
            EventSnapshot(id: "3", title: "1:1 with Manager", startDate: Date().addingTimeInterval(150 * 60), calendarTitle: "Work", hasVideoLink: true),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingEntry) -> Void) {
        completion(UpcomingEntry(date: Date(), events: fetchEvents()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingEntry>) -> Void) {
        let entry = UpcomingEntry(date: Date(), events: fetchEvents())
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func fetchEvents() -> [EventSnapshot] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
        let store = EKEventStore()
        let now = Date()
        let end = now.addingTimeInterval(8 * 3600)
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .prefix(3)
            .map { event in
                EventSnapshot(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    calendarTitle: event.calendar?.title,
                    hasVideoLink: hasVideoLink(event)
                )
            }
    }

    // Mirrors MeetingLinkDetector patterns — HTTPS only, anchored to known paths
    private static let videoPatterns: [String] = [
        #"https://[\w.-]*zoom\.us/j/"#,
        #"https://meet\.google\.com/[a-z-]"#,
        #"https://teams\.microsoft\.com/l/meetup-join/"#,
        #"https://teams\.live\.com/meet/"#,
        #"https://[\w-]+\.webex\.com/"#,
        #"https://meet\.around\.co/"#,
        #"https://[\w.-]*whereby\.com/"#,
        #"https://meet\.jit\.si/"#,
        #"https://bluejeans\.com/"#,
        #"https://global\.gotomeeting\.com/join/"#,
    ]

    private func hasVideoLink(_ event: EKEvent) -> Bool {
        let texts = [event.url?.absoluteString, event.location, event.notes].compactMap { $0 }
        return texts.contains { text in
            Self.videoPatterns.contains { text.range(of: $0, options: .regularExpression) != nil }
        }
    }
}

// MARK: - Views

struct PunctualWidgetEntryView: View {
    var entry: UpcomingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("Upcoming")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            if entry.events.isEmpty {
                Spacer()
                Text("No upcoming meetings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(entry.events) { event in
                    EventRowView(event: event)
                }
                Spacer()
            }
        }
        .padding()
        .containerBackground(.regularMaterial, for: .widget)
    }
}

struct EventRowView: View {
    let event: EventSnapshot

    private var minutesUntil: Int {
        max(0, Int(event.startDate.timeIntervalSinceNow / 60))
    }

    private var timeLabel: String {
        if minutesUntil == 0 { return "now" }
        if minutesUntil < 60 { return "in \(minutesUntil)m" }
        return event.startDate.formatted(.dateTime.hour().minute())
    }

    private var timeColor: Color {
        if minutesUntil == 0 { return .red }
        if minutesUntil < 10 { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: event.hasVideoLink ? "video.fill" : "calendar")
                .font(.caption2)
                .foregroundStyle(.orange)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.caption)
                    .lineLimit(1)
                if let cal = event.calendarTitle {
                    Text(cal)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(timeLabel)
                .font(.caption2.bold())
                .foregroundStyle(timeColor)
        }
    }
}

// MARK: - Widget declaration

struct PunctualWidget: Widget {
    let kind = "PunctualWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PunctualWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Punctual")
        .description("See your upcoming meetings at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
