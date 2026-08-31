import Foundation

/// Role: Nail. One seated land in night order. A nailed bit leaves the draw set and stays on the pie.
struct Land: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var sliceID: UUID
    var name: String
    var bit: Int

    init(id: UUID = UUID(), sliceID: UUID, name: String, bit: Int) {
        self.id = id
        self.sliceID = sliceID
        self.name = name
        self.bit = bit
    }
}

/// Role: Nail. Solver result. Land is an index through the eligible mask, never the full pie.
enum LandCall: Equatable, Sendable {
    case spin(bit: Int)
    case awardWithoutSpin(bit: Int)
    case liftAll
}

/// Role: Nail. Outcome of one land verb. Plan exists only after a pick that still needs rotation.
struct LandOutcome: Equatable, Sendable {
    var felt: Felt
    var call: LandCall
    var plan: SpinPlan?
    var land: Land?
}
