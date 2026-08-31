import Foundation

/// Role: Slice. Named dare or room pack stored on the felt. Loaded onto open bits; never a remote catalog.
struct BoothPack: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var title: String
    var names: [String]

    init(id: UUID = UUID(), title: String, names: [String]) {
        self.id = id
        self.title = title
        self.names = names
    }
}
