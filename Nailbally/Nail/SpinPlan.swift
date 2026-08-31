import Foundation

/// Role: Nail. Pick the land index first, then rotate clockwise: 360/n per slice, +5–7 turns, centre, ~3.4s.
struct SpinPlan: Equatable, Sendable {
    static let durationSeconds: TimeInterval = 3.4
    static let extraTurnBounds = 5 ... 7

    var bit: Int
    var wedge: Int
    var liveCount: Int
    var extraTurns: Int
    var landCenterDegrees: Double
    var clockwiseDegrees: Double
    var duration: TimeInterval
    var pulseTimes: [TimeInterval]
    var nailSeatAt: TimeInterval

    static func make(
        bit: Int,
        open: UInt64,
        extraTurns: Int,
        currentDegrees: Double = 0
    ) -> SpinPlan? {
        guard extraTurnBounds.contains(extraTurns) else { return nil }
        let liveCount = open.nonzeroBitCount
        guard liveCount >= 2, let wedge = PieMask.wedgeOrdinal(bit: bit, open: open) else {
            return nil
        }
        let step = 360.0 / Double(liveCount)
        let center = (Double(wedge) + 0.5) * step
        let delta = clockwiseDistance(from: currentDegrees, to: center)
        let total = Double(extraTurns) * 360.0 + delta
        let duration = durationSeconds
        return SpinPlan(
            bit: bit,
            wedge: wedge,
            liveCount: liveCount,
            extraTurns: extraTurns,
            landCenterDegrees: center,
            clockwiseDegrees: total,
            duration: duration,
            pulseTimes: pulseSchedule(duration: duration),
            nailSeatAt: duration
        )
    }

    static func normalize(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }

    static func clockwiseDistance(from: Double, to: Double) -> Double {
        var delta = normalize(to) - normalize(from)
        if delta < 0 { delta += 360 }
        return delta
    }

    /// Haptics ease into a landing climax; a second tick fires when the nail seats.
    static func pulseSchedule(duration: TimeInterval) -> [TimeInterval] {
        [0.35, 0.55, 0.72, 0.85, 0.92].map { $0 * duration }
    }
}
