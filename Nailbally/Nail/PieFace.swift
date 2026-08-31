import Foundation

/// Role: Nail. Projection of the bitmask pie for the replicator. Eligible = open AND NOT nailed; land is an index through that mask. Views never write bits.
struct PieFace: Equatable, Sendable {
    struct Wedge: Equatable, Sendable {
        var bit: Int
        var name: String
        var nailed: Bool
    }

    var wedges: [Wedge]
    var eligibleCount: Int
    var rotationDegrees: Double

    var liveCount: Int { wedges.count }

    static let empty = PieFace(wedges: [], eligibleCount: 0, rotationDegrees: 0)

    /// Walks the open mask for replica order. Nails mark landed bits; they stay on the pie.
    static func project(_ felt: Felt, rotation: Double = 0, nails: UInt64? = nil) -> PieFace {
        let shown = nails ?? felt.nailedMask
        let live = felt.openMask.nonzeroBitCount
        var wedges: [Wedge] = []
        wedges.reserveCapacity(live)
        for ordinal in 0 ..< live {
            guard let bit = PieMask.walk(felt.openMask, ordinal: ordinal) else { break }
            wedges.append(
                Wedge(
                    bit: bit,
                    name: felt.slice(bit: bit)?.name ?? "",
                    nailed: shown & PieMask.bit(bit) != 0
                )
            )
        }
        return PieFace(
            wedges: wedges,
            eligibleCount: felt.eligibleCount,
            rotationDegrees: rotation
        )
    }
}
