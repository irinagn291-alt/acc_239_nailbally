import Foundation

/// Role: Felt. Codable envelope for the one felt document. Domain types never decode this JSON themselves.
struct FeltDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var slices: [Slice]
    var packs: [BoothPack]
    var openMask: UInt64
    var nailedMask: UInt64
    var nights: [Night]
    var hapticsOn: Bool
    var onboardingComplete: Bool
}

enum FeltCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ felt: Felt) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: felt))
    }

    static func decode(_ data: Data) throws -> Felt {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return felt(from: try decoder.decode(FeltDocument.self, from: data))
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func document(from felt: Felt) -> FeltDocument {
        FeltDocument(
            schemaVersion: currentSchema,
            slices: felt.slices,
            packs: felt.packs,
            openMask: felt.openMask,
            nailedMask: felt.nailedMask,
            nights: felt.nights,
            hapticsOn: felt.hapticsOn,
            onboardingComplete: felt.onboardingComplete
        )
    }

    static func felt(from document: FeltDocument) -> Felt {
        Felt(
            slices: document.slices,
            packs: document.packs,
            openMask: document.openMask,
            nailedMask: document.nailedMask,
            nights: document.nights,
            hapticsOn: document.hapticsOn,
            onboardingComplete: document.onboardingComplete
        )
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
