import XCTest
@testable import Nailbally

final class MidwayHopTests: XCTestCase {
    func test_contactURLAndUserAgentAreThisApp() {
        XCTAssertEqual(MidwayHop.contactURL.absoluteString, "https://nailbally-felt.pro/contact-us")
        XCTAssertEqual(MidwayHop.userAgent, "Nailbally/1.0 (iOS; +https://nailbally-felt.pro)")
    }
}
