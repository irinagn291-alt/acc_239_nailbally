import XCTest
@testable import Nailbally

final class FeltActTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private let now = Date(timeIntervalSince1970: 1_777_680_000)

    func test_landEmptyPopulatedInvalid() throws {
        XCTAssertThrowsError(
            try FeltAct.land(on: .empty, pick: { _ in 0 }, extraTurns: 6, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? FeltFault, .emptyFelt)
        }

        var felt = try FeltAct.join("Marlo", onto: .empty)
        felt = try FeltAct.join("Vesper", onto: felt)
        felt = try FeltAct.join("Nix", onto: felt)
        let outcome = try FeltAct.land(
            on: felt,
            pick: { _ in 1 },
            extraTurns: 6,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(outcome.land?.name, "Vesper")
        XCTAssertEqual(outcome.felt.nailedMask & PieMask.bit(1), PieMask.bit(1))
        XCTAssertEqual(outcome.felt.eligibleCount, 2)
        XCTAssertNotNil(outcome.plan)
        XCTAssertEqual(outcome.plan?.wedge, 1)

        XCTAssertThrowsError(
            try FeltAct.land(on: felt, pick: { _ in 9 }, extraTurns: 6, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? FeltFault, .badDraw)
        }
        XCTAssertThrowsError(try FeltAct.join("   ", onto: felt)) { error in
            XCTAssertEqual(error as? FeltFault, .blankName)
        }
    }

    func test_lastOpenAwardsThenLiftsAll() throws {
        var felt = try FeltAct.join("Marlo", onto: .empty)
        felt = try FeltAct.join("Vesper", onto: felt)
        felt = try FeltAct.land(
            on: felt,
            pick: { _ in 0 },
            extraTurns: 5,
            now: now,
            calendar: calendar
        ).felt
        XCTAssertEqual(felt.eligibleCount, 1)
        let last = try FeltAct.land(
            on: felt,
            pick: { _ in 0 },
            extraTurns: 5,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(last.call, .awardWithoutSpin(bit: 1))
        XCTAssertNil(last.plan)
        XCTAssertEqual(last.land?.name, "Vesper")
        XCTAssertEqual(last.felt.nailedMask, 0)
        XCTAssertEqual(last.felt.eligibleCount, 2)
        XCTAssertEqual(last.felt.nights.first?.lands.map(\.name), ["Marlo", "Vesper"])
    }

    func test_lateJoinerSitsOpenAndRemoveLiftsOnlyThatNail() throws {
        var felt = try FeltAct.join("Marlo", onto: .empty)
        felt = try FeltAct.join("Vesper", onto: felt)
        felt = try FeltAct.join("Nix", onto: felt)
        felt = try FeltAct.land(
            on: felt,
            pick: { _ in 0 },
            extraTurns: 6,
            now: now,
            calendar: calendar
        ).felt
        XCTAssertEqual(felt.nailedMask, PieMask.bit(0))

        felt = try FeltAct.join("Calico", onto: felt)
        XCTAssertEqual(felt.openMask & PieMask.bit(3), PieMask.bit(3))
        XCTAssertEqual(felt.nailedMask & PieMask.bit(3), 0)

        let dropped = try XCTUnwrap(felt.slices.first { $0.name == "Marlo" }?.id)
        felt = try FeltAct.drop(dropped, from: felt)
        XCTAssertEqual(felt.openMask & PieMask.bit(0), 0)
        XCTAssertEqual(felt.nailedMask & PieMask.bit(0), 0)
        XCTAssertEqual(felt.slices.map(\.name), ["Vesper", "Nix", "Calico"])
        XCTAssertEqual(felt.eligibleCount, 3)
    }

    func test_nightKeyIsYYYYMMDDFromStartOfDay() {
        let key = NightKey.from(now, calendar: calendar)
        XCTAssertEqual(key.rawValue, 20260502)
        XCTAssertEqual(NightKey.from(now.addingTimeInterval(3 * 3600), calendar: calendar), key)
    }
}
