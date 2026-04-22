import AppKit
import EventKit
import SwiftUI

struct OverlayView: View {
    let event: EKEvent
    let onDismiss: () -> Void
    let onSnooze: (_ minutes: Int) -> Void

    private var minutesUntil: Int {
        max(0, Int(event.startDate.timeIntervalSinceNow / 60))
    }

    private var urgencyColor: Color {
        minutesUntil == 0 ? .red : .orange
    }

    private var meetingLink: MeetingLink? {
        MeetingLinkDetector.detect(in: event)
    }

    private var notesSnippet: String? {
        guard let notes = event.notes, !notes.isEmpty else { return nil }
        let plain = notes.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        guard let line = plain.components(separatedBy: .newlines)
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .first(where: { !$0.isEmpty })
        else { return nil }
        return line.count > 120 ? String(line.prefix(120)) + "…" : line
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(urgencyColor)
                Text(minutesUntil == 0 ? "Starting now!" : "In \(minutesUntil) min")
                    .font(.subheadline.bold())
                    .foregroundStyle(urgencyColor)
                Spacer()
                Text(event.startDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(event.title ?? "Untitled Meeting")
                .font(.title3.bold())
                .lineLimit(2)

            if let location = event.location, !location.isEmpty, meetingLink == nil {
                Label(location, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let snippet = notesSnippet {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let calendarTitle = event.calendar?.title {
                    Text(calendarTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("1 min") { onSnooze(1) }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button("5 min") { onSnooze(5) }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                if let link = meetingLink {
                    Button("Got it") { onDismiss() }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.escape, modifiers: [])
                        .controlSize(.large)
                    Button("Join \(link.service.rawValue)") {
                        NSWorkspace.shared.open(link.url)
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                    .controlSize(.large)
                } else {
                    Button("Got it") { onDismiss() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [])
                        .controlSize(.large)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 400)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
