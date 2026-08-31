import Foundation

/// Role: Nail. Bitmask pie: eligible = open AND NOT nailed. The solver walks set bits and returns a slice index.
enum PieMask {
    static let bitCount = 64

    static func bit(_ index: Int) -> UInt64 {
        guard index >= 0, index < bitCount else { return 0 }
        return UInt64(1) << index
    }

    static func eligible(open: UInt64, nailed: UInt64) -> UInt64 {
        open & ~nailed
    }

    static func firstFreeBit(_ mask: UInt64) -> Int? {
        for index in 0 ..< bitCount where mask & bit(index) == 0 {
            return index
        }
        return nil
    }

    /// Ordinal of `bit` among set bits in `open` — the live wedge index on the replicator.
    static func wedgeOrdinal(bit: Int, open: UInt64) -> Int? {
        guard bit >= 0, bit < bitCount, open & self.bit(bit) != 0 else { return nil }
        if bit == 0 { return 0 }
        return (open & (self.bit(bit) - 1)).nonzeroBitCount
    }

    static func walk(_ mask: UInt64, ordinal: Int) -> Int? {
        guard ordinal >= 0 else { return nil }
        var seen = 0
        var remaining = mask
        var index = 0
        while remaining != 0 {
            if remaining & 1 == 1 {
                if seen == ordinal { return index }
                seen += 1
            }
            remaining >>= 1
            index += 1
        }
        return nil
    }

    /// Counts set bits in the eligible mask, draws an ordinal in that count, walks to that bit.
    static func solve(open: UInt64, nailed: UInt64, pick: (Int) -> Int) -> LandCall? {
        let mask = eligible(open: open, nailed: nailed)
        let count = mask.nonzeroBitCount
        if count == 0 { return .liftAll }
        if count == 1 {
            guard let index = walk(mask, ordinal: 0) else { return nil }
            return .awardWithoutSpin(bit: index)
        }
        let ordinal = pick(count)
        guard (0 ..< count).contains(ordinal), let index = walk(mask, ordinal: ordinal) else {
            return nil
        }
        return .spin(bit: index)
    }
}
