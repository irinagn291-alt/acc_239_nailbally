import Foundation

/// Role: Felt. In-memory pie: slices, packs, open and nailed masks, nights. File and UserDefaults are a projection.
struct Felt: Equatable, Sendable {
    var slices: [Slice]
    var packs: [BoothPack]
    var openMask: UInt64
    var nailedMask: UInt64
    var nights: [Night]
    var hapticsOn: Bool
    var onboardingComplete: Bool

    static let empty = Felt(
        slices: [],
        packs: [],
        openMask: 0,
        nailedMask: 0,
        nights: [],
        hapticsOn: true,
        onboardingComplete: false
    )

    var eligibleMask: UInt64 { PieMask.eligible(open: openMask, nailed: nailedMask) }
    var eligibleCount: Int { eligibleMask.nonzeroBitCount }
    var liveCount: Int { slices.count }

    func slice(bit: Int) -> Slice? {
        slices.first { $0.bit == bit }
    }
}

enum FeltFault: Error, Equatable, Sendable {
    case emptyFelt
    case fullFelt
    case blankName
    case unknownSlice
    case unknownPack
    case badDraw
}

/// Role: Felt. Pure mutations. Views never write masks; land writes one nailed bit or lifts all.
enum FeltAct {
    static func join(_ name: String, onto felt: Felt) throws -> Felt {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FeltFault.blankName }
        guard let bit = PieMask.firstFreeBit(felt.openMask) else { throw FeltFault.fullFelt }
        var next = felt
        next.slices.append(Slice(name: trimmed, bit: bit))
        next.openMask |= PieMask.bit(bit)
        return next
    }

    static func drop(_ id: UUID, from felt: Felt) throws -> Felt {
        guard let slice = felt.slices.first(where: { $0.id == id }) else { throw FeltFault.unknownSlice }
        var next = felt
        next.slices.removeAll { $0.id == id }
        next.openMask &= ~PieMask.bit(slice.bit)
        next.nailedMask &= ~PieMask.bit(slice.bit)
        return next
    }

    static func keep(_ pack: BoothPack, on felt: Felt) throws -> Felt {
        let names = pack.names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard names.contains(where: { !$0.isEmpty }) else { throw FeltFault.blankName }
        var next = felt
        if !next.packs.contains(where: { $0.id == pack.id }) {
            next.packs.append(pack)
        }
        return next
    }

    static func load(_ pack: BoothPack, onto felt: Felt) throws -> Felt {
        var next = try keep(pack, on: felt)
        let names = pack.names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard next.slices.count + names.count <= PieMask.bitCount else { throw FeltFault.fullFelt }
        for name in names {
            next = try join(name, onto: next)
        }
        return next
    }

    static func land(
        on felt: Felt,
        pick: (Int) -> Int,
        extraTurns: Int,
        now: Date,
        calendar: Calendar
    ) throws -> LandOutcome {
        guard felt.openMask != 0 else { throw FeltFault.emptyFelt }
        guard let call = PieMask.solve(open: felt.openMask, nailed: felt.nailedMask, pick: pick) else {
            throw FeltFault.badDraw
        }
        switch call {
        case .liftAll:
            var next = felt
            next.nailedMask = 0
            return LandOutcome(felt: next, call: call, plan: nil, land: nil)
        case .awardWithoutSpin(let bit):
            let seated = try seat(bit, on: felt, now: now, calendar: calendar)
            return LandOutcome(felt: seated.felt, call: call, plan: nil, land: seated.land)
        case .spin(let bit):
            guard let plan = SpinPlan.make(bit: bit, open: felt.openMask, extraTurns: extraTurns) else {
                throw FeltFault.badDraw
            }
            let seated = try seat(bit, on: felt, now: now, calendar: calendar)
            return LandOutcome(felt: seated.felt, call: call, plan: plan, land: seated.land)
        }
    }

    private static func seat(
        _ bit: Int,
        on felt: Felt,
        now: Date,
        calendar: Calendar
    ) throws -> (felt: Felt, land: Land) {
        guard let slice = felt.slice(bit: bit) else { throw FeltFault.unknownSlice }
        var next = felt
        next.nailedMask |= PieMask.bit(bit)
        let land = Land(sliceID: slice.id, name: slice.name, bit: bit)
        let key = NightKey.from(now, calendar: calendar)
        if let index = next.nights.firstIndex(where: { $0.key == key }) {
            next.nights[index].lands.append(land)
        } else {
            next.nights.append(Night(key: key, lands: [land]))
            next.nights.sort { $0.key < $1.key }
        }
        if next.eligibleCount == 0 {
            next.nailedMask = 0
        }
        return (next, land)
    }
}
