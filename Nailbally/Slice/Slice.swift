import Foundation

/// Role: Slice. One live name on the pie. `bit` is the mask coordinate; the replicator still shows every open slice.
struct Slice: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var name: String
    var bit: Int

    init(id: UUID = UUID(), name: String, bit: Int) {
        self.id = id
        self.name = name
        self.bit = bit
    }
}
