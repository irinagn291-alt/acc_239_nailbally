import XCTest
@testable import Nailbally

final class NailballyTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: NailballyApp.self), "NailballyApp")
    }
}
