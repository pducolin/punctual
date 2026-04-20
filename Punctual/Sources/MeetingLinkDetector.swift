import EventKit
import Foundation

enum MeetingService: String {
    case zoom = "Zoom"
    case googleMeet = "Google Meet"
    case teams = "Teams"
    case webex = "Webex"
}

struct MeetingLink {
    let url: URL
    let service: MeetingService
}

struct MeetingLinkDetector {
    private static let servicePatterns: [(pattern: String, service: MeetingService)] = [
        (#"https://[\w.-]*zoom\.us/j/[^\s"'>]+"#, .zoom),
        (#"https://meet\.google\.com/[a-z-]+"#, .googleMeet),
        (#"https://teams\.microsoft\.com/l/meetup-join/[^\s"'>]+"#, .teams),
        (#"https://teams\.live\.com/meet/[^\s"'>]+"#, .teams),
        (#"https://[\w-]+\.webex\.com/[^\s"'>]+"#, .webex),
    ]

    static func detect(in event: EKEvent) -> MeetingLink? {
        // Dedicated URL field first
        if let url = event.url, let link = match(url.absoluteString) {
            return link
        }
        // Then location and notes
        for text in [event.location, event.notes].compactMap({ $0 }) {
            if let link = match(text) { return link }
        }
        return nil
    }

    private static func match(_ text: String) -> MeetingLink? {
        for (pattern, service) in servicePatterns {
            if let range = text.range(of: pattern, options: .regularExpression),
               let url = URL(string: String(text[range])) {
                return MeetingLink(url: url, service: service)
            }
        }
        return nil
    }
}
