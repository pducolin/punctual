import AppKit
import EventKit
import SwiftUI

struct OverlayView: View {
    let event: EKEvent
    let onDismiss: () -> Void

    private var minutesUntil: Int {
        max(0, Int(event.startDate.timeIntervalSinceNow / 60))
    }

    private var urgencyColor: Color {
        minutesUntil == 0 ? .red : .orange
    }

    private var meetingLink: MeetingLink? {
        MeetingLinkDetector.detect(in: event)
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

            HStack {
                if let calendarTitle = event.calendar?.title {
                    Text(calendarTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("Got it") { onDismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])
                    .controlSize(.large)
                if let link = meetingLink {
                    Button("Join \(link.service.rawValue)") {
                        NSWorkspace.shared.open(link.url)
                        onDismiss()
                    }
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
