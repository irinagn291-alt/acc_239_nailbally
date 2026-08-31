import XCTest
@testable import Nailbally

final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_pickFirstThenRotateClockwiseOntoSliceCentre() throws {
        let open: UInt64 = 0b1111
        let pick: (Int) -> Int = { _ in 2 }
        let call = try XCTUnwrap(PieMask.solve(open: open, nailed: 0, pick: pick))
        guard case .spin(let bit) = call else {
            XCTFail("pick first from the eligible mask")
            return
        }
        let plan = try XCTUnwrap(SpinPlan.make(bit: bit, open: open, extraTurns: 6))
        let live = open.nonzeroBitCount
        XCTAssertEqual(plan.liveCount, live)
        XCTAssertEqual(plan.landCenterDegrees, (Double(plan.wedge) + 0.5) * (360.0 / Double(live)), accuracy: 0.0001)
        XCTAssertEqual(plan.clockwiseDegrees, 6 * 360.0 + plan.landCenterDegrees, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(plan.clockwiseDegrees, 5 * 360.0)
        XCTAssertLessThanOrEqual(plan.clockwiseDegrees, 7 * 360.0 + 360.0)
        XCTAssertEqual(plan.duration, 3.4)
        XCTAssertTrue(SpinPlan.extraTurnBounds.contains(plan.extraTurns))
        XCTAssertEqual(plan.pulseTimes, plan.pulseTimes.sorted())
        XCTAssertLessThan(plan.pulseTimes.last ?? 0, plan.nailSeatAt)
        XCTAssertEqual(plan.nailSeatAt, 3.4)
    }

    func test_familyInvariant_nailedBitNeverLandsUntilLift() {
        let open: UInt64 = 0b1111
        let nailed: UInt64 = PieMask.bit(1)
        for ordinal in 0 ..< 3 {
            let call = PieMask.solve(open: open, nailed: nailed, pick: { _ in ordinal })
            guard case .spin(let bit) = call else {
                XCTFail("expected spin")
                return
            }
            XCTAssertEqual(nailed & PieMask.bit(bit), 0)
            XCTAssertNotEqual(bit, 1)
        }
    }
}

@MainActor
final class PresentationMaskTests: XCTestCase {
    func test_architecture_pieFaceWalksOpenMaskNailsAreSiblings() {
        let felt = FeltFixture.nightedSeed()
        let face = PieFace.project(felt)
        XCTAssertEqual(face.liveCount, felt.openMask.nonzeroBitCount)
        XCTAssertEqual(face.eligibleCount, PieMask.eligible(open: felt.openMask, nailed: felt.nailedMask).nonzeroBitCount)
        XCTAssertEqual(face.wedges.map(\.bit), [0, 1, 2, 3])
        XCTAssertTrue(face.wedges[0].nailed)
        XCTAssertFalse(face.wedges[1].nailed)
        XCTAssertEqual(face.eligibleCount, 3)
        for wedge in face.wedges {
            XCTAssertNotEqual(felt.openMask & PieMask.bit(wedge.bit), 0)
        }
    }

    func test_architecture_replicatorCountMatchesOpenBitsAndNailsAreNotReplicas() {
        let view = PieCanvasView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
        let face = PieFace.project(FeltFixture.nightedSeed())
        view.layoutIfNeeded()
        view.apply(face)
        XCTAssertEqual(view.replicatorCount, face.liveCount)
        XCTAssertEqual(view.nailLayerCount, face.wedges.filter(\.nailed).count)
        XCTAssertNotEqual(view.nailLayerCount, view.replicatorCount)
    }

    func test_screensConstructWithNoArguments() {
        _ = ArenaView()
        _ = HistoryView()
        _ = SettingsView()
        _ = FairShareView()
        _ = OnboardingView()
        XCTAssertEqual(String(describing: ArenaView.self), "ArenaView")
    }
}
