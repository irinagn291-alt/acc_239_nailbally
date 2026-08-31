import XCTest
@testable import Nailbally

final class SpinPlanTests: XCTestCase {
    func test_pickFirstThenRotateClockwiseOntoSliceCentre() throws {
        let open: UInt64 = 0b1111
        let pick: (Int) -> Int = { _ in 2 }
        let call = try XCTUnwrap(PieMask.solve(open: open, nailed: 0, pick: pick))
        guard case .spin(let bit) = call else {
            XCTFail("expected spin")
            return
        }
        let plan = try XCTUnwrap(SpinPlan.make(bit: bit, open: open, extraTurns: 6))
        XCTAssertEqual(bit, 2)
        XCTAssertEqual(plan.wedge, 2)
        XCTAssertEqual(plan.liveCount, 4)
        XCTAssertEqual(plan.extraTurns, 6)
        XCTAssertEqual(plan.duration, 3.4)
        XCTAssertEqual(plan.landCenterDegrees, (2.5) * 90.0, accuracy: 0.0001)
        XCTAssertEqual(plan.clockwiseDegrees, 6 * 360.0 + plan.landCenterDegrees, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(plan.clockwiseDegrees, 5 * 360.0)
        XCTAssertTrue(SpinPlan.extraTurnBounds.contains(plan.extraTurns))
        XCTAssertEqual(plan.nailSeatAt, 3.4)
        XCTAssertEqual(plan.pulseTimes, plan.pulseTimes.sorted())
        XCTAssertGreaterThan(plan.pulseTimes.last ?? 0, plan.pulseTimes.first ?? 1)
        XCTAssertLessThan(plan.pulseTimes.last ?? 0, plan.nailSeatAt)
    }

    func test_extraTurnsStayInFiveToSevenAndRejectCoinFlipRange() {
        let open: UInt64 = 0b111
        XCTAssertNil(SpinPlan.make(bit: 0, open: open, extraTurns: 4))
        XCTAssertNil(SpinPlan.make(bit: 0, open: open, extraTurns: 8))
        XCTAssertNotNil(SpinPlan.make(bit: 0, open: open, extraTurns: 5))
        XCTAssertNotNil(SpinPlan.make(bit: 0, open: open, extraTurns: 7))
        XCTAssertNil(SpinPlan.make(bit: 0, open: 0b1, extraTurns: 6))
    }

    func test_clockwiseDistanceNeverGoesBackwards() {
        XCTAssertEqual(SpinPlan.clockwiseDistance(from: 350, to: 10), 20, accuracy: 0.0001)
        XCTAssertEqual(SpinPlan.clockwiseDistance(from: 10, to: 10), 0, accuracy: 0.0001)
        XCTAssertGreaterThan(SpinPlan.clockwiseDistance(from: 10, to: 9), 300)
    }
}
