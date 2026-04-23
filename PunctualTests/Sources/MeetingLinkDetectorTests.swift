import XCTest
@testable import Punctual

final class MeetingLinkDetectorTests: XCTestCase {

    // MARK: - Individual service detection

    func testZoom() {
        let link = MeetingLinkDetector.match("https://zoom.us/j/123456789")
        XCTAssertEqual(link?.service, .zoom)
        XCTAssertEqual(link?.url.absoluteString, "https://zoom.us/j/123456789")
    }

    func testZoomWithQueryParams() {
        let link = MeetingLinkDetector.match("https://zoom.us/j/99887766?pwd=abc123xyz")
        XCTAssertEqual(link?.service, .zoom)
    }

    func testZoomSubdomain() {
        let link = MeetingLinkDetector.match("https://mycompany.zoom.us/j/123456789")
        XCTAssertEqual(link?.service, .zoom)
    }

    func testGoogleMeet() {
        let link = MeetingLinkDetector.match("https://meet.google.com/abc-defg-hij")
        XCTAssertEqual(link?.service, .googleMeet)
        XCTAssertEqual(link?.url.absoluteString, "https://meet.google.com/abc-defg-hij")
    }

    func testTeamsMicrosoft() {
        let link = MeetingLinkDetector.match("https://teams.microsoft.com/l/meetup-join/abc123%40thread.v2/0")
        XCTAssertEqual(link?.service, .teams)
    }

    func testTeamsLive() {
        let link = MeetingLinkDetector.match("https://teams.live.com/meet/9876543210")
        XCTAssertEqual(link?.service, .teams)
    }

    func testWebex() {
        let link = MeetingLinkDetector.match("https://mycompany.webex.com/meet/myroom")
        XCTAssertEqual(link?.service, .webex)
    }

    func testAround() {
        let link = MeetingLinkDetector.match("https://meet.around.co/r/abc123")
        XCTAssertEqual(link?.service, .around)
    }

    func testWhereby() {
        let link = MeetingLinkDetector.match("https://whereby.com/my-room")
        XCTAssertEqual(link?.service, .whereby)
    }

    func testWherebySubdomain() {
        let link = MeetingLinkDetector.match("https://mycompany.whereby.com/room-name")
        XCTAssertEqual(link?.service, .whereby)
    }

    func testJitsi() {
        let link = MeetingLinkDetector.match("https://meet.jit.si/my-meeting-room")
        XCTAssertEqual(link?.service, .jitsi)
    }

    func testBlueJeans() {
        let link = MeetingLinkDetector.match("https://bluejeans.com/123456789")
        XCTAssertEqual(link?.service, .bluejeans)
    }

    func testGoToMeeting() {
        let link = MeetingLinkDetector.match("https://global.gotomeeting.com/join/123456789")
        XCTAssertEqual(link?.service, .gotomeeting)
    }

    // MARK: - No match

    func testNoLinkInPlainText() {
        XCTAssertNil(MeetingLinkDetector.match("Let's catch up tomorrow"))
    }

    func testEmptyString() {
        XCTAssertNil(MeetingLinkDetector.match(""))
    }

    func testHttpNotMatched() {
        XCTAssertNil(MeetingLinkDetector.match("http://zoom.us/j/123456789"))
    }

    func testUnrecognisedDomain() {
        XCTAssertNil(MeetingLinkDetector.match("https://unknownservice.com/meet/abc"))
    }

    // MARK: - Link embedded in longer text

    func testLinkEmbeddedInNotes() {
        let text = "Please join: https://meet.google.com/abc-defg-hij\nAgenda follows."
        let link = MeetingLinkDetector.match(text)
        XCTAssertEqual(link?.service, .googleMeet)
    }

    func testFirstServiceWinsWhenMultipleLinksPresent() {
        // Zoom pattern appears first in servicePatterns; Zoom URL comes first in text
        let text = "Zoom: https://zoom.us/j/111 or Teams: https://teams.microsoft.com/l/meetup-join/abc"
        let link = MeetingLinkDetector.match(text)
        XCTAssertEqual(link?.service, .zoom)
    }

    // MARK: - detect(in:) field priority

    func testDetectPrefersURLFieldOverLocation() {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.url = URL(string: "https://zoom.us/j/111")
        event.location = "https://teams.microsoft.com/l/meetup-join/abc"
        let link = MeetingLinkDetector.detect(in: event)
        XCTAssertEqual(link?.service, .zoom)
    }

    func testDetectPrefersLocationOverNotes() {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.location = "https://teams.microsoft.com/l/meetup-join/abc"
        event.notes = "https://zoom.us/j/111"
        let link = MeetingLinkDetector.detect(in: event)
        XCTAssertEqual(link?.service, .teams)
    }

    func testDetectFallsBackToNotes() {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.notes = "Join here: https://meet.jit.si/my-room"
        let link = MeetingLinkDetector.detect(in: event)
        XCTAssertEqual(link?.service, .jitsi)
    }

    func testDetectReturnsNilWhenNoLink() {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = "Coffee chat"
        event.location = "Kitchen"
        XCTAssertNil(MeetingLinkDetector.detect(in: event))
    }
}
