import Foundation

/// Role: Night. Order of lands for one YYYYMMDD key — a sheet, not a bag of isolated winners.
struct Night: Hashable, Sendable, Equatable, Codable {
    var key: NightKey
    var lands: [Land]
}
