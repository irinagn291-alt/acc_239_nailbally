import XCTest
@testable import Nailbally

final class PieMaskTests: XCTestCase {
    func test_eligibleIsOpenAndNotNailed() {
        let open: UInt64 = 0b11111
        let nailed: UInt64 = 0b00101
        XCTAssertEqual(PieMask.eligible(open: open, nailed: nailed), 0b11010)
    }

    func test_solverNeverSamplesFullPieOrNailedBit() {
        let open: UInt64 = 0b11111
        let nailed: UInt64 = 0b00101
        var seenCount: Int?
        for ordinal in 0 ..< 3 {
            let call = PieMask.solve(open: open, nailed: nailed, pick: { count in
                seenCount = count
                return ordinal
            })
            XCTAssertEqual(seenCount, 3)
            guard case .spin(let bit) = call else {
                XCTFail("expected spin")
                return
            }
            XCTAssertEqual(nailed & PieMask.bit(bit), 0)
            XCTAssertNotEqual(bit, 0)
            XCTAssertNotEqual(bit, 2)
        }
    }

    func test_maskWalkHitsOrdinalAmongSetBits() {
        let mask: UInt64 = 0b10110
        XCTAssertEqual(PieMask.walk(mask, ordinal: 0), 1)
        XCTAssertEqual(PieMask.walk(mask, ordinal: 1), 2)
        XCTAssertEqual(PieMask.walk(mask, ordinal: 2), 4)
        XCTAssertNil(PieMask.walk(mask, ordinal: 3))
    }

    func test_lastOpenIsAwardedWithoutSpin() {
        let open: UInt64 = 0b10101
        let nailed: UInt64 = 0b00101
        var pickCalled = false
        let call = PieMask.solve(open: open, nailed: nailed, pick: { _ in
            pickCalled = true
            return 0
        })
        XCTAssertEqual(call, .awardWithoutSpin(bit: 4))
        XCTAssertFalse(pickCalled)
    }

    func test_zeroEligibleLiftsAllNails() {
        let open: UInt64 = 0b00111
        let nailed: UInt64 = 0b00111
        let call = PieMask.solve(open: open, nailed: nailed, pick: { _ in 0 })
        XCTAssertEqual(call, .liftAll)
    }

    func test_wedgeOrdinalSkipsClearedBits() {
        let open: UInt64 = 0b11010
        XCTAssertEqual(PieMask.wedgeOrdinal(bit: 1, open: open), 0)
        XCTAssertEqual(PieMask.wedgeOrdinal(bit: 3, open: open), 1)
        XCTAssertEqual(PieMask.wedgeOrdinal(bit: 4, open: open), 2)
        XCTAssertNil(PieMask.wedgeOrdinal(bit: 0, open: open))
    }
}
